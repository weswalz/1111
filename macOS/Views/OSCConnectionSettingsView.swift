//
//  OSCConnectionSettingsView.swift
//  LED Messenger macOS
//
//  Created on April 18, 2025
//

import Foundation
import SwiftUI
import Combine

/// View for configuring OSC connection settings for Resolume Arena
struct OSCConnectionSettingsView: View {
    // MARK: - Properties
    
    /// The OSC settings
    @Binding var oscSettings: OSCSettings
    
    /// The Resolume connector
    @ObservedObject var resolumeConnector: ResolumeConnector
    
    /// Whether the form has changes
    @State private var hasChanges = false
    
    /// Whether to show validation message
    @State private var showValidationMessage = false
    
    /// Validation message
    @State private var validationMessage = ""
    
    /// Whether validation is successful
    @State private var validationSuccess = false
    
    /// Test message to send
    @State private var testMessage = "Test Message"
    
    /// Whether a test is in progress
    @State private var testingInProgress = false
    
    /// Test status message
    @State private var testStatusMessage = ""
    
    /// Whether test was successful
    @State private var testSuccess = false
    
    /// Connection test cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("OSC Connection Settings")
                    .font(.headline)
                
                Spacer()
                
                // Connection status
                HStack(spacing: 4) {
                    Circle()
                        .fill(connectionStatusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(connectionStatusText)
                        .font(.caption)
                        .foregroundColor(connectionStatusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .stroke(connectionStatusColor, lineWidth: 1)
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Connection settings section
                    connectionSettingsSection
                    
                    Divider()
                    
                    // Resolume configuration section
                    resolumeConfigurationSection
                    
                    Divider()
                    
                    // Auto-clear settings section
                    autoClearSettingsSection
                    
                    Divider()
                    
                    // Testing section
                    testingSection
                    
                    Divider()
                    
                    // Advanced options
                    advancedOptionsSection
                    
                    Divider()
                    
                    // Validation section
                    validationSection
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                // Reset button
                Button("Reset") {
                    resetSettings()
                }
                .disabled(!hasChanges)
                
                Spacer()
                
                // Apply button
                Button(hasChanges ? "Apply Changes" : "Changes Applied") {
                    applyChanges()
                }
                .disabled(!hasChanges)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            validateSettings()
        }
        .onChange(of: oscSettings) { _ in
            hasChanges = true
            validateSettings()
        }
    }
    
    // MARK: - Connection Settings Section
    
    /// Section for connection settings
    private var connectionSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text("Connection Settings")
                .font(.headline)
            
            // IP address
            VStack(alignment: .leading, spacing: 4) {
                Text("IP Address")
                    .font(.subheadline)
                
                TextField("IP Address", text: $oscSettings.ipAddress)
                    .textFieldStyle(.roundedBorder)
                    .help("The IP address of the Resolume Arena computer (e.g. 127.0.0.1 for local)")
            }
            
            // Port
            VStack(alignment: .leading, spacing: 4) {
                Text("Port")
                    .font(.subheadline)
                
                TextField("Port", value: $oscSettings.port, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .help("The OSC port Resolume is listening on (default: 7000)")
            }
            
            // Connect button
            Button(action: toggleConnection) {
                Text(resolumeConnector.connectionState == .connected ? "Disconnect" : "Connect")
                    .frame(maxWidth: .infinity)
            }
            .disabled(resolumeConnector.connectionState == .connecting || !isConfigurationValid)
        }
    }
    
    // MARK: - Resolume Configuration Section
    
    /// Section for Resolume configuration
    private var resolumeConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text("Resolume Configuration")
                .font(.headline)
            
