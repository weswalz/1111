//
//  KeyboardShortcuts.swift
//  LED Messenger macOS
//
//  Created on April 18, 2025
//

import SwiftUI
import Combine

/// Manages keyboard shortcuts for the macOS application
final class KeyboardShortcutManager: ObservableObject {
    // MARK: - Properties
    
    /// Shared instance for app-wide access
    static let shared = KeyboardShortcutManager()
    
    /// Published to trigger view updates when commands are registered or removed
    @Published var registeredCommands: [KeyCommand: [UUID: () -> Void]] = [:]
    
    /// Local monitor for keyboard events
    private var localMonitor: Any?
    
    /// Global monitor for keyboard events
    private var globalMonitor: Any?
    
    /// Cancellables for cleanup
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        setupMonitors()
    }
    
    // MARK: - Deinitialization
    
    /// Clean up monitors when deinitializing
    deinit {
        removeMonitors()
    }
    
    // MARK: - Setup
    
    /// Set up keyboard event monitors
    private func setupMonitors() {
        // Set up local monitor for keyboard events
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Handle the event
            if self?.handleKeyEvent(event) == true {
                // Event was handled, don't propagate
                return nil
            }
            
            // Event wasn't handled, propagate normally
            return event
        }
        
        // Log setup
        logInfo("Keyboard shortcut manager initialized", category: .app)
    }
    
    /// Remove event monitors
    private func removeMonitors() {
        // Remove local monitor
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        
        // Remove global monitor
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }
    
    // MARK: - Command Registration
    
    /// Register a handler for a keyboard command
    /// - Parameters:
    ///   - command: The command to register
    ///   - id: A unique identifier for the handler
    ///   - handler: The action to perform when the command is triggered
    func register(command: KeyCommand, id: UUID, handler: @escaping () -> Void) {
        // Create handler array if it doesn't exist
        if registeredCommands[command] == nil {
            registeredCommands[command] = [:]
        }
        
        // Add handler
        registeredCommands[command]?[id] = handler
    }
    
    /// Unregister a handler for a keyboard command
    /// - Parameters:
    ///   - command: The command to unregister
    ///   - id: The unique identifier for the handler
    func unregister(command: KeyCommand, id: UUID) {
        // Remove handler
        registeredCommands[command]?[id] = nil
        
        // Clean up if no handlers remain
        if registeredCommands[command]?.isEmpty == true {
            registeredCommands[command] = nil
        }
    }
    
    /// Unregister all handlers for a view
    /// - Parameter id: The unique identifier for the view
    func unregisterAll(for id: UUID) {
        // Remove all handlers for this view
        for command in KeyCommand.allCases {
            unregister(command: command, id: id)
        }
    }
    
    // MARK: - Event Handling
    
    /// Handle a keyboard event
    /// - Parameter event: The keyboard event
    /// - Returns: Whether the event was handled
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // Convert event to command
        guard let command = KeyCommand(from: event) else {
            return false
        }
        
        // Check if we have handlers for this command
        guard let handlers = registeredCommands[command], !handlers.isEmpty else {
            return false
        }
        
        // Get first responder view
        guard let firstResponder = NSApp.keyWindow?.firstResponder else {
            return false
        }
        
        // Find the view tag linked to first responder
        var currentResponder: NSResponder? = firstResponder
        var viewID: UUID? = nil
        
        // Walk up the responder chain to find a tagged view
        while viewID == nil, let responder = currentResponder {
            if let tagged = responder as? TaggableViewRepresentable {
                viewID = tagged.viewID
            }
            currentResponder = responder.nextResponder
        }
        
        // If no tag was found, try to use any handler
        if viewID == nil, let anyHandler = handlers.first {
            // Execute handler
            anyHandler.value()
            return true
        }
        
        // If we have a specific handler for this view, execute it
        if let viewID = viewID, let handler = handlers[viewID] {
            // Execute handler
            handler()
            return true
        }
        
        // No handler found
        return false
    }
}

/// Protocol for views that can be tagged with an ID
protocol TaggableViewRepresentable: NSResponder {
    /// The unique identifier for this view
    var viewID: UUID { get }
}

/// Keyboard commands supported by the application
enum KeyCommand: Hashable, CaseIterable {
    // MARK: - Cases
    
    /// Command+N: New queue
    case newQueue
    
    /// Command+Shift+N: New message
    case newMessage
    
    /// Command+E: Edit selected message
    case editMessage
    
    /// Command+Delete: Delete selected message
    case deleteMessage
    
    /// Command+S: Save changes
    case save
    
    /// Command+R: Refresh connection
    case refreshConnection
    
    /// Command+Option+C: Connect/disconnect
    case toggleConnection
    
    /// Command+Option+X: Clear message
    case clearMessage
    
    /// Space: Send selected message
    case sendMessage
    
    /// Up arrow: Previous message
    case previousMessage
    
    /// Down arrow: Next message
    case nextMessage
    
    /// Left arrow: Previous queue
    case previousQueue
    
    /// Right arrow: Next queue
    case nextQueue
    
    // MARK: - Properties
    
    /// The display name for the command
    var displayName: String {
        switch self {
        case .newQueue:
            return "New Queue"
        case .newMessage:
            return "New Message"
        case .editMessage:
            return "Edit Message"
        case .deleteMessage:
            return "Delete Message"
        case .save:
            return "Save"
        case .refreshConnection:
            return "Refresh Connection"
        case .toggleConnection:
            return "Connect/Disconnect"
        case .clearMessage:
            return "Clear Message"
        case .sendMessage:
            return "Send Message"
        case .previousMessage:
            return "Previous Message"
        case .nextMessage:
            return "Next Message"
        case .previousQueue:
            return "Previous Queue"
        case .nextQueue:
            return "Next Queue"
        }
    }
    
