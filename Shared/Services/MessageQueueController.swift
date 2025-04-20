//
//  MessageQueueController.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation
import Combine

/// Manages operations on message queues and coordinates with the OSC service
public class MessageQueueController: ObservableObject {
    
    // MARK: - Properties
    
    /// The persistence manager
    private let persistenceManager: PersistenceManager
    
    /// The Resolume connector
    private let resolumeConnector: ResolumeConnector
    
    /// The currently selected queue
    @Published public private(set) var currentQueue: MessageQueue?
    
    /// Whether a message is currently being sent
    @Published public private(set) var isSending: Bool = false
    
    /// Message send history
    @Published public private(set) var sendHistory: [Message] = []
    
    /// The maximum size of the send history
    private var maxHistorySize: Int = 100
    
    /// Subscriptions for observing queue and connector changes
    private var subscriptions = Set<AnyCancellable>()
    
    /// Timer for checking message expirations
    private var expirationTimer: Timer?
    
    // MARK: - Initialization
    
    /// Initialize with persistence manager and Resolume connector
    /// - Parameters:
    ///   - persistenceManager: The persistence manager to use
    ///   - resolumeConnector: The Resolume connector to use
    public init(persistenceManager: PersistenceManager, resolumeConnector: ResolumeConnector) {
        self.persistenceManager = persistenceManager
        self.resolumeConnector = resolumeConnector
        
        // Initialize with the selected queue from persistence manager
        self.currentQueue = persistenceManager.selectedQueue
        
        // Set up observers
        setupObservers()
        
        // Set up expiration timer
        setupExpirationTimer()
        
        logInfo("MessageQueueController initialized", category: .queue)
    }
    
