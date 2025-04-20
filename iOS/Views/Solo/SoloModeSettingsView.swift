//
//  SoloModeSettingsView.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import SwiftUI

/// Settings view for Solo mode
struct SoloModeSettingsView: View {
    // MARK: - Environment
    
    /// Settings manager
    @EnvironmentObject var settingsManager: SettingsManager
    
    /// Resolume connector
    @EnvironmentObject var resolumeConnector: ResolumeConnector
    
    /// Environment for dismissing the sheet
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    
    /// Local copy of settings for editing
    @State private var settings: Settings
    
    /// Currently selected tab
    @State private var selectedTab = 0
    
    /// Whether changes have been made
    @State private var hasChanges = false
    
    /// Whether discard changes alert is showing
    @State private var showingDiscardAlert = false
    
    // MARK: - Initialization
    
    init() {
        // Initialize with a copy of the current settings
        self._settings = State(initialValue: SettingsManager().settings)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // General settings tab
                generalSettingsView
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(0)
                
                // OSC settings tab
                oscSettingsView
                    .tabItem {
                        Label("OSC", systemImage: "network")
                    }
                    .tag(1)
                
                // UI settings tab
                uiSettingsView
                    .tabItem {
                        Label("UI", systemImage: "paintbrush")
                    }
                    .tag(2)
                
                // Default message settings tab
                defaultMessageSettingsView
                    .tabItem {
                        Label("Default Format", systemImage: "textformat")
                    }
                    .tag(3)
                
                // About tab
                aboutView
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
                    .tag(4)
            }
            .onAppear {
                // Load current settings when view appears
                settings = settingsManager.settings
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                }
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
        }
    }
    
    // MARK: - General Settings View
    
    /// View for general application settings
    private var generalSettingsView: some View {
        Form {
            Section(header: Text("Auto-Save")) {
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
            
            Section(header: Text("Message History")) {
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
            
            Section(header: Text("Confirmation")) {
                Toggle("Confirm before sending", isOn: $settings.generalSettings.confirmBeforeSending)
                    .onChange(of: settings.generalSettings.confirmBeforeSending) { _ in
                        hasChanges = true
                    }
                
                Toggle("Confirm before deleting", isOn: $settings.generalSettings.confirmBeforeDeleting)
                    .onChange(of: settings.generalSettings.confirmBeforeDeleting) { _ in
                        hasChanges = true
                    }
            }
            
            Section(header: Text("Queue Management")) {
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
            Section(header: Text("Connection")) {
                TextField("IP Address", text: $settings.oscSettings.ipAddress)
                    .keyboardType(.decimalPad)
                    .onChange(of: settings.oscSettings.ipAddress) { _ in
                        hasChanges = true
                    }
                
                HStack {
                    Text("Port")
                    Spacer()
                    TextField("Port", value: $settings.oscSettings.port, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: settings.oscSettings.port) { _ in
                            hasChanges = true
                        }
                }
            }
            
            Section(header: Text("Resolume Configuration")) {
                HStack {
                    Text("Layer")
                    Spacer()
                    TextField("Layer", value: $settings.oscSettings.layer, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: settings.oscSettings.layer) { _ in
                            hasChanges = true
                        }
                }
                
                HStack {
                    Text("Clip")
                    Spacer()
                    TextField("Clip", value: $settings.oscSettings.clip, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: settings.oscSettings.clip) { _ in
                            hasChanges = true
                        }
                }
                
                HStack {
                    Text("Clear Clip")
                    Spacer()
                    TextField("Clear Clip", value: $settings.oscSettings.clearClip, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: settings.oscSettings.clearClip) { _ in
                            hasChanges = true
                        }
                }
                
                HStack {
                    Text("Clip Rotation")
                    Spacer()
                    TextField("Clip Rotation", value: $settings.oscSettings.clipRotation, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: settings.oscSettings.clipRotation) { _ in
                            hasChanges = true
                        }
                }
            }
            
            Section(header: Text("Auto-Clear")) {
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
            
            Section(header: Text("Test")) {
                Toggle("Show test pattern during setup", isOn: $settings.oscSettings.showTestPattern)
                    .onChange(of: settings.oscSettings.showTestPattern) { _ in
                        hasChanges = true
                    }
                
                Button(action: {
                    // Test connection with current settings
                    let currentSettings = settingsManager.settings.oscSettings
                    
                    // Create temporary connector with edited settings
                    let tempConnector = ResolumeConnector(settings: settings.oscSettings)
                    tempConnector.connect { result in
                        if case .success = result {
                            tempConnector.sendTestPattern { _ in
                                // Disconnect after test
                                tempConnector.disconnect()
                            }
                        }
                    }
                }) {
                    Text("Test Connection")
                        .frame(maxWidth: .infinity)
                }
                .disabled(resolumeConnector.isSending)
            }
        }
    }
    
    // MARK: - UI Settings View
    
    /// View for UI settings
    private var uiSettingsView: some View {
        Form {
            Section(header: Text("Theme")) {
                Picker("Theme", selection: $settings.uiSettings.theme) {
                    ForEach(UISettings.AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: settings.uiSettings.theme) { _ in
                    hasChanges = true
                }
            }
            
            Section(header: Text("Display")) {
                Toggle("Compact mode", isOn: $settings.uiSettings.compactMode)
                    .onChange(of: settings.uiSettings.compactMode) { _ in
                        hasChanges = true
                    }
                
                Toggle("Show tooltips", isOn: $settings.uiSettings.showTooltips)
                    .onChange(of: settings.uiSettings.showTooltips) { _ in
                        hasChanges = true
                    }
            }
            
            Section(header: Text("Sound")) {
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
                        Image(systemName: "speaker.fill")
                    } maximumValueLabel: {
                        Image(systemName: "speaker.wave.3.fill")
                    }
                    .onChange(of: settings.uiSettings.soundVolume) { _ in
                        hasChanges = true
                    }
                }
            }
        }
    }
    
    // MARK: - Default Message Settings View
    
    /// View for default message formatting settings
    private var defaultMessageSettingsView: some View {
        Form {
            Section(header: Text("Text")) {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Text("\(Int(settings.defaultMessageSettings.fontSize))")
                }
                
                Slider(
                    value: $settings.defaultMessageSettings.fontSize,
                    in: 12...120,
                    step: 2
                ) {
                    Text("Font Size")
                } minimumValueLabel: {
                    Text("12")
                } maximumValueLabel: {
                    Text("120")
                }
                .onChange(of: settings.defaultMessageSettings.fontSize) { _ in
                    hasChanges = true
                }
                
                Picker("Font Weight", selection: $settings.defaultMessageSettings.fontWeight) {
                    ForEach(MessageFormatting.FontWeight.allCases, id: \.self) { weight in
                        Text(weight.rawValue).tag(weight)
                    }
                }
                .onChange(of: settings.defaultMessageSettings.fontWeight) { _ in
                    hasChanges = true
                }
                
                Picker("Alignment", selection: $settings.defaultMessageSettings.alignment) {
                    ForEach(MessageFormatting.TextAlignment.allCases, id: \.self) { alignment in
                        Text(alignment.rawValue).tag(alignment)
                    }
                }
                .onChange(of: settings.defaultMessageSettings.alignment) { _ in
                    hasChanges = true
                }
            }
            
            Section(header: Text("Colors")) {
                NavigationLink {
                    // Text color picker view
                    ColorSettingsView(
                        color: $settings.defaultMessageSettings.textColor,
                        title: "Text Color"
                    )
                    .onChange(of: settings.defaultMessageSettings.textColor) { _ in
                        hasChanges = true
                    }
                } label: {
                    HStack {
                        Text("Text Color")
                        Spacer()
                        Circle()
                            .fill(settings.defaultMessageSettings.textColor.toColor())
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                    }
                }
                
                NavigationLink {
                    // Background color picker view
                    ColorSettingsView(
                        color: $settings.defaultMessageSettings.backgroundColor,
                        title: "Background Color"
                    )
                    .onChange(of: settings.defaultMessageSettings.backgroundColor) { _ in
                        hasChanges = true
                    }
                } label: {
                    HStack {
                        Text("Background Color")
                        Spacer()
                        Circle()
                            .fill(settings.defaultMessageSettings.backgroundColor.toColor())
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                    }
                }
            }
            
            Section(header: Text("Animation")) {
                Picker("Animation", selection: $settings.defaultMessageSettings.animation) {
                    ForEach(MessageFormatting.MessageAnimation.allCases, id: \.self) { animation in
                        Text(animation.rawValue).tag(animation)
                    }
                }
                .onChange(of: settings.defaultMessageSettings.animation) { _ in
                    hasChanges = true
                }
            }
            
            // Preview of the default formatting
            Section(header: Text("Preview")) {
                ZStack {
                    Color.black
                        .frame(height: 100)
                    
                    Text("Preview Text")
                        .font(.system(size: settings.defaultMessageSettings.fontSize))
                        .fontWeight(fontWeight(from: settings.defaultMessageSettings.fontWeight))
                        .foregroundColor(settings.defaultMessageSettings.textColor.toColor())
                        .multilineTextAlignment(textAlignment(from: settings.defaultMessageSettings.alignment))
                        .padding()
                        .background(settings.defaultMessageSettings.backgroundColor.toColor())
                }
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - About View
    
    /// View for app information
    private var aboutView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            
            Text("LED Messenger")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version \(AppConstants.App.fullVersion)")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Divider()
                .padding(.horizontal, 40)
            
            Text("Professional text messaging for LED walls")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Text("© 2025. All rights reserved.")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    /// Save the settings
    private func saveSettings() {
        settingsManager.updateSettings(settings)
        hasChanges = false
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

/// View for color settings
struct ColorSettingsView: View {
    /// The color being edited
    @Binding var color: MessageColor
    
    /// Title for the view
    let title: String
    
    /// RGB components
    @State private var red: Double
    @State private var green: Double
    @State private var blue: Double
    @State private var alpha: Double
    
    /// Hex code
    @State private var hexCode: String = ""
    
    /// Initialize with the color binding
    init(color: Binding<MessageColor>, title: String) {
        self._color = color
        self.title = title
        self._red = State(initialValue: color.wrappedValue.red)
        self._green = State(initialValue: color.wrappedValue.green)
        self._blue = State(initialValue: color.wrappedValue.blue)
        self._alpha = State(initialValue: color.wrappedValue.alpha)
        
        // Initialize hex code
        let r = Int(color.wrappedValue.red * 255) & 0xFF
        let g = Int(color.wrappedValue.green * 255) & 0xFF
        let b = Int(color.wrappedValue.blue * 255) & 0xFF
        self._hexCode = State(initialValue: String(format: "#%02X%02X%02X", r, g, b))
    }
    
    var body: some View {
        VStack {
            // Color preview
            ZStack {
                // Checkboard pattern for transparent colors
                CheckerboardPattern()
                    .frame(height: 100)
                    .overlay(
                        Rectangle()
                            .fill(Color(
                                red: red,
                                green: green,
                                blue: blue,
                                opacity: alpha
                            ))
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 0.5)
                    )
                    .padding()
            }
            
            Form {
                // RGB sliders
                Section(header: Text("RGB Components")) {
                    colorSlider(value: $red, color: .red, label: "Red")
                    colorSlider(value: $green, color: .green, label: "Green")
                    colorSlider(value: $blue, color: .blue, label: "Blue")
                    colorSlider(value: $alpha, color: .gray, label: "Alpha")
                }
                
                // Hex code input
                Section(header: Text("Hex Color")) {
                    HStack {
                        TextField("Hex Code", text: $hexCode)
                            .onChange(of: hexCode) { newValue in
                                if newValue.hasPrefix("#") && newValue.count == 7 {
                                    if let color = MessageColor(hex: newValue) {
                                        red = color.red
                                        green = color.green
                                        blue = color.blue
                                        // Alpha is not updated from hex
                                        updateColorFromComponents()
                                    }
                                }
                            }
                        
                        Button(action: {
                            updateHexFromRGB()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
                
                // Preset colors
                Section(header: Text("Presets")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(presetColors, id: \.self) { presetColor in
                            Button(action: {
                                setColor(presetColor)
                            }) {
                                Circle()
                                    .fill(Color(
                                        red: presetColor.red,
                                        green: presetColor.green,
                                        blue: presetColor.blue
                                    ))
                                    .frame(height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(radius: 1)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .onAppear {
            // Ensure hex code is correct when view appears
            updateHexFromRGB()
        }
        .onChange(of: red) { _ in updateColorFromComponents() }
        .onChange(of: green) { _ in updateColorFromComponents() }
        .onChange(of: blue) { _ in updateColorFromComponents() }
        .onChange(of: alpha) { _ in updateColorFromComponents() }
    }
    
    /// Color slider component
    private func colorSlider(value: Binding<Double>, color: Color, label: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue * 255))")
            }
            
            Slider(value: value, in: 0...1) {
                Text(label)
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("255")
            }
            .accentColor(color)
        }
    }
    
    /// Update the color from RGB components
    private func updateColorFromComponents() {
        color = MessageColor(red: red, green: green, blue: blue, alpha: alpha)
        updateHexFromRGB()
    }
    
    /// Update the hex code from RGB values
    private func updateHexFromRGB() {
        let r = Int(red * 255) & 0xFF
        let g = Int(green * 255) & 0xFF
        let b = Int(blue * 255) & 0xFF
        hexCode = String(format: "#%02X%02X%02X", r, g, b)
    }
    
    /// Set the color from a MessageColor
    private func setColor(_ messageColor: MessageColor) {
        red = messageColor.red
        green = messageColor.green
        blue = messageColor.blue
        // Don't change alpha when using presets
        updateColorFromComponents()
    }
    
    /// Preset colors for quick selection
    private var presetColors: [MessageColor] {
        [
            MessageColor(red: 1, green: 1, blue: 1), // White
            MessageColor(red: 0, green: 0, blue: 0), // Black
            MessageColor(red: 0.9, green: 0.9, blue: 0.9), // Light Gray
            MessageColor(red: 0.5, green: 0.5, blue: 0.5), // Gray
            MessageColor(red: 0.2, green: 0.2, blue: 0.2), // Dark Gray
            MessageColor(red: 1, green: 0, blue: 0), // Red
            MessageColor(red: 0, green: 1, blue: 0), // Green
            MessageColor(red: 0, green: 0, blue: 1), // Blue
            MessageColor(red: 1, green: 1, blue: 0), // Yellow
            MessageColor(red: 1, green: 0, blue: 1), // Magenta
            MessageColor(red: 0, green: 1, blue: 1), // Cyan
            MessageColor(red: 1, green: 0.5, blue: 0), // Orange
            MessageColor(red: 0.5, green: 0, blue: 0.5), // Purple
            MessageColor(red: 0, green: 0.5, blue: 0), // Dark Green
            MessageColor(red: 0, green: 0, blue: 0.5), // Navy
            MessageColor(red: 0.5, green: 0.25, blue: 0), // Brown
            MessageColor(red: 1, green: 0.75, blue: 0.8), // Pink
            MessageColor(red: 0.8, green: 0.9, blue: 1), // Light Blue
        ]
    }
}

struct SoloModeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SoloModeSettingsView()
            .environmentObject(SettingsManager())
            .environmentObject(ResolumeConnector(settings: Settings().oscSettings))
    }
}
