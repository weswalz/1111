//
//  MessageQueueListView.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import SwiftUI

/// View that displays a list of messages in a queue
struct MessageQueueListView: View {
    // MARK: - Properties
    
    /// The message queue to display
    @ObservedObject var queue: MessageQueue
    
    /// The message queue controller
    @EnvironmentObject var messageQueueController: MessageQueueController
    
    /// Whether message sending is in progress
    @Binding var isSending: Bool
    
    /// The currently editing message (if any)
    @State private var editingMessage: Message?
    
    /// Whether a message is being edited
    @State private var isEditingMessage = false
    
    /// Message being created (if any)
    @State private var newMessage: Message?
    
    /// Whether a new message is being created
    @State private var isCreatingMessage = false
    
    /// Whether the delete confirmation is showing
    @State private var showingDeleteConfirmation = false
    
    /// ID of the message to delete
    @State private var messageToDeleteID: UUID?
    
    /// Action to perform when selecting a message
    var onSelect: ((Message) -> Void)?
    
    /// Action to perform when sending a message
    var onSend: ((Message) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Queue header
            queueHeader
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            if queue.messages.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Message list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(queue.messages) { message in
                            MessageRowView(
                                message: message,
                                isCurrentMessage: message.id == queue.currentIndex.map { queue.messages[$0].id },
                                onEdit: { editMessage(message) },
                                onSelect: { selectMessage(message) },
                                onSend: { sendMessage(message) }
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                            .contextMenu {
                                messageContextMenu(for: message)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .sheet(isPresented: $isEditingMessage) {
            if let message = editingMessage {
                MessageEditorView(
                    message: Binding(
                        get: { message },
                        set: { editingMessage = $0 }
                    ),
                    isEditing: $isEditingMessage,
                    onSave: { updatedMessage in
                        saveEditedMessage(updatedMessage)
                        isEditingMessage = false
                    },
                    onCancel: {
                        isEditingMessage = false
                    }
                )
            }
        }
        .sheet(isPresented: $isCreatingMessage) {
            if let message = newMessage {
                MessageEditorView(
                    message: Binding(
                        get: { message },
                        set: { newMessage = $0 }
                    ),
                    isEditing: $isCreatingMessage,
                    onSave: { createdMessage in
                        saveNewMessage(createdMessage)
                        isCreatingMessage = false
                    },
                    onCancel: {
                        isCreatingMessage = false
                    }
                )
            }
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Message"),
                message: Text("Are you sure you want to delete this message?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let id = messageToDeleteID {
                        deleteMessage(withID: id)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Queue Header
    
    /// Header view for the message queue
    private var queueHeader: some View {
        HStack {
            Text(queue.name)
                .font(.headline)
            
            Spacer()
            
            // Create new message button
            Button(action: createNewMessage) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
    }
    
    // MARK: - Empty State
    
    /// View shown when the queue is empty
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
            
            Text("No Messages")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("Tap the + button to create a new message")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.8))
            
            Button(action: createNewMessage) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Message")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppTheme.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Context Menu
    
    /// Context menu for a message
    private func messageContextMenu(for message: Message) -> some View {
        Group {
            // Edit message
            Button(action: { editMessage(message) }) {
                Label("Edit", systemImage: "pencil")
            }
            
            // Duplicate message
            Button(action: { duplicateMessage(message) }) {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            
            // Send message
            Button(action: { sendMessage(message) }) {
                Label("Send", systemImage: "paperplane")
            }
            .disabled(isSending)
            
            Divider()
            
            // Delete message
            Button(role: .destructive, action: { confirmDelete(message) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Message Actions
    
    /// Create a new message
    private func createNewMessage() {
        // Create a new message with default formatting
        newMessage = Message(
            text: "",
            formatting: messageQueueController.settingsManager?.settings.defaultMessageSettings ?? MessageFormatting()
        )
        isCreatingMessage = true
    }
    
    /// Edit an existing message
    private func editMessage(_ message: Message) {
        editingMessage = message
        isEditingMessage = true
    }
    
    /// Select a message as the current one
    private func selectMessage(_ message: Message) {
        messageQueueController.selectMessage(withID: message.id)
        onSelect?(message)
    }
    
    /// Send a message to the LED wall
    private func sendMessage(_ message: Message) {
        onSend?(message)
    }
    
    /// Duplicate a message
    private func duplicateMessage(_ message: Message) {
        let duplicate = message.duplicate()
        messageQueueController.addMessage(duplicate)
    }
    
    /// Show delete confirmation for a message
    private func confirmDelete(_ message: Message) {
        messageToDeleteID = message.id
        showingDeleteConfirmation = true
    }
    
    /// Delete a message
    private func deleteMessage(withID id: UUID) {
        messageQueueController.removeMessage(withID: id)
    }
    
    /// Save an edited message
    private func saveEditedMessage(_ message: Message) {
        messageQueueController.updateMessage(withID: message.id, to: message)
    }
    
    /// Save a new message
    private func saveNewMessage(_ message: Message) {
        messageQueueController.addMessage(message)
    }
}

/// View for a single message in the queue
struct MessageRowView: View {
    // MARK: - Properties
    
    /// The message to display
    let message: Message
    
    /// Whether this is the current message
    let isCurrentMessage: Bool
    
    /// Action to perform when editing
    let onEdit: () -> Void
    
    /// Action to perform when selecting
    let onSelect: () -> Void
    
    /// Action to perform when sending
    let onSend: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                // Message status indicator
                Circle()
                    .fill(message.hasBeenSent ? AppTheme.Colors.success : AppTheme.Colors.primary)
                    .frame(width: 12, height: 12)
                
                // Message content
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(.subheadline)
                        .fontWeight(isCurrentMessage ? .semibold : .regular)
                        .foregroundColor(AppTheme.Colors.text)
                        .lineLimit(2)
                    
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
                            
                            Text("\(formatDuration(duration))")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Action buttons
                HStack(spacing: 16) {
                    // Edit button
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.text.opacity(0.6))
                    }
                    
                    // Send button
                    Button(action: onSend) {
                        Image(systemName: "paperplane.fill")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            
            // Show countdown overlay if active
            if message.hasActiveCountdown() {
                CountdownView(
                    duration: message.timeRemaining() ?? 0,
                    color: AppTheme.Colors.primary,
                    onComplete: {
                        // Countdown completed - this will be handled by the controller
                    }
                )
            }
        }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrentMessage ? 
                      AppTheme.Colors.primary.opacity(0.1) : 
                      AppTheme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isCurrentMessage ? 
                    AppTheme.Colors.primary.opacity(0.5) : 
                    Color.gray.opacity(0.2),
                    lineWidth: isCurrentMessage ? 2 : 1
                )
        )
        .onTapGesture {
            onSelect()
        }
    }
    
    /// Format duration in seconds to a readable string
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if remainingSeconds == 0 {
            return "\(minutes)m"
        } else {
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
}

struct MessageQueueListView_Previews: PreviewProvider {
    static var previews: some View {
        let queue = MessageQueue(name: "Preview Queue")
        
        return MessageQueueListView(
            queue: queue,
            isSending: .constant(false)
        )
        .environmentObject(MessageQueueController(
            persistenceManager: PersistenceManager(),
            resolumeConnector: ResolumeConnector(settings: Settings().oscSettings)
        ))
    }
}
