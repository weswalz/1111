//
//  NotificationBanner.swift
//  LED Messenger macOS
//
//  Created on April 18, 2025
//

import SwiftUI

/// The type of notification to display
enum NotificationType {
    /// An informational notification
    case info
    /// A success notification
    case success
    /// A warning notification
    case warning
    /// An error notification
    case error
    
    /// The color associated with this notification type
    var color: Color {
        switch self {
        case .info:
            return Color.blue
        case .success:
            return Color.green
        case .warning:
            return Color.yellow
        case .error:
            return Color.red
        }
    }
    
    /// The icon associated with this notification type
    var icon: String {
        switch self {
        case .info:
            return "info.circle"
        case .success:
            return "checkmark.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        }
    }
}

/// A banner notification that appears at the top of the window
struct NotificationBanner: View {
    /// The message to display
    let message: String
    
    /// The type of notification
    let type: NotificationType
    
    /// Whether the notification is visible
    @Binding var isVisible: Bool
    
    /// The duration to show the notification for (in seconds)
    var duration: Double = 3.0
    
    /// Whether to show a dismiss button
    var showDismissButton: Bool = true
    
    /// Whether the notification has been shown
    @State private var hasAppeared = false
    
    /// The opacity of the notification
    @State private var opacity: Double = 0.0
    
    /// The Y offset of the notification
    @State private var yOffset: CGFloat = -100
    
    var body: some View {
        HStack {
            Image(systemName: type.icon)
                .foregroundColor(.white)
                .imageScale(.large)
            
            Text(message)
                .foregroundColor(.white)
                .font(.body)
            
            Spacer()
            
            if showDismissButton {
                Button {
                    hideNotification()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.7))
                        .imageScale(.small)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(type.color)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        .opacity(opacity)
        .offset(y: yOffset)
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                showNotification()
                
                if duration > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        hideNotification()
                    }
                }
            }
        }
    }
    
    /// Shows the notification with animation
    private func showNotification() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 1.0
            yOffset = 0
        }
    }
    
    /// Hides the notification with animation
    private func hideNotification() {
        withAnimation(.easeIn(duration: 0.3)) {
            opacity = 0.0
            yOffset = -100
        }
        
        // Set isVisible to false after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isVisible = false
        }
    }
}

/// A container for managing notification banners
struct NotificationContainer: View {
    /// The currently visible notifications
    @State private var notifications: [UUID: (String, NotificationType, Bool)] = [:]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(notifications.keys), id: \.self) { id in
                if let notification = notifications[id] {
                    NotificationBanner(
                        message: notification.0,
                        type: notification.1,
                        isVisible: Binding(
                            get: { notifications[id] != nil },
                            set: { if !$0 { notifications.removeValue(forKey: id) } }
                        ),
                        showDismissButton: notification.2
                    )
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    /// Shows a notification
    /// - Parameters:
    ///   - message: The message to display
    ///   - type: The type of notification
    ///   - duration: The duration to show the notification (in seconds)
    ///   - showDismissButton: Whether to show a dismiss button
    /// - Returns: A unique identifier for the notification
    func show(
        message: String,
        type: NotificationType = .info,
        duration: Double = 3.0,
        showDismissButton: Bool = true
    ) -> UUID {
        let id = UUID()
        notifications[id] = (message, type, showDismissButton)
        
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                notifications.removeValue(forKey: id)
            }
        }
        
        return id
    }
    
    /// Dismisses a notification
    /// - Parameter id: The identifier of the notification to dismiss
    func dismiss(id: UUID) {
        notifications.removeValue(forKey: id)
    }
    
    /// Dismisses all notifications
    func dismissAll() {
        notifications.removeAll()
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        
        VStack {
            Spacer()
            
            Button("Show Info") {
                // This would be handled by an observed object in a real implementation
            }
            
            Button("Show Success") {
                // This would be handled by an observed object in a real implementation
            }
            
            Button("Show Warning") {
                // This would be handled by an observed object in a real implementation
            }
            
            Button("Show Error") {
                // This would be handled by an observed object in a real implementation
            }
            
            Spacer()
        }
        
        VStack {
            NotificationBanner(
                message: "This is an info message",
                type: .info,
                isVisible: .constant(true)
            )
            
            NotificationBanner(
                message: "This is a success message",
                type: .success,
                isVisible: .constant(true)
            )
            
            NotificationBanner(
                message: "This is a warning message",
                type: .warning,
                isVisible: .constant(true)
            )
            
            NotificationBanner(
                message: "This is an error message",
                type: .error,
                isVisible: .constant(true)
            )
            
            Spacer()
        }
        .padding()
    }
}