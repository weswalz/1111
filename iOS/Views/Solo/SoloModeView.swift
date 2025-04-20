//
//  SoloModeView.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import SwiftUI
import Combine

/// Main view for Solo mode operation on iPad
struct SoloModeView: View {
    // MARK: - Environment Objects
    
    /// Settings manager
    @EnvironmentObject var settingsManager: SettingsManager
    
    /// Message queue controller
    @EnvironmentObject var messageQueueController: MessageQueueController
    
    /// Resolume connector
    @EnvironmentObject var resolumeConnector: ResolumeConnector
    
    /// Mode manager
    @EnvironmentObject var modeManager: ModeManager
    
    // MARK: - State
    
    /// Currently selected message
    @State private var selectedMessage: Message?
    
    /// Whether the settings sheet is showing
    @State private var showingSettings = false
    
    /// Whether the connection sheet is showing
    @State private var showingConnectionSettings = false
    
    /// Whether the queue selection sheet is showing
    @State private var showingQueueSelection = false
    
    /// Whether the queue creation sheet is showing
    @State private var showingQueueCreation = false
    
    /// Name for a new queue
    @State private var newQueueName = ""
    
    /// Whether the clear confirmation alert is showing
    @State private var showingClearConfirmation = false
    
    /// Whether the queue list is showing (for smaller screens)
    @State private var showingQueueList = true
    
    /// Subscription cancellable
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Whether there is an active message queue
    private var hasActiveQueue: Bool {
        messageQueueController.currentQueue != nil
    }
    
