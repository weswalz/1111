//
//  Color+Extensions.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Extensions for Color manipulation
extension Color {
    
    /// Initialize from hex string
    /// - Parameter hex: The hex color string (e.g. "#FF0000" or "FF0000")
    public init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    /// Convert to hex string
    /// - Returns: Hex color string with # prefix
    public func toHex() -> String {
        #if os(iOS)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif os(macOS)
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        let r = Int(red * 255) & 0xFF
        let g = Int(green * 255) & 0xFF
        let b = Int(blue * 255) & 0xFF
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    /// Convert to MessageColor
    /// - Returns: MessageColor representation
    public func toMessageColor() -> MessageColor {
        #if os(iOS)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif os(macOS)
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        return MessageColor(red: Double(red), 
                          green: Double(green), 
                           blue: Double(blue), 
                          alpha: Double(alpha))
    }
    
    /// Create a darker version of this color
    /// - Parameter percentage: How much darker (0-1)
    /// - Returns: Darker color
    public func darker(by percentage: CGFloat = 0.2) -> Color {
        #if os(iOS)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif os(macOS)
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        return Color(
            red: max(red - percentage, 0),
            green: max(green - percentage, 0),
            blue: max(blue - percentage, 0),
            opacity: alpha
        )
    }
    
    /// Create a lighter version of this color
    /// - Parameter percentage: How much lighter (0-1)
    /// - Returns: Lighter color
    public func lighter(by percentage: CGFloat = 0.2) -> Color {
        #if os(iOS)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif os(macOS)
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        return Color(
            red: min(red + percentage, 1),
            green: min(green + percentage, 1),
            blue: min(blue + percentage, 1),
            opacity: alpha
        )
    }
    
    /// Check if this color is dark
    /// - Returns: True if the color is dark
    public func isDark() -> Bool {
        #if os(iOS)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif os(macOS)
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        // Calculate perceived brightness using the formula:
        // (0.299*R + 0.587*G + 0.114*B)
        let brightness = (0.299 * red + 0.587 * green + 0.114 * blue)
        
        // Return true if the brightness is less than 0.5
        return brightness < 0.5
    }
    
    /// Get a contrasting color for text (white or black)
    /// - Returns: White for dark backgrounds, black for light backgrounds
    public func contrastingTextColor() -> Color {
        return isDark() ? .white : .black
    }
    
    /// Get the RGBA components of the color
    /// - Returns: Tuple of red, green, blue, alpha values (0-1)
    public func components() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        #if os(iOS)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif os(macOS)
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }
}
