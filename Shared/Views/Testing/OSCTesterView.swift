//
//  OSCTesterView.swift
//  LED Messenger
//
//  Created on April 19, 2025
//

#if DEBUG

import SwiftUI

/// View for testing OSC connectivity and sending custom OSC messages
public struct OSCTesterView: View {
    // MARK: - Properties
    
    /// The settings manager
    @StateObject private var settingsManager = SettingsManager()
    
    /// The Resolume connector service (initialized in onAppear with proper settings)
    @StateObject private var resolumeConnector = ResolumeConnector()
    
    /// Custom OSC address input
    @State private var customAddress = "/composition/layers/5/clips/1/video/source/textgenerator/text/params/lines"
    
    /// Custom message text input
    @State private var customMessage = "TEST MESSAGE"
    
    /// Selected message type
    @State private var selectedMessageType = 0
    
    /// Connection test results
    @State private var testResults = ""
    
    /// Whether a test is currently running
    @State private var isTesting = false
    
    /// Animation state for highlighting current OSC messages
    @State private var highlightedMessage: String? = nil
    
    /// List of preset OSC messages
    let presetMessages = [
        ("Set Text", "/composition/layers/{layer}/clips/{clip}/video/source/textgenerator/text/params/lines"),
        ("Trigger Clip", "/composition/layers/{layer}/clips/{clip}/connect"),
        ("Clear Screen", "/composition/layers/{layer}/clips/{clearClip}/connect"),
        ("Layer Opacity", "/composition/layers/{layer}/opacity/values"),
        ("Layer Bypass", "/composition/layers/{layer}/bypass"),
        ("Get Clip Names", "/composition/layers/{layer}/clips/names")
    ]
    
    /// Message types
    let messageTypes = ["Text", "True", "Float (1.0)", "Int (1)", "Bang"]
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Connection status card
                    connectionStatusCard
                    
                    // OSC connection details
                    oscConnectionDetailsCard
                    
                    // Custom message tester
                    customMessageTesterCard
                    
                    // Preset message tests
                    presetMessagesCard
                    
