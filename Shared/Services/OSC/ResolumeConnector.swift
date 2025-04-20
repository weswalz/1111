//
//  ResolumeConnector.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation
import Combine

/// Service for communicating with Resolume Arena via OSC
public class ResolumeConnector: ObservableObject {
    
    // MARK: - Properties
    
    /// The OSC service for communication
    private var oscService: OSCService
    
    /// The current OSC settings
    private var oscSettings: OSCSettings
    
    /// Public access to current OSC settings
    public var settings: OSCSettings {
        return oscSettings
    }
    
    /// The current clip index for rotation
    private var currentClipIndex: Int
    
    /// Current connection state
    @Published public var connectionState: OSCConnectionState = .disconnected
    
    /// Whether the connection is established
    @Published public var isConnected: Bool = false
    
    /// Whether a message is currently being sent
    @Published public var isSending: Bool = false
    
    /// Counter for clip rotation
    private var clipRotationCounter: Int = 0
    
    /// Connection state observer
    private var connectionStateObserver: AnyCancellable?
    
    /// Auto-clear timer
    private var autoClearTimer: Timer?
    
    // MARK: - Initialization
    
    /// Initialize with OSC settings
    /// - Parameter settings: The OSC settings to use
    public init(settings: OSCSettings) {
        self.oscSettings = settings
        self.oscService = NetworkOSCService(ipAddress: settings.ipAddress, port: settings.port)
        self.currentClipIndex = settings.clip
        
        logDebug("ResolumeConnector initialized with settings: \(settings)", category: .osc)
        
        // Start observing connection state
        startObservingConnectionState()
    }
    
