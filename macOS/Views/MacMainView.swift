//
//  MacMainView.swift
//  LED Messenger macOS
//
//  Created on April 19, 2025
//

import SwiftUI
import Combine

/// Main view for the macOS application
struct MacMainView: View {
    // MARK: - Environment Objects
    
    /// Settings manager
    @EnvironmentObject var settingsManager: SettingsManager
    
    /// Message queue controller
    @EnvironmentObject var messageQueueController: MessageQueueController
    
    /// Resolume connector
    @EnvironmentObject var resolumeConnector: ResolumeConnector
    
    /// Peer server
    @EnvironmentObject var peerServer: PeerServer
    
    /// App coordinator
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    // MARK: - State
    
    /// Selected sidebar item
    @State private var selectedSidebarItem: SidebarItem = .messageQueue
    
    /// Selected message queue ID
    @State private var selectedQueueID: UUID?
    
    /// Whether settings sheet is showing
    @State private var showingSettings = false
    
    /// Whether to show the connection sheet
    @State private var showingConnectionSettings = false
    
    /// Whether the new queue sheet is showing
    @State private var showingNewQueueSheet = false
    
    /// Name for new queue
    @State private var newQueueName = ""
    
    /// Whether to show clear confirmation
    @State private var showingClearConfirmation = false
    
    /// Whether to show keyboard shortcuts help
    @State private var showingKeyboardShortcutsHelp = false
    
    /// Unique ID for this view (for keyboard shortcuts)
    private let viewID = UUID()
    
