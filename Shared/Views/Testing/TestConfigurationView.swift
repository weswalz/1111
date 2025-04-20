//
//  TestConfigurationView.swift
//  LED Messenger
//
//  Created on April 19, 2025
//

#if DEBUG

import SwiftUI

/// Configuration view for testing tools
public struct TestConfigurationView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            List {
                Section("Testing Tools") {
                    // OSC Tester
                    NavigationLink(destination: OSCTesterView()) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(AppTheme.Colors.primary)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("OSC Tester")
                                    .font(.headline)
                                
                                Text("Test OSC connectivity and messages")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                    
                    // System Information
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(AppTheme.Colors.primary)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("System Information")
                                    .font(.headline)
                                
                                Text("View detailed system and app information")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                }
                
                Section("Documentation") {
                    // Documentation Button
                    Button(action: {
                        openDocumentation()
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(AppTheme.Colors.primary)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("View Documentation")
                                    .font(.headline)
                                
                                Text("Open detailed OSC protocol documentation")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                }
                
                Section("Developer Options") {
                    // Log Bundle
                    Button(action: {
                        createLogBundle()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(AppTheme.Colors.primary)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Export Log Bundle")
                                    .font(.headline)
                                
                                Text("Create and share diagnostic information")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                    
                    // Reset App
                    Button(action: {
                        confirmResetApp()
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Reset Application")
                                    .font(.headline)
                                
                                Text("Reset all settings and data")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Testing & Configuration")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
    
    // MARK: - Actions
    
    /// Open the OSC protocol documentation
    private func openDocumentation() {
        // Implementation would use URL to open documentation
        logInfo("Opening documentation", category: .app)
    }
    
    /// Create and share a log bundle for diagnostics
    private func createLogBundle() {
        logInfo("Creating log bundle", category: .app)
        // Implementation would gather logs and present share sheet
    }
    
    /// Show confirmation for resetting the app
    private func confirmResetApp() {
        logInfo("Reset app requested", category: .app)
        // Implementation would show an alert and handle reset
    }
}

// MARK: - Preview

struct TestConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        TestConfigurationView()
    }
}

#endif