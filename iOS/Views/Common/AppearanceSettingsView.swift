//
//  AppearanceSettingsView.swift
//  LED Messenger iOS
//
//  Created on April 19, 2025
//

import SwiftUI

/// View for iOS appearance customization settings
struct AppearanceSettingsView: View {
    // MARK: - Environment
    
    /// Environment for dismissal
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    /// Appearance manager
    @ObservedObject private var appearanceManager = AppearanceManager.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Theme settings
                Section {
                    Picker("Theme", selection: $appearanceManager.theme) {
                        ForEach(AppearanceTheme.allCases) { theme in
                            Label(theme.displayName, systemImage: theme.icon)
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Theme")
                } footer: {
                    Text("Choose how the app appears on your device.")
                }
                
                // Text size settings
                Section {
                    Picker("Text Size", selection: $appearanceManager.textSizeMultiplier) {
                        ForEach(TextSizeMultiplier.allCases) { size in
                            Text(size.displayName)
                                .tag(size)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    // Preview of current text size
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Headline Text")
                                .font(.headline)
                                .scaleEffect(appearanceManager.textSizeMultiplier.scaleFactor)
                            
                            Text("This is a sample of body text at the selected size.")
                                .font(.body)
                                .scaleEffect(appearanceManager.textSizeMultiplier.scaleFactor)
                            
                            Text("Caption text example")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .scaleEffect(appearanceManager.textSizeMultiplier.scaleFactor)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Text Size")
                } footer: {
                    Text("Adjust the size of text throughout the app.")
                }
                
                // Accessibility settings
                Section {
                    Toggle("High Contrast", isOn: $appearanceManager.highContrast)
                    
                    Toggle("Reduce Motion", isOn: $appearanceManager.reduceMotion)
                } header: {
                    Text("Accessibility")
                } footer: {
                    Text("Improve visibility and reduce motion in the app.")
                }
                
                // Color settings
                Section {
                    Toggle("Use Custom Accent Color", isOn: $appearanceManager.useCustomAccentColor)
                    
                    if appearanceManager.useCustomAccentColor {
                        ColorPicker("Accent Color", selection: $appearanceManager.customAccentColor)
                            .padding(.vertical, 4)
                        
                        // Preview
                        HStack(spacing: 8) {
                            Button("Button") {}
                                .buttonStyle(.bordered)
                                .accentColor(appearanceManager.customAccentColor)
                            
                            Toggle("Toggle", isOn: .constant(true))
                                .toggleStyle(.switch)
                                .accentColor(appearanceManager.customAccentColor)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Colors")
                } footer: {
                    Text("Customize the accent color used throughout the app.")
                }
                
                // Reset section
                Section {
                    Button("Reset to Defaults") {
                        appearanceManager.resetToDefaults()
                    }
                    .foregroundColor(.red)
                } footer: {
                    Text("Resets all appearance settings to their default values.")
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Preview provider for appearance settings
struct AppearanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSettingsView()
    }
}