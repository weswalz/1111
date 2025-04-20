//
//  PersistenceManager.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation
import Combine

/// Protocol defining the persistence service requirements
public protocol PersistenceService {
    /// Save an encodable object to a file
    func save<T: Encodable>(_ object: T, to filename: String, in directory: PersistenceDirectory) -> Result<Void, PersistenceError>
    
    /// Load a decodable object from a file
    func load<T: Decodable>(from filename: String, in directory: PersistenceDirectory) -> Result<T, PersistenceError>
    
    /// Delete a file
    func delete(_ filename: String, in directory: PersistenceDirectory) -> Result<Void, PersistenceError>
}

/// Directory locations for persistent storage
public enum PersistenceDirectory {
    case documents
    case applicationSupport
    case caches
    case temporary
    
    /// Get the URL for this directory
    public var url: URL {
        switch self {
        case .documents:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        case .applicationSupport:
            return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        case .caches:
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        case .temporary:
            return FileManager.default.temporaryDirectory
        }
    }
}

/// Errors that can occur during persistence operations
public enum PersistenceError: Error, LocalizedError {
    case fileNotFound
    case dataCorrupted
    case encodingFailed
    case decodingFailed
    case writeFailed
    case deleteFailed
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .dataCorrupted:
            return "Data is corrupted"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .writeFailed:
            return "Failed to write data to file"
        case .deleteFailed:
            return "Failed to delete file"
        }
    }
}

/// Manages persistence of message queues and other application data
public class PersistenceManager: ObservableObject, PersistenceService {
    
    // MARK: - Properties
    
    /// Shared instance for singleton access
    public static let shared = PersistenceManager()
    
    /// The list of message queues
    @Published public private(set) var messageQueues: [MessageQueue] = []
    
    /// The currently selected queue
    @Published public private(set) var selectedQueue: MessageQueue?
    
    /// Whether changes need to be saved
    @Published public private(set) var hasUnsavedChanges: Bool = false
    
    /// File URL where message queues are stored
    private let queuesFileURL: URL
    
    /// Auto-save timer
    private var autoSaveTimer: Timer?
    
    /// Auto-save interval in seconds
    private var autoSaveInterval: TimeInterval = 60.0
    
    /// Subject that emits when queues are modified
    private let queuesChangedSubject = PassthroughSubject<Void, Never>()
    
    /// Publisher that emits when queues are modified
    public var queuesChanged: AnyPublisher<Void, Never> {
        queuesChangedSubject.eraseToAnyPublisher()
    }
    
    /// Subject that emits when the selected queue changes
    private let selectedQueueChangedSubject = PassthroughSubject<MessageQueue?, Never>()
    
    /// Publisher that emits when the selected queue changes
    public var selectedQueueChanged: AnyPublisher<MessageQueue?, Never> {
        selectedQueueChangedSubject.eraseToAnyPublisher()
    }
    
    /// Subscription set for observing queue changes
    private var queueSubscriptions = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with default file location
    public init() {
        // Get the Documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Create the file URL for message queues
        self.queuesFileURL = documentsDirectory.appendingPathComponent("messageQueues.json")
        
        // Load existing queues
        loadMessageQueues()
        
        // Set up auto-save
        setupAutoSave()
        
        logInfo("PersistenceManager initialized with default file location", category: .persistence)
    }
    
    /// Initialize with custom file URL
    /// - Parameter fileURL: The file URL to use for storage
    public init(fileURL: URL) {
        self.queuesFileURL = fileURL
        
        // Load existing queues
        loadMessageQueues()
        
        // Set up auto-save
        setupAutoSave()
        
        logInfo("PersistenceManager initialized with custom file location: \(fileURL.path)", category: .persistence)
    }
    
    // MARK: - Queue Management
    
    /// Add a new message queue
    /// - Parameter queue: The queue to add
    public func addMessageQueue(_ queue: MessageQueue) {
        // Add to the list of queues
        messageQueues.append(queue)
        
        // Set as selected if it's the first queue
        if messageQueues.count == 1 {
            selectedQueue = queue
        }
        
        // Mark for saving
        hasUnsavedChanges = true
        
        // Subscribe to queue changes
        subscribeToQueueChanges(queue)
        
        logInfo("Added message queue: \(queue.name)", category: .persistence)
    }
    