            // Layer settings
            VStack(alignment: .leading, spacing: 4) {
                Text("Layer")
                    .font(.subheadline)
                
                TextField("Layer", value: $oscSettings.layer, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .help("The Resolume layer to use for text (default: 1)")
            }
            
            // Clip settings
            VStack(alignment: .leading, spacing: 4) {
                Text("Clip")
                    .font(.subheadline)
                
                TextField("Clip", value: $oscSettings.clip, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .help("The Resolume clip to use for text (default: 1)")
            }
            
            // Clear clip settings
            VStack(alignment: .leading, spacing: 4) {
                Text("Clear Clip")
                    .font(.subheadline)
                
                TextField("Clear Clip", value: $oscSettings.clearClip, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .help("The Resolume clip to use for clearing text (default: 2)")
            }
            
            // Clip rotation
            Toggle("Rotate through clips", isOn: Binding<Bool>(
                get: { oscSettings.clipRotation > 1 },
                set: { oscSettings.clipRotation = $0 ? 3 : 1 }
            ))
                .help("When enabled, messages will cycle through multiple clips for smoother transitions")
            
            if oscSettings.clipRotation > 1 {
                // Clip count
                VStack(alignment: .leading, spacing: 4) {
                    Text("Number of Clips")
                        .font(.subheadline)
                    
                    Stepper(value: $oscSettings.clipRotation, in: 2...10) {
                        Text("\(oscSettings.clipRotation) clips")
                    }
                    .help("Number of clips to rotate through (2-10)")
                }
                .padding(.leading)
            }
        }
    }
    
    // MARK: - Auto-Clear Settings Section
    
    /// Section for auto-clear settings
    private var autoClearSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text("Auto-Clear Settings")
                .font(.headline)
            
            // Auto-clear toggle
            Toggle("Automatically clear messages after delay", isOn: $oscSettings.autoClear)
                .help("When enabled, messages will be automatically cleared after a delay")
            
            // Auto-clear delay
            if oscSettings.autoClear {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Clear Delay: \(String(format: "%.1f", oscSettings.autoClearDelay)) seconds")
                        .font(.subheadline)
                    
                    Slider(value: $oscSettings.autoClearDelay, in: 1...60, step: 0.5)
                        .help("Time to wait before clearing a message (1-60 seconds)")
                }
                .padding(.leading)
            }
        }
    }
    
    // MARK: - Testing Section
    
    /// Section for testing connection
    private var testingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            HStack {
                Text("Test Connection")
                    .font(.headline)
                
                Spacer()
                
                // Test status
                if !testStatusMessage.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(testSuccess ? AppTheme.Colors.success : AppTheme.Colors.error)
                            .frame(width: 8, height: 8)
                        
                        Text(testStatusMessage)
                            .font(.caption)
                            .foregroundColor(testSuccess ? AppTheme.Colors.success : AppTheme.Colors.error)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .stroke(testSuccess ? AppTheme.Colors.success : AppTheme.Colors.error, lineWidth: 1)
                    )
                }
            }
            
            // Test message
            VStack(alignment: .leading, spacing: 4) {
                Text("Test Message")
                    .font(.subheadline)
                
                TextField("Test Message", text: $testMessage)
                    .textFieldStyle(.roundedBorder)
                    .help("Enter a test message to send to Resolume")
            }
            
            // Test button
            Button(action: testConnection) {
                Text(testingInProgress ? "Testing..." : "Test Connection")
                    .frame(maxWidth: .infinity)
            }
            .disabled(testingInProgress || resolumeConnector.connectionState != .connected)
            
            // Help text
            Text("This will send a test message to Resolume using the current settings.")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Advanced Options Section
    
    /// Section for advanced options
    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text("Advanced Options")
                .font(.headline)
            
            // Show test pattern on connect
            Toggle("Show test pattern on connect", isOn: $oscSettings.showTestPattern)
                .help("When enabled, a test pattern will be sent when connecting to verify the connection")
            
            // Format options (could be expanded)
            Text("Additional format options coming soon...")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Validation Section
    
    /// Section for configuration validation
    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            HStack {
                Text("Configuration Validation")
                    .font(.headline)
                
                Spacer()
                
                // Validation status
                if showValidationMessage {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(validationSuccess ? AppTheme.Colors.success : AppTheme.Colors.error)
                            .frame(width: 8, height: 8)
                        
                        Text(validationSuccess ? "Valid Configuration" : "Invalid Configuration")
                            .font(.caption)
                            .foregroundColor(validationSuccess ? AppTheme.Colors.success : AppTheme.Colors.error)
                    }
                }
            }
            
            // Validation message
            if showValidationMessage && !validationSuccess {
                Text(validationMessage)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.error)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Colors.error.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("• Use 127.0.0.1 if Resolume is on the same computer")
                    .font(.caption)
                
                Text("• Ensure Resolume has OSC input enabled and is using the same port")
                    .font(.caption)
                
                Text("• Test your connection to verify settings are correct")
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Properties
    
    /// Check if the configuration is valid
    private var isConfigurationValid: Bool {
        oscSettings.validate().isValid
    }
    
    /// Color for connection status
    private var connectionStatusColor: Color {
        switch resolumeConnector.connectionState {
        case .connected:
            return AppTheme.Colors.success
        case .connecting:
            return AppTheme.Colors.warning
        case .disconnected:
            return AppTheme.Colors.textSecondary
        case .failed:
            return AppTheme.Colors.error
        }
    }
    
    /// Text for connection status
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
    
    // MARK: - Actions
    
    /// Toggle connection to Resolume
    private func toggleConnection() {
        if resolumeConnector.connectionState == .connected {
            // Disconnect
            resolumeConnector.disconnect()
        } else {
            // Connect
            let validationResult = oscSettings.validate()
            if !validationResult.isValid {
                // Show validation error
                showValidationMessage = true
                validationMessage = validationResult.error ?? "Unknown validation error"
                validationSuccess = false
                return
            }
            
            // Reset test status
            testStatusMessage = ""
            
            // Connect to Resolume
            resolumeConnector.connect { _ in
                // Connection result handled by UI binding to connectionState
            }
        }
    }
    
    /// Test connection to Resolume
    private func testConnection() {
        guard !testMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            testStatusMessage = "Test message cannot be empty"
            testSuccess = false
            return
        }
        
        testingInProgress = true
        testStatusMessage = "Testing connection..."
        
        // Create a test message
        let message = Message(
            text: testMessage,
            formatting: MessageFormatting()
        )
        
        // Send the test message
        resolumeConnector.sendMessage(message) { result in
            DispatchQueue.main.async {
                testingInProgress = false
                
                switch result {
                case .success:
                    testStatusMessage = "Test successful!"
                    testSuccess = true
                    
                    // Auto-clear after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if oscSettings.autoClear {
                            resolumeConnector.clearMessage()
                        }
                    }
                    
                case .failure(let error):
                    testStatusMessage = "Test failed: \(error.localizedDescription)"
                    testSuccess = false
                }
            }
        }
    }
    
    /// Reset settings to current values
    private func resetSettings() {
        // Reset to the current settings in the ResolumeConnector
        oscSettings = resolumeConnector.oscSettings
        hasChanges = false
        
        // Re-validate settings
        validateSettings()
    }
    
    /// Apply changes to settings
    private func applyChanges() {
        // Validate settings before applying
        let validationResult = oscSettings.validate()
        if !validationResult.isValid {
            showValidationMessage = true
            validationMessage = validationResult.error ?? "Unknown validation error"
            validationSuccess = false
            return
        }
        
        // Update the ResolumeConnector's settings
        resolumeConnector.updateSettings(newSettings: oscSettings)
        
        // Mark as saved
        hasChanges = false
        showValidationMessage = true
        validationMessage = "Settings applied successfully"
        validationSuccess = true
    }
    
    /// Validate the current settings
    private func validateSettings() {
        let validationResult = oscSettings.validate()
        showValidationMessage = true
        validationSuccess = validationResult.isValid
        
        if !validationResult.isValid {
            validationMessage = validationResult.error ?? "Unknown validation error"
        }
    }
}

/// Preview for the OSC connection settings view
struct OSCConnectionSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = Settings().oscSettings
        let resolumeConnector = ResolumeConnector(settings: settings)
        
        return OSCConnectionSettingsView(
            oscSettings: .constant(settings),
            resolumeConnector: resolumeConnector
        )
        .frame(width: 500, height: 600)
    }
}