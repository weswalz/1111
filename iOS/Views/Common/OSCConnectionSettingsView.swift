//
//  OSCConnectionSettingsView.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import SwiftUI
import Combine

/// View for OSC connection settings and testing
struct OSCConnectionSettingsView: View {
    // MARK: - Properties
    
    /// The OSC settings being edited
    @Binding var oscSettings: OSCSettings
    
    /// The Resolume connector
    @ObservedObject var resolumeConnector: ResolumeConnector
    
    /// Environment for dismissing the sheet
    @Environment(\.dismiss) var dismiss
    
    /// Test connection state
    @State private var isTestingConnection = false
    
    /// Test result message
    @State private var testResultMessage: String?
    
    /// Test result success state
    @State private var testResultSuccess = false
    
    /// Test message for connection test
    @State private var testMessage = "Test Connection"
    
    /// Connection test task for cancellation
    @State private var connectionTestTask: Task<Void, Never>?
    
    /// Subscription cancellable
    @State private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Connection settings
                Section(header: Text("Connection")) {
                    TextField("IP Address", text: $oscSettings.ipAddress)
                        .keyboardType(.decimalPad)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("Port", value: $oscSettings.port, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    connectionStatusView
                }
                
                // Resolume configuration
                Section(header: Text("Resolume Configuration")) {
                    HStack {
                        Text("Layer")
                        Spacer()
                        TextField("Layer", value: $oscSettings.layer, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Clip")
                        Spacer()
                        TextField("Clip", value: $oscSettings.clip, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Clear Clip")
                        Spacer()
                        TextField("Clear Clip", value: $oscSettings.clearClip, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Clip Rotation")
                        Text("(for smooth transitions)")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Spacer()
                        TextField("Rotation", value: $oscSettings.clipRotation, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                // Auto-clear settings
                Section(header: Text("Auto-Clear")) {
                    Toggle("Auto-clear messages", isOn: $oscSettings.autoClear)
                    
                    if oscSettings.autoClear {
                        HStack {
                            Text("Clear delay")
                            Spacer()
                            Text("\(String(format: "%.1f", oscSettings.autoClearDelay)) seconds")
                        }
                        
                        Slider(
                            value: $oscSettings.autoClearDelay,
                            in: 1...30,
                            step: 0.5
                        ) {
                            Text("Clear delay")
                        } minimumValueLabel: {
                            Text("1s")
                        } maximumValueLabel: {
                            Text("30s")
                        }
                    }
                }
                
                // Test connection
                Section {
                    TextField("Test Message", text: $testMessage)
                    
                    Button(action: testConnection) {
                        HStack {
                            Text(isTestingConnection ? "Testing..." : "Test Connection")
                            
                            if isTestingConnection {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(isTestingConnection)
                    
                    if let resultMessage = testResultMessage {
                        HStack {
                            Image(systemName: testResultSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(testResultSuccess ? AppTheme.Colors.success : AppTheme.Colors.error)
                            
                            Text(resultMessage)
                                .foregroundColor(testResultSuccess ? AppTheme.Colors.success : AppTheme.Colors.error)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Test")
                } footer: {
                    Text("Use this to verify your connection to Resolume. The test message will appear on your LED wall when successful.")
                }
                
                // Validation status
                Section {
                    // Display validation issues if any
                    let validationResult = oscSettings.validate()
                    if !validationResult.isValid, let error = validationResult.error {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppTheme.Colors.warning)
                                
                                Text("Invalid Configuration")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.Colors.warning)
                            }
                            
                            // Detailed validation error
                            Text(error)
                                .foregroundColor(AppTheme.Colors.warning)
                                .font(.subheadline)
                            
                            // Validation tips based on error
                            if error.contains("IP address") {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("IP Address Tips:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Text("• Use format 192.168.1.100")
                                    Text("• Check Resolume's network settings")
                                    Text("• Ensure both devices are on the same network")
                                }
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.top, 4)
                            } else if error.contains("port") {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Port Tips:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Text("• Default Resolume OSC port is 7000")
                                    Text("• Port must be between 1024 and 65535")
                                    Text("• Check Resolume's OSC settings")
                                }
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.top, 4)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.Colors.success)
                                
                                Text("Configuration is valid")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.Colors.success)
                            }
                            
                            Text("All settings are correctly formatted. Use the Test Connection button to verify communication with Resolume.")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.top, 2)
                        }
                    }
                } header: {
                    Text("Validation")
                } footer: {
                    Text("The connection test will verify that LED Messenger can successfully communicate with Resolume Arena.")
                }
            }
            .navigationTitle("OSC Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                }
            }
            .onAppear {
                // Validate settings on appear
                validateSettings()
            }
            .onDisappear {
                // Cancel any ongoing test
                connectionTestTask?.cancel()
                connectionTestTask = nil
            }
        }
    }
    
