//
//  Settings.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation

/// Represents the application settings for LED Messenger
public struct Settings: Codable, Equatable {
    
    // MARK: - Properties
    
    /// OSC connection settings
    public var oscSettings: OSCSettings
    
    /// General application settings
    public var generalSettings: GeneralSettings
    
    /// UI settings
    public var uiSettings: UISettings
    
    /// Default message settings used for new messages
    public var defaultMessageSettings: MessageFormatting
    
    // MARK: - Initialization
    
    /// Create settings with default values
    public init() {
        self.oscSettings = OSCSettings()
        self.generalSettings = GeneralSettings()
        self.uiSettings = UISettings()
        self.defaultMessageSettings = MessageFormatting()
    }
    
    /// Create custom settings
    /// - Parameters:
    ///   - oscSettings: OSC connection settings
    ///   - generalSettings: General application settings
    ///   - uiSettings: UI settings
    ///   - defaultMessageSettings: Default message formatting
    public init(
        oscSettings: OSCSettings,
        generalSettings: GeneralSettings,
        uiSettings: UISettings,
        defaultMessageSettings: MessageFormatting
    ) {
        self.oscSettings = oscSettings
        self.generalSettings = generalSettings
        self.uiSettings = uiSettings
        self.defaultMessageSettings = defaultMessageSettings
    }
}

/// Settings for OSC communication
public struct OSCSettings: Codable, Equatable {
    
    // MARK: - Properties
    
    /// The IP address of the Resolume machine
    public var ipAddress: String
    
    /// The port number for OSC communication
    public var port: Int
    
    /// The layer to send messages to in Resolume
    public var layer: Int
    
    /// The clip index for showing messages
    public var clip: Int
    
    /// The clip index for clearing messages
    public var clearClip: Int
    
    /// The number of rotating clips (for smooth transitions)
    public var clipRotation: Int
    
    /// Whether to automatically clear messages after sending
    public var autoClear: Bool
    
    /// Delay (in seconds) before auto-clearing
    public var autoClearDelay: Double
    
    /// Whether to show a test pattern during setup
    public var showTestPattern: Bool
    
    // MARK: - Initialization
    
    /// Create OSC settings with default values
    public init() {
        self.ipAddress = "127.0.0.1"
        self.port = 2269
        self.layer = 1
        self.clip = 1
        self.clearClip = 2
        self.clipRotation = 3
        self.autoClear = false
        self.autoClearDelay = 5.0
        self.showTestPattern = false
    }
    
    /// Create custom OSC settings
    /// - Parameters:
    ///   - ipAddress: The IP address of the Resolume machine
    ///   - port: The port number for OSC communication
    ///   - layer: The layer to send messages to in Resolume
    ///   - clip: The clip index for showing messages
    ///   - clearClip: The clip index for clearing messages
    ///   - clipRotation: The number of rotating clips
    ///   - autoClear: Whether to automatically clear messages
    ///   - autoClearDelay: Delay before auto-clearing
    ///   - showTestPattern: Whether to show a test pattern
    public init(
        ipAddress: String,
        port: Int,
        layer: Int,
        clip: Int,
        clearClip: Int,
        clipRotation: Int,
        autoClear: Bool,
        autoClearDelay: Double,
        showTestPattern: Bool
    ) {
        self.ipAddress = ipAddress
        self.port = port
        self.layer = layer
        self.clip = clip
        self.clearClip = clearClip
        self.clipRotation = clipRotation
        self.autoClear = autoClear
        self.autoClearDelay = autoClearDelay
        self.showTestPattern = showTestPattern
    }
    
    // MARK: - Methods
    
    /// Validate the settings for correctness
    /// - Returns: A tuple with a boolean indicating validity and an optional error message
    public func validate() -> (isValid: Bool, error: String?) {
        // Validate IP address format
        let ipRegex = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        if ipAddress.range(of: ipRegex, options: .regularExpression) == nil {
            return (false, "Invalid IP address format")
        }
        
        // Validate port range
        if port < 1 || port > 65535 {
            return (false, "Port must be between 1 and 65535")
        }
        
        // Validate layer, clip, and clearClip values
        if layer < 1 {
            return (false, "Layer must be 1 or greater")
        }
        
        if clip < 1 {
            return (false, "Clip must be 1 or greater")
        }
        
        if clearClip < 1 {
            return (false, "Clear clip must be 1 or greater")
        }
        
        // Validate clip rotation
        if clipRotation < 2 {
            return (false, "Clip rotation must be at least 2")
        }
        
        // Validate that clip and clearClip are not the same
        if clip == clearClip {
            return (false, "Clip and clear clip must be different")
        }
        
        // Validate autoClearDelay
        if autoClear && autoClearDelay <= 0 {
            return (false, "Auto-clear delay must be greater than 0")
        }
        
        return (true, nil)
    }
}

