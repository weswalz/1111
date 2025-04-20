//
//  LogLevel.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation

/// Defines the severity levels for application logging
public enum LogLevel: Int, Comparable, CaseIterable {
    
    /// Debug information for development purposes
    case debug = 0
    
    /// Informational messages about normal application operation
    case info = 1
    
    /// Warnings that don't prevent the application from functioning but
    /// indicate potential issues or unexpected behavior
    case warning = 2
    
    /// Errors that affect application functionality but don't cause complete failure
    case error = 3
    
    /// Critical failures that prevent the application from functioning properly
    case critical = 4
    
    /// Returns a string representation of the log level
    public var description: String {
        switch self {
        case .debug:    return "DEBUG"
        case .info:     return "INFO"
        case .warning:  return "WARNING"
        case .error:    return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
    
    /// Returns an emoji representation of the log level for visual identification
    public var emoji: String {
        switch self {
        case .debug:    return "🔍"
        case .info:     return "ℹ️"
        case .warning:  return "⚠️"
        case .error:    return "❌"
        case .critical: return "🔥"
        }
    }
    
    /// The color associated with this log level (for console output styling)
    public var colorName: String {
        switch self {
        case .debug:    return "gray"
        case .info:     return "green"
        case .warning:  return "yellow"
        case .error:    return "red"
        case .critical: return "purple"
        }
    }
    
    // Implement Comparable protocol
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
