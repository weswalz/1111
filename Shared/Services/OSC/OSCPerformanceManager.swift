//
//  OSCPerformanceManager.swift
//  LED Messenger
//
//  Created on April 18, 2025
//

import Foundation
import Combine

/// Class to manage OSC performance and optimization
class OSCPerformanceManager: ObservableObject {
    // MARK: - Properties
    
    /// Settings manager
    private let settingsManager: SettingsManager
    
    /// Logger service
    private let logger: LoggingService
    
    /// Message cache for recently sent messages
    private var messageCache: [String: OSCMessage] = [:]
    
    /// Cache expiration time in seconds
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    /// Message rate limiting queue
    private let sendQueue = DispatchQueue(label: "com.ledmessenger.oscPerformance", qos: .userInitiated)
    
    /// Throttle window for identical messages in seconds
    private let messageThrottleWindow: TimeInterval = 0.1
    
    /// Last send time by message hash
    private var lastSendTime: [String: Date] = [:]
    
    /// Statistics for sent messages
    @Published private(set) var statistics = OSCStatistics()
    
    /// Message pooling properties
    private var messagePool: [OSCMessage] = []
    private var isPoolingEnabled = false
    private var poolTimer: Timer?
    private var poolInterval: TimeInterval = 0.05 // 50ms default pooling interval
    
    /// Compression level for OSC data (0-9), with 0 being no compression
    private var compressionLevel = 0
    
    // MARK: - Initialization
    
    /// Initialize with settings manager and logger
    /// - Parameters:
    ///   - settingsManager: The settings manager
    ///   - logger: The logging service
    init(settingsManager: SettingsManager, logger: LoggingService) {
        self.settingsManager = settingsManager
        self.logger = logger
        
        // Configure from settings
        updateFromSettings()
        
        // Start the cache cleanup timer
        startCacheCleanupTimer()
    }
    
    // MARK: - Configuration
    
    /// Update configuration from settings
    func updateFromSettings() {
        guard let settings = settingsManager.settings else {
            return
        }
        
        // Configure performance settings
        isPoolingEnabled = settings.oscSettings.enablePooling
        compressionLevel = settings.oscSettings.compressionLevel
        
        if isPoolingEnabled {
            poolInterval = Double(settings.oscSettings.poolingInterval) / 1000.0 // Convert ms to seconds
            startMessagePooling()
        } else {
            stopMessagePooling()
        }
        
        // Log configuration
        logger.info(
            category: .osc,
            message: "OSC performance configuration updated",
            metadata: [
                "pooling": .bool(isPoolingEnabled),
                "poolInterval": .double(poolInterval),
                "compression": .int(compressionLevel)
            ]
        )
    }
    
    // MARK: - Message Processing
    
    /// Process a message for optimal sending
    /// - Parameters:
    ///   - message: The OSC message to process
    ///   - forceNoCache: Whether to skip cache lookup
    /// - Returns: The optimized message and a flag indicating if it should be sent
    func processMessage(_ message: OSCMessage, forceNoCache: Bool = false) -> (message: OSCMessage, shouldSend: Bool) {
        // Message hash for cache/throttle lookup
        let messageHash = message.hashString
        
        // Check for cached identical message
        if !forceNoCache, let cachedMessage = messageCache[messageHash] {
            // Update statistics
            statistics.cacheHits += 1
            return (cachedMessage, false) // Use cached message, don't resend
        }
        
        // Rate limiting check
        if let lastSent = lastSendTime[messageHash] {
            let timeSinceLastSend = Date().timeIntervalSince(lastSent)
            if timeSinceLastSend < messageThrottleWindow {
                // Update statistics
                statistics.throttledMessages += 1
                return (message, false) // Too soon, don't send
            }
        }
        
        // Apply compression if enabled
        let processedMessage: OSCMessage
        if compressionLevel > 0 {
            processedMessage = compressMessage(message)
        } else {
            processedMessage = message
        }
        
        // Update cache and last send time
        messageCache[messageHash] = processedMessage
        lastSendTime[messageHash] = Date()
        
        // Update statistics
        statistics.cacheMisses += 1
        
        // If pooling is enabled, add to pool instead of sending immediately
        if isPoolingEnabled {
            addToMessagePool(processedMessage)
            return (processedMessage, false) // Will be sent by pool timer
        }
        
        return (processedMessage, true) // Send immediately
    }
    