    // MARK: - Connection Status View
    
    /// View showing the current connection status
    private var connectionStatusView: some View {
        HStack {
            Text("Status:")
            
            Spacer()
            
            HStack {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 10, height: 10)
                
                Text(connectionStatusText)
                    .foregroundColor(connectionStatusColor)
            }
            
            Button(action: toggleConnection) {
                Text(resolumeConnector.connectionState == .connected ? "Disconnect" : "Connect")
                    .foregroundColor(
                        resolumeConnector.connectionState == .connected ? 
                        AppTheme.Colors.error : AppTheme.Colors.primary
                    )
                    .fontWeight(.medium)
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(isTestingConnection)
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
    
    // MARK: - Actions
    
    /// Save the settings and update the connector
    private func saveSettings() {
        // Update the connector with the new settings
        resolumeConnector.updateSettings(newSettings: oscSettings)
        
        // Dismiss the view
        dismiss()
    }
    
    /// Toggle the connection state
    private func toggleConnection() {
        switch resolumeConnector.connectionState {
        case .connected:
            resolumeConnector.disconnect()
        case .disconnected:
            // Update settings first
            resolumeConnector.updateSettings(newSettings: oscSettings)
            // Then connect
            resolumeConnector.connect { _ in
                // Connection state is handled by binding to connectionState
            }
        default:
            // Do nothing if connecting or failed
            break
        }
    }
    
    /// Test the connection by sending a test message
    private func testConnection() {
        // Check if settings are valid
        let validationResult = oscSettings.validate()
        guard validationResult.isValid else {
            testResultMessage = "Invalid settings: \(validationResult.error ?? "Unknown error")"
            testResultSuccess = false
            return
        }
        
        // Set testing state
        isTestingConnection = true
        testResultMessage = nil
        
        // Create a temporary connector with the current settings
        let tempConnector = ResolumeConnector(settings: oscSettings)
        
        // Cancel any existing task
        connectionTestTask?.cancel()
        
        // Start a new test task
        connectionTestTask = Task {
            // Connect to Resolume
            var connectionSuccess = false
            
            // Create a continuation to wait for the connection result
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                tempConnector.connect { result in
                    switch result {
                    case .success:
                        connectionSuccess = true
                    case .failure(let error):
                        // Update the test result on the main thread
                        DispatchQueue.main.async {
                            self.testResultMessage = "Connection failed: \(error.localizedDescription)"
                            self.testResultSuccess = false
                            self.isTestingConnection = false
                        }
                    }
                    continuation.resume()
                }
            }
            
            // If connection was successful, send the test message
            if connectionSuccess {
                let message = Message(
                    text: testMessage.isEmpty ? "Test Connection" : testMessage
                )
                
                // Wait for the message to be sent
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    tempConnector.sendMessage(message) { result in
                        switch result {
                        case .success:
                            // Update the test result on the main thread
                            DispatchQueue.main.async {
                                self.testResultMessage = "Test successful! Check your LED wall."
                                self.testResultSuccess = true
                            }
                        case .failure(let error):
                            // Update the test result on the main thread
                            DispatchQueue.main.async {
                                self.testResultMessage = "Failed to send message: \(error.localizedDescription)"
                                self.testResultSuccess = false
                            }
                        }
                        continuation.resume()
                    }
                }
                
                // Disconnect after the test
                tempConnector.disconnect()
            }
            
            // Reset testing state
            DispatchQueue.main.async {
                self.isTestingConnection = false
            }
        }
    }
}

struct OSCConnectionSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = Settings()
        
        return OSCConnectionSettingsView(
            oscSettings: .constant(settings.oscSettings),
            resolumeConnector: ResolumeConnector(settings: settings.oscSettings)
        )
    }
}
