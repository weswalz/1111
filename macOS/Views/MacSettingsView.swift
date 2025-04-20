//
//  MacSettingsView.swift
//  LED Messenger macOS
//
//  Created on April 17, 2025
//

import SwiftUI
import Combine

/// Settings view for the macOS application
struct MacSettingsView: View {
    // MARK: - Environment Objects
    
    /// Settings manager
    @EnvironmentObject var settingsManager: SettingsManager
    
    /// Resolume connector
    @EnvironmentObject var resolumeConnector: ResolumeConnector
    
    /// Appearance manager for customization
    @StateObject private var appearanceManager = AppearanceManager.shared
    
    // MARK: - State
    
    /// Local copy of settings for editing
    @State private var settings: Settings
    
    /// Currently selected tab
    @State private var selectedTab = 0
    
    /// Whether changes have been made
    @State private var hasChanges = false
    
    /// Whether discard changes alert is showing
    @State private var showingDiscardAlert = false
    
    /// Environment for dismissal
    @Environment(\.dismiss) var dismiss
    
    /// Subscription cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with settings manager
    init() {
        // Initialize with a copy of the current settings
        self._settings = State(initialValue: SettingsManager().settings)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Text("Settings")
                    .font(.headline)
                
                HStack {
                    // Cancel button
                    Button("Cancel") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    // Save button
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!hasChanges)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Settings tabs
            TabView(selection: $selectedTab) {
                // General tab
                generalSettingsView
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(0)
                
                // OSC tab
                oscSettingsView
                    .tabItem {
                        Label("OSC", systemImage: "network")
                    }
                    .tag(1)
                
                // Connections tab
                connectionsSettingsView
                    .tabItem {
                        Label("Connections", systemImage: "ipad.and.iphone")
                    }
                    .tag(2)
                
                // UI tab
                uiSettingsView
                    .tabItem {
                        Label("UI", systemImage: "paintbrush")
                    }
                    .tag(3)
                
                // Default message tab
                defaultMessageSettingsView
                    .tabItem {
                        Label("Default Format", systemImage: "textformat")
                    }
                    .tag(4)
                
                // About tab
                aboutView
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
                    .tag(5)
            }
            .padding()
        }
        .onAppear {
            // Load current settings
            settings = settingsManager.settings
        }
        .alert("Discard Changes", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            
            Button("Keep Editing", role: .cancel) {
                // Just dismiss the alert
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .frame(width: 600, height: 500)
    }
    
    // MARK: - General Settings View
    
    /// View for general application settings
    private var generalSettingsView: some View {
        Form {
            Section("Auto-Save") {
                Toggle("Auto-save messages", isOn: $settings.generalSettings.autoSave)
                    .onChange(of: settings.generalSettings.autoSave) { _ in
                        hasChanges = true
                    }
                
                if settings.generalSettings.autoSave {
                    HStack {
                        Text("Save interval")
                        Spacer()
                        Text("\(Int(settings.generalSettings.autoSaveInterval)) seconds")
                    }
                    
                    Slider(
                        value: $settings.generalSettings.autoSaveInterval,
                        in: 10...300,
                        step: 10
                    ) {
                        Text("Auto-save interval")
                    } minimumValueLabel: {
                        Text("10s")
                    } maximumValueLabel: {
                        Text("5m")
                    }
                    .onChange(of: settings.generalSettings.autoSaveInterval) { _ in
                        hasChanges = true
                    }
                }
            }
            
            Section("Message History") {
                HStack {
                    Text("History size")
                    Spacer()
                    Text("\(settings.generalSettings.historySize) messages")
                }
                
                Slider(
                    value: Binding(
                        get: { Double(settings.generalSettings.historySize) },
                        set: { settings.generalSettings.historySize = Int($0) }
                    ),
                    in: 10...500,
                    step: 10
                ) {
                    Text("History size")
                } minimumValueLabel: {
                    Text("10")
                } maximumValueLabel: {
                    Text("500")
                }
                .onChange(of: settings.generalSettings.historySize) { _ in
                    hasChanges = true
                }
            }
            
            Section("Confirmation") {
                Toggle("Confirm before sending", isOn: $settings.generalSettings.confirmBeforeSending)
                    .onChange(of: settings.generalSettings.confirmBeforeSending) { _ in
                        hasChanges = true
                    }
                
                Toggle("Confirm before deleting", isOn: $settings.generalSettings.confirmBeforeDeleting)
                    .onChange(of: settings.generalSettings.confirmBeforeDeleting) { _ in
                        hasChanges = true
                    }
            }
            
            Section("Queue Management") {
                Toggle("Keep sent messages in queue", isOn: $settings.generalSettings.keepSentMessages)
                    .onChange(of: settings.generalSettings.keepSentMessages) { _ in
                        hasChanges = true
                    }
                
                Toggle("Show message previews", isOn: $settings.generalSettings.showPreviews)
                    .onChange(of: settings.generalSettings.showPreviews) { _ in
                        hasChanges = true
                    }
            }
        }
    }
    
    // MARK: - OSC Settings View
    
    /// View for OSC connection settings
    private var oscSettingsView: some View {
        Form {
            Section("Connection") {
                TextField("IP Address", text: $settings.oscSettings.ipAddress)
                    .onChange(of: settings.oscSettings.ipAddress) { _ in
                        hasChanges = true
                    }
                
                HStack {
                    Text("Port")
                    Spacer()
                    TextField("Port", value: $settings.oscSettings.port, formatter: NumberFormatter())
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: settings.oscSettings.port) { _ in
                            hasChanges = true
                        }
                }
            }
            
            Section("Resolume Configuration") {
                HStack {
                    Text("Layer")
                    Spacer()
                    TextField("Layer", value: $settings.oscSettings.layer, formatter: NumberFormatter())
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: settings.oscSettings.layer) { _ in
                            hasChanges = true
                        }
                }
                
                HStack {
                    Text("Clip")
                    Spacer()
                    TextField("Clip", value: $settings.oscSettings.clip, formatter: NumberFormatter())
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: settings.oscSettings.clip) { _ in
                            hasChanges = true
                        }
                }
                
                HStack {
                    Text("Clear Clip")
                    Spacer()
                    TextField("Clear Clip", value: $settings.oscSettings.clearClip, formatter: NumberFormatter())
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: settings.oscSettings.clearClip) { _ in
                            hasChanges = true
                        }
                }
                
