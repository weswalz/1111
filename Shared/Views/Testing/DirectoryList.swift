//
//  DirectoryList.swift
//  LED Messenger
//
//  Created on April 19, 2025
//

#if DEBUG

// This file is a placeholder to ensure the Testing directory is created and included in the compilation.
// It exports the OSCTesterView and TestConfigurationView for use in the app.

import Foundation
import SwiftUI

/// Directory of test modules available
public enum TestModules {
    /// All test views available in the app
    public static let allViews: [String] = [
        "OSC Tester",
        "Test Configuration"
    ]
    
    /// Get a test view by name
    /// - Parameter name: The name of the test view
    /// - Returns: The requested view, or nil if not found
    public static func getView(named name: String) -> AnyView? {
        switch name {
        case "OSC Tester":
            return AnyView(OSCTesterView())
        case "Test Configuration":
            return AnyView(TestConfigurationView())
        default:
            return nil
        }
    }
}

#endif