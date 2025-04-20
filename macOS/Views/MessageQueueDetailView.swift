//
//  MessageQueueDetailView.swift
//  LED Messenger macOS
//
//  Created on April 19, 2025
//

import SwiftUI
import Combine

/// Detail view for a message queue on macOS
struct MessageQueueDetailView: View {
    // MARK: - Properties
    
    /// The message queue to display
    @ObservedObject var queue: MessageQueue
    
    /// The message queue controller
    @EnvironmentObject var messageQueueController: MessageQueueController
    
    /// The Resolume connector
    @EnvironmentObject var resolumeConnector: ResolumeConnector
    
    // MARK: - State
    
    /// Currently selected message
    @State private var selectedMessageID: UUID?
    
    /// Currently editing message
    @State private var editingMessage: Message?
    
    /// Whether a message is being edited
    @State private var isEditingMessage = false
    
    /// Whether a new message is being created
    @State private var isCreatingMessage = false
    
    /// New message being created
    @State private var newMessage: Message?
    
    /// Whether to show clear confirmation
    @State private var showingClearConfirmation = false
    
    /// Whether to show delete confirmation
    @State private var showingDeleteConfirmation = false
    
    /// Unique ID for this view (for keyboard shortcuts)
    private let viewID = UUID()
    
    /// Subscription cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Body
    
