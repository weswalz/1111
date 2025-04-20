//
//  Message.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation
import SwiftUI

/// Represents a text message that can be sent to an LED wall via OSC
public struct Message: Identifiable, Codable, Equatable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the message
    public var id: UUID
    
    /// The content text of the message
    public var text: String
    
    /// Optional description or note about this message (not sent to LED wall)
    public var note: String?
    
    /// Format options for this message
    public var formatting: MessageFormatting
    
    /// The date when the message was created
    public var createdAt: Date
    
    /// The date when the message was last modified
    public var modifiedAt: Date
    
    /// Flag indicating if this message has been sent
    public var hasBeenSent: Bool
    
    /// The last time this message was sent to the LED wall
    public var lastSentAt: Date?
    
    /// Optional duration for message display in seconds (nil means indefinite)
    public var displayDuration: Double?
    
    /// Optional expiration date (calculated from lastSentAt + displayDuration)
    public var expiresAt: Date? {
        guard let sentAt = lastSentAt, let duration = displayDuration else {
            return nil
        }
        return sentAt.addingTimeInterval(duration)
    }
    
    // MARK: - Initialization
    
    /// Create a new message with default formatting
    /// - Parameter text: The message text
    public init(text: String) {
        self.id = UUID()
        self.text = text
        self.formatting = MessageFormatting()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.hasBeenSent = false
        self.displayDuration = nil
    }
    
    /// Create a new message with specific formatting
    /// - Parameters:
    ///   - text: The message text
    ///   - formatting: The formatting options to apply
    ///   - displayDuration: Optional duration in seconds (nil means indefinite)
    public init(text: String, formatting: MessageFormatting, displayDuration: Double? = nil) {
        self.id = UUID()
        self.text = text
        self.formatting = formatting
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.hasBeenSent = false
        self.displayDuration = displayDuration
    }
    
    /// Create a fully customized message
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - text: The message text
    ///   - note: Optional note about the message
    ///   - formatting: The formatting options
    ///   - createdAt: Creation date (defaults to now)
    ///   - modifiedAt: Last modification date (defaults to now)
    ///   - hasBeenSent: Whether this message has been sent
    ///   - lastSentAt: The last time this message was sent
    ///   - displayDuration: Optional duration in seconds (nil means indefinite)
    public init(
        id: UUID = UUID(),
        text: String,
        note: String? = nil,
        formatting: MessageFormatting = MessageFormatting(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        hasBeenSent: Bool = false,
        lastSentAt: Date? = nil,
        displayDuration: Double? = nil
    ) {
        self.id = id
        self.text = text
        self.note = note
        self.formatting = formatting
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.hasBeenSent = hasBeenSent
        self.lastSentAt = lastSentAt
        self.displayDuration = displayDuration
    }
    
    // MARK: - Methods
    
    /// Mark this message as sent
    public mutating func markAsSent() {
        self.hasBeenSent = true
        self.lastSentAt = Date()
        self.modifiedAt = Date()
    }
    
    /// Update the message text and mark as modified
    /// - Parameter newText: The new text content
    public mutating func updateText(_ newText: String) {
        self.text = newText
        self.modifiedAt = Date()
    }
    
    /// Update the formatting options and mark as modified
    /// - Parameter newFormatting: The new formatting options
    public mutating func updateFormatting(_ newFormatting: MessageFormatting) {
        self.formatting = newFormatting
        self.modifiedAt = Date()
    }
    
    /// Create a copy of this message with a new ID
    /// - Returns: A duplicated message
    public func duplicate() -> Message {
        var copy = self
        copy.id = UUID()
        copy.createdAt = Date()
        copy.modifiedAt = Date()
        copy.hasBeenSent = false
        copy.lastSentAt = nil
        // Keep the display duration
        return copy
    }
    
    /// Get the time remaining until message expiration
    /// - Returns: Time remaining in seconds, or nil if no expiration
    public func timeRemaining() -> Double? {
        guard let expiryDate = expiresAt else {
            return nil
        }
        
        return max(0, expiryDate.timeIntervalSinceNow)
    }
    
    /// Check if this message has an active countdown running
    /// - Returns: True if countdown is active
    public func hasActiveCountdown() -> Bool {
        guard hasBeenSent, displayDuration != nil, let remaining = timeRemaining() else {
            return false
        }
        
        return remaining > 0
    }
    
    // MARK: - Hashable Conformance
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable Conformance
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

/// Formatting options for a message
public struct MessageFormatting: Codable, Equatable, Hashable {
    
    // MARK: - Properties
    
    /// Font size for the message
    public var fontSize: Double
    
    /// Text alignment for the message
    public var alignment: TextAlignment
    
    /// Font weight for the message
    public var fontWeight: FontWeight
    
    /// Text color for the message
    public var textColor: MessageColor
    
    /// Background color for the message
    public var backgroundColor: MessageColor
    
    /// Optional stroke color for the message
    public var strokeColor: MessageColor?
    
    /// Stroke width (if stroke color is set)
    public var strokeWidth: Double
    
    /// Whether to apply a shadow effect
    public var hasShadow: Bool
    
    /// Shadow color (if shadow is enabled)
    public var shadowColor: MessageColor
    
    /// Shadow radius (if shadow is enabled)
    public var shadowRadius: Double
    
    /// Shadow offset X (if shadow is enabled)
    public var shadowOffsetX: Double
    
    /// Shadow offset Y (if shadow is enabled)
    public var shadowOffsetY: Double
    
    /// Animation style for the message
    public var animation: MessageAnimation
    
    // MARK: - Nested Types
    
    /// Text alignment options
    public enum TextAlignment: String, Codable, CaseIterable {
        case leading = "Leading"
        case center = "Center"
        case trailing = "Trailing"
    }
    
    /// Font weight options
    public enum FontWeight: String, Codable, CaseIterable {
        case regular = "Regular"
        case medium = "Medium"
        case semibold = "Semibold"
        case bold = "Bold"
        case heavy = "Heavy"
    }
    
    /// Animation options for messages
    public enum MessageAnimation: String, Codable, CaseIterable {
        case none = "None"
        case fade = "Fade"
        case slide = "Slide"
        case zoom = "Zoom"
        case typing = "Typing"
        case pulse = "Pulse"
    }
    
    // MARK: - Initialization
    
    /// Create formatting with default values
    public init() {
        self.fontSize = 48
        self.alignment = .center
        self.fontWeight = .bold
        self.textColor = MessageColor(red: 1, green: 1, blue: 1)
        self.backgroundColor = MessageColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.strokeColor = nil
        self.strokeWidth = 0
        self.hasShadow = false
        self.shadowColor = MessageColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.shadowRadius = 4
        self.shadowOffsetX = 2
        self.shadowOffsetY = 2
        self.animation = .fade
    }
    
    /// Create custom formatting
    /// - Parameters:
    ///   - fontSize: The font size
    ///   - alignment: Text alignment
    ///   - fontWeight: Font weight
    ///   - textColor: Text color
    ///   - backgroundColor: Background color
    ///   - strokeColor: Optional stroke color
    ///   - strokeWidth: Stroke width
    ///   - hasShadow: Whether to apply a shadow
    ///   - shadowColor: Shadow color
    ///   - shadowRadius: Shadow radius
    ///   - shadowOffsetX: Shadow X offset
    ///   - shadowOffsetY: Shadow Y offset
    ///   - animation: Animation style
    public init(
        fontSize: Double,
        alignment: TextAlignment,
        fontWeight: FontWeight,
        textColor: MessageColor,
        backgroundColor: MessageColor,
        strokeColor: MessageColor? = nil,
        strokeWidth: Double = 0,
        hasShadow: Bool = false,
        shadowColor: MessageColor = MessageColor(red: 0, green: 0, blue: 0, alpha: 0.5),
        shadowRadius: Double = 4,
        shadowOffsetX: Double = 2,
        shadowOffsetY: Double = 2,
        animation: MessageAnimation = .fade
    ) {
        self.fontSize = fontSize
        self.alignment = alignment
        self.fontWeight = fontWeight
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.hasShadow = hasShadow
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffsetX = shadowOffsetX
        self.shadowOffsetY = shadowOffsetY
        self.animation = animation
    }
}

/// Color representation for message formatting
public struct MessageColor: Codable, Equatable, Hashable {
    
    // MARK: - Properties
    
    /// Red component (0-1)
    public var red: Double
    
    /// Green component (0-1)
    public var green: Double
    
    /// Blue component (0-1)
    public var blue: Double
    
    /// Alpha component (0-1)
    public var alpha: Double
    
    // MARK: - Initialization
    
    /// Create a color with the specified components
    /// - Parameters:
    ///   - red: Red component (0-1)
    ///   - green: Green component (0-1)
    ///   - blue: Blue component (0-1)
    ///   - alpha: Alpha component (0-1), defaults to 1
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    /// Create a color from hexadecimal representation
    /// - Parameter hex: Hex string (e.g. "#FF0000" or "FF0000")
    public init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        self.red = Double((rgb & 0xFF0000) >> 16) / 255.0
        self.green = Double((rgb & 0x00FF00) >> 8) / 255.0
        self.blue = Double(rgb & 0x0000FF) / 255.0
        self.alpha = 1.0
    }
    
    // MARK: - Methods
    
    /// Convert to a SwiftUI Color
    /// - Returns: A SwiftUI Color representation
    public func toColor() -> Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    /// Convert to a hex string
    /// - Returns: Hexadecimal representation of the color
    public func toHex() -> String {
        let r = Int(red * 255) & 0xFF
        let g = Int(green * 255) & 0xFF
        let b = Int(blue * 255) & 0xFF
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    /// Convert to RGB string for OSC transmission
    /// - Returns: Comma-separated RGB values (0-255)
    public func toRGBString() -> String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return "\(r),\(g),\(b)"
    }
    
    /// Convert to RGBA string for OSC transmission
    /// - Returns: Comma-separated RGBA values (0-255, alpha 0-1)
    public func toRGBAString() -> String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return "\(r),\(g),\(b),\(alpha)"
    }
}
