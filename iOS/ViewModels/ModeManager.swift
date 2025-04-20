//
//  ModeManager.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import Foundation
import Combine
import SwiftUI

/// Defines the operation modes for the iPad app
public enum OperationMode: String, CaseIterable, Identifiable, Codable {
    /// Independent operation with direct OSC connection
    case solo = "SOLO"
    
    /// Connected to Mac as a peer
    case paired = "PAIRED"
    
    /// Unique identifier for the mode
    public var id: String { rawValue }
    
    /// Display name for the mode
    public var displayName: String {
        switch self {
        case .solo:
            return AppConstants.OperationMode.soloModeName
        case .paired:
            return AppConstants.OperationMode.pairedModeName
        }
    }
    
    /// Description of the mode
    public var description: String {
        switch self {
        case .solo:
            return AppConstants.OperationMode.soloModeDescription
        case .paired:
            return AppConstants.OperationMode.pairedModeDescription
        }
    }
    
    /// Icon for the mode
    public var iconName: String {
        switch self {
        case .solo:
            return "ipad"
        case .paired:
            return "ipad.and.iphone"
        }
    }
    
    /// Color associated with the mode
    public var color: Color {
        switch self {
        case .solo:
            return .blue
        case .paired:
            return .green
        }
    }
}

/// Manages the operation mode of the iPad app
public class ModeManager: ObservableObject {
    
    // MARK: - Properties
    
    /// The current operation mode
    @Published public private(set) var currentMode: OperationMode?
    
    /// Whether the mode selection screen should be shown
    @Published public var showModeSelection: Bool = true
    
    /// Whether the mode has been selected for this session
    @Published public private(set) var modeSelected: Bool = false
    
    /// UserDefaults for storing the selected mode
    private let userDefaults: UserDefaults
    
    /// Key for storing the last used mode
    private let lastUsedModeKey = AppConstants.OperationMode.lastUsedModeKey
    
    /// Whether to remember the last used mode
    @AppStorage("rememberLastMode") private var rememberLastMode: Bool = true
    
    /// Observers
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with standard UserDefaults
    public init() {
        self.userDefaults = UserDefaults.standard
        
        // Check for a remembered mode
        if rememberLastMode, let lastMode = loadLastUsedMode() {
            // Found a remembered mode, but still show selection screen
            currentMode = lastMode
            showModeSelection = true
            modeSelected = false
            logInfo("Loaded last used mode: \(lastMode)", category: .app)
        } else {
            // No remembered mode, show selection screen
            currentMode = nil
            showModeSelection = true
            modeSelected = false
            logInfo("No last used mode found, showing mode selection", category: .app)
        }
    }
    
    /// Initialize with custom UserDefaults
    /// - Parameter userDefaults: The UserDefaults instance to use
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        
        // Check for a remembered mode
        if rememberLastMode, let lastMode = loadLastUsedMode() {
            // Found a remembered mode, but still show selection screen
            currentMode = lastMode
            showModeSelection = true
            modeSelected = false
            logInfo("Loaded last used mode: \(lastMode)", category: .app)
        } else {
            // No remembered mode, show selection screen
            currentMode = nil
            showModeSelection = true
            modeSelected = false
            logInfo("No last used mode found, showing mode selection", category: .app)
        }
    }
    
    // MARK: - Mode Management
    
    /// Set the operation mode
    /// - Parameter mode: The mode to set
    public func setMode(_ mode: OperationMode) {
        currentMode = mode
        modeSelected = true
        showModeSelection = false
        
        // Remember this mode if enabled
        if rememberLastMode {
            saveLastUsedMode(mode)
        }
        
        logInfo("Set operation mode to: \(mode)", category: .app)
    }
    
    /// Show the mode selection screen
    public func showModeSelectionScreen() {
        showModeSelection = true
        modeSelected = false
        logInfo("Showing mode selection screen", category: .app)
    }
    
    /// Reset the selected mode
    public func resetMode() {
        currentMode = nil
        modeSelected = false
        showModeSelection = true
        logInfo("Reset operation mode", category: .app)
    }
    
    /// Toggle whether to remember the last used mode
    /// - Parameter remember: Whether to remember the mode
    public func setRememberLastMode(_ remember: Bool) {
        rememberLastMode = remember
        
        if !remember {
            // Clear the saved mode
            userDefaults.removeObject(forKey: lastUsedModeKey)
        } else if let mode = currentMode {
            // Save the current mode
            saveLastUsedMode(mode)
        }
        
        logInfo("Set remember last mode to: \(remember)", category: .app)
    }
    
    // MARK: - Private Methods
    
    /// Save the last used mode to UserDefaults
    /// - Parameter mode: The mode to save
    private func saveLastUsedMode(_ mode: OperationMode) {
        userDefaults.set(mode.rawValue, forKey: lastUsedModeKey)
        logDebug("Saved last used mode: \(mode)", category: .app)
    }
    
    /// Load the last used mode from UserDefaults
    /// - Returns: The last used mode, if any
    private func loadLastUsedMode() -> OperationMode? {
        guard let modeString = userDefaults.string(forKey: lastUsedModeKey),
              let mode = OperationMode(rawValue: modeString) else {
            return nil
        }
        
        return mode
    }
}
