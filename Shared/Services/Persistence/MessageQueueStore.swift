//
//  MessageQueueStore.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation
import Combine

/// Manages the storage and retrieval of message queues
public class MessageQueueStore: ObservableObject {
    
    // MARK: - Properties
    
    /// The collection of all available message queues
    @Published public private(set) var queues: [MessageQueue]
    
    /// The currently active message queue
    @Published public private(set) var activeQueue: MessageQueue?
    
    /// The persistence service for saving and loading queues
    private let persistenceService: PersistenceService
    
    /// Directory for storing message queues
    private let queuesDirectory: PersistenceDirectory
    
    /// Subject that emits when queues are modified
    private let queuesChangedSubject = PassthroughSubject<Void, Never>()
    
    /// Publisher that emits when queues are modified
    public var queuesChanged: AnyPublisher<Void, Never> {
        queuesChangedSubject.eraseToAnyPublisher()
    }
    
    /// Subject that emits when the active queue changes
    private let activeQueueChangedSubject = PassthroughSubject<MessageQueue?, Never>()
    
    /// Publisher that emits when the active queue changes
    public var activeQueueChanged: AnyPublisher<MessageQueue?, Never> {
        activeQueueChangedSubject.eraseToAnyPublisher()
    }
    
    /// Subscribers for auto-save
    private var subscribers = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with default parameters
    public init() {
        self.queues = []
        self.activeQueue = nil
        self.persistenceService = PersistenceManager.shared
        self.queuesDirectory = .applicationSupport
        
        // Create a default queue if none exists
        if self.queues.isEmpty {
            let defaultQueue = MessageQueue(name: "Default Queue")
            self.queues.append(defaultQueue)
            self.activeQueue = defaultQueue
        }
        
        // Set up auto-save when queues change
        setupAutoSave()
        
        // Load existing queues
        loadQueues()
        
        logDebug("MessageQueueStore initialized", category: .queue)
    }
    
    /// Initialize with custom parameters
    /// - Parameters:
    ///   - persistenceService: The persistence service to use
    ///   - queuesDirectory: The directory for storing queues
    public init(
        persistenceService: PersistenceService,
        queuesDirectory: PersistenceDirectory = .applicationSupport
    ) {
        self.queues = []
        self.activeQueue = nil
        self.persistenceService = persistenceService
        self.queuesDirectory = queuesDirectory
        
        // Set up auto-save when queues change
        setupAutoSave()
        
        // Load existing queues
        loadQueues()
        
        // Create a default queue if none exists
        if self.queues.isEmpty {
            let defaultQueue = MessageQueue(name: "Default Queue")
            self.queues.append(defaultQueue)
            self.activeQueue = defaultQueue
            saveAllQueues()
        }
        
        logDebug("MessageQueueStore initialized with custom parameters", category: .queue)
    }
    
    // MARK: - Auto-Save Setup
    
    /// Set up auto-save when queues change
    private func setupAutoSave() {
        // Observe changes to the queues array
        $queues
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveAllQueues()
            }
            .store(in: &subscribers)
        