    /// The keyboard shortcut string for display
    var shortcutString: String {
        switch self {
        case .newQueue:
            return "⌘N"
        case .newMessage:
            return "⌘⇧N"
        case .editMessage:
            return "⌘E"
        case .deleteMessage:
            return "⌘⌫"
        case .save:
            return "⌘S"
        case .refreshConnection:
            return "⌘R"
        case .toggleConnection:
            return "⌘⌥C"
        case .clearMessage:
            return "⌘⌥X"
        case .sendMessage:
            return "Space"
        case .previousMessage:
            return "↑"
        case .nextMessage:
            return "↓"
        case .previousQueue:
            return "←"
        case .nextQueue:
            return "→"
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize a command from a keyboard event
    /// - Parameter event: The keyboard event
    init?(from event: NSEvent) {
        // Get key and modifiers
        let key = event.charactersIgnoringModifiers ?? ""
        let modifiers = event.modifierFlags
        
        // Check for command key combinations
        if modifiers.contains(.command) {
            // Check for command+option combinations
            if modifiers.contains(.option) {
                switch key {
                case "c", "C":
                    self = .toggleConnection
                    return
                case "x", "X":
                    self = .clearMessage
                    return
                default:
                    break
                }
            }
            
            // Check for command+shift combinations
            if modifiers.contains(.shift) {
                switch key {
                case "n", "N":
                    self = .newMessage
                    return
                default:
                    break
                }
            }
            
            // Regular command combinations
            switch key {
            case "n", "N":
                self = .newQueue
                return
            case "e", "E":
                self = .editMessage
                return
            case "s", "S":
                self = .save
                return
            case "r", "R":
                self = .refreshConnection
                return
            default:
                break
            }
            
            // Check for delete key with command
            if event.keyCode == 51 {
                self = .deleteMessage
                return
            }
        }
        
        // Check for arrow keys
        switch event.keyCode {
        case 125: // Down arrow
            self = .nextMessage
            return
        case 126: // Up arrow
            self = .previousMessage
            return
        case 123: // Left arrow
            self = .previousQueue
            return
        case 124: // Right arrow
            self = .nextQueue
            return
        default:
            break
        }
        
        // Check for space key
        if key == " " {
            self = .sendMessage
            return
        }
        
        return nil
    }
}

// MARK: - View Extensions

/// Extension to add keyboard shortcut handling to SwiftUI views
extension View {
    /// Add keyboard shortcut handler to the view
    /// - Parameters:
    ///   - command: The command to handle
    ///   - perform: The action to perform
    /// - Returns: The modified view
    func onKeyCommand(_ command: KeyCommand, perform: @escaping () -> Void) -> some View {
        let id = UUID()
        
        return self.onAppear {
            // Register command handler
            KeyboardShortcutManager.shared.register(command: command, id: id, handler: perform)
        }
        .onDisappear {
            // Unregister command handler
            KeyboardShortcutManager.shared.unregister(command: command, id: id)
        }
    }
    
    /// Add multiple keyboard shortcut handlers to the view
    /// - Parameter shortcuts: A dictionary of commands and actions
    /// - Returns: The modified view
    func withKeyboardShortcuts(_ shortcuts: [KeyCommand: () -> Void]) -> some View {
        let id = UUID()
        
        return self.onAppear {
            // Register all shortcut handlers
            for (command, handler) in shortcuts {
                KeyboardShortcutManager.shared.register(command: command, id: id, handler: handler)
            }
        }
        .onDisappear {
            // Unregister all shortcut handlers
            KeyboardShortcutManager.shared.unregisterAll(for: id)
        }
    }
}

/// View displaying available keyboard shortcuts
struct KeyboardShortcutsHelpView: View {
    /// Whether the view is being presented
    @Binding var isPresented: Bool
    
    /// Group the commands by category
    private var commandCategories: [String: [KeyCommand]] {
        [
            "General": [.newQueue, .save],
            "Messages": [.newMessage, .editMessage, .deleteMessage, .sendMessage],
            "Navigation": [.previousMessage, .nextMessage, .previousQueue, .nextQueue],
            "Connection": [.refreshConnection, .toggleConnection, .clearMessage]
        ]
    }
    
    /// The view's body
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Close button
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                }
                .buttonStyle(.plain)
            }
            
            // Shortcut groups
            ForEach(Array(commandCategories.keys).sorted(), id: \.self) { category in
                if let commands = commandCategories[category] {
                    VStack(alignment: .leading, spacing: 12) {
                        // Category header
                        Text(category)
                            .font(.headline)
                            .foregroundColor(AppTheme.Colors.text)
                        
                        // Divider
                        Rectangle()
                            .fill(AppTheme.Colors.separator)
                            .frame(height: 1)
                        
                        // Commands in this category
                        ForEach(commands, id: \.self) { command in
                            HStack {
                                // Command name
                                Text(command.displayName)
                                    .foregroundColor(AppTheme.Colors.text)
                                
                                Spacer()
                                
                                // Shortcut
                                Text(command.shortcutString)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(AppTheme.Colors.text.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

/// Preview provider for the keyboard shortcuts help view
struct KeyboardShortcutsHelpView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutsHelpView(isPresented: .constant(true))
            .previewLayout(.sizeThatFits)
    }
}