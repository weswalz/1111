//
//  FeedbackGenerators.swift
//  LED Messenger
//
//  Created on April 18, 2025
//

import SwiftUI
import CoreHaptics

// MARK: - Haptic Feedback

/// A class to provide haptic feedback services
class HapticFeedback {
    // MARK: - Properties
    
    /// Haptic engine
    private var engine: CHHapticEngine?
    
    /// Whether haptic feedback is enabled
    private var isEnabled = true
    
    /// Whether advanced haptics are supported
    private var supportsAdvancedHaptics: Bool {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    // MARK: - Initialization
    
    /// Initialize haptic feedback
    init() {
        setupHapticEngine()
    }
    
    /// Set up the haptic engine
    private func setupHapticEngine() {
        guard supportsAdvancedHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Restart the engine when necessary
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
            
            // Restart the engine if app loses focus
            engine?.stoppedHandler = { [weak self] reason in
                if reason == .applicationSuspended {
                    self?.setupHapticEngine()
                }
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }
    
    // MARK: - Simple Feedback
    
    /// Trigger a success feedback
    func success() {
        guard isEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Trigger a warning feedback
    func warning() {
        guard isEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Trigger an error feedback
    func error() {
        guard isEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Trigger a selection feedback
    func selection() {
        guard isEnabled else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Trigger a light impact feedback
    func lightImpact() {
        guard isEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Trigger a medium impact feedback
    func mediumImpact() {
        guard isEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Trigger a heavy impact feedback
    func heavyImpact() {
        guard isEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // MARK: - Advanced Feedback
    
    /// Play a message sent haptic pattern
    func messageSent() {
        guard isEnabled, supportsAdvancedHaptics else {
            success() // Fallback to basic feedback
            return
        }
        
        // Define haptic pattern for message sent
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        
        let event1 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )
        
        let event2 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0.1
        )
        
        playHapticPattern(events: [event1, event2])
    }
    
    /// Play a message received haptic pattern
    func messageReceived() {
        guard isEnabled, supportsAdvancedHaptics else {
            selection() // Fallback to basic feedback
            return
        }
        
        // Define haptic pattern for message received
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )
        
        playHapticPattern(events: [event])
    }
    
    /// Play a connection established haptic pattern
    func connectionEstablished() {
        guard isEnabled, supportsAdvancedHaptics else {
            success() // Fallback to basic feedback
            return
        }
        
        // Define haptic pattern for connection established
        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.15
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.3,
                duration: 0.15
            )
        ]
        
        playHapticPattern(events: events)
    }
    
    /// Play a connection lost haptic pattern
    func connectionLost() {
        guard isEnabled, supportsAdvancedHaptics else {
            error() // Fallback to basic feedback
            return
        }
        
        // Define haptic pattern for connection lost
        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0.2
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.4
            )
        ]
        
        playHapticPattern(events: events)
    }
    
    /// Play a custom haptic pattern
    /// - Parameter events: The haptic events to play
    private func playHapticPattern(events: [CHHapticEvent]) {
        guard supportsAdvancedHaptics else { return }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    // MARK: - Configuration
    
    /// Enable or disable haptic feedback
    /// - Parameter enabled: Whether haptic feedback is enabled
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}

// MARK: - Sound Feedback

/// A class to provide sound feedback services
class SoundFeedback {
    // MARK: - Properties
    
    /// Whether sound feedback is enabled
    private var isEnabled = true
    
    /// Sound player for UI feedback
    private var soundEffectPlayer: AVAudioPlayer?
    
    // MARK: - Simple Feedback
    
    /// Play a button tap sound
    func buttonTap() {
        guard isEnabled else { return }
        playSound(named: "button_tap")
    }
    
    /// Play a message sent sound
    func messageSent() {
        guard isEnabled else { return }
        playSound(named: "message_sent")
    }
    
    /// Play a message received sound
    func messageReceived() {
        guard isEnabled else { return }
        playSound(named: "message_received")
    }
    
    /// Play a connection established sound
    func connectionEstablished() {
        guard isEnabled else { return }
        playSound(named: "connection_established")
    }
    
    /// Play a connection lost sound
    func connectionLost() {
        guard isEnabled else { return }
        playSound(named: "connection_lost")
    }
    
    /// Play a success sound
    func success() {
        guard isEnabled else { return }
        playSound(named: "success")
    }
    
    /// Play an error sound
    func error() {
        guard isEnabled else { return }
        playSound(named: "error")
    }
    
    /// Play a warning sound
    func warning() {
        guard isEnabled else { return }
        playSound(named: "warning")
    }
    
    // MARK: - Implementation
    
    /// Play a sound by name
    /// - Parameter name: The name of the sound file
    private func playSound(named name: String) {
        guard isEnabled else { return }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("Could not find sound file: \(name)")
            return
        }
        
        do {
            soundEffectPlayer = try AVAudioPlayer(contentsOf: url)
            soundEffectPlayer?.volume = 0.5
            soundEffectPlayer?.play()
        } catch {
            print("Could not play sound file: \(error)")
        }
    }
    
    // MARK: - Configuration
    
    /// Enable or disable sound feedback
    /// - Parameter enabled: Whether sound feedback is enabled
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}

// MARK: - Combined Feedback Service

/// A service that provides both haptic and sound feedback
class FeedbackService: ObservableObject {
    // MARK: - Properties
    
    /// The haptic feedback service
    let haptic = HapticFeedback()
    
    /// The sound feedback service
    let sound = SoundFeedback()
    
    /// Whether haptic feedback is enabled
    @Published var hapticsEnabled: Bool = true {
        didSet {
            haptic.setEnabled(hapticsEnabled)
            UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled")
        }
    }
    
    /// Whether sound feedback is enabled
    @Published var soundEnabled: Bool = true {
        didSet {
            sound.setEnabled(soundEnabled)
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize with default settings
    init() {
        // Load user preferences
        hapticsEnabled = UserDefaults.standard.bool(forKey: "hapticsEnabled")
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        
        // Set initial state
        haptic.setEnabled(hapticsEnabled)
        sound.setEnabled(soundEnabled)
    }
    
    // MARK: - Combined Feedback
    
    /// Trigger a success feedback
    func success() {
        haptic.success()
        sound.success()
    }
    
    /// Trigger a warning feedback
    func warning() {
        haptic.warning()
        sound.warning()
    }
    
    /// Trigger an error feedback
    func error() {
        haptic.error()
        sound.error()
    }
    
    /// Trigger a button tap feedback
    func buttonTap() {
        haptic.lightImpact()
        sound.buttonTap()
    }
    
    /// Trigger a message sent feedback
    func messageSent() {
        haptic.messageSent()
        sound.messageSent()
    }
    
    /// Trigger a message received feedback
    func messageReceived() {
        haptic.messageReceived()
        sound.messageReceived()
    }
    
    /// Trigger a connection established feedback
    func connectionEstablished() {
        haptic.connectionEstablished()
        sound.connectionEstablished()
    }
    
    /// Trigger a connection lost feedback
    func connectionLost() {
        haptic.connectionLost()
        sound.connectionLost()
    }
}

// MARK: - SwiftUI Extensions

/// Button with haptic feedback
struct FeedbackButton<Label: View>: View {
    // MARK: - Properties
    
    /// The action to perform
    var action: () -> Void
    
    /// The feedback type
    var feedbackType: FeedbackType
    
    /// The button label
    @ViewBuilder var label: () -> Label
    
    /// The feedback service
    @EnvironmentObject var feedbackService: FeedbackService
    
    // MARK: - Initialization
    
    /// Initialize with action and label
    /// - Parameters:
    ///   - feedbackType: The feedback type
    ///   - action: The action to perform
    ///   - label: The button label
    init(
        feedbackType: FeedbackType = .buttonTap,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.feedbackType = feedbackType
        self.action = action
        self.label = label
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            // Provide feedback
            switch feedbackType {
            case .buttonTap:
                feedbackService.buttonTap()
            case .success:
                feedbackService.success()
            case .warning:
                feedbackService.warning()
            case .error:
                feedbackService.error()
            case .messageSent:
                feedbackService.messageSent()
            case .messageReceived:
                feedbackService.messageReceived()
            case .connectionEstablished:
                feedbackService.connectionEstablished()
            case .connectionLost:
                feedbackService.connectionLost()
            }
            
            // Perform action
            action()
        } label: {
            label()
        }
    }
}

// MARK: - Supporting Types

/// Types of feedback
enum FeedbackType {
    /// Button tap feedback
    case buttonTap
    
    /// Success feedback
    case success
    
    /// Warning feedback
    case warning
    
    /// Error feedback
    case error
    
    /// Message sent feedback
    case messageSent
    
    /// Message received feedback
    case messageReceived
    
    /// Connection established feedback
    case connectionEstablished
    
    /// Connection lost feedback
    case connectionLost
}

// Import AVFoundation for sound playback
#if canImport(AVFoundation)
import AVFoundation
#endif