    /// Current queue name
    private var currentQueueName: String {
        messageQueueController.currentQueue?.name ?? "No Queue Selected"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Message queue list (conditionally shown on smaller screens)
                    if showingQueueList || geometry.size.width > 700 {
                        queueListView(width: min(350, geometry.size.width * 0.4))
                    }
                    
                    // Main content area
                    VStack(spacing: 0) {
                        // Header
                        headerView
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        
                        Divider()
                        
                        // Message view / action area
                        if hasActiveQueue {
                            messageActionView
                                .padding()
                        } else {
                            noQueueSelectedView
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            setupSubscriptions()
        }
        .sheet(isPresented: $showingSettings) {
            SoloModeSettingsView()
                .environmentObject(settingsManager)
                .environmentObject(resolumeConnector)
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
        }
        .sheet(isPresented: $showingQueueSelection) {
            queueSelectionView
        }
        .alert(isPresented: $showingClearConfirmation) {
            Alert(
                title: Text("Clear Message"),
                message: Text("Are you sure you want to clear the current message?"),
                primaryButton: .destructive(Text("Clear")) {
                    clearCurrentMessage()
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Create New Queue", isPresented: $showingQueueCreation) {
            TextField("Queue Name", text: $newQueueName)
            Button("Cancel", role: .cancel) {
                newQueueName = ""
            }
            Button("Create") {
                createNewQueue()
            }
        } message: {
            Text("Enter a name for the new message queue")
        }
    }
    
    // MARK: - Queue List View
    
    /// View for the message queue list
    private func queueListView(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Queue list header
            HStack {
                Text("Message Queue")
                    .font(.headline)
                
                Spacer()
                
                // Queue actions menu
                Menu {
                    // Create new queue
                    Button(action: {
                        newQueueName = ""
                        showingQueueCreation = true
                    }) {
                        Label("Create New Queue", systemImage: "plus")
                    }
                    
                    // Select queue
                    Button(action: {
                        showingQueueSelection = true
                    }) {
                        Label("Select Queue", systemImage: "folder")
                    }
                    
                    if hasActiveQueue {
                        // Duplicate current queue
                        Button(action: duplicateCurrentQueue) {
                            Label("Duplicate Queue", systemImage: "plus.square.on.square")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Message queue list
            if let queue = messageQueueController.currentQueue {
                MessageQueueListView(
                    queue: queue,
                    isSending: Binding(
                        get: { resolumeConnector.isSending },
                        set: { _ in }
                    ),
                    onSelect: { message in
                        selectedMessage = message
                    },
                    onSend: { message in
                        sendMessage(message)
                    }
                )
                .environmentObject(messageQueueController)
            } else {
                VStack {
                    Text("No Queue Selected")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding()
                    
                    Button(action: {
                        showingQueueSelection = true
                    }) {
                        Text("Select Queue")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .frame(width: width)
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Header View
    
    /// Header view with title and actions
    private var headerView: some View {
        HStack {
            // Toggle queue list button (for smaller screens)
            Button(action: {
                withAnimation {
                    showingQueueList.toggle()
                }
            }) {
                Image(systemName: showingQueueList ? "sidebar.left" : "sidebar.left.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.Colors.text)
            }
            .minimumTapTarget()
            
            // Current queue name
            Text(currentQueueName)
                .font(.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            Spacer()
            
            // Connection status
            connectionStatusButton
            
            // Connection settings button
            Button(action: {
                showingConnectionSettings = true
            }) {
                Image(systemName: "network")
                    .font(.title3)
                    .foregroundColor(AppTheme.Colors.text)
            }
            .minimumTapTarget()
            
            // Settings button
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gear")
                    .font(.title3)
                    .foregroundColor(AppTheme.Colors.text)
            }
            .minimumTapTarget()
            
            // Mode indicator
            Button(action: {
                modeManager.resetMode()
            }) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.Colors.primary)
                        .frame(width: 8, height: 8)
                    
                    Text("SOLO")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .stroke(AppTheme.Colors.primary, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Connection Status
    
    /// Button showing the connection status
    private var connectionStatusButton: some View {
        Button(action: {
            toggleConnection()
        }) {
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
        case .disconnected:
            return AppTheme.Colors.error
        case .failed:
            return AppTheme.Colors.error
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
        }
    }
    
    // MARK: - Message Action View
    
    /// View for displaying and acting on the current message
    private var messageActionView: some View {
        VStack(spacing: 20) {
            // Message preview
            if let message = messageQueueController.currentQueue?.getCurrentMessage() {
                ZStack {
                    // Background
                    Rectangle()
                        .fill(Color.black)
                    
                    // Message text with styling
                    Text(message.text)
                        .font(.system(size: message.formatting.fontSize))
                        .fontWeight(fontWeight(from: message.formatting.fontWeight))
                        .foregroundColor(message.formatting.textColor.toColor())
                        .multilineTextAlignment(textAlignment(from: message.formatting.alignment))
                        .padding()
                        .background(message.formatting.backgroundColor.toColor())
                        .if(message.formatting.strokeColor != nil) { view in
                            view.overlay(
                                Text(message.text)
                                    .font(.system(size: message.formatting.fontSize))
                                    .fontWeight(fontWeight(from: message.formatting.fontWeight))
                                    .foregroundColor(.clear)
                                    .multilineTextAlignment(textAlignment(from: message.formatting.alignment))
                                    .padding()
                                    .overlay(
                                        Text(message.text)
                                            .font(.system(size: message.formatting.fontSize))
                                            .fontWeight(fontWeight(from: message.formatting.fontWeight))
                                            .foregroundColor(.clear)
                                            .multilineTextAlignment(textAlignment(from: message.formatting.alignment))
                                            .padding()
                                            .stroke(
                                                message.formatting.strokeColor?.toColor() ?? Color.clear,
                                                lineWidth: message.formatting.strokeWidth
                                            )
                                    )
                            )
                        }
                        .if(message.formatting.hasShadow) { view in
                            view.shadow(
                                color: message.formatting.shadowColor.toColor(),
                                radius: message.formatting.shadowRadius,
                                x: message.formatting.shadowOffsetX,
                                y: message.formatting.shadowOffsetY
                            )
                        }
                }
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(12)
                .shadow(radius: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                    
                    Text("No message selected")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(12)
                .shadow(radius: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Message controls
            HStack(spacing: 20) {
                // Previous message button
                Button(action: previousMessage) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.Colors.text)
                }
                
                Spacer()
                
                // Clear button
                Button(action: {
                    showingClearConfirmation = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                        
                        Text("Clear")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppTheme.Colors.error)
                }
                
                Spacer()
                
                // Send button
                Button(action: sendCurrentMessage) {
                    VStack(spacing: 4) {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.system(size: 64))
                        
                        Text("Send")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
                .disabled(messageQueueController.currentQueue?.getCurrentMessage() == nil || 
                          resolumeConnector.isSending)
                
                Spacer()
                
                // Next message button
                Button(action: nextMessage) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.Colors.text)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical)
            
            Spacer()
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
            
            Text("Please select or create a message queue to get started")
                .font(.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button(action: {
                    showingQueueSelection = true
                }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("Select Queue")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.Colors.primary, lineWidth: 2)
                    )
                    .foregroundColor(AppTheme.Colors.primary)
                }
                
                Button(action: {
                    newQueueName = ""
                    showingQueueCreation = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create Queue")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(40)
    }
    
    // MARK: - Queue Selection View
    
    /// View for selecting a message queue
    private var queueSelectionView: some View {
        NavigationView {
            List {
                ForEach(messageQueueController.persistenceManager.messageQueues) { queue in
                    Button(action: {
                        selectQueue(queue)
                        showingQueueSelection = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(queue.name)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.Colors.text)
                                
                                Text("\(queue.messages.count) messages")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if queue.id == messageQueueController.currentQueue?.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button(action: {
                            duplicateQueue(queue)
                        }) {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                    }
                }
                .onDelete { indexSet in
                    deleteQueues(at: indexSet)
                }
                
                if messageQueueController.persistenceManager.messageQueues.isEmpty {
                    ContentUnavailableView {
                        Label("No Message Queues", systemImage: "tray")
                    } description: {
                        Text("Create a new message queue to get started")
                    } actions: {
                        Button(action: {
                            showingQueueSelection = false
                            newQueueName = ""
                            showingQueueCreation = true
                        }) {
                            Text("Create Queue")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Select Message Queue")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        newQueueName = ""
                        showingQueueCreation = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingQueueSelection = false
                    }
                }
            }
        }
    }
    
    // MARK: - Subscription Setup
    
    /// Set up Combine subscriptions
    private func setupSubscriptions() {
        // Update selectedMessage when currentIndex changes
        messageQueueController.currentQueue?.$currentIndex
            .sink { [weak self] index in
                guard let self = self, let index = index, 
                      index < messageQueueController.currentQueue?.messages.count ?? 0 else {
                    selectedMessage = nil
                    return
                }
                
                selectedMessage = messageQueueController.currentQueue?.messages[index]
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    /// Create a new message queue
    private func createNewQueue() {
        guard !newQueueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let queue = messageQueueController.createQueue(name: newQueueName)
        messageQueueController.selectQueue(withID: queue.id)
        newQueueName = ""
    }
    
    /// Select a queue
    private func selectQueue(_ queue: MessageQueue) {
        messageQueueController.selectQueue(withID: queue.id)
    }
    
    /// Delete queues at indexSet
    private func deleteQueues(at indexSet: IndexSet) {
        for index in indexSet {
            let queue = messageQueueController.persistenceManager.messageQueues[index]
            messageQueueController.deleteQueue(withID: queue.id)
        }
    }
    
    /// Duplicate a queue
    private func duplicateQueue(_ queue: MessageQueue) {
        _ = messageQueueController.duplicateQueue(withID: queue.id)
    }
    
    /// Duplicate the current queue
    private func duplicateCurrentQueue() {
        guard let queue = messageQueueController.currentQueue else { return }
        _ = messageQueueController.duplicateQueue(withID: queue.id)
    }
    
    /// Go to the next message
    private func nextMessage() {
        guard let queue = messageQueueController.currentQueue else { return }
        _ = queue.nextMessage()
        messageQueueController.persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
    }
    
    /// Go to the previous message
    private func previousMessage() {
        guard let queue = messageQueueController.currentQueue else { return }
        _ = queue.previousMessage()
        messageQueueController.persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
    }
    
    /// Send the current message
    private func sendCurrentMessage() {
        guard let message = messageQueueController.currentQueue?.getCurrentMessage() else { return }
        sendMessage(message)
    }
    
    /// Send a specific message
    private func sendMessage(_ message: Message) {
        messageQueueController.sendMessage(message)
    }
    
    /// Clear the current message
    private func clearCurrentMessage() {
        messageQueueController.clearCurrentMessage()
    }
    
    /// Toggle the connection state
    private func toggleConnection() {
        switch resolumeConnector.connectionState {
        case .connected:
            resolumeConnector.disconnect()
        case .disconnected:
            resolumeConnector.connect()
        default:
            // Do nothing if connecting or failed
            break
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get the SwiftUI TextAlignment from MessageFormatting.TextAlignment
    private func textAlignment(from alignment: MessageFormatting.TextAlignment) -> TextAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
    
    /// Get the SwiftUI Font.Weight from MessageFormatting.FontWeight
    private func fontWeight(from weight: MessageFormatting.FontWeight) -> Font.Weight {
        switch weight {
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        }
    }
}

// MARK: - Previews

struct SoloModeView_Previews: PreviewProvider {
    static var previews: some View {
        let settingsManager = SettingsManager()
        let persistenceManager = PersistenceManager()
        let resolumeConnector = ResolumeConnector(settings: settingsManager.settings.oscSettings)
        let messageQueueController = MessageQueueController(
            persistenceManager: persistenceManager,
            resolumeConnector: resolumeConnector
        )
        
        return SoloModeView()
            .environmentObject(settingsManager)
            .environmentObject(messageQueueController)
            .environmentObject(resolumeConnector)
            .environmentObject(ModeManager())
    }
}
