//
//  AppearanceManager.swift
//  LED Messenger
//
//  Created on April 19, 2025
//

import SwiftUI
import Combine

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Manages app appearance settings across platforms
public class AppearanceManager: ObservableObject {
    // MARK: - Shared Instance
    
    /// Shared instance for app-wide access
    public static let shared = AppearanceManager()
    
    // MARK: - Published Properties
    
    /// The current appearance theme
    @Published public var theme: AppearanceTheme = .system {
        didSet {
            applyTheme()
            saveThemePreference()
        }
    }
    
    /// Whether to use high contrast mode
    @Published public var highContrast: Bool = false {
        didSet {
            applyHighContrastSettings()
            saveHighContrastPreference()
        }
    }
    
    /// Current text size multiplier
    @Published public var textSizeMultiplier: TextSizeMultiplier = .medium {
        didSet {
            applyTextSizeSettings()
            saveTextSizePreference()
        }
    }
    
    /// Whether to reduce motion
    @Published public var reduceMotion: Bool = false {
        didSet {
            applyReduceMotionSettings()
            saveReduceMotionPreference()
        }
    }
    
    /// Whether to use custom accent color
    @Published public var useCustomAccentColor: Bool = false {
        didSet {
            applyAccentColorSettings()
            saveAccentColorPreference()
        }
    }
    
    /// Custom accent color
    @Published public var customAccentColor: Color = .blue {
        didSet {
            if useCustomAccentColor {
                applyAccentColorSettings()
                saveAccentColorPreference()
            }
        }
    }
    
    // MARK: - Private Properties
    
    /// UserDefaults key for theme preference
    private let themePreferenceKey = "com.ledmessenger.appearance.theme"
    
    /// UserDefaults key for high contrast preference
    private let highContrastPreferenceKey = "com.ledmessenger.appearance.highContrast"
    
    /// UserDefaults key for text size preference
    private let textSizePreferenceKey = "com.ledmessenger.appearance.textSize"
    
    /// UserDefaults key for reduce motion preference
    private let reduceMotionPreferenceKey = "com.ledmessenger.appearance.reduceMotion"
    
    /// UserDefaults key for custom accent color preference
    private let useCustomAccentColorPreferenceKey = "com.ledmessenger.appearance.useCustomAccent"
    
    /// UserDefaults key for custom accent color value
    private let customAccentColorPreferenceKey = "com.ledmessenger.appearance.customAccentColor"
    
    /// Store for cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        // Load saved preferences
        loadPreferences()
        
        // Setup system preference monitoring
        setupSystemPreferenceMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Reset all appearance settings to default values
    public func resetToDefaults() {
        theme = .system
        highContrast = false
        textSizeMultiplier = .medium
        reduceMotion = false
        useCustomAccentColor = false
        customAccentColor = .blue
    }
    
    /// Apply the current appearance settings
    public func applyCurrentSettings() {
        applyTheme()
        applyHighContrastSettings()
        applyTextSizeSettings()
        applyReduceMotionSettings()
        applyAccentColorSettings()
    }
    
    // MARK: - Private Methods
    
    /// Load saved preferences from UserDefaults
    private func loadPreferences() {
        // Load theme preference
        if let themeName = UserDefaults.standard.string(forKey: themePreferenceKey),
           let savedTheme = AppearanceTheme(rawValue: themeName) {
            theme = savedTheme
        } else {
            theme = .system
        }
        
        // Load high contrast preference
        highContrast = UserDefaults.standard.bool(forKey: highContrastPreferenceKey)
        
        // Load text size preference
        if let textSizeName = UserDefaults.standard.string(forKey: textSizePreferenceKey),
           let savedTextSize = TextSizeMultiplier(rawValue: textSizeName) {
            textSizeMultiplier = savedTextSize
        } else {
            textSizeMultiplier = .medium
        }
        
        // Load reduce motion preference
        reduceMotion = UserDefaults.standard.bool(forKey: reduceMotionPreferenceKey)
        
        // Load custom accent color preferences
        useCustomAccentColor = UserDefaults.standard.bool(forKey: useCustomAccentColorPreferenceKey)
        
        // Load custom accent color if saved
        if let colorData = UserDefaults.standard.data(forKey: customAccentColorPreferenceKey) {
            do {
                // Decode color data
                let decoder = JSONDecoder()
                let colorComponents = try decoder.decode(ColorComponents.self, from: colorData)
                customAccentColor = Color(.sRGB, 
                                         red: colorComponents.red,
                                         green: colorComponents.green,
                                         blue: colorComponents.blue,
                                         opacity: colorComponents.alpha)
            } catch {
                logError("Failed to load custom accent color: \(error.localizedDescription)", category: .app)
                customAccentColor = .blue
            }
        }
    }
    