    /// Subscription cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        // Add message queue button
                        Button(action: {
                            newQueueName = ""
                            showingNewQueueSheet = true
                        }) {
                            Label("New Queue", systemImage: "plus")
                        }
                    }
                }
        } detail: {
            // Main content
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                // Content based on selected sidebar item
                switch selectedSidebarItem {
                case .messageQueue:
                    if let queueID = selectedQueueID,
                       let queue = messageQueueController.persistenceManager.messageQueues.first(where: { $0.id == queueID }) {
                        // Show selected queue
                        MessageQueueDetailView(queue: queue)
                            .environmentObject(messageQueueController)
                            .environmentObject(resolumeConnector)
                            .id(queueID) // Force refresh when queue changes
                    } else {
                        // No queue selected
                        noQueueSelectedView
                    }
                    
                case .connections:
                    // Connections view
                    ConnectionsView()
                        .environmentObject(peerServer)
                        .environmentObject(resolumeConnector)
                    
                case .settings:
                    // Settings view
                    MacSettingsView()
                        .environmentObject(settingsManager)
                        .environmentObject(resolumeConnector)
                }
                
                // Error notification overlay
                if let errorMessage = appCoordinator.notificationMessage, 
                   appCoordinator.notificationType == .error || 
                   appCoordinator.notificationType == .warning {
                    VStack {
                        Spacer()
                        
                        // Error notification banner
                        HStack(spacing: 12) {
                            // Icon
                            Image(systemName: appCoordinator.notificationType.icon)
                                .foregroundColor(.white)
                                .font(.title3)
                            
                            // Message
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appCoordinator.notificationType == .error ? "Error" : "Warning")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            // Dismiss button
                            Button(action: {
                                appCoordinator.notificationMessage = nil
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.headline)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(appCoordinator.notificationType.color)
                                .shadow(color: Color.black.opacity(0.3), radius: 3, y: 2)
                        )
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(100)
                    .animation(.easeInOut, value: appCoordinator.notificationMessage)
                }
                
                // Success notification overlay
                if let successMessage = appCoordinator.notificationMessage,
                   appCoordinator.notificationType == .success {
                    VStack {
                        // Success notification banner
                        HStack(spacing: 12) {
                            // Icon
                            Image(systemName: appCoordinator.notificationType.icon)
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            // Message
                            Text(successMessage)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.success)
                                .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
                        )
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .zIndex(100)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: appCoordinator.notificationMessage)
                }
            }
            .toolbar {
                // Message queue toolbar items
                if selectedSidebarItem == .messageQueue, selectedQueueID != nil {
                    ToolbarItemGroup(placement: .automatic) {
                        // Refresh button
                        Button(action: refreshOSCConnection) {
                            Label("Refresh Connection", systemImage: "arrow.clockwise")
                        }
                        .help("Refresh OSC Connection")
                        
                        // Connection settings button
                        Button(action: {
                            showingConnectionSettings = true
                        }) {
                            Label("Connection Settings", systemImage: "network")
                        }
                        .help("Connection Settings")
                        
                        // Connection status indicator
                        connectionStatusButton
                            .help(connectionStatusText)
                    }
                }
                
                // Help toolbar items
                ToolbarItemGroup(placement: .automatic) {
                    // Keyboard shortcuts help button
                    Button(action: {
                        showingKeyboardShortcutsHelp = true
                    }) {
                        Label("Keyboard Shortcuts", systemImage: "keyboard")
                    }
                    .help("Keyboard Shortcuts")
                }
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
        .sheet(isPresented: $showingSettings) {
            MacSettingsView()
                .environmentObject(settingsManager)
                .environmentObject(resolumeConnector)
                .frame(minWidth: 600, minHeight: 500)
        }
        .sheet(isPresented: $showingConnectionSettings) {
            OSCConnectionSettingsView(
                oscSettings: Binding(
                    get: { settingsManager.settings.oscSettings },
                    set: { newSettings in
                        var settings = settingsManager.settings
                        settings.oscSettings = newSettings
                        settingsManager.updateSettings(settings)
                    }
                ),
                resolumeConnector: resolumeConnector
            )
            .frame(width: 500, height: 600)
        }
        .sheet(isPresented: $showingKeyboardShortcutsHelp) {
            KeyboardShortcutsHelpView(isPresented: $showingKeyboardShortcutsHelp)
        }
        .alert("Create New Queue", isPresented: $showingNewQueueSheet) {
            TextField("Queue Name", text: $newQueueName)
            
            Button("Cancel", role: .cancel) {
                newQueueName = ""
            }
            
            Button("Create") {
                createNewQueue()
            }
            .disabled(newQueueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a name for the new message queue")
        }
        .alert("Clear Message", isPresented: $showingClearConfirmation) {
            Button("Clear", role: .destructive) {
                clearCurrentMessage()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to clear the current message from the LED wall?")
        }
        .tagForKeyboardShortcuts(id: viewID)
    }
    
    // MARK: - Sidebar
    
    /// Sidebar view with navigation items
    private var sidebar: some View {
        List(selection: $selectedSidebarItem) {
            Section("Message Queues") {
                ForEach(messageQueueController.persistenceManager.messageQueues) { queue in
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text(queue.name)
                            .fontWeight(selectedQueueID == queue.id ? .semibold : .regular)
                    }
                    .tag(SidebarItem.messageQueue)
                    .contextMenu {
                        Button(action: {
                            renameQueue(queue)
                        }) {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            duplicateQueue(queue)
                        }) {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            deleteQueue(queue)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .onTapGesture {
                        selectedQueueID = queue.id
                        selectedSidebarItem = .messageQueue
                        
                        // Select this queue in the controller
                        messageQueueController.selectQueue(withID: queue.id)
                    }
                }
            }
            .collapsible(false)
            
            Section("App") {
                HStack {
                    Image(systemName: "network")
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text("Connections")
                }
                .tag(SidebarItem.connections)
                
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text("Settings")
                }
                .tag(SidebarItem.settings)
            }
            .collapsible(false)
        }
        .listStyle(.sidebar)
    }
    
    // MARK: - Connection Status
    
    /// Button showing connection status
    private var connectionStatusButton: some View {
        Button(action: toggleConnection) {
            HStack(spacing: 4) {
                // Status indicator
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 8, height: 8)
                
                // Status text
                Text(connectionStatusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(connectionStatusColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .stroke(connectionStatusColor, lineWidth: 1)
            )
        }
    }
    
    /// The color for the connection status
    private var connectionStatusColor: Color {
        switch resolumeConnector.connectionState {
        case .connected:
            return AppTheme.Colors.success
        case .connecting:
            return AppTheme.Colors.warning
        case .disconnected, .failed:
            return AppTheme.Colors.error
        default:
            return Color.gray
        }
    }
    
    /// The text for the connection status
    private var connectionStatusText: String {
        switch resolumeConnector.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .failed:
            return "Failed"
        default:
            return "Unknown"
        }
    }
    
    // MARK: - No Queue Selected View
    
    /// View shown when no queue is selected
    private var noQueueSelectedView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
            
            Text("No Message Queue Selected")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.text)
            
            Text("Select a message queue from the sidebar or create a new one")
                .font(.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                newQueueName = ""
                showingNewQueueSheet = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create New Queue")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
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
    
    // MARK: - Setup
    
    /// Set up initial state when view appears
    private func setupInitialState() {
        // Try to select the first queue if available
        if selectedQueueID == nil, !messageQueueController.persistenceManager.messageQueues.isEmpty {
            let queue = messageQueueController.persistenceManager.messageQueues[0]
            selectedQueueID = queue.id
            messageQueueController.selectQueue(withID: queue.id)
        }
        
        // Start advertising peer service
        if !peerServer.isAdvertising {
            peerServer.startAdvertising()
        }
        
        // Connect to Resolume if auto-connect is enabled
        if settingsManager.settings.generalSettings.autoConnect && 
           resolumeConnector.connectionState == .disconnected {
            resolumeConnector.connect()
        }
    }
    
    /// Set up subscriptions for state changes
    private func setupSubscriptions() {
        // Listen for selected queue changes
        messageQueueController.$currentQueue
            .sink { [weak self] queue in
                if let queue = queue {
                    self?.selectedQueueID = queue.id
                }
            }
            .store(in: &cancellables)
        
        // Listen for connection state changes
        resolumeConnector.$connectionState
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    /// Set up keyboard shortcuts
    private func setupKeyboardShortcuts() {
        // Register keyboard shortcuts
        let shortcuts: [KeyCommand: () -> Void] = [
            .newQueue: {
                self.newQueueName = ""
                self.showingNewQueueSheet = true
            },
            .save: {
                self.messageQueueController.persistenceManager.saveAll()
                self.appCoordinator.showNotification(
                    message: "All changes saved",
                    type: .success,
                    duration: 2.0
                )
            },
            .refreshConnection: {
                self.refreshOSCConnection()
            },
            .toggleConnection: {
                self.toggleConnection()
            },
            .clearMessage: {
                self.showingClearConfirmation = true
            },
            .previousQueue: {
                self.selectPreviousQueue()
            },
            .nextQueue: {
                self.selectNextQueue()
            }
        ]
        
        // Register all shortcuts
        for (command, handler) in shortcuts {
            KeyboardShortcutManager.shared.register(command: command, id: viewID, handler: handler)
        }
    }
    
    // MARK: - Actions
    
    /// Create a new message queue
    private func createNewQueue() {
        guard !newQueueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            appCoordinator.showNotification(
                message: "Queue name cannot be empty",
                type: .warning
            )
            return
        }
        
        do {
            // Create the queue
            let queue = messageQueueController.createQueue(name: newQueueName)
            
            // Select the new queue
            selectedQueueID = queue.id
            selectedSidebarItem = .messageQueue
            
            // Show success notification
            appCoordinator.showNotification(
                message: "Queue '\(queue.name)' created successfully",
                type: .success,
                duration: 2.0
            )
            
            // Reset name
            newQueueName = ""
            
            // Log the creation
            logInfo("Created new message queue: \(queue.name)", category: .app)
            
        } catch {
            // Show error notification
            appCoordinator.showNotification(
                message: "Failed to create queue: \(error.localizedDescription)",
                type: .error
            )
            
            // Log the error
            logError("Failed to create message queue: \(error.localizedDescription)", category: .app)
        }
    }
    
    /// Delete a queue
    /// - Parameter queue: The queue to delete
    private func deleteQueue(_ queue: MessageQueue) {
        do {
            // Delete from controller
            messageQueueController.deleteQueue(withID: queue.id)
            
            // Update selected queue if necessary
            if selectedQueueID == queue.id {
                // Select another queue or clear selection
                if !messageQueueController.persistenceManager.messageQueues.isEmpty {
                    selectedQueueID = messageQueueController.persistenceManager.messageQueues[0].id
                    messageQueueController.selectQueue(withID: selectedQueueID!)
                } else {
                    selectedQueueID = nil
                }
            }
            
            // Show success notification
            appCoordinator.showNotification(
                message: "Queue '\(queue.name)' deleted",
                type: .success,
                duration: 2.0
            )
            
            // Log the deletion
            logInfo("Deleted message queue: \(queue.name)", category: .app)
            
        } catch {
            // Show error notification
            appCoordinator.showNotification(
                message: "Failed to delete queue: \(error.localizedDescription)",
                type: .error
            )
            
            // Log the error
            logError("Failed to delete message queue: \(error.localizedDescription)", category: .app)
        }
    }
    
    /// Rename a queue
    /// - Parameter queue: The queue to rename
    private func renameQueue(_ queue: MessageQueue) {
        // Show rename dialog
        let alert = NSAlert()
        alert.messageText = "Rename Queue"
        alert.informativeText = "Enter a new name for the queue:"
        
        // Add text field
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = queue.name
        alert.accessoryView = textField
        
        // Add buttons
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        
        // Show alert and process result
        if alert.runModal() == .alertFirstButtonReturn {
            let newName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newName.isEmpty {
                messageQueueController.renameQueue(withID: queue.id, to: newName)
            }
        }
    }
    
    /// Duplicate a queue
    /// - Parameter queue: The queue to duplicate
    private func duplicateQueue(_ queue: MessageQueue) {
        // Duplicate in controller
        if let newQueue = messageQueueController.duplicateQueue(withID: queue.id) {
            // Select the new queue
            selectedQueueID = newQueue.id
            messageQueueController.selectQueue(withID: newQueue.id)
        }
    }
    
    /// Toggle the connection to Resolume
    private func toggleConnection() {
        if resolumeConnector.connectionState == .connected {
            // Disconnect from Resolume
            resolumeConnector.disconnect()
            
            // Show notification
            appCoordinator.showNotification(
                message: "Disconnected from Resolume",
                type: .info,
                duration: 2.0
            )
            
            // Log the disconnection
            logInfo("Manually disconnected from Resolume", category: .osc)
            
        } else if resolumeConnector.connectionState == .disconnected {
            // Validate OSC settings before connecting
            let validationResult = resolumeConnector.validateSettings()
            if !validationResult.isValid {
                // Show validation error
                appCoordinator.showNotification(
                    message: "Invalid OSC settings: \(validationResult.error ?? "Unknown error")",
                    type: .error
                )
                
                // Log the validation error
                logError("Connection failed: invalid OSC settings: \(validationResult.error ?? "Unknown error")", category: .osc)
                return
            }
            
            // Set connecting state
            appCoordinator.isConnecting = true
            
            // Show connecting notification
            appCoordinator.showNotification(
                message: "Connecting to Resolume...",
                type: .info,
                duration: 2.0
            )
            
            // Connect to Resolume
            resolumeConnector.connect { result in
                // Reset connecting state
                appCoordinator.isConnecting = false
                
                switch result {
                case .success:
                    // Show success notification
                    appCoordinator.showNotification(
                        message: "Connected to Resolume successfully",
                        type: .success,
                        duration: 2.0
                    )
                    
                    // Log the connection
                    logInfo("Connected to Resolume at \(resolumeConnector.oscSettings.ipAddress):\(resolumeConnector.oscSettings.port)", category: .osc)
                    
                case .failure(let error):
                    // Show error notification
                    appCoordinator.showNotification(
                        message: "Failed to connect to Resolume: \(error.localizedDescription)",
                        type: .error
                    )
                    
                    // Log the error
                    logError("Failed to connect to Resolume: \(error.localizedDescription)", category: .osc)
                }
            }
        }
    }
    
    /// Refresh the OSC connection
    private func refreshOSCConnection() {
        // Show refreshing notification
        appCoordinator.showNotification(
            message: "Refreshing Resolume connection...",
            type: .info,
            duration: 2.0
        )
        
        // Log the refresh
        logInfo("Refreshing Resolume connection", category: .osc)
        
        // Disconnect and reconnect
        resolumeConnector.disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Validate OSC settings before connecting
            let validationResult = resolumeConnector.validateSettings()
            if !validationResult.isValid {
                // Show validation error
                appCoordinator.showNotification(
                    message: "Invalid OSC settings: \(validationResult.error ?? "Unknown error")",
                    type: .error
                )
                
                // Log the validation error
                logError("Connection refresh failed: invalid OSC settings: \(validationResult.error ?? "Unknown error")", category: .osc)
                return
            }
            
            // Connect to Resolume
            resolumeConnector.connect { result in
                switch result {
                case .success:
                    // Show success notification
                    appCoordinator.showNotification(
                        message: "Resolume connection refreshed",
                        type: .success,
                        duration: 2.0
                    )
                    
                    // Log the refresh completion
                    logInfo("Resolume connection refreshed successfully", category: .osc)
                    
                case .failure(let error):
                    // Show error notification
                    appCoordinator.showNotification(
                        message: "Failed to refresh connection: \(error.localizedDescription)",
                        type: .error
                    )
                    
                    // Log the error
                    logError("Failed to refresh Resolume connection: \(error.localizedDescription)", category: .osc)
                }
            }
        }
    }
    
    /// Clear the current message from the LED wall
    private func clearCurrentMessage() {
        do {
            // Clear the current message
            messageQueueController.clearCurrentMessage()
            
            // Show success notification
            appCoordinator.showNotification(
                message: "Message cleared from LED wall",
                type: .success,
                duration: 2.0
            )
            
            // Log the clear action
            logInfo("Cleared message from LED wall", category: .osc)
            
        } catch {
            // Show error notification
            appCoordinator.showNotification(
                message: "Failed to clear message: \(error.localizedDescription)",
                type: .error
            )
            
            // Log the error
            logError("Failed to clear message: \(error.localizedDescription)", category: .osc)
        }
    }
    
    /// Select the previous queue in the list
    private func selectPreviousQueue() {
        let queues = messageQueueController.persistenceManager.messageQueues
        guard let selectedQueueID = selectedQueueID,
              let currentIndex = queues.firstIndex(where: { $0.id == selectedQueueID }),
              currentIndex > 0 else {
            return
        }
        
        // Select the previous queue
        let previousIndex = currentIndex - 1
        let previousQueue = queues[previousIndex]
        self.selectedQueueID = previousQueue.id
        messageQueueController.selectQueue(withID: previousQueue.id)
    }
    
    /// Select the next queue in the list
    private func selectNextQueue() {
        let queues = messageQueueController.persistenceManager.messageQueues
        guard let selectedQueueID = selectedQueueID,
              let currentIndex = queues.firstIndex(where: { $0.id == selectedQueueID }),
              currentIndex < queues.count - 1 else {
            return
        }
        
        // Select the next queue
        let nextIndex = currentIndex + 1
        let nextQueue = queues[nextIndex]
        self.selectedQueueID = nextQueue.id
        messageQueueController.selectQueue(withID: nextQueue.id)
    }
}

/// Sidebar navigation items
enum SidebarItem: Hashable {
    case messageQueue
    case connections
    case settings
}

/// Helper functions
func logInfo(_ message: String, category: LogCategory) {
    print("[\(category)] INFO: \(message)")
}

func logError(_ message: String, category: LogCategory) {
    print("[\(category)] ERROR: \(message)")
}

enum LogCategory: String {
    case app
    case osc
    case queue
    case persistence
    case ui
    case network
}

/// Extension for View conditionals
extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// Preview for the main view
struct MacMainView_Previews: PreviewProvider {
    static var previews: some View {
        let settingsManager = SettingsManager()
        let persistenceManager = PersistenceManager()
        let resolumeConnector = ResolumeConnector()
        let messageQueueController = MessageQueueController(
            persistenceManager: persistenceManager,
            resolumeConnector: resolumeConnector
        )
        
        return MacMainView()
            .environmentObject(settingsManager)
            .environmentObject(messageQueueController)
            .environmentObject(resolumeConnector)
            .environmentObject(PeerServer())
            .environmentObject(AppCoordinator())
    }
}