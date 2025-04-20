//
//  MessageQueueOptimizer.swift
//  LED Messenger
//
//  Created on April 18, 2025
//

import Foundation
import Combine

/// A class to optimize message queue handling and performance
class MessageQueueOptimizer {
    // MARK: - Properties
    
    /// The logger service
    private let logger: LoggingService
    
    /// Cache for message formatting
    private var formattingCache: NSCache<NSString, CachedFormatting> = NSCache()
    
    /// Cache for message rendering data
    private var renderCache: NSCache<NSString, CachedRenderData> = NSCache()
    
    /// Message queue processing queue
    private let processingQueue = DispatchQueue(
        label: "com.ledmessenger.messageProcessing",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    /// Whether message batching is enabled
    private var batchingEnabled = true
    
    /// Maximum batch size for message operations
    private var maxBatchSize = 20
    
    /// Pending batch operations
    private var pendingBatchOperations: [() -> Void] = []
    
    /// Batch processing timer
    private var batchTimer: Timer?
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Performance statistics
    private(set) var statistics = MessageProcessingStatistics()
    
    // MARK: - Initialization
    
    /// Initialize with logger
    /// - Parameter logger: The logging service
    init(logger: LoggingService) {
        self.logger = logger
        
        // Configure caches
        formattingCache.countLimit = 100
        renderCache.countLimit = 50
        
        // Start batch timer
        startBatchTimer()
    }
    
    // MARK: - Memory Management
    
    /// Clear caches to free memory
    func clearCaches() {
        formattingCache.removeAllObjects()
        renderCache.removeAllObjects()
        
        logger.debug("Message caches cleared", category: .app)
    }
    
    /// Respond to memory pressure
    func handleMemoryPressure() {
        // Adjust cache limits based on memory pressure
        formattingCache.countLimit = 50
        renderCache.countLimit = 25
        
        // Clear less-used items from caches
        formattingCache.removeAllObjects()
        renderCache.removeAllObjects()
        
        logger.debug("Reduced message cache sizes due to memory pressure. formattingCacheLimit: \(formattingCache.countLimit), renderCacheLimit: \(renderCache.countLimit)", category: .app)
    }
    
    // MARK: - Formatting Optimization
    
    /// Get optimized formatting for a message
    /// - Parameter message: The message to optimize formatting for
    /// - Returns: Optimized formatting data
    func optimizedFormatting(for message: Message) -> MessageFormatting {
        let cacheKey = "\(message.id.uuidString)-formatting" as NSString
        
        // Check cache first
        if let cached = formattingCache.object(forKey: cacheKey) {
            statistics.formattingCacheHits += 1
            return cached.formatting
        }
        
        // Start performance measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create optimized formatting (in a real app, this might involve more complex processing)
        let optimizedFormatting = message.formatting
        
        // Cache the result
        let cached = CachedFormatting(formatting: optimizedFormatting)
        formattingCache.setObject(cached, forKey: cacheKey)
        
        // Update statistics
        statistics.formattingCacheMisses += 1
        statistics.formattingProcessingTime += CFAbsoluteTimeGetCurrent() - startTime
        
        return optimizedFormatting
    }
    
    // MARK: - Render Optimization
    
    /// Get optimized render data for a message
    /// - Parameter message: The message to optimize rendering for
    /// - Returns: Optimized render data
    func optimizedRenderData(for message: Message) -> Data {
        let cacheKey = "\(message.id.uuidString)-render" as NSString
        
        // Check cache first
        if let cached = renderCache.object(forKey: cacheKey) {
            statistics.renderCacheHits += 1
            return cached.data
        }
        
        // Start performance measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create render data (simplified for this example)
        // In a real app, this might involve more complex operations
        let renderData = computeRenderData(for: message)
        
        // Cache the result
        let cached = CachedRenderData(data: renderData)
        renderCache.setObject(cached, forKey: cacheKey)
        
        // Update statistics
        statistics.renderCacheMisses += 1
        statistics.renderProcessingTime += CFAbsoluteTimeGetCurrent() - startTime
        
        return renderData
    }
    
    /// Compute render data for a message (simplified)
    /// - Parameter message: The message to compute render data for
    /// - Returns: The render data
    private func computeRenderData(for message: Message) -> Data {
        // Simulate expensive render computation
        // In a real app, this would create actual render data
        return Data(message.text.utf8)
    }
    
    // MARK: - Batch Processing
    
    /// Start the batch processing timer
    private func startBatchTimer() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.processBatch()
        }
    }
    
    /// Process a batch of operations
    private func processBatch() {
        guard batchingEnabled && !pendingBatchOperations.isEmpty else { return }
        
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Get batch of operations to process (up to max batch size)
            var operations = [() -> Void]()
            
            DispatchQueue.main.sync {
                let batchSize = min(self.pendingBatchOperations.count, self.maxBatchSize)
                operations = Array(self.pendingBatchOperations.prefix(batchSize))
                self.pendingBatchOperations.removeFirst(batchSize)
            }
            
            // Process operations
            for operation in operations {
                operation()
            }
            
            // Update statistics
            DispatchQueue.main.async {
                self.statistics.batchesProcessed += 1
                self.statistics.operationsProcessed += operations.count
            }
        }
    }
    
    /// Add an operation to the batch
    /// - Parameter operation: The operation to add
    func addToBatch(_ operation: @escaping () -> Void) {
        if batchingEnabled {
            pendingBatchOperations.append(operation)
        } else {
            processingQueue.async(execute: operation)
        }
    }
    
    // MARK: - Queue Optimization
    
    /// Optimize a message queue
    /// - Parameter queue: The queue to optimize
    /// - Returns: The optimized queue
    func optimizeQueue(_ queue: MessageQueue) -> MessageQueue {
        // Start performance measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create a copy of the queue to optimize
        var optimizedQueue = queue
        
        // Sort messages based on optimized criteria
        // For example, we might prioritize unread messages or messages with specific properties
        optimizedQueue.messages.sort { (message1, message2) -> Bool in
            // Example criteria: prioritize shorter messages for faster rendering
            return message1.text.count < message2.text.count
        }
        
        // Update statistics
        statistics.queuesOptimized += 1
        statistics.queueOptimizationTime += CFAbsoluteTimeGetCurrent() - startTime
        
        return optimizedQueue
    }
    
    // MARK: - Statistics
    
    /// Reset performance statistics
    func resetStatistics() {
        statistics = MessageProcessingStatistics()
    }
}

