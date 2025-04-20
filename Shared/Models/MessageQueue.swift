//
//  MessageQueue.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation

/// Represents a queue of messages to be sent to the LED wall
public class MessageQueue: ObservableObject, Identifiable {
    
    // MARK: - Properties
    
    /// Unique identifier for the queue
    public let id: UUID
    
    /// Name of the message queue
    @Published public var name: String
    
    /// Messages in the queue
    @Published public var messages: [Message]
    
    /// The date when the queue was created
    public let createdAt: Date
    
    /// The date when the queue was last modified
    @Published public var modifiedAt: Date
    
    /// Index of the currently active message
    @Published public var currentIndex: Int?
    
    /// Optional description or note about this queue
    @Published public var note: String?
    
    // MARK: - Initialization
    
    /// Create a new empty message queue
    /// - Parameter name: Name for the queue
    public init(name: String) {
        self.id = UUID()
        self.name = name
        self.messages = []
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.currentIndex = nil
    }
    
    /// Create a message queue with initial messages
    /// - Parameters:
    ///   - name: Name for the queue
    ///   - messages: Initial messages to add
    public init(name: String, messages: [Message]) {
        self.id = UUID()
        self.name = name
        self.messages = messages
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.currentIndex = nil
    }
    
    /// Create a fully customized message queue
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - name: Name for the queue
    ///   - messages: Messages in the queue
    ///   - createdAt: Creation date (defaults to now)
    ///   - modifiedAt: Last modification date (defaults to now)
    ///   - currentIndex: Index of the currently active message (if any)
    ///   - note: Optional note about the queue
    public init(
        id: UUID = UUID(),
        name: String,
        messages: [Message],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        currentIndex: Int? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.messages = messages
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.currentIndex = currentIndex
        self.note = note
    }
    
