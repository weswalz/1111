//
//  AppConstants.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation
import SwiftUI

/// Constants used throughout the application
public enum AppConstants {
    
    /// App information
    public enum App {
        /// App name
        public static let name = "LED Messenger"
        
        /// App version
        public static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        /// App build number
        public static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        /// Bundle identifier
        public static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.ledmessenger"
        
        /// Full version string (version + build)
        public static let fullVersion = "v\(version) (\(build))"
    }
    
    /// UI-related constants
    public enum UI {
        /// Standard corner radius for UI elements
        public static let cornerRadius: CGFloat = 10
        
        /// Standard padding for view content
        public static let standardPadding: CGFloat = 16
        
        /// Small padding for compact spacing
        public static let smallPadding: CGFloat = 8
        
        /// Large padding for emphasized spacing
        public static let largePadding: CGFloat = 24
        
        /// Animation duration for standard transitions
        public static let animationDuration: Double = 0.3
        
        /// Maximum width for UI elements on large screens
        public static let maxContentWidth: CGFloat = 1200
        
        /// Space between list items
        public static let listSpacing: CGFloat = 8
        
        /// Size for icon buttons
        public static let iconButtonSize: CGFloat = 44
        
        /// Minimum dimension for touch targets
        public static let minimumTouchTarget: CGFloat = 44
    }
    
    /// Theme colors
    public enum Colors {
        /// Primary brand color
        public static let primary = Color("Primary", bundle: nil)
        
        /// Secondary brand color
        public static let secondary = Color("Secondary", bundle: nil)
        
        /// Accent color for highlights
        public static let accent = Color("Accent", bundle: nil)
        
        /// Background color
        public static let background = Color("Background", bundle: nil)
        
        /// Surface color for cards and elevated elements
        public static let surface = Color("Surface", bundle: nil)
        
        /// Text color
        public static let text = Color("Text", bundle: nil)
        
        /// Subdued text color
        public static let textSecondary = Color("TextSecondary", bundle: nil)
        
        /// Success color
        public static let success = Color("Success", bundle: nil)
        
        /// Warning color
        public static let warning = Color("Warning", bundle: nil)
        
        /// Error color
        public static let error = Color("Error", bundle: nil)
        
        /// Disabled color
        public static let disabled = Color("Disabled", bundle: nil)
        
        /// Overlay background color
        public static let overlay = Color.black.opacity(0.5)
    }
    
    /// Network and OSC constants
    public enum Network {
        /// Default OSC port
        public static let defaultOSCPort = 2269
        
        /// Default peer discovery port
        public static let defaultPeerPort = 8001
        
        /// Network timeout in seconds
        public static let timeout: TimeInterval = 5.0
        
        /// Default send/receive buffer size
        public static let bufferSize = 1024
        
        /// Retry count for failed connections
        public static let connectionRetryCount = 3
        
        /// Time between connection retries in seconds
        public static let connectionRetryDelay: TimeInterval = 2.0
    }
    
    /// File and storage constants
    public enum Storage {
        /// Default directory for message queues
        public static let queuesDirectory = "MessageQueues"
        
        /// Default filename for settings
        public static let settingsFilename = "settings.json"
        
        /// Default message queue filename
        public static let defaultQueueFilename = "default.json"
        
        /// Maximum number of recent files to remember
        public static let maxRecentFiles = 10
        
        /// Default auto-save interval in seconds
        public static let autoSaveInterval: TimeInterval = 60.0
    }
    
    /// iPad operation mode constants
    public enum OperationMode {
        /// Name for solo mode
        public static let soloModeName = "SOLO"
        
        /// Description for solo mode
        public static let soloModeDescription = "Operate independently with direct OSC connection"
        
        /// Name for paired mode
        public static let pairedModeName = "PAIRED"
        
        /// Description for paired mode
        public static let pairedModeDescription = "Connect to a Mac running LED Messenger"
        
        /// UserDefaults key for storing the last used mode
        public static let lastUsedModeKey = "lastUsedOperationMode"
    }
}
