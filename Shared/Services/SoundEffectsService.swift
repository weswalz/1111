//
//  SoundEffectsService.swift
//  LED Messenger
//
//  Created on April 19, 2025
//

import Foundation
import Combine

#if os(iOS)
import AVFoundation
#endif

/// Service for playing sound effects
public class SoundEffectsService: ObservableObject {
    // MARK: - Shared Instance
    
    /// Shared instance for app-wide access
    public static let shared = SoundEffectsService()
    
    // MARK: - Published Properties
    
    /// Whether sound effects are enabled
    @Published public var soundEffectsEnabled: Bool = true {
        didSet {
            // Save preference
            UserDefaults.standard.set(soundEffectsEnabled, forKey: soundEnabledKey)
        }
    }
    
    /// Sound effect volume (0-1)
    @Published public var volume: Float = 0.5 {
        didSet {
            // Save preference
            UserDefaults.standard.set(volume, forKey: volumeKey)
        }
    }
    
    // MARK: - Private Properties
    
    #if os(iOS)
    /// Sound players for each sound effect
    private var soundPlayers: [SoundEffect: AVAudioPlayer] = [:]
    #endif
    
    /// Queue for loading sounds
    private let soundLoadQueue = DispatchQueue(label: "com.ledmessenger.soundLoading", qos: .utility)
    
    /// User defaults key for sound enabled preference
    private let soundEnabledKey = "com.ledmessenger.soundEffectsEnabled"
    
    /// User defaults key for volume preference
    private let volumeKey = "com.ledmessenger.soundEffectsVolume"
    
    /// Logging service
    private let logger = LogManager.shared
    
    #if os(iOS)
    /// Audio session
    private var audioSession: AVAudioSession {
        AVAudioSession.sharedInstance()
    }
    #endif
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        // Load saved preferences
        loadPreferences()
        
        // Preload all sound effects
        preloadSoundEffects()
        
        // Set up the audio session
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    
    /// Play a sound effect
    /// - Parameters:
    ///   - effect: The sound effect to play
    ///   - volume: Optional volume override (0-1)
    public func playSound(_ effect: SoundEffect, volume: Float? = nil) {
        // Skip if sound effects are disabled
        guard soundEffectsEnabled else { return }
        
        #if os(iOS)
        // Get the sound player
        guard let player = soundPlayers[effect] else {
            logger.warning("Sound effect not loaded: \(effect.rawValue)", category: .app)
            
            // Try to load and play
            loadSoundEffect(effect) { [weak self] success in
                if success {
                    self?.playSound(effect, volume: volume)
                }
            }
            return
        }
        
        // Set volume
        player.volume = volume ?? self.volume
        
        // Reset player to start
        player.currentTime = 0
        
        // Play the sound
        player.play()
        
        logger.debug("Playing sound effect: \(effect.rawValue)", category: .app)
        #else
        // macOS implementation could be added here
        logger.debug("Playing sound effect: \(effect.rawValue) (macOS stub)", category: .app)
        #endif
    }
    
    /// Preload a specific sound effect
    /// - Parameter effect: The sound effect to preload
    public func preloadSoundEffect(_ effect: SoundEffect) {
        soundLoadQueue.async { [weak self] in
            self?.loadSoundEffect(effect)
        }
    }
    
    /// Preload all sound effects
    public func preloadSoundEffects() {
        soundLoadQueue.async { [weak self] in
            #if os(iOS)
            for effect in SoundEffect.allCases {
                self?.loadSoundEffect(effect)
            }
            #else
            // macOS implementation could be added here
            self?.logger.debug("Preloading sound effects (macOS stub)", category: .app)
            #endif
        }
    }
    
    // MARK: - Private Methods
    
    /// Load saved preferences
    private func loadPreferences() {
        // Load sound enabled preference
        if UserDefaults.standard.object(forKey: soundEnabledKey) != nil {
            soundEffectsEnabled = UserDefaults.standard.bool(forKey: soundEnabledKey)
        }
        
        // Load volume preference
        if UserDefaults.standard.object(forKey: volumeKey) != nil {
            volume = Float(UserDefaults.standard.float(forKey: volumeKey))
        }
    }
    