    /// Start observing the connection state
    private func startObservingConnectionState() {
        // Use timer to poll connection state since OSCService doesn't use Combine
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let newState = self.oscService.connectionState
            if self.connectionState != newState {
                DispatchQueue.main.async {
                    self.connectionState = newState
                    self.isConnected = newState.isConnected
                }
            }
        }
    }
    
    // MARK: - Connection Management
    
    /// Connect to Resolume using current settings
    /// - Parameter completion: Optional completion handler called when the connection attempt completes
    public func connect(completion: ((Result<Void, Error>) -> Void)? = nil) {
        // Log detailed connection information for troubleshooting
        logInfo("Connecting to Resolume at \(oscSettings.ipAddress):\(oscSettings.port)", category: .osc)
        logInfo("Layer: \(oscSettings.layer), Base Clip: \(oscSettings.clip), Rotation: \(oscSettings.clipRotation)", category: .osc)
        logInfo("Using clips \(oscSettings.clip) through \(oscSettings.clip + oscSettings.clipRotation - 1), Clear Clip: \(oscSettings.clearClip)", category: .osc)
        
        oscService.connect { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                logInfo("Connected to Resolume successfully", category: .osc)
                
                // Show test pattern if enabled
                if self.oscSettings.showTestPattern {
                    self.sendTestPattern()
                }
                
            case .failure(let error):
                logError("Failed to connect to Resolume: \(error.localizedDescription)", category: .osc)
            }
            
            completion?(result)
        }
    }
    
    /// Disconnect from Resolume
    public func disconnect() {
        logInfo("Disconnecting from Resolume", category: .osc)
        oscService.disconnect()
    }
    
    /// Update the OSC settings
    /// - Parameter newSettings: The new settings to use
    /// - Returns: Result indicating success or failure
    @discardableResult
    public func updateSettings(newSettings: OSCSettings) -> Result<Void, Error> {
        // Validate settings
        let validation = newSettings.validate()
        guard validation.isValid else {
            let error = OSCError.invalidSettings(validation.error ?? "Unknown validation error")
            logError("Invalid OSC settings: \(error.localizedDescription)", category: .osc)
            return .failure(error)
        }
        
        // Check if we need to reconnect
        let needsReconnect = newSettings.ipAddress != oscSettings.ipAddress || newSettings.port != oscSettings.port
        
        // If connected and need to reconnect, disconnect first
        if needsReconnect && oscService.isConnected {
            disconnect()
        }
        
        // Update settings
        oscSettings = newSettings
        currentClipIndex = newSettings.clip
        
        // If we needed to reconnect, create a new OSC service
        if needsReconnect {
            oscService = NetworkOSCService(ipAddress: newSettings.ipAddress, port: newSettings.port)
            
            // Reconnect if we were previously connected
            if connectionState.isConnected {
                connect()
            }
        }
        
        logInfo("OSC settings updated", category: .osc)
        return .success(())
    }
    
    // MARK: - Message Sending
    
    /// Send a message to Resolume
    /// - Parameters:
    ///   - message: The message to send
    ///   - completion: Optional completion handler called when the send operation completes
    public func sendMessage(_ message: Message, completion: ((Result<Void, Error>) -> Void)? = nil) {
        // Must be connected to send
        guard oscService.isConnected else {
            let error = OSCError.notConnected
            logError("Cannot send message: \(error.localizedDescription)", category: .osc)
            completion?(.failure(error))
            return
        }
        
        // Get the next clip in rotation
        let clipIndex = getNextClipIndex()
        
        // Set sending state
        DispatchQueue.main.async {
            self.isSending = true
        }
        
        // Create text content OSC message
        let textPath = "/composition/layers/\(oscSettings.layer)/clips/\(clipIndex)/video/source/textgenerator/text/params/lines"
        let textMessage = OSCMessage(address: textPath, arguments: [.string(message.text)])
        
        logInfo("Sending message to Resolume:", category: .osc)
        logInfo("- Layer: \(oscSettings.layer)", category: .osc)
        logInfo("- Clip: \(clipIndex) (base: \(oscSettings.clip), rotation: \(oscSettings.clipRotation))", category: .osc)
        logInfo("- Message: \(message.text)", category: .osc)
        logInfo("- OSC Path: \(textPath)", category: .osc)
        
        // Send the text content
        oscService.send(message: textMessage) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                logDebug("Text content sent successfully", category: .osc)
                
                // Now trigger the clip
                self.triggerClip(clipIndex) { triggerResult in
                    switch triggerResult {
                    case .success:
                        logInfo("Message sent to Resolume successfully", category: .osc)
                        
                        // Set up auto-clear if enabled
                        if self.oscSettings.autoClear {
                            self.scheduleAutoClear()
                        }
                        
                        // Reset sending state
                        DispatchQueue.main.async {
                            self.isSending = false
                        }
                        
                        completion?(.success(()))
                        
                    case .failure(let error):
                        logError("Failed to trigger clip: \(error.localizedDescription)", category: .osc)
                        
                        // Reset sending state
                        DispatchQueue.main.async {
                            self.isSending = false
                        }
                        
                        completion?(.failure(error))
                    }
                }
                
            case .failure(let error):
                logError("Failed to send text content: \(error.localizedDescription)", category: .osc)
                
                // Reset sending state
                DispatchQueue.main.async {
                    self.isSending = false
                }
                
                completion?(.failure(error))
            }
        }
    }
    
    /// Clear the currently displayed message
    /// - Parameter completion: Optional completion handler called when the clear operation completes
    public func clearMessage(completion: ((Result<Void, Error>) -> Void)? = nil) {
        // Must be connected to clear
        guard oscService.isConnected else {
            let error = OSCError.notConnected
            logError("Cannot clear message: \(error.localizedDescription)", category: .osc)
            completion?(.failure(error))
            return
        }
        
        // Cancel any pending auto-clear
        cancelAutoClear()
        
        // Trigger the clear clip
        triggerClip(oscSettings.clearClip, completion: completion)
    }
    
    /// Send a test pattern to verify connection
    /// - Parameter completion: Optional completion handler called when the test operation completes
    public func sendTestPattern(completion: ((Result<Void, Error>) -> Void)? = nil) {
        // Send the specific test sequence: "LEDMESSENGER.COM (3 SECOND DELAY) LET'S PARTY (3 SECOND DELAY) CLEAR SLOT"
        logInfo("Sending test pattern sequence", category: .osc)
        
        // Create first test message
        let firstMessage = Message(text: "LEDMESSENGER.COM")
        
        // Send first message
        sendMessage(firstMessage) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                logInfo("First test message sent successfully", category: .osc)
                
                // Wait 3 seconds, then send second message
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    // Create second test message
                    let secondMessage = Message(text: "LET'S PARTY")
                    
                    // Send second message
                    self.sendMessage(secondMessage) { result in
                        switch result {
                        case .success:
                            logInfo("Second test message sent successfully", category: .osc)
                            
                            // Wait 3 seconds, then clear
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                // Clear the message
                                self.clearMessage { result in
                                    switch result {
                                    case .success:
                                        logInfo("Test pattern sequence completed successfully", category: .osc)
                                        completion?(.success(()))
                                    case .failure(let error):
                                        logError("Failed to clear message in test pattern: \(error.localizedDescription)", category: .osc)
                                        completion?(.failure(error))
                                    }
                                }
                            }
                            
                        case .failure(let error):
                            logError("Failed to send second test message: \(error.localizedDescription)", category: .osc)
                            completion?(.failure(error))
                        }
                    }
                }
                
            case .failure(let error):
                logError("Failed to send first test message: \(error.localizedDescription)", category: .osc)
                completion?(.failure(error))
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Get the next clip index in rotation
    /// - Returns: The next clip index
    private func getNextClipIndex() -> Int {
        if oscSettings.clipRotation <= 1 {
            // No rotation, always use the same clip
            return oscSettings.clip
        }
        
        // Calculate next clip in rotation
        let baseClip = oscSettings.clip  // This is the starting clip (e.g., 4)
        let rotationCount = oscSettings.clipRotation  // Number of clips to rotate through (e.g., 5)
        
        // We want to cycle through clips in sequence:
        // For example with baseClip=4, rotationCount=5:
        // First message: clip 4
        // Second message: clip 5
        // Third message: clip 6
        // Fourth message: clip 7
        // Fifth message: clip 8
        // Then back to clip 4
        
        // Get the next clip in sequence (0-based index within rotation)
        let nextIndex = clipRotationCounter
        
        // Increment counter for next time
        clipRotationCounter = (clipRotationCounter + 1) % rotationCount
        
        // The actual clip number is baseClip + offset
        let nextClip = baseClip + nextIndex
        
        logDebug("Selected clip \(nextClip) in rotation (base: \(baseClip), rotation: \(rotationCount), counter: \(nextIndex))", category: .osc)
        
        return nextClip
    }
    
    /// Trigger a specific clip in Resolume
    /// - Parameters:
    ///   - clipIndex: The clip index to trigger
    ///   - completion: Optional completion handler called when the trigger operation completes
    private func triggerClip(_ clipIndex: Int, completion: ((Result<Void, Error>) -> Void)? = nil) {
        // Create clip trigger OSC message
        let triggerPath = "/composition/layers/\(oscSettings.layer)/clips/\(clipIndex)/connect"
        let triggerMessage = OSCMessage(address: triggerPath, arguments: [.from(1)])
        
        logDebug("Triggering clip at \(triggerPath)", category: .osc)
        
        // Send the trigger message
        oscService.send(message: triggerMessage, completion: completion)
    }
    
    /// Schedule an auto-clear operation
    private func scheduleAutoClear() {
        // Cancel any existing timer
        cancelAutoClear()
        
        // Create a new timer
        let delay = oscSettings.autoClearDelay
        autoClearTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            logDebug("Auto-clearing message after \(delay) seconds", category: .osc)
            self.clearMessage()
        }
    }
    
    /// Cancel any pending auto-clear operation
    private func cancelAutoClear() {
        autoClearTimer?.invalidate()
        autoClearTimer = nil
    }
    
    // MARK: - Debug & Testing Methods
    
    /// Convenience initializer with default settings
    public convenience init() {
        let defaultSettings = OSCSettings()
        self.init(settings: defaultSettings)
    }
    
    /// Force a reconnection to the OSC server
    /// - Returns: Whether reconnection was successful
    @discardableResult
    public func reconnect() async -> Bool {
        // Reset connection state
        await MainActor.run {
            connectionState = .disconnected
            isConnected = false
        }
        
        // Disconnect and reconnect
        disconnect()
        
        var success = false
        let semaphore = DispatchSemaphore(value: 0)
        
        connect { result in
            success = result.isSuccess
            semaphore.signal()
        }
        
        // Wait for connection to complete (with timeout)
        _ = semaphore.wait(timeout: .now() + 5.0)
        
        // Update connection status
        await MainActor.run {
            isConnected = oscService.isConnected
        }
        
        return success
    }
    
    /// Send a generic OSC message for testing
    /// - Parameters:
    ///   - address: The OSC address
    ///   - value: The value to send (String, Bool, Float, Int, or nil for bang)
    /// - Returns: Whether the message was sent successfully
    @discardableResult
    public func sendOSCMessage(address: String, value: Any?) async -> Bool {
        // Create appropriate OSC message based on value type
        let message: OSCMessage
        
        if let stringValue = value as? String {
            message = OSCMessage(address: address, arguments: [.string(stringValue)])
        } else if let boolValue = value as? Bool {
            message = OSCMessage(address: address, arguments: [.from(boolValue ? 1 : 0)])
        } else if let floatValue = value as? Float {
            message = OSCMessage(address: address, arguments: [.float(floatValue)])
        } else if let doubleValue = value as? Double {
            message = OSCMessage(address: address, arguments: [.float(Float(doubleValue))])
        } else if let intValue = value as? Int {
            message = OSCMessage(address: address, arguments: [.int(intValue)])
        } else {
            // Bang (no arguments)
            message = OSCMessage(address: address, arguments: [])
        }
        
        // Send the message
        var success = false
        let semaphore = DispatchSemaphore(value: 0)
        
        oscService.send(message: message) { result in
            success = result.isSuccess
            semaphore.signal()
        }
        
        // Wait for send to complete (with timeout)
        _ = semaphore.wait(timeout: .now() + 5.0)
        
        return success
    }
    
    /// Ping the OSC server to check connection
    /// - Returns: Whether the ping was successful
    public func ping() async -> Bool {
        return await sendOSCMessage(address: "/composition/ping", value: nil)
    }
    
    /// Send a test message to verify functionality
    /// - Returns: Whether the test was successful
    public func sendTestMessage() async -> Bool {
        let success = await sendOSCMessage(
            address: "/composition/layers/\(oscSettings.layer)/clips/\(oscSettings.clip)/video/source/textgenerator/text/params/lines",
            value: "LED MESSENGER TEST"
        )
        
        // Add slight delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Clear the test message
        if success {
            return await sendOSCMessage(
                address: "/composition/layers/\(oscSettings.layer)/clips/\(oscSettings.clearClip)/connect",
                value: true
            )
        }
        
        return success
    }
}

// MARK: - Result Extension

extension Result {
    /// Whether the result is a success
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}
