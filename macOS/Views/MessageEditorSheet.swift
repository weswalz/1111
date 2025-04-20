//
//  MessageEditorSheet.swift
//  LED Messenger macOS
//
//  Created on April 19, 2025
//

import SwiftUI
import Combine

/// Sheet for editing and creating messages on macOS
struct MessageEditorSheet: View {
    // MARK: - Properties
    
    /// The message being edited
    @State private var message: Message
    
    /// Whether the sheet is showing
    @Binding var isEditing: Bool
    
    /// The save action
    var onSave: (Message) -> Void
    
    /// The cancel action
    var onCancel: () -> Void
    
    /// Selected tab
    @State private var selectedTab = 0
    
    /// Original message for cancel
    private let originalMessage: Message
    
    // MARK: - Initialization
    
    /// Initialize with message and bindings
    /// - Parameters:
    ///   - message: The message to edit
    ///   - isEditing: Whether the sheet is showing
    ///   - onSave: Action to perform when saving
    ///   - onCancel: Action to perform when canceling
    init(message: Message, isEditing: Binding<Bool>, onSave: @escaping (Message) -> Void, onCancel: @escaping () -> Void) {
        self._message = State(initialValue: message)
        self._isEditing = isEditing
        self.onSave = onSave
        self.onCancel = onCancel
        self.originalMessage = message
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Text(originalMessage.id == message.id ? "Edit Message" : "New Message")
                    .font(.headline)
                
                HStack {
                    // Cancel button
                    Button("Cancel") {
                        onCancel()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    // Save button
                    Button("Save") {
                        saveMessage()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Tabs
            TabView(selection: $selectedTab) {
                // Content tab
                contentView
                    .tabItem {
                        Label("Content", systemImage: "text.bubble")
                    }
                    .tag(0)
                
                // Preview tab
                previewView
                    .tabItem {
                        Label("Preview", systemImage: "eye")
                    }
                    .tag(1)
            }
        }
    }
    
    // MARK: - Content View
    
    /// View for editing the message content
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Text input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message Text")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    TextEditor(text: $message.text)
                        .font(.body)
                        .frame(height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Note input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note (not displayed on LED wall)")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    TextField("", text: Binding(
                        get: { message.note ?? "" },
                        set: { message.note = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Styling options
                VStack(alignment: .leading, spacing: 16) {
                    // Section title
                    Text("Styling")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    // Font size slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Font Size")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(Int(28))")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: .constant(28), in: 12...72, step: 2)
                    }
                    
                    // Text color
                    HStack {
                        Text("Text Color")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        ColorPicker("", selection: .constant(Color.white))
                            .labelsHidden()
                    }
                    
                    // Background color
                    HStack {
                        Text("Background Color")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        ColorPicker("", selection: .constant(Color.black))
                            .labelsHidden()
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                // Display duration options
                VStack(alignment: .leading, spacing: 16) {
                    // Section title
                    Text("Display Duration")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    // Duration picker
                    Picker("Duration", selection: Binding(
                        get: { message.displayDuration },
                        set: { message.displayDuration = $0 }
                    )) {
                        Text("Indefinite").tag(nil as Double?)
                        Text("1 minute").tag(60.0 as Double?)
                        Text("2 minutes").tag(120.0 as Double?)
                        Text("3 minutes").tag(180.0 as Double?)
                        Text("4 minutes").tag(240.0 as Double?)
                        Text("5 minutes").tag(300.0 as Double?)
                        Text("10 minutes").tag(600.0 as Double?)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if message.displayDuration != nil {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(AppTheme.Colors.primary)
                            
                            Text("Message will automatically clear after \(formatDuration(message.displayDuration ?? 0))")
                                .font(.footnote)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Preview View
    
    /// View for previewing the message
    private var previewView: some View {
        VStack(spacing: 20) {
            // Preview header
            Text("Message Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Preview display
            ZStack {
                // Background
                Rectangle()
                    .fill(Color.black)
                
                // Message text with styling
                Text(message.text.isEmpty ? "Message Preview" : message.text)
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
            }
            .aspectRatio(16/9, contentMode: .fit)
            .cornerRadius(12)
            .shadow(radius: 2)
            
            // How it will look on the LED wall
            Text("This is how your message will appear on the LED wall")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Actions
    
    /// Save the message
    private func saveMessage() {
        onSave(message)
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
}

/// Preview for the message editor sheet
struct MessageEditorSheet_Previews: PreviewProvider {
    static var previews: some View {
        MessageEditorSheet(
            message: Message(text: "Hello World"),
            isEditing: .constant(true),
            onSave: { _ in },
            onCancel: {}
        )
    }
}