    // MARK: - Caching and Pooling
    
    /// Add a message to the message pool
    /// - Parameter message: The message to add
    private func addToMessagePool(_ message: OSCMessage) {
        sendQueue.async {
            // Check if a similar message already exists in the pool
            if !self.messagePool.contains(where: { $0.address == message.address }) {
                self.messagePool.append(message)
            } else {
                // Replace existing message with same address
                if let index = self.messagePool.firstIndex(where: { $0.address == message.address }) {
                    self.messagePool[index] = message
                }
            }
        }
    }
    
    /// Start message pooling
    private func startMessagePooling() {
        stopMessagePooling() // Ensure any existing timer is stopped
        
        poolTimer = Timer.scheduledTimer(withTimeInterval: poolInterval, repeats: true) { [weak self] _ in
            self?.processMessagePool()
        }
    }
    
    /// Stop message pooling
    private func stopMessagePooling() {
        poolTimer?.invalidate()
        poolTimer = nil
    }
    
    /// Process messages in the pool
    private func processMessagePool() {
        sendQueue.async {
            guard !self.messagePool.isEmpty else { return }
            
            // Create a copy of the current pool
            let messagesToSend = self.messagePool
            
            // Clear the pool
            self.messagePool.removeAll()
            
            // Update statistics
            self.statistics.pooledMessageBatches += 1
            self.statistics.pooledMessages += messagesToSend.count
            
            // Return messages to be sent (to be handled by the caller)
            DispatchQueue.main.async {
                self.objectWillChange.send()
                
                // Notify listeners (in a real app, we'd use a publisher here)
                NotificationCenter.default.post(
                    name: NSNotification.Name("OSCPooledMessagesReady"),
                    object: self,
                    userInfo: ["messages": messagesToSend]
                )
            }
        }
    }
    
    /// Start the cache cleanup timer
    private func startCacheCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.cleanupCache()
        }
    }
    
    /// Clean up expired cache entries
    private func cleanupCache() {
        let now = Date()
        
        sendQueue.async {
            // Remove expired entries from message cache
            let expiredKeys = self.messageCache.keys.filter { key in
                guard let lastSent = self.lastSendTime[key] else { return true }
                return now.timeIntervalSince(lastSent) > self.cacheExpirationTime
            }
            
            for key in expiredKeys {
                self.messageCache.removeValue(forKey: key)
                self.lastSendTime.removeValue(forKey: key)
            }
            
            // Log cleanup if entries were removed
            if !expiredKeys.isEmpty {
                self.logger.debug(
                    category: .osc,
                    message: "Cleaned up OSC message cache",
                    metadata: ["removedEntries": .int(expiredKeys.count)]
                )
            }
        }
    }
    
    // MARK: - Compression
    
    /// Compress an OSC message
    /// - Parameter message: The message to compress
    /// - Returns: The compressed message
    private func compressMessage(_ message: OSCMessage) -> OSCMessage {
        // In a real app, this would implement actual compression
        // For this example, we'll just pass through the message
        return message
    }
    
    // MARK: - Statistics
    
    /// Reset performance statistics
    func resetStatistics() {
        statistics = OSCStatistics()
    }
}

// MARK: - OSC Statistics

/// Statistics for OSC message sending
struct OSCStatistics {
    /// Number of cache hits
    var cacheHits: Int = 0
    
    /// Number of cache misses
    var cacheMisses: Int = 0
    
    /// Number of throttled messages
    var throttledMessages: Int = 0
    
    /// Number of pooled message batches
    var pooledMessageBatches: Int = 0
    
    /// Number of pooled messages
    var pooledMessages: Int = 0
    
    /// Total messages processed
    var totalMessagesProcessed: Int {
        return cacheHits + cacheMisses
    }
    
    /// Cache hit rate as a percentage
    var cacheHitRate: Double {
        guard totalMessagesProcessed > 0 else { return 0.0 }
        return Double(cacheHits) / Double(totalMessagesProcessed) * 100.0
    }
    
    /// Average number of messages per batch
    var averageMessagesPerBatch: Double {
        guard pooledMessageBatches > 0 else { return 0.0 }
        return Double(pooledMessages) / Double(pooledMessageBatches)
    }
}

// MARK: - Hashable Extension

extension OSCMessage {
    /// String representation of hash for caching
    var hashString: String {
        return "\(address):\(arguments.map { $0.description }.joined(separator: ","))"
    }
}