    /// Set up the timer for checking message expirations
    private func setupExpirationTimer() {
        // Invalidate any existing timer
        expirationTimer?.invalidate()
        
        // Create a new timer that fires every second
        expirationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForExpiredMessages()
        }
    }
    
    /// Check for and handle expired messages
    private func checkForExpiredMessages() {
        guard let queue = currentQueue else { return }
        
        // Check if any sent messages have expired
        var needsUpdate = false
        let currentTime = Date()
        
        for (index, message) in queue.messages.enumerated() {
            // Check if message has been sent, has a duration, and has expired
            if message.hasBeenSent, 
               let duration = message.displayDuration,
               let sentAt = message.lastSentAt,
               currentTime >= sentAt.addingTimeInterval(duration) {
                
                // If this is the current message being displayed
                if queue.currentIndex == index {
                    // Clear the message from the display
                    clearCurrentMessage()
                    
                    logInfo("Message expired and cleared: \(message.text)", category: .queue)
                    needsUpdate = true
                }
            }
        }
        
        // Update the queue if needed
        if needsUpdate {
            persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
        }
    }
    
    /// Set up observers for persistence manager and Resolume connector
    private func setupObservers() {
        // Observe selected queue changes in persistence manager
        persistenceManager.$selectedQueue
            .sink { [weak self] queue in
                guard let self = self else { return }
                self.currentQueue = queue
                logDebug("Current queue changed to: \(queue?.name ?? "nil")", category: .queue)
            }
            .store(in: &subscriptions)
        
        // Observe sending state changes in Resolume connector
        resolumeConnector.$isSending
            .sink { [weak self] isSending in
                guard let self = self else { return }
                self.isSending = isSending
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Queue Management
    
    /// Create a new empty message queue
    /// - Parameter name: The name for the new queue
    /// - Returns: The created queue
    @discardableResult
    public func createQueue(name: String) -> MessageQueue {
        let newQueue = MessageQueue(name: name)
        persistenceManager.addMessageQueue(newQueue)
        persistenceManager.selectMessageQueue(withID: newQueue.id)
        
        logInfo("Created new message queue: \(name)", category: .queue)
        return newQueue
    }
    
    /// Duplicate an existing queue
    /// - Parameter queueID: The ID of the queue to duplicate
    /// - Returns: The duplicated queue, or nil if the original was not found
    @discardableResult
    public func duplicateQueue(withID queueID: UUID) -> MessageQueue? {
        // Find the queue to duplicate
        guard let queue = persistenceManager.messageQueues.first(where: { $0.id == queueID }) else {
            logWarning("Cannot duplicate queue: Queue with ID \(queueID) not found", category: .queue)
            return nil
        }
        
        // Create a duplicate
        let duplicate = queue.duplicate()
        persistenceManager.addMessageQueue(duplicate)
        
        logInfo("Duplicated queue: \(queue.name) -> \(duplicate.name)", category: .queue)
        return duplicate
    }
    
    /// Delete a queue
    /// - Parameter queueID: The ID of the queue to delete
    public func deleteQueue(withID queueID: UUID) {
        persistenceManager.removeMessageQueue(withID: queueID)
        logInfo("Deleted queue with ID: \(queueID)", category: .queue)
    }
    
    /// Select a queue
    /// - Parameter queueID: The ID of the queue to select
    public func selectQueue(withID queueID: UUID) {
        persistenceManager.selectMessageQueue(withID: queueID)
        logInfo("Selected queue with ID: \(queueID)", category: .queue)
    }
    
    /// Rename a queue
    /// - Parameters:
    ///   - queueID: The ID of the queue to rename
    ///   - newName: The new name for the queue
    public func renameQueue(withID queueID: UUID, to newName: String) {
        // Find the queue
        guard let index = persistenceManager.messageQueues.firstIndex(where: { $0.id == queueID }) else {
            logWarning("Cannot rename queue: Queue with ID \(queueID) not found", category: .queue)
            return
        }
        
        // Get the queue
        var queue = persistenceManager.messageQueues[index]
        
        // Update the name
        let oldName = queue.name
        queue.name = newName
        
        // Update in persistence manager
        persistenceManager.updateMessageQueue(withID: queueID, to: queue)
        
        logInfo("Renamed queue: \(oldName) -> \(newName)", category: .queue)
    }
    
    // MARK: - Message Management
    
    /// Add a message to the current queue
    /// - Parameter message: The message to add
    /// - Returns: Whether the operation was successful
    @discardableResult
    public func addMessage(_ message: Message) -> Bool {
        guard var queue = currentQueue else {
            logWarning("Cannot add message: No current queue", category: .queue)
            return false
        }
        
        // Add the message
        queue.addMessage(message)
        
        // Update in persistence manager
        persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
        
        logInfo("Added message to queue: \(queue.name)", category: .queue)
        return true
    }
    
    /// Remove a message from the current queue
    /// - Parameter messageID: The ID of the message to remove
    /// - Returns: Whether the operation was successful
    @discardableResult
    public func removeMessage(withID messageID: UUID) -> Bool {
        guard var queue = currentQueue else {
            logWarning("Cannot remove message: No current queue", category: .queue)
            return false
        }
        
        // Remove the message
        guard let _ = queue.removeMessage(withID: messageID) else {
            logWarning("Cannot remove message: Message with ID \(messageID) not found", category: .queue)
            return false
        }
        
        // Update in persistence manager
        persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
        
        logInfo("Removed message from queue: \(queue.name)", category: .queue)
        return true
    }
    
    /// Update a message in the current queue
    /// - Parameters:
    ///   - messageID: The ID of the message to update
    ///   - updatedMessage: The updated message data
    /// - Returns: Whether the operation was successful
    @discardableResult
    public func updateMessage(withID messageID: UUID, to updatedMessage: Message) -> Bool {
        guard var queue = currentQueue else {
            logWarning("Cannot update message: No current queue", category: .queue)
            return false
        }
        
        // Update the message
        guard queue.updateMessage(withID: messageID, to: updatedMessage) else {
            logWarning("Cannot update message: Message with ID \(messageID) not found", category: .queue)
            return false
        }
        
        // Update in persistence manager
        persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
        
        logInfo("Updated message in queue: \(queue.name)", category: .queue)
        return true
    }
    
    /// Move a message within the current queue
    /// - Parameters:
    ///   - fromIndex: The current index of the message
    ///   - toIndex: The target index for the message
    /// - Returns: Whether the operation was successful
    @discardableResult
    public func moveMessage(from fromIndex: Int, to toIndex: Int) -> Bool {
        guard var queue = currentQueue else {
            logWarning("Cannot move message: No current queue", category: .queue)
            return false
        }
        
        // Validate indices
        guard fromIndex >= 0 && fromIndex < queue.messages.count,
              toIndex >= 0 && toIndex < queue.messages.count else {
            logWarning("Cannot move message: Invalid indices (from: \(fromIndex), to: \(toIndex))", category: .queue)
            return false
        }
        
        // Move the message
        queue.moveMessage(from: fromIndex, to: toIndex)
        
        // Update in persistence manager
        persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
        
        logInfo("Moved message in queue: \(queue.name)", category: .queue)
        return true
    }
    
    /// Select a message as the current one
    /// - Parameter messageID: The ID of the message to select
    /// - Returns: Whether the operation was successful
    @discardableResult
    public func selectMessage(withID messageID: UUID) -> Bool {
        guard var queue = currentQueue else {
            logWarning("Cannot select message: No current queue", category: .queue)
            return false
        }
        
        // Select the message
        guard let _ = queue.setCurrentMessage(withID: messageID) else {
            logWarning("Cannot select message: Message with ID \(messageID) not found", category: .queue)
            return false
        }
        
        // Update in persistence manager
        persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
        
        logInfo("Selected message in queue: \(queue.name)", category: .queue)
        return true
    }
    
    // MARK: - Message Sending
    
    /// Send the current message to Resolume
    /// - Parameter completion: Optional completion handler called when the send operation completes
    public func sendCurrentMessage(completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let queue = currentQueue else {
            let error = MessageQueueError.noActiveQueue
            logError("Cannot send message: \(error.localizedDescription)", category: .queue)
            completion?(.failure(error))
            return
        }
        
        guard let message = queue.getCurrentMessage() else {
            let error = MessageQueueError.noCurrentMessage
            logError("Cannot send message: \(error.localizedDescription)", category: .queue)
            completion?(.failure(error))
            return
        }
        
        sendMessage(message, completion: completion)
    }
    
    /// Send a specific message to Resolume
    /// - Parameters:
    ///   - message: The message to send
    ///   - completion: Optional completion handler called when the send operation completes
    public func sendMessage(_ message: Message, completion: ((Result<Void, Error>) -> Void)? = nil) {
        // Set sending state
        isSending = true
        
        logInfo("Sending message: \(message.text)", category: .queue)
        
        logInfo("Preparing to send message to Resolume. Layer: \(resolumeConnector.settings.layer), Starting Clip: \(resolumeConnector.settings.clip), Clip Rotation: \(resolumeConnector.settings.clipRotation), Clear Clip: \(resolumeConnector.settings.clearClip)", category: .queue)
        
        // Send via Resolume connector
        resolumeConnector.sendMessage(message) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Mark the message as sent
                var updatedMessage = message
                updatedMessage.markAsSent()
                
                // If it's in the current queue, update it
                if let queue = self.currentQueue,
                   let index = queue.messages.firstIndex(where: { $0.id == message.id }) {
                    
                    var updatedQueue = queue
                    updatedQueue.messages[index] = updatedMessage
                    self.persistenceManager.updateMessageQueue(withID: queue.id, to: updatedQueue)
                }
                
                // Add to send history
                self.addToSendHistory(updatedMessage)
                
                // Move to next message if this is from the current queue
                if let queue = self.currentQueue,
                   let currentIndex = queue.currentIndex,
                   currentIndex < queue.messages.count - 1 {
                    
                    var updatedQueue = queue
                    _ = updatedQueue.nextMessage(wrap: false)
                    self.persistenceManager.updateMessageQueue(withID: queue.id, to: updatedQueue)
                }
                
                // Reset sending state
                self.isSending = false
                
                logInfo("Message sent successfully", category: .queue)
                completion?(.success(()))
                
            case .failure(let error):
                // Reset sending state
                self.isSending = false
                
                logError("Failed to send message: \(error.localizedDescription)", category: .queue)
                completion?(.failure(error))
            }
        }
    }
    
    /// Clear the current message from Resolume
    /// - Parameter completion: Optional completion handler called when the clear operation completes
    public func clearCurrentMessage(completion: ((Result<Void, Error>) -> Void)? = nil) {
        logInfo("Clearing current message", category: .queue)
        
        // Clear via Resolume connector
        resolumeConnector.clearMessage(completion: completion)
    }
    
    /// Add a message to the send history
    /// - Parameter message: The message to add
    private func addToSendHistory(_ message: Message) {
        // Add to the beginning of the history
        sendHistory.insert(message, at: 0)
        
        // Trim the history if needed
        if sendHistory.count > maxHistorySize {
            sendHistory.removeLast(sendHistory.count - maxHistorySize)
        }
    }
    
    /// Update the maximum size of the send history
    /// - Parameter size: The new maximum size
    public func updateMaxHistorySize(_ size: Int) {
        maxHistorySize = size
        
        // Trim the history if needed
        if sendHistory.count > maxHistorySize {
            sendHistory.removeLast(sendHistory.count - maxHistorySize)
        }
        
        logInfo("Updated maximum history size to \(size)", category: .queue)
    }
    
    /// Clear the send history
    public func clearSendHistory() {
        sendHistory.removeAll()
        logInfo("Cleared send history", category: .queue)
    }
    
    // MARK: - Saving
    
    /// Save all message queues
    public func saveMessageQueues() {
        persistenceManager.saveMessageQueues()
        logInfo("Saved all message queues", category: .queue)
    }
}

/// Errors specific to message queue operations
public enum MessageQueueError: Error, LocalizedError {
    /// No active queue is selected
    case noActiveQueue
    
    /// No current message is selected
    case noCurrentMessage
    
    /// The specified message was not found
    case messageNotFound
    
    /// A localized description of the error
    public var errorDescription: String? {
        switch self {
        case .noActiveQueue:
            return "No active message queue is selected"
        case .noCurrentMessage:
            return "No current message is selected"
        case .messageNotFound:
            return "The specified message was not found"
        }
    }
}