    /// Required decoder initializer - must be in the class, not in the extension
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        messages = try container.decode([Message].self, forKey: .messages)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        currentIndex = try container.decodeIfPresent(Int.self, forKey: .currentIndex)
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }
    
    // MARK: - Queue Management Methods
    
    /// Add a message to the end of the queue
    /// - Parameter message: The message to add
    public func addMessage(_ message: Message) {
        messages.append(message)
        modifiedAt = Date()
    }
    
    /// Add multiple messages to the queue
    /// - Parameter newMessages: Array of messages to add
    public func addMessages(_ newMessages: [Message]) {
        messages.append(contentsOf: newMessages)
        modifiedAt = Date()
    }
    
    /// Insert a message at a specific position
    /// - Parameters:
    ///   - message: The message to insert
    ///   - index: The position to insert at
    public func insertMessage(_ message: Message, at index: Int) {
        guard index >= 0 && index <= messages.count else {
            logError("Attempted to insert message at invalid index: \(index)", category: .queue)
            return
        }
        
        messages.insert(message, at: index)
        
        // Update currentIndex if necessary
        if let currentIdx = currentIndex, index <= currentIdx {
            currentIndex = currentIdx + 1
        }
        
        modifiedAt = Date()
    }
    
    /// Remove a message from the queue
    /// - Parameter id: ID of the message to remove
    /// - Returns: The removed message, if found
    @discardableResult
    public func removeMessage(withID id: UUID) -> Message? {
        guard let index = messages.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        
        let removedMessage = messages.remove(at: index)
        
        // Update currentIndex if necessary
        if let currentIdx = currentIndex {
            if index == currentIdx {
                // The current message was removed
                if messages.isEmpty {
                    currentIndex = nil
                } else if index >= messages.count {
                    // If the last message was removed, point to the new last message
                    currentIndex = messages.count - 1
                }
                // Otherwise, keep currentIndex pointing to the same position
                // which now has a different message
            } else if index < currentIdx {
                // A message before the current one was removed
                currentIndex = currentIdx - 1
            }
        }
        
        modifiedAt = Date()
        return removedMessage
    }
    
    /// Move a message from one position to another
    /// - Parameters:
    ///   - fromIndex: The current position
    ///   - toIndex: The target position
    public func moveMessage(from fromIndex: Int, to toIndex: Int) {
        guard fromIndex >= 0 && fromIndex < messages.count,
              toIndex >= 0 && toIndex < messages.count else {
            logError("Invalid index in moveMessage - from: \(fromIndex), to: \(toIndex)", category: .queue)
            return
        }
        
        let message = messages.remove(at: fromIndex)
        messages.insert(message, at: toIndex)
        
        // Update currentIndex if necessary
        if let currentIdx = currentIndex {
            if currentIdx == fromIndex {
                // The current message was moved
                currentIndex = toIndex
            } else if fromIndex < currentIdx && toIndex >= currentIdx {
                // A message before the current one was moved after it
                currentIndex = currentIdx - 1
            } else if fromIndex > currentIdx && toIndex <= currentIdx {
                // A message after the current one was moved before it
                currentIndex = currentIdx + 1
            }
        }
        
        modifiedAt = Date()
    }
    
    /// Update an existing message in the queue
    /// - Parameters:
    ///   - id: ID of the message to update
    ///   - updatedMessage: The new message data
    /// - Returns: Whether the update was successful
    @discardableResult
    public func updateMessage(withID id: UUID, to updatedMessage: Message) -> Bool {
        guard let index = messages.firstIndex(where: { $0.id == id }) else {
            return false
        }
        
        // Use the same ID for the updated message
        var finalMessage = updatedMessage
        finalMessage.id = id
        
        messages[index] = finalMessage
        modifiedAt = Date()
        return true
    }
    
    /// Clear all messages from the queue
    public func clearQueue() {
        messages.removeAll()
        currentIndex = nil
        modifiedAt = Date()
    }
    
    // MARK: - Queue Navigation Methods
    
    /// Set a specific message as the current one
    /// - Parameter index: Index of the message to make current
    /// - Returns: The message at the specified index
    @discardableResult
    public func setCurrentMessage(at index: Int) -> Message? {
        guard index >= 0 && index < messages.count else {
            return nil
        }
        
        currentIndex = index
        return messages[index]
    }
    
    /// Set a specific message as the current one by ID
    /// - Parameter id: ID of the message to make current
    /// - Returns: The message with the specified ID
    @discardableResult
    public func setCurrentMessage(withID id: UUID) -> Message? {
        guard let index = messages.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        
        currentIndex = index
        return messages[index]
    }
    
    /// Get the current message
    /// - Returns: The current message, if any
    public func getCurrentMessage() -> Message? {
        guard let index = currentIndex, index >= 0 && index < messages.count else {
            return nil
        }
        
        return messages[index]
    }
    
    /// Move to the next message in the queue
    /// - Parameter wrap: Whether to wrap around to the beginning if at the end
    /// - Returns: The next message, if available
    @discardableResult
    public func nextMessage(wrap: Bool = true) -> Message? {
        guard !messages.isEmpty else {
            return nil
        }
        
        if let current = currentIndex {
            if current + 1 < messages.count {
                // Move to next message
                currentIndex = current + 1
            } else if wrap {
                // Wrap to beginning
                currentIndex = 0
            } else {
                // Stay at the end
                return nil
            }
        } else {
            // No current message, start at the beginning
            currentIndex = 0
        }
        
        return getCurrentMessage()
    }
    
    /// Move to the previous message in the queue
    /// - Parameter wrap: Whether to wrap around to the end if at the beginning
    /// - Returns: The previous message, if available
    @discardableResult
    public func previousMessage(wrap: Bool = true) -> Message? {
        guard !messages.isEmpty else {
            return nil
        }
        
        if let current = currentIndex {
            if current > 0 {
                // Move to previous message
                currentIndex = current - 1
            } else if wrap {
                // Wrap to end
                currentIndex = messages.count - 1
            } else {
                // Stay at the beginning
                return nil
            }
        } else {
            // No current message, start at the end
            currentIndex = messages.count - 1
        }
        
        return getCurrentMessage()
    }
    
    // MARK: - Queue Information Methods
    
    /// Get the number of messages in the queue
    /// - Returns: Message count
    public func messageCount() -> Int {
        return messages.count
    }
    
    /// Get the number of sent messages in the queue
    /// - Returns: Count of sent messages
    public func sentMessageCount() -> Int {
        return messages.filter { $0.hasBeenSent }.count
    }
    
    /// Get the number of unsent messages in the queue
    /// - Returns: Count of unsent messages
    public func unsentMessageCount() -> Int {
        return messages.filter { !$0.hasBeenSent }.count
    }
    
    /// Create a duplicate of this queue with a new ID
    /// - Returns: A duplicated message queue
    public func duplicate() -> MessageQueue {
        return MessageQueue(
            name: "\(name) Copy",
            messages: messages,
            createdAt: Date(),
            modifiedAt: Date(),
            currentIndex: currentIndex,
            note: note
        )
    }
}

// MARK: - Equatable Conformance

extension MessageQueue: Equatable {
    public static func == (lhs: MessageQueue, rhs: MessageQueue) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable Conformance

extension MessageQueue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Codable Conformance

extension MessageQueue: Codable {
    // We need to implement Codable manually to handle @Published properties
    
    enum CodingKeys: String, CodingKey {
        case id, name, messages, createdAt, modifiedAt, currentIndex, note
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(messages, forKey: .messages)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encode(currentIndex, forKey: .currentIndex)
        try container.encode(note, forKey: .note)
    }
    
    // Decoder initializer moved to main class definition
}
