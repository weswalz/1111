//
//  LogCategory.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation

/// Defines categories for organizing and filtering log messages
public enum LogCategory: String, CaseIterable {
    
    /// General application events and operations
    case app = "App"
    
    /// User interface actions and events
    case ui = "UI"
    
    /// Network operations including OSC communication
    case network = "Network"
    
    /// Open Sound Control protocol specific logging
    case osc = "OSC"
    
    /// Message queue management and operations
    case queue = "Queue"
    
    /// Application settings and preferences
    case settings = "Settings"
    
    /// Data persistence and storage operations
    case persistence = "Persistence"
    
    /// Peer-to-peer communication for device synchronization
    case peer = "Peer"
    
    /// Performance metrics and optimization information
    case performance = "Performance"
    
    /// The default category for messages that don't fit elsewhere
    case general = "General"
    
    /// Returns all categories as an array of strings
    public static var allCategoryNames: [String] {
        Self.allCases.map { $0.rawValue }
    }
    
    /// Returns an icon representation for the category
    public var icon: String {
        switch self {
        case .app:          return "📱"
        case .ui:           return "🖼️"
        case .network:      return "🌐"
        case .osc:          return "📡"
        case .queue:        return "📋"
        case .settings:     return "⚙️"
        case .persistence:  return "💾"
        case .peer:         return "🔄"
        case .performance:  return "⚡"
        case .general:      return "📝"
        }
    }
}
