//
//  SettingsManager.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation
import Combine

/// Manages application settings persistence and access
public class SettingsManager: ObservableObject {
    
    // MARK: - Properties
    
    /// The current application settings
    @Published public private(set) var settings: Settings
    
    /// UserDefaults key for storing settings
    private let settingsKey = "com.ledmessenger.settings"
    
    /// The UserDefaults instance to use for storage
    private let userDefaults: UserDefaults
    
    /// Auto-save publisher
    private var autoSavePublisher: AnyCancellable?
    
    // MARK: - Initialization
    
    /// Initialize with default settings
    public init() {
        self.userDefaults = UserDefaults.standard
        
        // Try to load settings from UserDefaults
        if let loadedSettings = Self.loadSettings(from: userDefaults) {
            self.settings = loadedSettings
            logInfo("Settings loaded from UserDefaults", category: .settings)
        } else {
            // Use default settings if none are stored
            self.settings = Settings()
            logInfo("Using default settings (none found in UserDefaults)", category: .settings)
        }
        
        // Set up auto-save when settings change
        setupAutoSave()
    }
    
    /// Initialize with custom UserDefaults
    /// - Parameter userDefaults: The UserDefaults instance to use
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        
        // Try to load settings from UserDefaults
        if let loadedSettings = Self.loadSettings(from: userDefaults) {
            self.settings = loadedSettings
            logInfo("Settings loaded from custom UserDefaults", category: .settings)
        } else {
            // Use default settings if none are stored
            self.settings = Settings()
            logInfo("Using default settings (none found in custom UserDefaults)", category: .settings)
        }
        
        // Set up auto-save when settings change
        setupAutoSave()
    }
    
    /// Initialize with specific settings
    /// - Parameter settings: The settings to use
    public init(settings: Settings) {
        self.userDefaults = UserDefaults.standard
        self.settings = settings
        
        // Set up auto-save when settings change
        setupAutoSave()
        
        logInfo("SettingsManager initialized with custom settings", category: .settings)
    }
    
    // MARK: - Settings Access Methods
    
    /// Update the entire settings object
    /// - Parameter newSettings: The new settings to use
    public func updateSettings(_ newSettings: Settings) {
        logInfo("Updating all settings", category: .settings)
        settings = newSettings
        saveSettings()
    }
    
    /// Update just the OSC settings
    /// - Parameter oscSettings: The new OSC settings to use
    public func updateOSCSettings(_ oscSettings: OSCSettings) {
        logInfo("Updating OSC settings", category: .settings)
        settings.oscSettings = oscSettings
        saveSettings()
    }
    
    /// Update just the general settings
    /// - Parameter generalSettings: The new general settings to use
    public func updateGeneralSettings(_ generalSettings: GeneralSettings) {
        logInfo("Updating general settings", category: .settings)
        settings.generalSettings = generalSettings
        saveSettings()
    }
    
    /// Update just the UI settings
    /// - Parameter uiSettings: The new UI settings to use
    public func updateUISettings(_ uiSettings: UISettings) {
        logInfo("Updating UI settings", category: .settings)
        settings.uiSettings = uiSettings
        saveSettings()
    }
    
    /// Update just the default message settings
    /// - Parameter defaultMessageSettings: The new default message settings to use
    public func updateDefaultMessageSettings(_ defaultMessageSettings: MessageFormatting) {
        logInfo("Updating default message settings", category: .settings)
        settings.defaultMessageSettings = defaultMessageSettings
        saveSettings()
    }
    
    /// Reset all settings to their default values
    public func resetToDefaults() {
        logInfo("Resetting all settings to defaults", category: .settings)
        settings = Settings()
        saveSettings()
    }
    
    // MARK: - Settings Persistence
    
    /// Save settings to UserDefaults
    public func saveSettings() {
        do {
            // Encode settings to JSON data
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            
            // Save to UserDefaults
            userDefaults.set(data, forKey: settingsKey)
            logInfo("Settings saved to UserDefaults", category: .settings)
        } catch {
            logError("Failed to save settings: \(error.localizedDescription)", category: .settings)
        }
    }
    
    /// Set up auto-save for settings changes
    private func setupAutoSave() {
        // Cancel any existing publisher
        autoSavePublisher?.cancel()
        
        // Create a new publisher that triggers on settings changes
        autoSavePublisher = $settings
            .debounce(for: .seconds(1), scheduler: RunLoop.main) // Debounce to avoid excessive saves
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Only auto-save if the feature is enabled
                if self.settings.generalSettings.autoSave {
                    self.saveSettings()
                }
            }
    }
    
    /// Load settings from UserDefaults
    /// - Parameter userDefaults: The UserDefaults instance to load from
    /// - Returns: The loaded settings, or nil if none were found
    private static func loadSettings(from userDefaults: UserDefaults) -> Settings? {
        // Get data from UserDefaults
        guard let data = userDefaults.data(forKey: "com.ledmessenger.settings") else {
            return nil
        }
        
        do {
            // Decode settings from JSON data
            let decoder = JSONDecoder()
            let settings = try decoder.decode(Settings.self, from: data)
            return settings
        } catch {
            logError("Failed to load settings: \(error.localizedDescription)", category: .settings)
            return nil
        }
    }
    
    // MARK: - Settings Export/Import
    
    /// Export settings to JSON data
    /// - Returns: The exported settings data, or nil if export failed
    public func exportSettings() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            logInfo("Settings exported successfully", category: .settings)
            return data
        } catch {
            logError("Failed to export settings: \(error.localizedDescription)", category: .settings)
            return nil
        }
    }
    
    /// Import settings from JSON data
    /// - Parameter data: The data to import
    /// - Returns: Whether the import was successful
    @discardableResult
    public func importSettings(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            let importedSettings = try decoder.decode(Settings.self, from: data)
            settings = importedSettings
            saveSettings()
            logInfo("Settings imported successfully", category: .settings)
            return true
        } catch {
            logError("Failed to import settings: \(error.localizedDescription)", category: .settings)
            return false
        }
    }
}