    var body: some View {
        HSplitView {
            // Message list
            messageListView
                .frame(minWidth: 300, maxWidth: 400)
            
            // Message detail
            if let messageID = selectedMessageID,
               let message = queue.messages.first(where: { $0.id == messageID }) {
                messageDetailView(message: message)
            } else {
                noMessageSelectedView
            }
        }
        .onAppear {
            setupInitialState()
            setupSubscriptions()
            setupKeyboardShortcuts()
        }
        .onDisappear {
            KeyboardShortcutManager.shared.unregisterAll(for: viewID)
        }
        .sheet(isPresented: $isEditingMessage) {
            if let message = editingMessage {
                MessageEditorSheet(
                    message: message,
                    isEditing: $isEditingMessage,
                    onSave: { updatedMessage in
                        saveEditedMessage(updatedMessage)
                    },
                    onCancel: {
                        isEditingMessage = false
                    }
                )
                .frame(width: 600, height: 700)
            }
        }
        .sheet(isPresented: $isCreatingMessage) {
            if let message = newMessage {
                MessageEditorSheet(
                    message: message,
                    isEditing: $isCreatingMessage,
                    onSave: { createdMessage in
                        saveNewMessage(createdMessage)
                    },
                    onCancel: {
                        isCreatingMessage = false
                    }
                )
                .frame(width: 600, height: 700)
            }
        }
        .alert("Clear Message", isPresented: $showingClearConfirmation) {
            Button("Clear", role: .destructive) {
                clearCurrentMessage()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to clear the current message from the LED wall?")
        }
        .alert("Delete Message", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteSelectedMessage()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this message? This action cannot be undone.")
        }
        .tagForKeyboardShortcuts(id: viewID)
    }
    
    // MARK: - Message List View
    
    /// View for the message list
    private var messageListView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Messages")
                    .font(.headline)
                
                Spacer()
                
                // New message button
                Button(action: createNewMessage) {
                    Image(systemName: "plus")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Create New Message")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Message list
            if queue.messages.isEmpty {
                emptyQueueView
            } else {
                List(selection: $selectedMessageID) {
                    ForEach(queue.messages) { message in
                        MessageRow(
                            message: message,
                            isCurrentMessage: queue.currentIndex.map { queue.messages[$0].id } == message.id
                        )
                        .tag(message.id)
                        .listRowBackground(
                            selectedMessageID == message.id ? 
                            AppTheme.Colors.primary.opacity(0.1) : Color.clear
                        )
                        .contextMenu {
                            Button(action: {
                                selectMessage(message)
                            }) {
                                Label("Select", systemImage: "checkmark.circle")
                            }
                            
                            Button(action: {
                                editMessage(message)
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(action: {
                                duplicateMessage(message)
                            }) {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            
                            Button(action: {
                                sendMessage(message)
                            }) {
                                Label("Send", systemImage: "paperplane")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                confirmDeleteMessage(message)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onDrag {
                            // Store the message ID as the drag item
                            if let index = queue.messages.firstIndex(where: { $0.id == message.id }) {
                                let messageData = ["messageIndex": String(index)]
                                return NSItemProvider(object: NSString(string: messageData.description))
                            } else {
                                return NSItemProvider()
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Empty Queue View
    
    /// View shown when the queue is empty
    private var emptyQueueView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
            
            Text("No Messages")
                .font(.title3)
                .foregroundColor(AppTheme.Colors.text)
            
            Text("Create a new message to get started")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Button(action: createNewMessage) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Message")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - No Message Selected View
    
    /// View shown when no message is selected
    private var noMessageSelectedView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "text.bubble")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
            
            Text("No Message Selected")
                .font(.title2)
                .foregroundColor(AppTheme.Colors.text)
            
            Text("Select a message from the list or create a new one")
                .font(.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: createNewMessage) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Message")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding(40)
    }
    
    // MARK: - Message Detail View
    
    /// View for showing message details
    /// - Parameter message: The message to display
    private func messageDetailView(message: Message) -> some View {
        VStack(spacing: 0) {
            // Toolbar with actions
            HStack {
                // Navigation buttons
                HStack(spacing: 16) {
                    // Previous button
                    Button(action: previousMessage) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(queue.currentIndex == 0 || queue.messages.isEmpty)
                    .help("Previous Message")
                    
                    // Next button
                    Button(action: nextMessage) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled((queue.currentIndex ?? 0) >= queue.messages.count - 1 || queue.messages.isEmpty)
                    .help("Next Message")
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    // Edit button
                    Button(action: {
                        editMessage(message)
                    }) {
                        Text("Edit")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.plain)
                    .help("Edit Message")
                    
                    // Clear button
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        Text("Clear")
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.error)
                    }
                    .buttonStyle(.plain)
                    .help("Clear Message from LED Wall")
                    
                    // Send button
                    Button(action: {
                        sendMessage(message)
                    }) {
                        Text("Send")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(resolumeConnector.isSending)
                    .help("Send Message to LED Wall")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Message preview
            ScrollView {
                VStack(spacing: 24) {
                    // Preview header
                    Text("Message Preview")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Preview display
                    ZStack {
                        // Background
                        Rectangle()
                            .fill(Color.black)
                        
                        // Message text
                        Text(message.text.isEmpty ? "Message Preview" : message.text)
                            .font(.system(size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Message details
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            // Message text
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Text")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.Colors.text)
                                
                                Text(message.text)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.Colors.surface)
                                    .cornerRadius(4)
                            }
                            
                            // Note if present
                            if let note = message.note, !note.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Note")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.Colors.text)
                                    
                                    Text(note)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppTheme.Colors.surface)
                                        .cornerRadius(4)
                                }
                            }
                            
                            // Status
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Status")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.Colors.text)
                                
                                HStack(spacing: 16) {
                                    // Sent status
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(message.hasBeenSent ? AppTheme.Colors.success : AppTheme.Colors.warning)
                                            .frame(width: 8, height: 8)
                                        
                                        Text(message.hasBeenSent ? "Sent" : "Not Sent")
                                            .foregroundColor(message.hasBeenSent ? AppTheme.Colors.success : AppTheme.Colors.warning)
                                    }
                                    
                                    // Last sent date
                                    if let lastSent = message.lastSentAt {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.caption)
                                            
                                            Text("Last sent: \(lastSent.formatted())")
                                                .font(.caption)
                                        }
                                    }
                                    
                                    // Display duration if set
                                    if let duration = message.displayDuration {
                                        HStack(spacing: 4) {
                                            Image(systemName: "timer")
                                                .font(.caption)
                                            
                                            Text("Duration: \(formatDuration(duration))")
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(8)
                                .background(AppTheme.Colors.surface)
                                .cornerRadius(4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Message Row
    
    /// Row view for a message in the list
    struct MessageRow: View {
        /// The message to display
        let message: Message
        
        /// Whether this is the current message
        let isCurrentMessage: Bool
        
        var body: some View {
            ZStack {
                HStack(spacing: 12) {
                    // Status indicator
                    Circle()
                        .fill(message.hasBeenSent ? AppTheme.Colors.success : AppTheme.Colors.primary)
                        .frame(width: 8, height: 8)
                    
                    // Message content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.text)
                            .lineLimit(1)
                            .fontWeight(isCurrentMessage ? .semibold : .regular)
                        
                        if let note = message.note, !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .lineLimit(1)
                        }
                        
                        // Display duration if set
                        if let duration = message.displayDuration, message.hasBeenSent {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.primary)
                                
                                Text("\(Int(duration / 60))m")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Current indicator
                    if isCurrentMessage {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                            .font(.caption)
                    }
                }
                
                // Show countdown overlay if active
                if message.hasActiveCountdown() {
                    CountdownView(
                        duration: message.timeRemaining() ?? 0,
                        color: AppTheme.Colors.primary,
                        onComplete: { }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Setup
    
    /// Set up initial state when view appears
    private func setupInitialState() {
        // Select the current message if there is one
        if let currentIndex = queue.currentIndex, currentIndex < queue.messages.count {
            selectedMessageID = queue.messages[currentIndex].id
        } else if !queue.messages.isEmpty {
            // Otherwise select the first message
            selectedMessageID = queue.messages[0].id
        }
    }
    
    /// Set up subscriptions for state changes
    private func setupSubscriptions() {
        // Update when currentIndex changes
        queue.$currentIndex
            .sink { [weak self] index in
                guard let self = self, let index = index, index < queue.messages.count else {
                    return
                }
                
                // Update selected message
                selectedMessageID = queue.messages[index].id
            }
            .store(in: &cancellables)
    }
    
    /// Set up keyboard shortcuts
    private func setupKeyboardShortcuts() {
        // Register keyboard shortcuts
        let shortcuts: [KeyCommand: () -> Void] = [
            .newMessage: {
                self.createNewMessage()
            },
            .editMessage: {
                if let messageID = self.selectedMessageID,
                   let message = self.queue.messages.first(where: { $0.id == messageID }) {
                    self.editMessage(message)
                }
            },
            .deleteMessage: {
                if self.selectedMessageID != nil {
                    self.showingDeleteConfirmation = true
                }
            },
            .sendMessage: {
                if let messageID = self.selectedMessageID,
                   let message = self.queue.messages.first(where: { $0.id == messageID }) {
                    self.sendMessage(message)
                }
            },
            .clearMessage: {
                self.showingClearConfirmation = true
            },
            .previousMessage: {
                self.previousMessage()
            },
            .nextMessage: {
                self.nextMessage()
            }
        ]
        
        // Register all shortcuts
        for (command, handler) in shortcuts {
            KeyboardShortcutManager.shared.register(command: command, id: viewID, handler: handler)
        }
    }
    
    // MARK: - Actions
    
    /// Create a new message
    func createNewMessage() {
        // Create a new message with default formatting
        newMessage = Message(text: "")
        isCreatingMessage = true
    }
    
    /// Edit a message
    /// - Parameter message: The message to edit
    func editMessage(_ message: Message) {
        editingMessage = message
        isEditingMessage = true
    }
    
    /// Save an edited message
    /// - Parameter message: The edited message
    func saveEditedMessage(_ message: Message) {
        messageQueueController.updateMessage(withID: message.id, to: message)
        isEditingMessage = false
    }
    
    /// Save a new message
    /// - Parameter message: The new message
    func saveNewMessage(_ message: Message) {
        messageQueueController.addMessage(message, to: queue)
        
        // Select the new message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.selectedMessageID = message.id
            
            // Make it the current message
            self.selectMessage(message)
        }
        
        isCreatingMessage = false
    }
    
    /// Select a message as the current one
    /// - Parameter message: The message to select
    func selectMessage(_ message: Message) {
        messageQueueController.selectMessage(withID: message.id, in: queue)
    }
    
    /// Duplicate a message
    /// - Parameter message: The message to duplicate
    func duplicateMessage(_ message: Message) {
        // Create a duplicate
        let duplicate = message.duplicate()
        
        // Add to queue
        messageQueueController.addMessage(duplicate, to: queue)
        
        // Select the new message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.selectedMessageID = duplicate.id
        }
    }
    
    /// Send a message to the LED wall
    /// - Parameter message: The message to send
    func sendMessage(_ message: Message) {
        // Select as current message first
        messageQueueController.selectMessage(withID: message.id, in: queue)
        
        // Send the message
        messageQueueController.sendMessage(message)
    }
    
    /// Move to the next message
    func nextMessage() {
        messageQueueController.nextMessage(in: queue)
    }
    
    /// Move to the previous message
    func previousMessage() {
        messageQueueController.previousMessage(in: queue)
    }
    
    /// Clear the current message from the LED wall
    func clearCurrentMessage() {
        messageQueueController.clearCurrentMessage()
    }
    
    /// Show confirmation for deleting a message
    /// - Parameter message: The message to delete
    func confirmDeleteMessage(_ message: Message) {
        selectedMessageID = message.id
        showingDeleteConfirmation = true
    }
    
    /// Delete the selected message
    func deleteSelectedMessage() {
        if let id = selectedMessageID {
            // Delete the message
            messageQueueController.removeMessage(withID: id, from: queue)
            
            // Clear selection if there are no more messages
            if queue.messages.isEmpty {
                selectedMessageID = nil
            } else if let index = queue.currentIndex {
                // Update selection to the current message
                selectedMessageID = queue.messages[index].id
            }
        }
    }
}

/// Helper to format dates
extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

/// Format duration in seconds to a readable string
private func formatDuration(_ seconds: Double) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    
    if remainingSeconds == 0 {
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    } else {
        return "\(minutes) minute\(minutes == 1 ? "" : "s") \(remainingSeconds) second\(remainingSeconds == 1 ? "" : "s")"
    }
}

/// Preview for the message queue detail view
struct MessageQueueDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let queue = MessageQueue(name: "Test Queue")
        queue.messages = [
            Message(text: "Hello World"),
            Message(text: "Welcome to LED Messenger")
        ]
        
        return MessageQueueDetailView(queue: queue)
            .environmentObject(MessageQueueController(
                persistenceManager: PersistenceManager(),
                resolumeConnector: ResolumeConnector()
            ))
            .environmentObject(ResolumeConnector())
    }
}