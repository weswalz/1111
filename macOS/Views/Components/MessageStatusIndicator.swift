//
//  MessageStatusIndicator.swift
//  LED Messenger macOS
//
//  Created on April 18, 2025
//

import SwiftUI

/// Represents the different states a message can be in
enum MessageDeliveryStatus {
    /// The message is being prepared to send
    case preparing
    /// The message is being sent
    case sending
    /// The message was successfully sent
    case sent
    /// The message failed to send
    case failed
    /// The message is waiting in queue
    case queued
    
    /// The color associated with this status
    var color: Color {
        switch self {
        case .preparing:
            return .yellow
        case .sending:
            return .blue
        case .sent:
            return .green
        case .failed:
            return .red
        case .queued:
            return .gray
        }
    }
    
    /// The icon associated with this status
    var icon: String {
        switch self {
        case .preparing:
            return "ellipsis"
        case .sending:
            return "arrow.up.circle"
        case .sent:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.circle"
        case .queued:
            return "clock"
        }
    }
    
    /// The label text associated with this status
    var label: String {
        switch self {
        case .preparing:
            return "Preparing"
        case .sending:
            return "Sending"
        case .sent:
            return "Sent"
        case .failed:
            return "Failed"
        case .queued:
            return "Queued"
        }
    }
}

/// A view that displays the status of a message
struct MessageStatusIndicator: View {
    /// The status to display
    let status: MessageDeliveryStatus
    
    /// Whether to show the label
    var showLabel: Bool = false
    
    /// The size of the indicator
    var size: CGFloat = 16
    
    /// Whether the indicator should animate
    var animate: Bool = false
    
    /// The current rotation angle for animation
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(status.color)
                .rotationEffect(.degrees(animate && status == .sending ? rotationAngle : 0))
                .onAppear {
                    if animate && status == .sending {
                        withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
                }
            
            if showLabel {
                Text(status.label)
                    .font(.system(size: size * 0.8))
                    .foregroundColor(status.color)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MessageStatusIndicator(status: .preparing, showLabel: true)
        MessageStatusIndicator(status: .sending, showLabel: true, animate: true)
        MessageStatusIndicator(status: .sent, showLabel: true)
        MessageStatusIndicator(status: .failed, showLabel: true)
        MessageStatusIndicator(status: .queued, showLabel: true)
    }
    .padding()
}