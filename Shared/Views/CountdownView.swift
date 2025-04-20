//
//  CountdownView.swift
//  LED Messenger
//
//  Created on April 19, 2025
//

import SwiftUI

/// A standalone view for showing a circular countdown animation for messages
public struct CountdownView: View {
    // MARK: - Properties
    
    /// The callback to execute when countdown completes
    let onComplete: () -> Void
    
    /// Duration in seconds (default is 4 minutes)
    let duration: Double
    
    /// Animation state
    @State private var progress: Double = 0.0
    @State private var isPulsing: Bool = false
    
    /// Border appearance
    let strokeWidth: CGFloat = 3.5
    let cornerRadius: CGFloat = 16
    let color: Color
    
    // MARK: - Initialization
    
    /// Create a new countdown view with custom duration and color
    /// - Parameters:
    ///   - duration: Duration in seconds
    ///   - color: Color of the countdown indicator
    ///   - onComplete: Action to perform when countdown finishes
    public init(duration: Double = 240.0, color: Color = .green, onComplete: @escaping () -> Void) {
        self.duration = duration
        self.color = color
        self.onComplete = onComplete
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Base non-animated border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color.opacity(0.3), lineWidth: 1.0)
            
            // Animated countdown border
            RoundedRectangle(cornerRadius: cornerRadius)
                .trim(from: 0, to: CGFloat(1.0 - progress))
                .stroke(
                    color.opacity(isPulsing ? 1.0 : 0.8),
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .rotationEffect(.degrees(-90)) // Start from top
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Timer countdown")
        .accessibilityValue("\(Int((1.0 - progress) * duration)) seconds remaining")
        .onAppear {
            // Start pulsing effect
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            
            // Start countdown animation
            withAnimation(.linear(duration: duration)) {
                progress = 1.0
            }
            
            // Schedule completion callback
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                onComplete()
            }
        }
    }
}

/// Preview for the countdown view
struct CountdownView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default appearance
            CountdownView(onComplete: {})
                .frame(width: 200, height: 200)
                .previewDisplayName("Default")
            
            // Custom color
            CountdownView(duration: 120, color: .blue, onComplete: {})
                .frame(width: 200, height: 200)
                .previewDisplayName("Blue, 2 minutes")
                .preferredColorScheme(.dark)
        }
    }
}