    /// Set up the audio session
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try audioSession.setCategory(.ambient, mode: .default)
            try audioSession.setActive(true)
        } catch {
            logger.error("Failed to set up audio session: \(error.localizedDescription)", category: .app)
        }
        #endif
    }
    
    /// Load a sound effect
    /// - Parameters:
    ///   - effect: The sound effect to load
    ///   - completion: Optional completion handler called when loading completes
    private func loadSoundEffect(_ effect: SoundEffect, completion: ((Bool) -> Void)? = nil) {
        #if os(iOS)
        // Skip if already loaded
        if soundPlayers[effect] != nil {
            completion?(true)
            return
        }
        
        // Get the sound file URL
        guard let soundURL = Bundle.main.url(forResource: effect.filename, withExtension: effect.fileExtension) else {
            logger.error("Sound effect file not found: \(effect.filename).\(effect.fileExtension)", category: .app)
            completion?(false)
            return
        }
        
        // Create and prepare the player
        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay()
            player.volume = volume
            
            // Store the player
            soundPlayers[effect] = player
            
            logger.debug("Loaded sound effect: \(effect.rawValue)", category: .app)
            
            completion?(true)
        } catch {
            logger.error("Failed to load sound effect: \(effect.rawValue)", category: .app)
            completion?(false)
        }
        #else
        // macOS implementation could be added here
        logger.debug("Loading sound effect (macOS stub): \(effect.rawValue)", category: .app)
        completion?(true)
        #endif
    }
}

// MARK: - Sound Effect Enum

/// Sound effects available in the app
public enum SoundEffect: String, CaseIterable {
    /// Sound when a message is sent
    case messageSent = "MessageSent"
    
    /// Sound when a message is cleared
    case messageCleared = "MessageCleared"
    
    /// Sound when a connection is established
    case connectionEstablished = "ConnectionEstablished"
    
    /// Sound when a connection is lost
    case connectionLost = "ConnectionLost"
    
    /// Sound for errors
    case error = "Error"
    
    /// Sound for notifications
    case notification = "Notification"
    
    /// Sound for button taps
    case buttonTap = "ButtonTap"
    
    /// Sound for successful actions
    case success = "Success"
    
    /// Filename for the sound effect
    var filename: String {
        switch self {
        case .messageSent:
            return "message_sent"
        case .messageCleared:
            return "message_cleared"
        case .connectionEstablished:
            return "connection_established"
        case .connectionLost:
            return "connection_lost"
        case .error:
            return "error"
        case .notification:
            return "notification"
        case .buttonTap:
            return "button_tap"
        case .success:
            return "success"
        }
    }
    
    /// File extension for the sound effect
    var fileExtension: String {
        return "m4a"
    }
    
    /// Description for the sound effect
    var description: String {
        switch self {
        case .messageSent:
            return "Message sent"
        case .messageCleared:
            return "Message cleared"
        case .connectionEstablished:
            return "Connection established"
        case .connectionLost:
            return "Connection lost"
        case .error:
            return "Error"
        case .notification:
            return "Notification"
        case .buttonTap:
            return "Button tap"
        case .success:
            return "Success"
        }
    }
}

// MARK: - Extensions

/// Extension to add sound effects to message queue controller
extension MessageQueueController {
    /// Play sound effect when sending a message
    func playMessageSentSound() {
        SoundEffectsService.shared.playSound(.messageSent)
    }
    
    /// Play sound effect when clearing a message
    func playMessageClearedSound() {
        SoundEffectsService.shared.playSound(.messageCleared)
    }
}

/// Extension to add sound effects to resolume connector
extension ResolumeConnector {
    /// Play sound effect when connection is established
    func playConnectionEstablishedSound() {
        SoundEffectsService.shared.playSound(.connectionEstablished)
    }
    
    /// Play sound effect when connection is lost
    func playConnectionLostSound() {
        SoundEffectsService.shared.playSound(.connectionLost)
    }
}

/// Extension to add sound effects to UI components
#if os(iOS) || os(macOS)
import SwiftUI

extension View {
    /// Add button tap sound effect to a view
    public func buttonTapSound() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                SoundEffectsService.shared.playSound(.buttonTap)
            }
        )
    }
    
    /// Add success sound effect to a view
    public func successSound() -> some View {
        self.onAppear {
            SoundEffectsService.shared.playSound(.success)
        }
    }
    
    /// Add error sound effect to a view
    public func errorSound() -> some View {
        self.onAppear {
            SoundEffectsService.shared.playSound(.error)
        }
    }
    
    /// Add notification sound effect to a view
    public func notificationSound() -> some View {
        self.onAppear {
            SoundEffectsService.shared.playSound(.notification)
        }
    }
}
#endif