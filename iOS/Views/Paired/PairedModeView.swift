//
//  PairedModeView.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import SwiftUI
import Combine
import MultipeerConnectivity

/// Main view for Paired mode operation on iPad
struct PairedModeView: View {
    // MARK: - Environment Objects
    
    /// Settings manager
    @EnvironmentObject var settingsManager: SettingsManager
    
    /// Message queue controller
    @EnvironmentObject var messageQueueController: MessageQueueController
    
    /// Resolume connector
    @EnvironmentObject var resolumeConnector: ResolumeConnector
    
    /// Mode manager
    @EnvironmentObject var modeManager: ModeManager
    
    /// Peer client
    @EnvironmentObject var peerClient: PeerClient
    
    // MARK: - State
    
    /// Currently selected message
    @State private var selectedMessage: Message?
    
    /// Whether the queue list is showing (for smaller screens)
    @State private var showingQueueList = true
    
    /// Whether the disconnect confirmation is showing
    @State private var showingDisconnectConfirmation = false
    
    /// Whether the clear confirmation alert is showing
    @State private var showingClearConfirmation = false
    
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
    
    /// Connected Mac name
    private var connectedMacName: String {
        if case let .connected(peer) = peerClient.connectionState {
            return peer.displayName
        }
        return "Unknown"
    }
    
    // MARK: - Body
    
    var body: some View {
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
        .onAppear {
            setupSubscriptions()
        }
        .alert("Disconnect from Mac", isPresented: $showingDisconnectConfirmation) {
            Button("Disconnect", role: .destructive) {
                disconnectFromMac()
            }
            
            Button("Cancel", role: .cancel) {
                // Just dismiss the alert
            }
        } message: {
            Text("Are you sure you want to disconnect from the Mac? You will need to reconnect to continue working in Paired mode.")
        }
        .alert("Clear Message", isPresented: $showingClearConfirmation) {
            Button("Clear", role: .destructive) {
                clearCurrentMessage()
            }
            
            Button("Cancel", role: .cancel) {
                // Just dismiss the alert
            }
        } message: {
            Text("Are you sure you want to clear the current message?")
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
                
                // Can't create new queues in Paired mode
                // Queues are managed by the Mac
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
                        
                        // Sync selection to Mac
                        sendMessageSelectionToMac(message)
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
                    
                    Text("The Mac will control which queue is active")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
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
            connectionStatusView
            
            // Mode indicator
            Button(action: {
                showingDisconnectConfirmation = true
            }) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.Colors.peerConnection)
                        .frame(width: 8, height: 8)
                    
                    Text("PAIRED")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.peerConnection)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .stroke(AppTheme.Colors.peerConnection, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Connection Status View
    
    /// View showing the connection status
    private var connectionStatusView: some View {
        HStack(spacing: 4) {
            // Status indicator
            Circle()
                .fill(connectionStatusColor)
                .frame(width: 8, height: 8)
            
            // Connected to text
            Text(connectedMacName)
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
    
    /// The color for the connection status
    private var connectionStatusColor: Color {
        if case .connected = peerClient.connectionState {
            return AppTheme.Colors.success
        }
        return AppTheme.Colors.error
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
            
            // Connected to Mac message
            HStack {
                Spacer()
                
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(AppTheme.Colors.peerConnection)
                        
                        Text("Connected to \(connectedMacName)")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.peerConnection)
                    }
                    
                    Text("The Mac is controlling OSC settings and queue management")
                        .font(.caption2)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Colors.peerConnection.opacity(0.1))
            )
            
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
            
            Text("Waiting for the Mac to select a message queue")
                .font(.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            // Connected to Mac message
            HStack {
                Spacer()
                
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(AppTheme.Colors.peerConnection)
                        
                        Text("Connected to \(connectedMacName)")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.peerConnection)
                    }
                    
                    Text("Message queues are managed by the Mac")
                        .font(.caption2)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Colors.peerConnection.opacity(0.1))
            )
            
            Spacer()
        }
        .padding(40)
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
    
    /// Go to the next message
    private func nextMessage() {
        guard let queue = messageQueueController.currentQueue else { return }
        _ = queue.nextMessage()
        messageQueueController.persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
        
        // Sync navigation to Mac
        if let message = queue.getCurrentMessage() {
            sendMessageSelectionToMac(message)
        }
    }
    
    /// Go to the previous message
    private func previousMessage() {
        guard let queue = messageQueueController.currentQueue else { return }
        _ = queue.previousMessage()
        messageQueueController.persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
        
        // Sync navigation to Mac
        if let message = queue.getCurrentMessage() {
            sendMessageSelectionToMac(message)
        }
    }
    
    /// Send the current message
    private func sendCurrentMessage() {
        guard let message = messageQueueController.currentQueue?.getCurrentMessage() else { return }
        sendMessage(message)
    }
    
    /// Send a specific message
    private func sendMessage(_ message: Message) {
        messageQueueController.sendMessage(message)
        
        // Notify Mac that message was sent
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            peerClient.sendData(data, messageType: .messageSent)
        } catch {
            logError("Failed to encode message: \(error.localizedDescription)", category: .peer)
        }
    }
    
    /// Clear the current message
    private func clearCurrentMessage() {
        messageQueueController.clearCurrentMessage()
        
        // Notify Mac that message was cleared
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode("clear")
            peerClient.sendData(data, messageType: .command)
        } catch {
            logError("Failed to encode clear command: \(error.localizedDescription)", category: .peer)
        }
    }
    
    /// Disconnect from the Mac
    private func disconnectFromMac() {
        peerClient.disconnect()
        modeManager.resetMode()
    }
    
    /// Send message selection to Mac
    private func sendMessageSelectionToMac(_ message: Message) {
        // Send selection update to Mac
        do {
            // Create selection info
            let selectionInfo = [
                "messageID": message.id.uuidString,
                "action": "select"
            ]
            
            // Encode and send
            let encoder = JSONEncoder()
            let data = try encoder.encode(selectionInfo)
            peerClient.sendData(data, messageType: .command)
        } catch {
            logError("Failed to encode message selection: \(error.localizedDescription)", category: .peer)
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

struct PairedModeView_Previews: PreviewProvider {
    static var previews: some View {
        let settingsManager = SettingsManager()
        let persistenceManager = PersistenceManager()
        let resolumeConnector = ResolumeConnector(settings: settingsManager.settings.oscSettings)
        let messageQueueController = MessageQueueController(
            persistenceManager: persistenceManager,
            resolumeConnector: resolumeConnector
        )
        
        return PairedModeView()
            .environmentObject(settingsManager)
            .environmentObject(messageQueueController)
            .environmentObject(resolumeConnector)
            .environmentObject(ModeManager())
            .environmentObject(PeerClient())
    }
}