    /// Setup monitoring of system preferences
    private func setupSystemPreferenceMonitoring() {
        #if os(iOS) || os(tvOS) || os(macOS)
        // Monitor system appearance changes
        NotificationCenter.default.publisher(for: .init("AppleInterfaceThemeChangedNotification"))
            .sink { [weak self] _ in
                // Only update if using system theme
                if self?.theme == .system {
                    self?.applyTheme()
                }
            }
            .store(in: &cancellables)
        #endif
        
        #if os(iOS)
        // Monitor accessibility settings changes
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification))
            .merge(with: NotificationCenter.default.publisher(for: UIAccessibility.reduceTransparencyStatusDidChangeNotification))
            .sink { [weak self] _ in
                self?.applyAccessibilitySettings()
            }
            .store(in: &cancellables)
        #endif
    }
    
    /// Apply the current theme
    private func applyTheme() {
        #if os(iOS)
        // Apply theme to UIKit elements
        switch theme {
        case .system:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .unspecified
        case .light:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
        case .dark:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
        }
        #endif
        
        #if os(macOS)
        // macOS doesn't allow direct theme override, but we can apply styling to views
        // This is handled in views via the @EnvironmentObject
        #endif
        
        logInfo("Applied theme: \(theme.rawValue)", category: .app)
    }
    
    /// Apply high contrast settings
    private func applyHighContrastSettings() {
        // High contrast is applied via SwiftUI modifiers in views
        logInfo("Applied high contrast: \(highContrast)", category: .app)
    }
    
    /// Apply text size settings
    private func applyTextSizeSettings() {
        // Text size is applied via SwiftUI modifiers in views
        logInfo("Applied text size multiplier: \(textSizeMultiplier.rawValue)", category: .app)
    }
    
    /// Apply reduce motion settings
    private func applyReduceMotionSettings() {
        #if os(iOS)
        // We can't override system-wide settings, but we track this for our own animations
        #endif
        
        logInfo("Applied reduce motion: \(reduceMotion)", category: .app)
    }
    
    /// Apply accent color settings
    private func applyAccentColorSettings() {
        // Accent color is applied via SwiftUI modifiers in views
        logInfo("Applied custom accent color: \(useCustomAccentColor)", category: .app)
    }
    
    /// Apply accessibility settings based on system preferences
    private func applyAccessibilitySettings() {
        #if os(iOS)
        // Sync with system settings when appropriate
        if !reduceMotion && UIAccessibility.isReduceMotionEnabled {
            reduceMotion = true
            saveReduceMotionPreference()
        }
        #endif
    }
    
    /// Save theme preference to UserDefaults
    private func saveThemePreference() {
        UserDefaults.standard.set(theme.rawValue, forKey: themePreferenceKey)
    }
    
    /// Save high contrast preference to UserDefaults
    private func saveHighContrastPreference() {
        UserDefaults.standard.set(highContrast, forKey: highContrastPreferenceKey)
    }
    
    /// Save text size preference to UserDefaults
    private func saveTextSizePreference() {
        UserDefaults.standard.set(textSizeMultiplier.rawValue, forKey: textSizePreferenceKey)
    }
    
    /// Save reduce motion preference to UserDefaults
    private func saveReduceMotionPreference() {
        UserDefaults.standard.set(reduceMotion, forKey: reduceMotionPreferenceKey)
    }
    
    /// Save custom accent color preference to UserDefaults
    private func saveAccentColorPreference() {
        UserDefaults.standard.set(useCustomAccentColor, forKey: useCustomAccentColorPreferenceKey)
        
        if useCustomAccentColor {
            // Get color components (approximate, as SwiftUI Color doesn't directly expose components)
            #if os(iOS)
            let uiColor = UIColor(customAccentColor)
            #elseif os(macOS)
            let nsColor = NSColor(customAccentColor)
            #endif
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            
            #if os(iOS)
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            #elseif os(macOS)
            nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            #endif
            
            // Create encodable color components
            let colorComponents = ColorComponents(
                red: Double(red),
                green: Double(green),
                blue: Double(blue),
                alpha: Double(alpha)
            )
            
            do {
                // Encode and save
                let encoder = JSONEncoder()
                let colorData = try encoder.encode(colorComponents)
                UserDefaults.standard.set(colorData, forKey: customAccentColorPreferenceKey)
            } catch {
                logError("Failed to save custom accent color: \(error.localizedDescription)", category: .app)
            }
        }
    }
}

