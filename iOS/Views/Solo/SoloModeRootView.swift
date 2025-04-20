//
//  SoloModeRootView.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import SwiftUI
import Combine

/// Root view for Solo mode, handles app lifecycle and state persistence
struct SoloModeRootView: View {
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
    
    /// App lifecycle state
    @Environment(\.scenePhase) private var scenePhase
    
    /// Subscription cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Alert message if any
    @State private var alertMessage: String?
    
    /// Whether an alert is showing
    @State private var showingAlert = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main content
            SoloModeView()
                .environmentObject(settingsManager)
                .environmentObject(messageQueueController)
                .environmentObject(resolumeConnector)
                .environmentObject(modeManager)
            
            // Startup connection indicator
            if resolumeConnector.connectionState == .connecting {
                connectionProgressOverlay
            }
        }
        .onAppear {
            // Initial setup
            setupInitialState()
            
            // Setup observers
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
    
    // MARK: - Connection Progress Overlay
    
    /// Overlay showing connection progress
    private var connectionProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Connecting to Resolume...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("IP: \(settingsManager.settings.oscSettings.ipAddress):\(settingsManager.settings.oscSettings.port)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.3))
                    .blur(radius: 2)
            )
        }
        .transition(.opacity)
    }
    
    // MARK: - Setup
    
    /// Setup the initial state when the app launches
    private func setupInitialState() {
        // Try to load the last used queue from persistence
        if messageQueueController.currentQueue == nil,
           !messageQueueController.persistenceManager.messageQueues.isEmpty {
            // Select the first queue
            let queue = messageQueueController.persistenceManager.messageQueues[0]
            messageQueueController.selectQueue(withID: queue.id)
        }
        
        // Try to connect to Resolume if auto-connect is enabled
        if settingsManager.settings.generalSettings.autoSave {
            resolumeConnector.connect { result in
                switch result {
                case .failure(let error):
                    // Show error alert
                    alertMessage = "Failed to connect to Resolume: \(error.localizedDescription)"
                    showingAlert = true
                default:
                    break
                }
            }
        }
    }
    
    /// Setup observers for state changes
    private func setupObservers() {
        // Observe connection state changes
        resolumeConnector.$connectionState
            .dropFirst() // Skip initial value
            .sink { state in
                if case let .failed(error) = state {
                    // Show error alert
                    alertMessage = "Connection failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
            .store(in: &cancellables)
        
        // Observe settings changes
        settingsManager.$settings
            .dropFirst() // Skip initial value
            .sink { [weak resolumeConnector] newSettings in
                // Update OSC settings when they change
                resolumeConnector?.updateSettings(newSettings: newSettings.oscSettings)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Scene Phase Handling
    
    /// Handle app lifecycle changes
    /// - Parameter newPhase: The new scene phase
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active
            logInfo("App became active in Solo mode", category: .app)
            
            // Reconnect to Resolume if was connected before
            if case .connected = resolumeConnector.connectionState {
                // Already connected, do nothing
            } else if settingsManager.settings.generalSettings.autoSave {
                // Auto-connect if enabled
                resolumeConnector.connect()
            }
            
        case .inactive:
            // App became inactive
            logInfo("App became inactive in Solo mode", category: .app)
            
        case .background:
            // App moved to background
            logInfo("App moved to background in Solo mode", category: .app)
            
            // Save any unsaved changes
            messageQueueController.saveMessageQueues()
            
            // Disconnect from Resolume if configured to do so
            if !settingsManager.settings.generalSettings.autoSave {
                resolumeConnector.disconnect()
            }
            
        @unknown default:
            logWarning("Unknown scene phase: \(newPhase)", category: .app)
        }
    }
}

struct SoloModeRootView_Previews: PreviewProvider {
    static var previews: some View {
        let settingsManager = SettingsManager()
        let persistenceManager = PersistenceManager()
        let resolumeConnector = ResolumeConnector(settings: settingsManager.settings.oscSettings)
        let messageQueueController = MessageQueueController(
            persistenceManager: persistenceManager,
            resolumeConnector: resolumeConnector
        )
        
        return SoloModeRootView()
            .environmentObject(settingsManager)
            .environmentObject(messageQueueController)
            .environmentObject(resolumeConnector)
            .environmentObject(ModeManager())
    }
}