                    // Test results display
                    testResultsCard
                }
                .padding()
            }
            .background(Color.black.opacity(0.1).ignoresSafeArea())
            .navigationTitle("OSC Tester")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reconnect") {
                        Task {
                            await resolumeConnector.reconnect()
                        }
                    }
                }
            }
        }
        .onAppear {
            // Initialize with current settings
            resolumeConnector.updateSettings(newSettings: settingsManager.settings.oscSettings)
            
            // Log detailed information about the current settings
            logInfo("OSC Tester initialized with the following settings:", category: .osc)
            logInfo("IP Address: \(settingsManager.settings.oscSettings.ipAddress)", category: .osc)
            logInfo("Port: \(settingsManager.settings.oscSettings.port) (Resolume Arena's default port)", category: .osc)
            logInfo("Layer: \(settingsManager.settings.oscSettings.layer)", category: .osc)
            
            // Log clip rotation information
            let baseClip = settingsManager.settings.oscSettings.clip
            let rotationCount = settingsManager.settings.oscSettings.clipRotation
            let clearClip = settingsManager.settings.oscSettings.clearClip
            logInfo("Starting Clip: \(baseClip)", category: .osc)
            logInfo("Clip Rotation: \(rotationCount) clips, using slots \(baseClip) through \(baseClip + rotationCount - 1)", category: .osc)
            logInfo("Clear Clip: \(clearClip)", category: .osc)
            
            // Log test pattern sequence
            logInfo("Test Pattern Sequence:", category: .osc)
            logInfo("1. Send \"LEDMESSENGER.COM\"", category: .osc)
            logInfo("2. Wait 3 seconds", category: .osc)
            logInfo("3. Send \"LET'S PARTY\"", category: .osc)
            logInfo("4. Wait 3 seconds", category: .osc)
            logInfo("5. Clear (using clear clip \(clearClip))", category: .osc)
            
            // Try to connect immediately for better user experience
            Task {
                let connectionResult = await resolumeConnector.reconnect()
                if connectionResult {
                    logInfo("Successfully connected to Resolume on startup", category: .osc)
                } else {
                    logWarning("Failed to connect to Resolume on startup - check settings", category: .osc)
                }
            }
        }
    }
    
    // MARK: - Connection Status Card
    
    /// Connection status indicator card
    private var connectionStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Connection Status")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            HStack(spacing: 16) {
                // OSC connection indicator
                VStack(alignment: .center, spacing: 4) {
                    Circle()
                        .fill(resolumeConnector.isConnected ? AppTheme.Colors.success : AppTheme.Colors.error)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                        .shadow(color: resolumeConnector.isConnected ? AppTheme.Colors.success.opacity(0.5) : AppTheme.Colors.error.opacity(0.5), radius: 4)
                    
                    Text("OSC")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Test connection button
                Button(action: {
                    testConnection()
                }) {
                    HStack {
                        Image(systemName: "network")
                        Text("Test Connection")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.Colors.primary)
                    )
                }
                .disabled(isTesting)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.surface)
        )
    }
    
    // MARK: - OSC Configuration Card
    
    /// OSC connection details card
    private var oscConnectionDetailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OSC Configuration")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "IP Address", value: settingsManager.settings.oscSettings.ipAddress)
                infoRow(label: "Port", value: "\(settingsManager.settings.oscSettings.port)")
                infoRow(label: "Layer", value: "\(settingsManager.settings.oscSettings.layer)")
                infoRow(label: "Clips", value: "\(settingsManager.settings.oscSettings.clip) (Clear: \(settingsManager.settings.oscSettings.clearClip))")
            }
            
            Button(action: {
                // Go to settings
            }) {
                Text("Go to Settings")
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.Colors.primary.opacity(0.8))
                    )
            }
            .padding(.top, 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.surface)
        )
    }
    
    // MARK: - Custom Message Card
    
    /// Custom message tester card
    private var customMessageTesterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom OSC Message")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            // OSC address input
            VStack(alignment: .leading, spacing: 4) {
                Text("OSC Address:")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                TextField("OSC Address", text: $customAddress)
                    .padding(8)
                    .background(AppTheme.Colors.background)
                    .cornerRadius(8)
            }
            
            // Message type selector
            VStack(alignment: .leading, spacing: 4) {
                Text("Message Type:")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Picker("Message Type", selection: $selectedMessageType) {
                    ForEach(0..<messageTypes.count, id: \.self) { index in
                        Text(messageTypes[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Message content input (only for text messages)
            if selectedMessageType == 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message Content:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    TextField("Message Content", text: $customMessage)
                        .padding(8)
                        .background(AppTheme.Colors.background)
                        .cornerRadius(8)
                }
            }
            
            // Send button
            Button(action: {
                sendCustomMessage()
            }) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Send Message")
                }
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.Colors.success)
                )
            }
            .disabled(isTesting)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.surface)
        )
    }
    
    // MARK: - Preset Messages Card
    
    /// Preset messages card
    private var presetMessagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preset Messages")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            // Preset message list
            ForEach(0..<presetMessages.count, id: \.self) { index in
                Button(action: {
                    selectPreset(index)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            // Preset name
                            Text(presetMessages[index].0)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.Colors.text)
                            
                            // OSC address (with template placeholders)
                            Text(presetMessages[index].1)
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Send button
                        Button(action: {
                            sendPreset(index)
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(AppTheme.Colors.success)
                                )
                        }
                        .disabled(isTesting)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(highlightedMessage == presetMessages[index].0 ? 
                                  AppTheme.Colors.primary.opacity(0.3) : AppTheme.Colors.background.opacity(0.5))
                    )
                    .animation(.easeInOut(duration: 0.3), value: highlightedMessage)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.surface)
        )
    }
    
    // MARK: - Test Results Card
    
    /// Test results card
    private var testResultsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Test Results")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                if !testResults.isEmpty {
                    Button(action: {
                        testResults = ""
                    }) {
                        Text("Clear")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.Colors.error.opacity(0.8))
                            )
                    }
                }
            }
            
            if testResults.isEmpty {
                Text("Results will appear here after testing")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .italic()
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView {
                    Text(testResults)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(AppTheme.Colors.text)
                        .padding()
                }
                .frame(height: 200)
                .background(AppTheme.Colors.background.opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.surface)
        )
    }
    
    // MARK: - Helper View Functions
    
    /// Helper for info rows
    private func infoRow(label: String, value: String, valueColor: Color = AppTheme.Colors.text) -> some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 140, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(valueColor)
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    /// Test OSC connection
    private func testConnection() {
        isTesting = true
        testResults = "⏳ Testing OSC connection...\n"
        
        // Start connection test
        Task {
            // Check current connection state
            testResults += "Current status: \(resolumeConnector.isConnected ? "Connected" : "Disconnected")\n"
            
            // Force reconnection
            testResults += "Attempting reconnection...\n"
            await resolumeConnector.reconnect()
            
            // Wait for connection to establish
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Check new connection state
            testResults += "New status: \(resolumeConnector.isConnected ? "Connected ✅" : "Disconnected ❌")\n"
            
            // Try to verify connection with a ping
            let pingResult = await resolumeConnector.ping()
            testResults += "Connection verification: \(pingResult ? "Successful ✅" : "Failed ❌")\n"
            
            // Run more comprehensive test if connected
            if pingResult {
                testResults += "\n🔍 Running comprehensive test...\n"
                
                // Send a test message
                let testMessageResult = await resolumeConnector.sendTestMessage()
                testResults += "Test message: \(testMessageResult ? "Successful ✅" : "Failed ❌")\n"
                
                // Check clip rotation setup
                let baseClip = settingsManager.settings.oscSettings.clip
                let rotation = settingsManager.settings.oscSettings.clipRotation
                let clearClip = settingsManager.settings.oscSettings.clearClip
                
                testResults += "\nClip Rotation Check:\n"
                testResults += "Starting at clip \(baseClip)\n"
                testResults += "Rotating through \(rotation) clips: \(baseClip) through \(baseClip + rotation - 1)\n"
                testResults += "Using clip \(clearClip) for clearing\n"
                
                // Check test pattern sequence
                testResults += "\nTest Pattern Sequence:\n"
                testResults += "1. \"LEDMESSENGER.COM\" (sent to clips in rotation)\n"
                testResults += "2. Wait 3 seconds\n"
                testResults += "3. \"LET'S PARTY\" (sent to next clip in rotation)\n"
                testResults += "4. Wait 3 seconds\n"
                testResults += "5. Clear (using clear clip \(clearClip))\n"
                
                // Check configuration
                testResults += "\nConfiguration check:\n"
                testResults += "IP: \(settingsManager.settings.oscSettings.ipAddress)\n"
                testResults += "Port: \(settingsManager.settings.oscSettings.port) (Resolume Arena's default port)\n"
                testResults += "Layer: \(settingsManager.settings.oscSettings.layer)\n"
                testResults += "Base clip: \(settingsManager.settings.oscSettings.clip)\n"
                testResults += "Clip rotation: \(settingsManager.settings.oscSettings.clipRotation)\n"
                testResults += "Clear clip: \(settingsManager.settings.oscSettings.clearClip)\n"
            }
            
            isTesting = false
        }
    }
    
    /// Send a custom OSC message
    private func sendCustomMessage() {
        isTesting = true
        let address = customAddress
        
        testResults = "⏳ Sending custom OSC message...\n"
        testResults += "Address: \(address)\n"
        
        Task {
            var success = false
            
            // Create and send OSC message based on selected type
            switch selectedMessageType {
            case 0: // Text
                testResults += "Type: Text\n"
                testResults += "Content: \(customMessage)\n"
                success = await resolumeConnector.sendOSCMessage(address: address, value: customMessage)
                
            case 1: // Boolean true
                testResults += "Type: Boolean (true)\n"
                success = await resolumeConnector.sendOSCMessage(address: address, value: true)
                
            case 2: // Float 1.0
                testResults += "Type: Float (1.0)\n"
                success = await resolumeConnector.sendOSCMessage(address: address, value: 1.0)
                
            case 3: // Int 1
                testResults += "Type: Int (1)\n"
                success = await resolumeConnector.sendOSCMessage(address: address, value: 1)
                
            case 4: // Bang (no arguments)
                testResults += "Type: Bang (no arguments)\n"
                success = await resolumeConnector.sendOSCMessage(address: address, value: nil)
                
            default:
                success = false
            }
            
            testResults += success ? "Message sent successfully ✅\n" : "Failed to send message ❌\n"
            isTesting = false
        }
    }
    
    /// Select a preset message
    private func selectPreset(_ index: Int) {
        let preset = presetMessages[index]
        
        // Replace template variables with actual values
        var address = preset.1
        address = address.replacingOccurrences(
            of: "{layer}",
            with: "\(settingsManager.settings.oscSettings.layer)"
        )
        
        address = address.replacingOccurrences(
            of: "{clip}",
            with: "\(settingsManager.settings.oscSettings.clip)"
        )
        
        address = address.replacingOccurrences(
            of: "{clearClip}",
            with: "\(settingsManager.settings.oscSettings.clearClip)"
        )
        
        // Update the custom address field
        customAddress = address
        
        // Set appropriate message type
        if preset.0 == "Set Text" {
            selectedMessageType = 0 // Text
            customMessage = "TEST MESSAGE"
        } else if preset.0 == "Layer Opacity" {
            selectedMessageType = 2 // Float
        } else {
            selectedMessageType = 1 // True
        }
    }
    
    /// Send a preset message
    private func sendPreset(_ index: Int) {
        let preset = presetMessages[index]
        
        // Highlight the selected preset
        highlightedMessage = preset.0
        
        // Auto-clear highlight after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                highlightedMessage = nil
            }
        }
        
        // Select and send the preset
        selectPreset(index)
        sendCustomMessage()
    }
}

// MARK: - Preview

struct OSCTesterView_Previews: PreviewProvider {
    static var previews: some View {
        OSCTesterView()
            .preferredColorScheme(.dark)
    }
}

#endif