//
//  PairedModeRootView.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import SwiftUI
import Combine
import MultipeerConnectivity

/// Root view for Paired mode, handles app lifecycle and peer connectivity
struct PairedModeRootView: View {
    // MARK: - Environment Objects
    
    /// Settings manager
    @EnvironmentObject var settingsManager: SettingsManager
    
    /// Message queue controller
    @EnvironmentObject var messageQueueController: MessageQueueController
    
    /// Resolume connector
    @EnvironmentObject var resolumeConnector: ResolumeConnector
    
    /// Mode manager
    @EnvironmentObject var modeManager: ModeManager
    
    /// Peer client for connecting to Mac
    @EnvironmentObject var peerClient: PeerClient
    
    // MARK: - State
    
    /// App lifecycle state
    @Environment(\.scenePhase) private var scenePhase
    
    /// Whether the discovery view is showing
    @State private var showingDiscoveryView = true
    
    /// Alert message if any
    @State private var alertMessage: String?
    
    /// Whether an alert is showing
    @State private var showingAlert = false
    
    /// Subscription cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main content - either discovery view or paired mode view
            if showingDiscoveryView {
                PeerDiscoveryView(
                    peerClient: peerClient,
                    onConnectionSuccess: {
                        withAnimation {
                            showingDiscoveryView = false
                        }
                    }
                )
                .environmentObject(modeManager)
                .transition(.opacity)
            } else {
                PairedModeView()
                    .environmentObject(settingsManager)
                    .environmentObject(messageQueueController)
                    .environmentObject(resolumeConnector)
                    .environmentObject(modeManager)
                    .environmentObject(peerClient)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Setup when view appears
            setupObservers()
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
        .alert("Connection Issue", isPresented: $showingAlert, presenting: alertMessage) { message in
            Button("OK") {
                showingAlert = false
                alertMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }
    
    // MARK: - Setup
    
    /// Setup observers for state changes
    private func setupObservers() {
        // Observe peer connection state changes
        peerClient.connectionStatePublisher
            .sink { state in
                switch state {
                case .connected:
                    // Connection successful, hide discovery view
                    withAnimation {
                        showingDiscoveryView = false
                    }
                    
                case .disconnected:
                    // Disconnected, show discovery view
                    withAnimation {
                        showingDiscoveryView = true
                    }
                    
                case .failed(let error):
                    // Connection failed, show alert
                    alertMessage = "Connection failed: \(error.localizedDescription)"
                    showingAlert = true
                    
                    // Show discovery view
                    withAnimation {
                        showingDiscoveryView = true
                    }
                    
                default:
                    // Other states don't require UI changes
                    break
                }
            }
            .store(in: &cancellables)
        
        // Start browsing for peers when in paired mode
        peerClient.startBrowsing()
        
        // Observe peer messages for settings and queue updates
        peerClient.messagePublisher
            .sink { completion in
                switch completion {
                case .failure(let error):
                    // Show error alert
                    alertMessage = "Message error: \(error.localizedDescription)"
                    showingAlert = true
                case .finished:
                    // Publisher finished normally
                    break
                }
            } receiveValue: { message in
                handlePeerMessage(message)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Peer Message Handling
    
    /// Handle messages received from the peer
    /// - Parameter message: The peer message
    private func handlePeerMessage(_ message: PeerMessage) {
        // Process message based on type
        switch message.type {
        case .settings:
            // Update settings
            handleSettingsUpdate(message.data)
            
        case .messageQueue:
            // Update message queue
            handleMessageQueueUpdate(message.data)
            
        case .messageSent:
            // Handle message sent event
            handleMessageSent(message.data)
            
        case .command:
            // Handle command
            handleCommand(message.data)
            
        default:
            // Other message types are handled elsewhere
            break
        }
    }
    
    /// Handle settings update from peer
    /// - Parameter data: The settings data
    private func handleSettingsUpdate(_ data: Data) {
        do {
            // Decode the settings
            let decoder = JSONDecoder()
            let newSettings = try decoder.decode(Settings.self, from: data)
            
            // Update settings
            settingsManager.updateSettings(newSettings)
            
            logInfo("Received settings update from Mac", category: .peer)
        } catch {
            logError("Failed to decode settings: \(error.localizedDescription)", category: .peer)
        }
    }
    
    /// Handle message queue update from peer
    /// - Parameter data: The message queue data
    private func handleMessageQueueUpdate(_ data: Data) {
        do {
            // Decode the message queue
            let decoder = JSONDecoder()
            let queue = try decoder.decode(MessageQueue.self, from: data)
            
            // Check if we already have this queue
            if messageQueueController.persistenceManager.messageQueues.contains(where: { $0.id == queue.id }) {
                // Update existing queue
                messageQueueController.persistenceManager.updateMessageQueue(withID: queue.id, to: queue)
            } else {
                // Add new queue
                messageQueueController.persistenceManager.addMessageQueue(queue)
            }
            
            // Select this queue
            messageQueueController.selectQueue(withID: queue.id)
            
            logInfo("Received queue update from Mac: \(queue.name)", category: .peer)
        } catch {
            logError("Failed to decode message queue: \(error.localizedDescription)", category: .peer)
        }
    }
    
    /// Handle message sent event from peer
    /// - Parameter data: The message data
    private func handleMessageSent(_ data: Data) {
        do {
            // Decode the message
            let decoder = JSONDecoder()
            let message = try decoder.decode(Message.self, from: data)
            
            // Mark the message as sent in our queue
            if let queue = messageQueueController.currentQueue,
               let index = queue.messages.firstIndex(where: { $0.id == message.id }) {
                var updatedQueue = queue
                var updatedMessage = queue.messages[index]
                updatedMessage.markAsSent()
                updatedQueue.messages[index] = updatedMessage
                
                // Update the queue
                messageQueueController.persistenceManager.updateMessageQueue(withID: queue.id, to: updatedQueue)
            }
            
            logInfo("Received message sent event from Mac", category: .peer)
        } catch {
            logError("Failed to decode message: \(error.localizedDescription)", category: .peer)
        }
    }
    
    /// Handle command from peer
    /// - Parameter data: The command data
    private func handleCommand(_ data: Data) {
        do {
            // Decode the command
            let decoder = JSONDecoder()
            let command = try decoder.decode(String.self, from: data)
            
            // Process the command
            switch command {
            case "clear":
                // Clear the current message
                messageQueueController.clearCurrentMessage()
                
            case "refresh":
                // Refresh all data
                refreshAllData()
                
            default:
                logWarning("Unknown command received: \(command)", category: .peer)
            }
            
            logInfo("Received command from Mac: \(command)", category: .peer)
        } catch {
            logError("Failed to decode command: \(error.localizedDescription)", category: .peer)
        }
    }
    
    /// Refresh all data from the Mac
    private func refreshAllData() {
        // Request settings and queues from the Mac
        sendRefreshRequest()
    }
    
    /// Send a refresh request to the Mac
    private func sendRefreshRequest() {
        // Send a command to request a refresh
        let command = "refresh"
        
        do {
            // Encode the command
            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            
            // Send the command
            peerClient.sendData(data, messageType: .command)
            
            logInfo("Sent refresh request to Mac", category: .peer)
        } catch {
            logError("Failed to encode refresh request: \(error.localizedDescription)", category: .peer)
        }
    }
    
    // MARK: - Scene Phase Handling
    
    /// Handle app lifecycle changes
    /// - Parameter newPhase: The new scene phase
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active
            logInfo("App became active in Paired mode", category: .app)
            
            // Start browsing for peers if not connected
            if !peerClient.connectionState.isConnected {
                peerClient.startBrowsing()
            }
            
        case .inactive:
            // App became inactive
            logInfo("App became inactive in Paired mode", category: .app)
            
        case .background:
            // App moved to background
            logInfo("App moved to background in Paired mode", category: .app)
            
            // Save any unsaved changes
            messageQueueController.saveMessageQueues()
            
            // Stop browsing for peers when app is in background
            if case .browsing = peerClient.connectionState {
                peerClient.stopBrowsing()
            }
            
        @unknown default:
            logWarning("Unknown scene phase: \(newPhase)", category: .app)
        }
    }
}

struct PairedModeRootView_Previews: PreviewProvider {
    static var previews: some View {
        let settingsManager = SettingsManager()
        let persistenceManager = PersistenceManager()
        let resolumeConnector = ResolumeConnector(settings: settingsManager.settings.oscSettings)
        let messageQueueController = MessageQueueController(
            persistenceManager: persistenceManager,
            resolumeConnector: resolumeConnector
        )
        
        return PairedModeRootView()
            .environmentObject(settingsManager)
            .environmentObject(messageQueueController)
            .environmentObject(resolumeConnector)
            .environmentObject(ModeManager())
            .environmentObject(PeerClient())
    }
}