/// General application settings
public struct GeneralSettings: Codable, Equatable {
    
    // MARK: - Properties
    
    /// Whether to automatically save messages
    public var autoSave: Bool
    
    /// Interval (in seconds) for auto-saving
    public var autoSaveInterval: Double
    
    /// Number of message history entries to keep
    public var historySize: Int
    
    /// Whether to confirm before sending messages
    public var confirmBeforeSending: Bool
    
    /// Whether to keep sent messages in the queue
    public var keepSentMessages: Bool
    
    /// Whether to confirm before deleting messages
    public var confirmBeforeDeleting: Bool
    
    /// Whether to show message previews
    public var showPreviews: Bool
    
    // MARK: - Initialization
    
    /// Create general settings with default values
    public init() {
        self.autoSave = true
        self.autoSaveInterval = 60.0 // 1 minute
        self.historySize = 100
        self.confirmBeforeSending = false
        self.keepSentMessages = true
        self.confirmBeforeDeleting = true
        self.showPreviews = true
    }
    
    /// Create custom general settings
    /// - Parameters:
    ///   - autoSave: Whether to automatically save messages
    ///   - autoSaveInterval: Interval for auto-saving
    ///   - historySize: Number of message history entries to keep
    ///   - confirmBeforeSending: Whether to confirm before sending
    ///   - keepSentMessages: Whether to keep sent messages
    ///   - confirmBeforeDeleting: Whether to confirm before deleting
    ///   - showPreviews: Whether to show message previews
    public init(
        autoSave: Bool,
        autoSaveInterval: Double,
        historySize: Int,
        confirmBeforeSending: Bool,
        keepSentMessages: Bool,
        confirmBeforeDeleting: Bool,
        showPreviews: Bool
    ) {
        self.autoSave = autoSave
        self.autoSaveInterval = autoSaveInterval
        self.historySize = historySize
        self.confirmBeforeSending = confirmBeforeSending
        self.keepSentMessages = keepSentMessages
        self.confirmBeforeDeleting = confirmBeforeDeleting
        self.showPreviews = showPreviews
    }
}

/// User interface settings
public struct UISettings: Codable, Equatable {
    
    // MARK: - Properties
    
    /// The application theme
    public var theme: AppTheme
    
    /// Whether to use compact mode for smaller screens
    public var compactMode: Bool
    
    /// Whether to show tooltips
    public var showTooltips: Bool
    
    /// Whether to enable sound effects
    public var soundEffects: Bool
    
    /// Sound effect volume (0-1)
    public var soundVolume: Double
    
    // MARK: - Nested Types
    
    /// Application theme options
    public enum AppTheme: String, Codable, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        case highContrast = "High Contrast"
    }
    
    // MARK: - Initialization
    
    /// Create UI settings with default values
    public init() {
        self.theme = .system
        self.compactMode = false
        self.showTooltips = true
        self.soundEffects = true
        self.soundVolume = 0.5
    }
    
    /// Create custom UI settings
    /// - Parameters:
    ///   - theme: The application theme
    ///   - compactMode: Whether to use compact mode
    ///   - showTooltips: Whether to show tooltips
    ///   - soundEffects: Whether to enable sound effects
    ///   - soundVolume: Sound effect volume
    public init(
        theme: AppTheme,
        compactMode: Bool,
        showTooltips: Bool,
        soundEffects: Bool,
        soundVolume: Double
    ) {
        self.theme = theme
        self.compactMode = compactMode
        self.showTooltips = showTooltips
        self.soundEffects = soundEffects
        self.soundVolume = soundVolume
    }
}

// MARK: - Extensions

extension Settings {
    /// Create a default settings object
    public static var `default`: Settings {
        Settings()
    }
}
