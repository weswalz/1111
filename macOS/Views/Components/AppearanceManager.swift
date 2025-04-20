//
//  AppearanceManager.swift
//  LED Messenger macOS
//
//  Created on April 19, 2025
//

import SwiftUI
import Combine

/// Available appearance themes for the app
enum AppearanceTheme: String, CaseIterable, Identifiable {
    /// System default theme
    case system = "System"
    
    /// Light theme
    case light = "Light"
    
    /// Dark theme
    case dark = "Dark"
    
    /// High contrast theme
    case highContrast = "High Contrast"
    
    /// The unique identifier
    var id: String { rawValue }
    
    /// User-friendly display name
    var displayName: String { rawValue }
    
    /// Icon for the theme
    var icon: String {
        switch self {
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
}

/// Available text size multipliers
enum TextSizeMultiplier: CGFloat, CaseIterable, Identifiable {
    /// Default text size
    case standard = 1.0
    
    /// Large text size
    case large = 1.2
    
    /// Extra large text size
    case extraLarge = 1.4
    
    /// Accessibility text size
    case accessibility = 1.6
    
    /// The unique identifier
    var id: CGFloat { rawValue }
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .large:
            return "Large"
        case .extraLarge:
            return "Extra Large"
        case .accessibility:
            return "Accessibility"
        }
    }
}

/// Manages app-wide appearance settings
class AppearanceManager: ObservableObject {
    /// Shared instance
    static let shared = AppearanceManager()
    
    /// Current appearance theme
    @Published var theme: AppearanceTheme = .system {
        didSet {
            updateInterfaceStyle()
            saveToUserDefaults()
        }
    }
    
    /// High contrast mode
    @Published var highContrast: Bool = false {
        didSet {
            saveToUserDefaults()
        }
    }
    
    /// Text size multiplier
    @Published var textSizeMultiplier: TextSizeMultiplier = .standard {
        didSet {
            saveToUserDefaults()
        }
    }
    
    /// Whether to use a custom accent color
    @Published var useCustomAccentColor: Bool = false {
        didSet {
            saveToUserDefaults()
        }
    }
    
    /// Custom accent color
    @Published var customAccentColor: Color = .purple {
        didSet {
            saveToUserDefaults()
        }
    }
    
    /// Whether to reduce motion
    @Published var reduceMotion: Bool = false {
        didSet {
            saveToUserDefaults()
        }
    }
    
    /// Private initializer for singleton
    private init() {
        loadFromUserDefaults()
    }
    
    /// Reset settings to defaults
    func resetToDefaults() {
        theme = .system
        highContrast = false
        textSizeMultiplier = .standard
        useCustomAccentColor = false
        customAccentColor = .purple
        reduceMotion = false
        saveToUserDefaults()
    }
    
    /// Save settings to UserDefaults
    private func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(theme.rawValue, forKey: "appearance_theme")
        defaults.set(highContrast, forKey: "appearance_highContrast")
        defaults.set(textSizeMultiplier.rawValue, forKey: "appearance_textSizeMultiplier")
        defaults.set(useCustomAccentColor, forKey: "appearance_useCustomAccentColor")
        
        // Save custom accent color components
        if let components = NSColor(customAccentColor).cgColor.components, components.count >= 3 {
            defaults.set(components[0], forKey: "appearance_accentColorRed")
            defaults.set(components[1], forKey: "appearance_accentColorGreen")
            defaults.set(components[2], forKey: "appearance_accentColorBlue")
        }
        
        defaults.set(reduceMotion, forKey: "appearance_reduceMotion")
    }
    
    /// Load settings from UserDefaults
    private func loadFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        // Load theme
        if let themeName = defaults.string(forKey: "appearance_theme"),
           let loadedTheme = AppearanceTheme(rawValue: themeName) {
            theme = loadedTheme
        }
        
        // Load other settings
        highContrast = defaults.bool(forKey: "appearance_highContrast")
        
        if let multiplier = defaults.object(forKey: "appearance_textSizeMultiplier") as? CGFloat,
           let size = TextSizeMultiplier(rawValue: multiplier) {
            textSizeMultiplier = size
        }
        
        useCustomAccentColor = defaults.bool(forKey: "appearance_useCustomAccentColor")
        
        // Load custom accent color
        if useCustomAccentColor {
            let red = defaults.double(forKey: "appearance_accentColorRed")
            let green = defaults.double(forKey: "appearance_accentColorGreen")
            let blue = defaults.double(forKey: "appearance_accentColorBlue")
            
            if red > 0 || green > 0 || blue > 0 {
                customAccentColor = Color(red: red, green: green, blue: blue)
            }
        }
        
        reduceMotion = defaults.bool(forKey: "appearance_reduceMotion")
    }
    
    /// Update the interface style based on the selected theme
    private func updateInterfaceStyle() {
        #if os(macOS)
        let style: NSAppearance.Name
        
        switch theme {
        case .system:
            // Use system setting
            style = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) ?? .aqua
        case .light:
            style = .aqua
        case .dark, .highContrast:
            style = .darkAqua
        }
        
        NSApp.appearance = NSAppearance(named: style)
        #endif
    }
}

// MARK: - UI Settings Structure

/// UI settings for the application
struct UISettings: Codable, Equatable {
    /// App theme preference
    var theme: AppTheme = .system
    
    /// Whether to use compact mode
    var compactMode: Bool = false
    
    /// Whether to show tooltips
    var showTooltips: Bool = true
    
    /// Whether to use sound effects
    var soundEffects: Bool = true
    
    /// Sound volume (0.0 - 1.0)
    var soundVolume: Double = 0.5
    
    /// App theme options
    enum AppTheme: String, Codable, CaseIterable {
        /// Follow system appearance
        case system = "System"
        
        /// Light theme
        case light = "Light"
        
        /// Dark theme
        case dark = "Dark"
        
        /// High contrast theme
        case highContrast = "High Contrast"
    }
}