    /// Remove a message queue
    /// - Parameter id: The ID of the queue to remove
    public func removeMessageQueue(withID id: UUID) {
        // Find the queue to remove
        guard let index = messageQueues.firstIndex(where: { $0.id == id }) else {
            logWarning("Attempted to remove non-existent queue with ID: \(id)", category: .persistence)
            return
        }
        
        // Get the queue for logging
        let queue = messageQueues[index]
        
        // Remove from the list
        messageQueues.remove(at: index)
        
        // Update selected queue if necessary
        if selectedQueue?.id == id {
            if !messageQueues.isEmpty {
                // Select the next queue, or previous if we removed the last one
                let newIndex = min(index, messageQueues.count - 1)
                selectedQueue = messageQueues[newIndex]
            } else {
                // No queues left
                selectedQueue = nil
            }
        }
        
        // Mark for saving
        hasUnsavedChanges = true
        
        logInfo("Removed message queue: \(queue.name)", category: .persistence)
    }
    
    /// Select a message queue
    /// - Parameter id: The ID of the queue to select
    public func selectMessageQueue(withID id: UUID) {
        guard let queue = messageQueues.first(where: { $0.id == id }) else {
            logWarning("Attempted to select non-existent queue with ID: \(id)", category: .persistence)
            return
        }
        
        selectedQueue = queue
        logInfo("Selected message queue: \(queue.name)", category: .persistence)
    }
    
    /// Update a message queue
    /// - Parameters:
    ///   - id: The ID of the queue to update
    ///   - updatedQueue: The updated queue data
    public func updateMessageQueue(withID id: UUID, to updatedQueue: MessageQueue) {
        guard let index = messageQueues.firstIndex(where: { $0.id == id }) else {
            logWarning("Attempted to update non-existent queue with ID: \(id)", category: .persistence)
            return
        }
        
        // Update the queue
        messageQueues[index] = updatedQueue
        
        // Update selected queue if necessary
        if selectedQueue?.id == id {
            selectedQueue = updatedQueue
        }
        
        // Mark for saving
        hasUnsavedChanges = true
        
        // Subscribe to queue changes
        subscribeToQueueChanges(updatedQueue)
        
        logInfo("Updated message queue: \(updatedQueue.name)", category: .persistence)
    }
    
    // MARK: - PersistenceService Implementation
    
    /// Save an encodable object to a file
    /// - Parameters:
    ///   - object: The object to save
    ///   - filename: The filename to save to
    ///   - directory: The directory to save in
    /// - Returns: Result indicating success or failure
    public func save<T: Encodable>(_ object: T, to filename: String, in directory: PersistenceDirectory) -> Result<Void, PersistenceError> {
        do {
            // Create directory if it doesn't exist
            let directoryURL = directory.url
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            // Create file URL
            let fileURL = directoryURL.appendingPathComponent(filename)
            
            // Encode the object
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            guard let data = try? encoder.encode(object) else {
                logError("Failed to encode object to \(filename)", category: .persistence)
                return .failure(.encodingFailed)
            }
            
            // Write data to file
            try data.write(to: fileURL)
            
            logDebug("Saved object to \(filename) in \(directory)", category: .persistence)
            return .success(())
        } catch {
            logError("Failed to save object to \(filename): \(error.localizedDescription)", category: .persistence)
            return .failure(.writeFailed)
        }
    }
    
    /// Load a decodable object from a file
    /// - Parameters:
    ///   - filename: The filename to load from
    ///   - directory: The directory to load from
    /// - Returns: Result containing the loaded object or an error
    public func load<T: Decodable>(from filename: String, in directory: PersistenceDirectory) -> Result<T, PersistenceError> {
        // Create file URL
        let fileURL = directory.url.appendingPathComponent(filename)
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logWarning("File not found: \(filename)", category: .persistence)
            return .failure(.fileNotFound)
        }
        