// MARK: - Cache Models

/// Cached formatting data
final class CachedFormatting {
    /// The cached formatting
    let formatting: MessageFormatting
    
    /// The timestamp when the cache was created
    let timestamp: Date
    
    /// Initialize with formatting
    /// - Parameter formatting: The formatting to cache
    init(formatting: MessageFormatting) {
        self.formatting = formatting
        self.timestamp = Date()
    }
}

/// Cached render data
final class CachedRenderData {
    /// The cached data
    let data: Data
    
    /// The timestamp when the cache was created
    let timestamp: Date
    
    /// Initialize with data
    /// - Parameter data: The data to cache
    init(data: Data) {
        self.data = data
        self.timestamp = Date()
    }
}

// MARK: - Statistics

/// Statistics for message processing
struct MessageProcessingStatistics {
    /// Number of formatting cache hits
    var formattingCacheHits: Int = 0
    
    /// Number of formatting cache misses
    var formattingCacheMisses: Int = 0
    
    /// Time spent processing formatting
    var formattingProcessingTime: Double = 0
    
    /// Number of render cache hits
    var renderCacheHits: Int = 0
    
    /// Number of render cache misses
    var renderCacheMisses: Int = 0
    
    /// Time spent processing renders
    var renderProcessingTime: Double = 0
    
    /// Number of batches processed
    var batchesProcessed: Int = 0
    
    /// Number of operations processed
    var operationsProcessed: Int = 0
    
    /// Number of queues optimized
    var queuesOptimized: Int = 0
    
    /// Time spent optimizing queues
    var queueOptimizationTime: Double = 0
    
    /// Total formatting requests
    var totalFormattingRequests: Int {
        return formattingCacheHits + formattingCacheMisses
    }
    
    /// Formatting cache hit rate as a percentage
    var formattingHitRate: Double {
        guard totalFormattingRequests > 0 else { return 0.0 }
        return Double(formattingCacheHits) / Double(totalFormattingRequests) * 100.0
    }
    
    /// Total render requests
    var totalRenderRequests: Int {
        return renderCacheHits + renderCacheMisses
    }
    
    /// Render cache hit rate as a percentage
    var renderHitRate: Double {
        guard totalRenderRequests > 0 else { return 0.0 }
        return Double(renderCacheHits) / Double(totalRenderRequests) * 100.0
    }
    
    /// Average operations per batch
    var averageOperationsPerBatch: Double {
        guard batchesProcessed > 0 else { return 0.0 }
        return Double(operationsProcessed) / Double(batchesProcessed)
    }
}