        // Set up individual queue observers
        setupQueueObservers()
    }
    
    /// Set up observers for individual queues
    private func setupQueueObservers() {
        // Remove existing observers
        subscribers.removeAll()
        
        // Add observers for each queue
        for queue in queues {
            observeQueue(queue)
        }
    }
    
    /// Observe changes to a specific queue
    /// - Parameter queue: The queue to observe
    private func observeQueue(_ queue: MessageQueue) {
        // Observe messages changes
        queue.$messages
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveQueue(queue)
            }
            .store(in: &subscribers)
        
        // Observe name changes
        queue.$name
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveQueue(queue)
            }
            .store(in: &subscribers)
        
        // Observe note changes
        queue.$note
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveQueue(queue)
            }
            .store(in: &subscribers)
    }
    
    // MARK: - Queue Management
    
    /// Create a new message queue
    /// - Parameter name: The name for the new queue
    /// - Returns: The newly created queue
    @discardableResult
    public func createQueue(name: String) -> MessageQueue {
        let newQueue = MessageQueue(name: name)
        queues.append(newQueue)
        observeQueue(newQueue)
        
        // If no active queue, set this as active
        if activeQueue == nil {
            setActiveQueue(newQueue)
        }
        
        saveQueue(newQueue)
        queuesChangedSubject.send()
        
        logInfo("Created new queue: \(name)", category: .queue)
        return newQueue
    }
    
    /// Delete a message queue
    /// - Parameter id: The ID of the queue to delete
    /// - Returns: Result indicating success or failure
    @discardableResult
    public func deleteQueue(withID id: UUID) -> Result<Void, Error> {
        guard let index = queues.firstIndex(where: { $0.id == id }) else {
            let error = NSError(domain: "com.ledmessenger.queue", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "Queue not found"])
            return .failure(error)
        }
        
        let queue = queues[index]
        
        // Check if this is the active queue
        if activeQueue?.id == id {
            // Set a new active queue if available
            if queues.count > 1 {
                let newActiveIndex = index > 0 ? index - 1 : 1
                setActiveQueue(queues[newActiveIndex])
            } else {
                setActiveQueue(nil)
            }
        }
        
        // Remove the queue
        queues.remove(at: index)
        
        // Delete the queue file
        let filename = queueFilename(for: queue.id)
        let _ = persistenceService.delete(filename, in: queuesDirectory)
        
        queuesChangedSubject.send()
        
        logInfo("Deleted queue: \(queue.name)", category: .queue)
        return .success(())
    }
    
    /// Duplicate a message queue
    /// - Parameter id: The ID of the queue to duplicate
    /// - Returns: The duplicated queue, or nil if the original wasn't found
    public func duplicateQueue(withID id: UUID) -> MessageQueue? {
        guard let originalQueue = queues.first(where: { $0.id == id }) else {
            return nil
        }
        
        let duplicatedQueue = originalQueue.duplicate()
        queues.append(duplicatedQueue)
        observeQueue(duplicatedQueue)
        
        saveQueue(duplicatedQueue)
        queuesChangedSubject.send()
        
        logInfo("Duplicated queue: \(originalQueue.name) → \(duplicatedQueue.name)", category: .queue)
        return duplicatedQueue
    }
    
    /// Rename a message queue
    /// - Parameters:
    ///   - id: The ID of the queue to rename
    ///   - newName: The new name for the queue
    /// - Returns: Result indicating success or failure
    @discardableResult
    public func renameQueue(withID id: UUID, to newName: String) -> Result<Void, Error> {
        guard let queue = queues.first(where: { $0.id == id }) else {
            let error = NSError(domain: "com.ledmessenger.queue", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "Queue not found"])
            return .failure(error)
        }
        
        let oldName = queue.name
        queue.name = newName
        queue.modifiedAt = Date()
        
        saveQueue(queue)
        queuesChangedSubject.send()
        
        logInfo("Renamed queue: \(oldName) → \(newName)", category: .queue)
        return .success(())
    }
    
    /// Set the active message queue
    /// - Parameter queue: The queue to set as active, or nil to clear
    public func setActiveQueue(_ queue: MessageQueue?) {
        activeQueue = queue
        activeQueueChangedSubject.send(queue)
        
        if let queue = queue {
            logInfo("Set active queue: \(queue.name)", category: .queue)
        } else {
            logInfo("Cleared active queue", category: .queue)
        }
    }
    
    /// Set the active message queue by ID
    /// - Parameter id: The ID of the queue to set as active
    /// - Returns: Whether the operation was successful
    @discardableResult
    public func setActiveQueue(withID id: UUID) -> Bool {
        guard let queue = queues.first(where: { $0.id == id }) else {
            return false
        }
        
        setActiveQueue(queue)
        return true
    }
    
    /// Get a queue by ID
    /// - Parameter id: The ID of the queue to get
    /// - Returns: The queue, or nil if not found
    public func getQueue(withID id: UUID) -> MessageQueue? {
        return queues.first(where: { $0.id == id })
    }
    
    // MARK: - Persistence Operations
    
    /// Generate a filename for a queue
    /// - Parameter id: The queue ID
    /// - Returns: A filename for the queue
    private func queueFilename(for id: UUID) -> String {
        return "queue-\(id.uuidString).json"
    }
    
    /// Save a specific queue
    /// - Parameter queue: The queue to save
    /// - Returns: Result indicating success or failure
    @discardableResult
    public func saveQueue(_ queue: MessageQueue) -> Result<Void, Error> {
        let filename = queueFilename(for: queue.id)
        let result = persistenceService.save(queue, to: filename, in: queuesDirectory)
        
        switch result {
        case .success:
            logDebug("Saved queue: \(queue.name)", category: .queue)
            return .success(())
        case .failure(let error):
            logError("Failed to save queue \(queue.name): \(error.localizedDescription)", category: .queue)
            return .failure(error)
        }
    }
    
    /// Save all queues
    /// - Returns: Result indicating success or failure
    @discardableResult
    public func saveAllQueues() -> Result<Void, Error> {
        // Save queue index
        let queueIndex = queues.map { $0.id }
        let indexFilename = "queue-index.json"
        
        // Save the index
        let indexResult = persistenceService.save(queueIndex, to: indexFilename, in: queuesDirectory)
        if case .failure(let error) = indexResult {
            logError("Failed to save queue index: \(error.localizedDescription)", category: .queue)
            return .failure(error)
        }
        
        // Save each queue
        for queue in queues {
            let result = saveQueue(queue)
            if case .failure(let error) = result {
                return .failure(error)
            }
        }
        
        logInfo("Saved all queues (\(queues.count) queues)", category: .queue)
        return .success(())
    }
    
    /// Load a specific queue
    /// - Parameter id: The ID of the queue to load
    /// - Returns: The loaded queue, or nil if loading failed
    public func loadQueue(withID id: UUID) -> MessageQueue? {
        let filename = queueFilename(for: id)
        let result: Result<MessageQueue, PersistenceError> = persistenceService.load(from: filename, in: queuesDirectory)
        
        switch result {
        case .success(let queue):
            logDebug("Loaded queue: \(queue.name)", category: .queue)
            return queue
        case .failure(let error):
            logError("Failed to load queue with ID \(id): \(error.localizedDescription)", category: .queue)
            return nil
        }
    }
    
    /// Load all queues
    /// - Returns: Whether the operation was successful
    @discardableResult
    public func loadQueues() -> Bool {
        // Load queue index
        let indexFilename = "queue-index.json"
        let indexResult: Result<[UUID], PersistenceError> = persistenceService.load(from: indexFilename, in: queuesDirectory)
        
        switch indexResult {
        case .success(let queueIDs):
            var loadedQueues: [MessageQueue] = []
            
            // Load each queue
            for id in queueIDs {
                if let queue = loadQueue(withID: id) {
                    loadedQueues.append(queue)
                    observeQueue(queue)
                }
            }
            
            if loadedQueues.isEmpty && !queueIDs.isEmpty {
                logWarning("No queues could be loaded despite having IDs", category: .queue)
                return false
            }
            
            // Update queues array
            queues = loadedQueues
            
            // Set active queue if available
            if let firstQueue = queues.first, activeQueue == nil {
                setActiveQueue(firstQueue)
            }
            
            queuesChangedSubject.send()
            
            logInfo("Loaded \(queues.count) queues", category: .queue)
            return true
            
        case .failure(let error):
            if case .fileNotFound = error {
                logInfo("No queue index found, starting with empty queue list", category: .queue)
            } else {
                logError("Failed to load queue index: \(error.localizedDescription)", category: .queue)
            }
            return false
        }
    }
    
    /// Export a queue to a file
    /// - Parameters:
    ///   - queueID: The ID of the queue to export
    ///   - url: The URL to export to
    /// - Returns: Result indicating success or failure
    public func exportQueue(withID queueID: UUID, to url: URL) -> Result<Void, Error> {
        guard let queue = getQueue(withID: queueID) else {
            let error = NSError(domain: "com.ledmessenger.queue", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "Queue not found"])
            return .failure(error)
        }
        
        do {
            let data = try JSONEncoder().encode(queue)
            try data.write(to: url)
            
            logInfo("Exported queue \(queue.name) to \(url.path)", category: .queue)
            return .success(())
        } catch {
            logError("Failed to export queue: \(error.localizedDescription)", category: .queue)
            return .failure(error)
        }
    }
    
    /// Import a queue from a file
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
            queues.append(importedQueue)
            observeQueue(importedQueue)
            
            saveQueue(importedQueue)
            queuesChangedSubject.send()
            
            logInfo("Imported queue \(importedQueue.name) from \(url.path)", category: .queue)
            return .success(importedQueue)
        } catch {
            logError("Failed to import queue: \(error.localizedDescription)", category: .queue)
            return .failure(error)
        }
    }
}