        do {
            // Read data from file
            let data = try Data(contentsOf: fileURL)
            
            // Decode the object
            let decoder = JSONDecoder()
            let object = try decoder.decode(T.self, from: data)
            
            logDebug("Loaded object from \(filename) in \(directory)", category: .persistence)
            return .success(object)
        } catch let error as DecodingError {
            logError("Failed to decode object from \(filename): \(error)", category: .persistence)
            return .failure(.decodingFailed)
        } catch {
            logError("Failed to load object from \(filename): \(error.localizedDescription)", category: .persistence)
            return .failure(.dataCorrupted)
        }
    }
    
    /// Delete a file
    /// - Parameters:
    ///   - filename: The filename to delete
    ///   - directory: The directory to delete from
    /// - Returns: Result indicating success or failure
    public func delete(_ filename: String, in directory: PersistenceDirectory) -> Result<Void, PersistenceError> {
        // Create file URL
        let fileURL = directory.url.appendingPathComponent(filename)
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logWarning("Cannot delete: File not found: \(filename)", category: .persistence)
            return .success(()) // Not considering it an error if the file doesn't exist
        }
        
        do {
            // Delete the file
            try FileManager.default.removeItem(at: fileURL)
            
            logDebug("Deleted file: \(filename) from \(directory)", category: .persistence)
            return .success(())
        } catch {
            logError("Failed to delete file \(filename): \(error.localizedDescription)", category: .persistence)
            return .failure(.deleteFailed)
        }
    }
    
    // MARK: - Message Queue Persistence
    
    /// Load message queues from storage
    public func loadMessageQueues() {
        // Check if the file exists
        guard FileManager.default.fileExists(atPath: queuesFileURL.path) else {
            logInfo("No message queues file found at \(queuesFileURL.path)", category: .persistence)
            return
        }
        
        do {
            // Load data from file
            let data = try Data(contentsOf: queuesFileURL)
            
            // Decode the queues
            let decoder = JSONDecoder()
            let loadedQueues = try decoder.decode([MessageQueue].self, from: data)
            
            // Set the queues
            messageQueues = loadedQueues
            
            // Select the first queue if there is one
            if !messageQueues.isEmpty {
                selectedQueue = messageQueues[0]
                selectedQueueChangedSubject.send(selectedQueue)
            }
            
            // Subscribe to queue changes
            for queue in messageQueues {
                subscribeToQueueChanges(queue)
            }
            
            hasUnsavedChanges = false
            queuesChangedSubject.send()
            
            logInfo("Loaded \(loadedQueues.count) message queues from \(queuesFileURL.path)", category: .persistence)
        } catch {
            logError("Failed to load message queues: \(error.localizedDescription)", category: .persistence)
        }
    }
    
    /// Save message queues to storage
    public func saveMessageQueues() {
        do {
            // Encode the queues
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(messageQueues)
            
            // Write to file
            try data.write(to: queuesFileURL)
            
            hasUnsavedChanges = false
            
            logInfo("Saved \(messageQueues.count) message queues to \(queuesFileURL.path)", category: .persistence)
        } catch {
            logError("Failed to save message queues: \(error.localizedDescription)", category: .persistence)
        }
    }
    
    /// Save all message queues, using the directory-based approach
    @discardableResult
    public func saveAll() -> Bool {
        // Save queue index
        let queueIndex = messageQueues.map { $0.id }
        let indexFilename = "queue-index.json"
        
        let directory = PersistenceDirectory.applicationSupport
        
        // Save the index
        let indexResult = save(queueIndex, to: indexFilename, in: directory)
        if case .failure(let error) = indexResult {
            logError("Failed to save queue index: \(error.localizedDescription)", category: .persistence)
            return false
        }
        
        // Save each queue
        for queue in messageQueues {
            let filename = "queue-\(queue.id.uuidString).json"
            let result = save(queue, to: filename, in: directory)
            
            if case .failure = result {
                return false
            }
        }
        
        hasUnsavedChanges = false
        logInfo("Saved all queues (\(messageQueues.count) queues) using directory-based approach", category: .persistence)
        return true
    }
    
    /// Subscribe to changes in a message queue
    private func subscribeToQueueChanges(_ queue: MessageQueue) {
        // Clear any existing subscription for this queue
        queueSubscriptions.removeAll { subscription in
            if let id = subscription.hashValue as? UUID, id == queue.id {
                return true
            }
            return false
        }
        
        // Subscribe to messages changes
        queue.$messages
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.hasUnsavedChanges = true
            }
            .store(in: &queueSubscriptions)
        
        // Subscribe to name changes
        queue.$name
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.hasUnsavedChanges = true
            }
            .store(in: &queueSubscriptions)
        
        // Subscribe to currentIndex changes
        queue.$currentIndex
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.hasUnsavedChanges = true
            }
            .store(in: &queueSubscriptions)
    }
    
    /// Set up auto-save timer
    private func setupAutoSave() {
        // Cancel any existing timer
        autoSaveTimer?.invalidate()
        
        // Create a new timer
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.hasUnsavedChanges else { return }
            
            logDebug("Auto-saving message queues", category: .persistence)
            self.saveMessageQueues()
        }
    }
    
    /// Update the auto-save interval
    /// - Parameter interval: The new interval in seconds
    public func updateAutoSaveInterval(_ interval: TimeInterval) {
        self.autoSaveInterval = interval
        setupAutoSave()
        
        logInfo("Updated auto-save interval to \(interval) seconds", category: .persistence)
    }
    
    // MARK: - Export/Import Methods
    
    /// Export all message queues to a JSON file
    /// - Parameter fileURL: The URL to export to
    /// - Returns: Whether the export was successful
    @discardableResult
    public func exportMessageQueues(to fileURL: URL) -> Bool {
        do {
            // Encode the queues
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(messageQueues)
            
            // Write to file
            try data.write(to: fileURL)
            
            logInfo("Exported \(messageQueues.count) message queues to \(fileURL.path)", category: .persistence)
            return true
        } catch {
            logError("Failed to export message queues: \(error.localizedDescription)", category: .persistence)
            return false
        }
    }
    
    /// Export a specific queue to a file
    /// - Parameters:
    ///   - queueID: The ID of the queue to export
    ///   - fileURL: The URL to export to
    /// - Returns: Result indicating success or failure
    public func exportQueue(withID queueID: UUID, to fileURL: URL) -> Result<Void, Error> {
        guard let queue = getQueue(withID: queueID) else {
            let error = NSError(domain: "com.ledmessenger.queue", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "Queue not found"])
            return .failure(error)
        }
        
        do {
            let data = try JSONEncoder().encode(queue)
            try data.write(to: fileURL)
            
            logInfo("Exported queue \(queue.name) to \(fileURL.path)", category: .persistence)
            return .success(())
        } catch {
            logError("Failed to export queue: \(error.localizedDescription)", category: .persistence)
            return .failure(error)
        }
    }
    
    /// Import message queues from a JSON file
    /// - Parameter fileURL: The URL to import from
    /// - Returns: Whether the import was successful
    @discardableResult
    public func importMessageQueues(from fileURL: URL) -> Bool {
        do {
            // Load data from file
            let data = try Data(contentsOf: fileURL)
            
            // Decode the queues
            let decoder = JSONDecoder()
            let importedQueues = try decoder.decode([MessageQueue].self, from: data)
            
            // Add the queues to our existing list
            for queue in importedQueues {
                // Check if we already have a queue with this ID
                if messageQueues.contains(where: { $0.id == queue.id }) {
                    // Generate a new ID for this queue
                    var newQueue = queue
                    newQueue.name = "\(queue.name) (Imported)"
                    addMessageQueue(newQueue)
                } else {
                    addMessageQueue(queue)
                }
            }
            
            // Save the updated list
            saveMessageQueues()
            
            logInfo("Imported \(importedQueues.count) message queues from \(fileURL.path)", category: .persistence)
            return true
        } catch {
            logError("Failed to import message queues: \(error.localizedDescription)", category: .persistence)
            return false
        }
    }
    
    /// Import a single queue from a file
    /// - Parameter url: The URL to import from
    /// - Returns: Result containing the imported queue or an error
    public func importQueue(from url: URL) -> Result<MessageQueue, Error> {
        do {
            let data = try Data(contentsOf: url)
            var importedQueue = try JSONDecoder().decode(MessageQueue.self, from: data)
            
            // Generate a new ID to avoid conflicts
            importedQueue = MessageQueue(
                id: UUID(),
                name: importedQueue.name,
                messages: importedQueue.messages,
                createdAt: Date(),
                modifiedAt: Date(),
                currentIndex: importedQueue.currentIndex,
                note: importedQueue.note
            )
            
            // Add to queues
            addMessageQueue(importedQueue)
            
            logInfo("Imported queue \(importedQueue.name) from \(url.path)", category: .persistence)
            return .success(importedQueue)
        } catch {
            logError("Failed to import queue: \(error.localizedDescription)", category: .persistence)
            return .failure(error)
        }
    }
    
    /// Get a queue by ID
    /// - Parameter id: The ID of the queue to get
    /// - Returns: The queue, or nil if not found
    public func getQueue(withID id: UUID) -> MessageQueue? {
        return messageQueues.first(where: { $0.id == id })
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Cancel the auto-save timer
        autoSaveTimer?.invalidate()
        
        // Save any unsaved changes
        if hasUnsavedChanges {
            saveMessageQueues()
        }
        
        logDebug("PersistenceManager deinitialized", category: .persistence)
    }
}