                HStack {
                    Text("Clip Rotation")
                    Spacer()
                    TextField("Clip Rotation", value: $settings.oscSettings.clipRotation, formatter: NumberFormatter())
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: settings.oscSettings.clipRotation) { _ in
                            hasChanges = true
                        }
                }
            }
            
            Section("Auto-Clear") {
                Toggle("Auto-clear messages", isOn: $settings.oscSettings.autoClear)
                    .onChange(of: settings.oscSettings.autoClear) { _ in
                        hasChanges = true
                    }
                
                if settings.oscSettings.autoClear {
                    HStack {
                        Text("Clear delay")
                        Spacer()
                        Text("\(String(format: "%.1f", settings.oscSettings.autoClearDelay)) seconds")
                    }
                    
                    Slider(
                        value: $settings.oscSettings.autoClearDelay,
                        in: 1...30,
                        step: 0.5
                    ) {
                        Text("Clear delay")
                    } minimumValueLabel: {
                        Text("1s")
                    } maximumValueLabel: {
                        Text("30s")
                    }
                    .onChange(of: settings.oscSettings.autoClearDelay) { _ in
                        hasChanges = true
                    }
                }
            }
            
            Section("Test") {
                Toggle("Show test pattern during setup", isOn: $settings.oscSettings.showTestPattern)
                    .onChange(of: settings.oscSettings.showTestPattern) { _ in
                        hasChanges = true
                    }
                
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(resolumeConnector.isSending)
            }
        }
    }
    
    // MARK: - Connections Settings View
    
    /// View for iPad connection settings
    private var connectionsSettingsView: some View {
        Form {
            Section("iPad Connections") {
                Toggle("Auto-start connection service", isOn: $settings.generalSettings.autoSave)
                    .onChange(of: settings.generalSettings.autoSave) { _ in
                        hasChanges = true
                    }
                
                Toggle("Auto-accept connection requests", isOn: $settings.generalSettings.autoSave)
                    .onChange(of: settings.generalSettings.autoSave) { _ in
                        hasChanges = true
                    }
                
                Toggle("Allow multiple connections", isOn: $settings.generalSettings.autoSave)
                    .onChange(of: settings.generalSettings.autoSave) { _ in
                        hasChanges = true
                    }
            }
            
            Section("Synchronization") {
                Toggle("Sync settings to iPads", isOn: $settings.generalSettings.autoSave)
                    .onChange(of: settings.generalSettings.autoSave) { _ in
                        hasChanges = true
                    }
                
                Toggle("Sync message queues to iPads", isOn: $settings.generalSettings.autoSave)
                    .onChange(of: settings.generalSettings.autoSave) { _ in
                        hasChanges = true
                    }
                
                Toggle("Allow iPads to send messages", isOn: $settings.generalSettings.autoSave)
                    .onChange(of: settings.generalSettings.autoSave) { _ in
                        hasChanges = true
                    }
                
                Toggle("Allow iPads to clear messages", isOn: $settings.generalSettings.autoSave)
                    .onChange(of: settings.generalSettings.autoSave) { _ in
                        hasChanges = true
                    }
            }
        }
    }
    
    // MARK: - UI Settings View
    
    /// View for UI settings
    private var uiSettingsView: some View {
        Form {
            // App theme settings
            Section("Theme") {
                Picker("Theme", selection: $settings.uiSettings.theme) {
                    ForEach(UISettings.AppTheme.allCases, id: \.self) { theme in
                        Label(theme.rawValue, systemImage: themeIcon(for: theme)).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: settings.uiSettings.theme) { _ in
                    hasChanges = true
                }
                
                // Also integrate with AppearanceManager
                Divider()
                
                Text("Advanced Appearance Settings")
                    .font(.headline)
                    .padding(.top, 10)
                
                Picker("App Appearance", selection: Binding(
                    get: { appearanceManager.theme },
                    set: { newValue in 
                        appearanceManager.theme = newValue
                    }
                )) {
                    ForEach(AppearanceTheme.allCases) { theme in
                        Label(theme.displayName, systemImage: theme.icon).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("High Contrast", isOn: Binding(
                    get: { appearanceManager.highContrast },
                    set: { newValue in
                        appearanceManager.highContrast = newValue
                    }
                ))
                
                Picker("Text Size", selection: Binding(
                    get: { appearanceManager.textSizeMultiplier },
                    set: { newValue in
                        appearanceManager.textSizeMultiplier = newValue
                    }
                )) {
                    ForEach(TextSizeMultiplier.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("Use Custom Accent Color", isOn: Binding(
                    get: { appearanceManager.useCustomAccentColor },
                    set: { newValue in
                        appearanceManager.useCustomAccentColor = newValue
                    }
                ))
                
                if appearanceManager.useCustomAccentColor {
                    ColorPicker("Accent Color", selection: Binding(
                        get: { appearanceManager.customAccentColor },
                        set: { newValue in
                            appearanceManager.customAccentColor = newValue
                        }
                    ))
                }
                
                Toggle("Reduce Motion", isOn: Binding(
                    get: { appearanceManager.reduceMotion },
                    set: { newValue in
                        appearanceManager.reduceMotion = newValue
                    }
                ))
                
                Button("Reset Appearance Settings") {
                    appearanceManager.resetToDefaults()
                }
                .buttonStyle(.borderless)
            }
            
            Section("Display") {
                Toggle("Compact mode", isOn: $settings.uiSettings.compactMode)
                    .onChange(of: settings.uiSettings.compactMode) { _ in
                        hasChanges = true
                    }
                
                Toggle("Show tooltips", isOn: $settings.uiSettings.showTooltips)
                    .onChange(of: settings.uiSettings.showTooltips) { _ in
                        hasChanges = true
                    }
            }
            
            Section("Sound") {
                Toggle("Sound effects", isOn: $settings.uiSettings.soundEffects)
                    .onChange(of: settings.uiSettings.soundEffects) { _ in
                        hasChanges = true
                    }
                
                if settings.uiSettings.soundEffects {
                    HStack {
                        Text("Volume")
                        Spacer()
                        Text("\(Int(settings.uiSettings.soundVolume * 100))%")
                    }
                    
                    Slider(
                        value: $settings.uiSettings.soundVolume,
                        in: 0...1,
                        step: 0.05
                    ) {
                        Text("Volume")
                    } minimumValueLabel: {
                        Image(systemName: "speaker")
                    } maximumValueLabel: {
                        Image(systemName: "speaker.wave.3")
                    }
                    .onChange(of: settings.uiSettings.soundVolume) { _ in
                        hasChanges = true
                    }
                }
            }
        }
    }
    
    /// Get the system image name for a theme
    /// - Parameter theme: The app theme
    /// - Returns: The system image name
    private func themeIcon(for theme: UISettings.AppTheme) -> String {
        switch theme {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        case .highContrast:
            return "eye"
        }
    }
    
    // MARK: - Default Message Settings View
    
    /// View for default message formatting settings
    private var defaultMessageSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Text alignment
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Alignment")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Picker("", selection: $settings.defaultMessageSettings.alignment) {
                        ForEach(MessageFormatting.TextAlignment.allCases, id: \.self) { alignment in
                            HStack {
                                Image(systemName: alignmentIcon(for: alignment))
                                Text(alignment.rawValue)
                            }
                            .tag(alignment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settings.defaultMessageSettings.alignment) { _ in
                        hasChanges = true
                    }
                }
                
                // Font size
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size")
                            .font(.headline)
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        Text("\(Int(settings.defaultMessageSettings.fontSize))")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Slider(
                        value: $settings.defaultMessageSettings.fontSize,
                        in: 12...120,
                        step: 2
                    ) {
                        Text("Font Size")
                    } minimumValueLabel: {
                        Text("12")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("120")
                            .font(.caption)
                    }
                    .onChange(of: settings.defaultMessageSettings.fontSize) { _ in
                        hasChanges = true
                    }
                }
                
                // Font weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Weight")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Picker("", selection: $settings.defaultMessageSettings.fontWeight) {
                        ForEach(MessageFormatting.FontWeight.allCases, id: \.self) { weight in
                            Text(weight.rawValue).tag(weight)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settings.defaultMessageSettings.fontWeight) { _ in
                        hasChanges = true
                    }
                }
                
                // Text color
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Text Color")
                            .font(.headline)
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        Text(settings.defaultMessageSettings.textColor.toHex())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .font(.caption)
                    }
                    
                    ColorPicker("", selection: Binding(
                        get: { settings.defaultMessageSettings.textColor.toColor() },
                        set: { color in
                            settings.defaultMessageSettings.textColor = MessageColor(
                                red: Double(color.cgColor?.components?[0] ?? 0),
                                green: Double(color.cgColor?.components?[1] ?? 0),
                                blue: Double(color.cgColor?.components?[2] ?? 0),
                                alpha: Double(color.cgColor?.components?[3] ?? 1)
                            )
                            hasChanges = true
                        }
                    ))
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
                
                // Background color
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Background Color")
                            .font(.headline)
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        Text(settings.defaultMessageSettings.backgroundColor.toHex())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .font(.caption)
                    }
                    
                    ColorPicker("", selection: Binding(
                        get: { settings.defaultMessageSettings.backgroundColor.toColor() },
                        set: { color in
                            settings.defaultMessageSettings.backgroundColor = MessageColor(
                                red: Double(color.cgColor?.components?[0] ?? 0),
                                green: Double(color.cgColor?.components?[1] ?? 0),
                                blue: Double(color.cgColor?.components?[2] ?? 0),
                                alpha: Double(color.cgColor?.components?[3] ?? 1)
                            )
                            hasChanges = true
                        }
                    ))
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
                
                // Animation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Animation")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Picker("", selection: $settings.defaultMessageSettings.animation) {
                        ForEach(MessageFormatting.MessageAnimation.allCases, id: \.self) { animation in
                            Text(animation.rawValue).tag(animation)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settings.defaultMessageSettings.animation) { _ in
                        hasChanges = true
                    }
                }
                
                // Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    ZStack {
                        // Background
                        Rectangle()
                            .fill(Color.black)
                        
                        // Preview text
                        Text("Sample Text")
                            .font(.system(size: settings.defaultMessageSettings.fontSize))
                            .fontWeight(fontWeight(from: settings.defaultMessageSettings.fontWeight))
                            .foregroundColor(settings.defaultMessageSettings.textColor.toColor())
                            .multilineTextAlignment(textAlignment(from: settings.defaultMessageSettings.alignment))
                            .padding()
                            .background(settings.defaultMessageSettings.backgroundColor.toColor())
                    }
                    .frame(height: 100)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    // MARK: - About View
    
    /// View for app information
    private var aboutView: some View {
        VStack(spacing: 20) {
            // App logo
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            
            // App name
            Text("LED Messenger")
                .font(.title)
                .fontWeight(.bold)
            
            // Version
            Text("Version \(AppConstants.App.fullVersion)")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Divider()
                .padding(.horizontal, 40)
            
            // Description
            Text("Professional text messaging for LED walls")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Copyright
            Text("© 2025. All rights reserved.")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    /// Save settings
    private func saveSettings() {
        settingsManager.updateSettings(settings)
        hasChanges = false
    }
    
    /// Test connection to Resolume
    private func testConnection() {
        // Use a temporary connector with the current settings
        let tempConnector = ResolumeConnector(settings: settings.oscSettings)
        
        // Connect and send test pattern
        tempConnector.connect { result in
            if case .success = result {
                tempConnector.sendTestPattern { _ in
                    // Disconnect after test
                    tempConnector.disconnect()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get the system image name for a text alignment
    /// - Parameter alignment: The text alignment
    /// - Returns: The system image name
    private func alignmentIcon(for alignment: MessageFormatting.TextAlignment) -> String {
        switch alignment {
        case .leading:
            return "text.alignleft"
        case .center:
            return "text.aligncenter"
        case .trailing:
            return "text.alignright"
        }
    }
    
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

/// Preview for the Mac settings view
struct MacSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MacSettingsView()
            .environmentObject(SettingsManager())
            .environmentObject(ResolumeConnector(settings: Settings().oscSettings))
    }
}
