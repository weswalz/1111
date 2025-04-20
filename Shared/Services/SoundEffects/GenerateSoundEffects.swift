//
//  GenerateSoundEffects.swift
//  LED Messenger
//
//  Created on April 19, 2025
//

import Foundation
import AVFoundation

/// Utility for generating test sound effects
/// This is only used during development to create placeholder sound files
/// Run this in a playground or a command-line tool to generate the sound files
class SoundEffectGenerator {
    
    /// Generate all sound effects
    static func generateAllSoundEffects(outputDirectory: URL) {
        // Create output directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        } catch {
            print("Error creating output directory: \(error.localizedDescription)")
            return
        }
        
        // Generate each sound effect
        for effect in SoundEffect.allCases {
            let outputURL = outputDirectory.appendingPathComponent("\(effect.filename).\(effect.fileExtension)")
            generateSoundEffect(effect: effect, outputURL: outputURL)
        }
    }
    
    /// Generate a specific sound effect
    /// - Parameters:
    ///   - effect: The sound effect to generate
    ///   - outputURL: The output file URL
    static func generateSoundEffect(effect: SoundEffect, outputURL: URL) {
        // Generate different sound profiles based on effect type
        switch effect {
        case .messageSent:
            generateSuccessSound(outputURL: outputURL, duration: 0.3, frequency: 880)
        case .messageCleared:
            generateSuccessSound(outputURL: outputURL, duration: 0.3, frequency: 660)
        case .connectionEstablished:
            generateAscendingSound(outputURL: outputURL, duration: 0.5, startFrequency: 440, endFrequency: 880)
        case .connectionLost:
            generateDescendingSound(outputURL: outputURL, duration: 0.5, startFrequency: 880, endFrequency: 440)
        case .error:
            generateErrorSound(outputURL: outputURL, duration: 0.5)
        case .notification:
            generateNotificationSound(outputURL: outputURL, duration: 0.4)
        case .buttonTap:
            generateClickSound(outputURL: outputURL, duration: 0.1)
        case .success:
            generateSuccessSound(outputURL: outputURL, duration: 0.5, frequency: 660)
        }
    }
    
    // MARK: - Sound Generation Functions
    
    /// Generate a success sound (simple tone)
    /// - Parameters:
    ///   - outputURL: The output file URL
    ///   - duration: The sound duration
    ///   - frequency: The tone frequency
    private static func generateSuccessSound(outputURL: URL, duration: Float64, frequency: Double) {
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let audioFile = try! AVAudioFile(forWriting: outputURL, settings: audioFormat.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(44100 * duration))!
        
        let sampleRate = Float(audioFormat.sampleRate)
        let channelCount = Int(audioFormat.channelCount)
        
        for frame in 0..<Int(44100 * duration) {
            let time = Float(frame) / sampleRate
            let value = Float(sin(2.0 * .pi * Float(frequency) * time))
            
            // Apply fade in/out envelope
            let fadeTime = min(time, Float(duration) - time) * 4 // 0.25s fade in/out
            let envelope = min(1.0, fadeTime / (Float(duration) * 0.25))
            
            for channel in 0..<channelCount {
                buffer.floatChannelData![channel][frame] = value * envelope
            }
        }
        
        buffer.frameLength = AVAudioFrameCount(44100 * duration)
        
        try! audioFile.write(from: buffer)
    }
    
    /// Generate an ascending tone sound
    private static func generateAscendingSound(outputURL: URL, duration: Float64, startFrequency: Double, endFrequency: Double) {
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let audioFile = try! AVAudioFile(forWriting: outputURL, settings: audioFormat.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(44100 * duration))!
        
        let sampleRate = Float(audioFormat.sampleRate)
        let channelCount = Int(audioFormat.channelCount)
        
        for frame in 0..<Int(44100 * duration) {
            let time = Float(frame) / sampleRate
            let timeRatio = time / Float(duration)
            
            // Interpolate frequency based on time
            let frequency = Float(startFrequency) + timeRatio * Float(endFrequency - startFrequency)
            
            let value = Float(sin(2.0 * .pi * frequency * time))
            
            // Apply envelope
            let envelope = min(1.0, 4 * time / Float(duration)) * min(1.0, 4 * (1.0 - timeRatio))
            
            for channel in 0..<channelCount {
                buffer.floatChannelData![channel][frame] = value * envelope
            }
        }
        
        buffer.frameLength = AVAudioFrameCount(44100 * duration)
        
        try! audioFile.write(from: buffer)
    }
    
    /// Generate a descending tone sound
    private static func generateDescendingSound(outputURL: URL, duration: Float64, startFrequency: Double, endFrequency: Double) {
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let audioFile = try! AVAudioFile(forWriting: outputURL, settings: audioFormat.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(44100 * duration))!
        
        let sampleRate = Float(audioFormat.sampleRate)
        let channelCount = Int(audioFormat.channelCount)
        
        for frame in 0..<Int(44100 * duration) {
            let time = Float(frame) / sampleRate
            let timeRatio = time / Float(duration)
            
            // Interpolate frequency based on time
            let frequency = Float(startFrequency) + timeRatio * Float(endFrequency - startFrequency)
            
            let value = Float(sin(2.0 * .pi * frequency * time))
            
            // Apply envelope
            let envelope = min(1.0, 4 * time / Float(duration)) * min(1.0, 4 * (1.0 - timeRatio))
            
            for channel in 0..<channelCount {
                buffer.floatChannelData![channel][frame] = value * envelope
            }
        }
        
        buffer.frameLength = AVAudioFrameCount(44100 * duration)
        
        try! audioFile.write(from: buffer)
    }
    
    /// Generate an error sound (two-tone descending)
    private static func generateErrorSound(outputURL: URL, duration: Float64) {
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let audioFile = try! AVAudioFile(forWriting: outputURL, settings: audioFormat.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(44100 * duration))!
        
        let sampleRate = Float(audioFormat.sampleRate)
        let channelCount = Int(audioFormat.channelCount)
        
        for frame in 0..<Int(44100 * duration) {
            let time = Float(frame) / sampleRate
            let timeRatio = time / Float(duration)
            
            // First half: higher frequency, second half: lower frequency
            let frequency = timeRatio < 0.5 ? 880.0 : 660.0
            
            let value = Float(sin(2.0 * .pi * Float(frequency) * time))
            
            // Apply envelope
            let envelope = min(1.0, 4 * time / Float(duration)) * min(1.0, 4 * (1.0 - timeRatio))
            
            for channel in 0..<channelCount {
                buffer.floatChannelData![channel][frame] = value * envelope
            }
        }
        
        buffer.frameLength = AVAudioFrameCount(44100 * duration)
        
        try! audioFile.write(from: buffer)
    }
    
    /// Generate a notification sound (two ascending tones)
    private static func generateNotificationSound(outputURL: URL, duration: Float64) {
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let audioFile = try! AVAudioFile(forWriting: outputURL, settings: audioFormat.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(44100 * duration))!
        
        let sampleRate = Float(audioFormat.sampleRate)
        let channelCount = Int(audioFormat.channelCount)
        
        for frame in 0..<Int(44100 * duration) {
            let time = Float(frame) / sampleRate
            let timeRatio = time / Float(duration)
            
            // First tone ascending
            let frequency1 = 440.0 + timeRatio * 440.0
            // Second tone a fifth higher
            let frequency2 = 660.0 + timeRatio * 220.0
            
            let value1 = Float(sin(2.0 * .pi * Float(frequency1) * time))
            let value2 = Float(sin(2.0 * .pi * Float(frequency2) * time))
            
            // Mix tones
            let value = 0.7 * value1 + 0.3 * value2
            
            // Apply envelope
            let envelope = min(1.0, 4 * time / Float(duration)) * min(1.0, 4 * (1.0 - timeRatio))
            
            for channel in 0..<channelCount {
                buffer.floatChannelData![channel][frame] = value * envelope
            }
        }
        
        buffer.frameLength = AVAudioFrameCount(44100 * duration)
        
        try! audioFile.write(from: buffer)
    }
    
    /// Generate a click sound for buttons
    private static func generateClickSound(outputURL: URL, duration: Float64) {
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let audioFile = try! AVAudioFile(forWriting: outputURL, settings: audioFormat.settings)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(44100 * duration))!
        
        let sampleRate = Float(audioFormat.sampleRate)
        let channelCount = Int(audioFormat.channelCount)
        
        for frame in 0..<Int(44100 * duration) {
            let time = Float(frame) / sampleRate
            let timeRatio = time / Float(duration)
            
            // Simple click with noise
            var value = Float(sin(2.0 * .pi * 1000.0 * time))
            
            // Add some noise
            let noise = Float.random(in: -0.2...0.2)
            value += noise
            
            // Apply very quick envelope
            let envelope = (1.0 - timeRatio) * (1.0 - timeRatio)
            
            for channel in 0..<channelCount {
                buffer.floatChannelData![channel][frame] = value * envelope
            }
        }
        
        buffer.frameLength = AVAudioFrameCount(44100 * duration)
        
        try! audioFile.write(from: buffer)
    }
}

// Usage example (for development only):
/*
 let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
 let outputDirectory = documentsDirectory.appendingPathComponent("SoundEffects")
 SoundEffectGenerator.generateAllSoundEffects(outputDirectory: outputDirectory)
 */