// MARK: - Types

/// Appearance theme options
public enum AppearanceTheme: String, CaseIterable, Identifiable {
    /// Use system setting
    case system = "System"
    
    /// Force light mode
    case light = "Light"
    
    /// Force dark mode
    case dark = "Dark"
    
    /// Identifier for the theme
    public var id: String { rawValue }
    
    /// Display name for the theme
    public var displayName: String { rawValue }
    
    /// Icon for the theme
    public var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

/// Text size multiplier options
public enum TextSizeMultiplier: String, CaseIterable, Identifiable {
    /// Extra small text
    case xSmall = "Extra Small"
    
    /// Small text
    case small = "Small"
    
    /// Medium (default) text
    case medium = "Medium"
    
    /// Large text
    case large = "Large"
    
    /// Extra large text
    case xLarge = "Extra Large"
    
    /// Accessibility text (largest)
    case accessibility = "Accessibility"
    
    /// Identifier for the text size
    public var id: String { rawValue }
    
    /// Display name for the text size
    public var displayName: String { rawValue }
    
    /// Scaling factor for text
    public var scaleFactor: CGFloat {
        switch self {
        case .xSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.2
        case .xLarge: return 1.4
        case .accessibility: return 1.8
        }
    }
}

/// Encodable color components for storage
private struct ColorComponents: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}

// MARK: - View Extensions

/// Extension to apply appearance customization to views
extension View {
    /// Apply the current appearance settings to a view
    public func withAppearanceCustomization() -> some View {
        self.modifier(AppearanceModifier())
    }
}

/// Platform-specific accessibility modifier to handle differences between iOS and macOS
struct PlatformAccessibilityModifier: ViewModifier {
    let highContrast: Bool
    let reduceMotion: Bool
    let scaledSizeCategory: ContentSizeCategory
    
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .environment(\.accessibilityHighContrast, highContrast)
            .environment(\.sizeCategory, scaledSizeCategory)
            .transaction { transaction in
                transaction.disablesAnimations = reduceMotion
            }
        #else
        content
            .environment(\.sizeCategory, scaledSizeCategory)
            .transaction { transaction in
                transaction.disablesAnimations = reduceMotion
            }
        #endif
    }
}

/// ViewModifier to apply appearance customization
public struct AppearanceModifier: ViewModifier {
    /// Appearance manager for settings
    @ObservedObject private var appearanceManager = AppearanceManager.shared
    
    /// Environment color scheme
    @Environment(\.colorScheme) private var colorScheme
    
    /// Apply the appearance customization
    public func body(content: Content) -> some View {
        content
            // Apply theme
            .environment(\.colorScheme, themeColorScheme)
            // Apply high contrast if enabled
            // Apply platform-specific accessibility settings
            .modifier(PlatformAccessibilityModifier(
                highContrast: appearanceManager.highContrast,
                reduceMotion: appearanceManager.reduceMotion,
                scaledSizeCategory: scaledSizeCategory
            ))
            // Apply custom accent color if enabled
            .accentColor(accentColor)
    }
    
    /// Get the color scheme based on selected theme
    private var themeColorScheme: ColorScheme {
        switch appearanceManager.theme {
        case .system:
            return colorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    /// Get scaled ContentSizeCategory
    private var scaledSizeCategory: ContentSizeCategory {
        // This is a rough approximation as there's no direct way to override size category
        let scaleMap: [TextSizeMultiplier: ContentSizeCategory] = [
            .xSmall: .small,
            .small: .medium,
            .medium: .large,
            .large: .extraLarge,
            .xLarge: .extraExtraLarge,
            .accessibility: .accessibilityExtraExtraExtraLarge
        ]
        
        return scaleMap[appearanceManager.textSizeMultiplier] ?? .large
    }
    
    /// Get the accent color to use
    private var accentColor: Color {
        appearanceManager.useCustomAccentColor ? appearanceManager.customAccentColor : Color.accentColor
    }
}