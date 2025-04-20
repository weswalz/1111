//
//  ConfirmationDialog.swift
//  LED Messenger macOS
//
//  Created on April 18, 2025
//

import SwiftUI

/// A confirmation dialog with customizable buttons
struct ConfirmationDialog: View {
    /// The title of the dialog
    let title: String
    
    /// The message to display
    let message: String
    
    /// Whether the dialog is visible
    @Binding var isPresented: Bool
    
    /// The text for the primary button
    var primaryButtonText: String = "OK"
    
    /// The action to perform when the primary button is tapped
    var primaryAction: () -> Void = {}
    
    /// The text for the secondary button
    var secondaryButtonText: String?
    
    /// The action to perform when the secondary button is tapped
    var secondaryAction: () -> Void = {}
    
    /// The text for the cancel button
    var cancelButtonText: String = "Cancel"
    
    /// Whether the primary action is destructive
    var isPrimaryDestructive: Bool = false
    
    /// The icon to display
    var icon: String?
    
    /// The color of the icon
    var iconColor: Color = .blue
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            if let icon = icon {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundColor(iconColor)
                    .padding(.top, 8)
            }
            
            // Title
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            // Buttons
            HStack(spacing: 16) {
                // Cancel button
                Button(cancelButtonText) {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                // Secondary button
                if let secondaryButtonText = secondaryButtonText {
                    Button(secondaryButtonText) {
                        secondaryAction()
                        isPresented = false
                    }
                    .keyboardShortcut(.escape, modifiers: [.command])
                }
                
                // Primary button
                Button(primaryButtonText) {
                    primaryAction()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(isPrimaryDestructive ? .red : .accentColor)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.bottom, 8)
        }
        .padding()
        .frame(minWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

/// A modifier that presents a confirmation dialog
struct ConfirmationDialogModifier: ViewModifier {
    /// The title of the dialog
    let title: String
    
    /// The message to display
    let message: String
    
    /// Whether the dialog is visible
    @Binding var isPresented: Bool
    
    /// The text for the primary button
    var primaryButtonText: String = "OK"
    
    /// The action to perform when the primary button is tapped
    var primaryAction: () -> Void = {}
    
    /// The text for the secondary button
    var secondaryButtonText: String?
    
    /// The action to perform when the secondary button is tapped
    var secondaryAction: () -> Void = {}
    
    /// The text for the cancel button
    var cancelButtonText: String = "Cancel"
    
    /// Whether the primary action is destructive
    var isPrimaryDestructive: Bool = false
    
    /// The icon to display
    var icon: String?
    
    /// The color of the icon
    var iconColor: Color = .blue
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            ZStack {
                if isPresented {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    ConfirmationDialog(
                        title: title,
                        message: message,
                        isPresented: $isPresented,
                        primaryButtonText: primaryButtonText,
                        primaryAction: primaryAction,
                        secondaryButtonText: secondaryButtonText,
                        secondaryAction: secondaryAction,
                        cancelButtonText: cancelButtonText,
                        isPrimaryDestructive: isPrimaryDestructive,
                        icon: icon,
                        iconColor: iconColor
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: isPresented)
        }
    }
}

/// Extension to add confirmation dialog to any view
extension View {
    /// Presents a confirmation dialog when a binding to a Boolean value is true
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the dialog
    ///   - title: The title of the dialog
    ///   - message: The message to display
    ///   - primaryButtonText: The text for the primary button
    ///   - primaryAction: The action to perform when the primary button is tapped
    ///   - secondaryButtonText: The text for the secondary button
    ///   - secondaryAction: The action to perform when the secondary button is tapped
    ///   - cancelButtonText: The text for the cancel button
    ///   - isPrimaryDestructive: Whether the primary action is destructive
    ///   - icon: The icon to display
    ///   - iconColor: The color of the icon
    /// - Returns: A view with a confirmation dialog
    func confirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        primaryButtonText: String = "OK",
        primaryAction: @escaping () -> Void = {},
        secondaryButtonText: String? = nil,
        secondaryAction: @escaping () -> Void = {},
        cancelButtonText: String = "Cancel",
        isPrimaryDestructive: Bool = false,
        icon: String? = nil,
        iconColor: Color = .blue
    ) -> some View {
        self.modifier(
            ConfirmationDialogModifier(
                title: title,
                message: message,
                isPresented: isPresented,
                primaryButtonText: primaryButtonText,
                primaryAction: primaryAction,
                secondaryButtonText: secondaryButtonText,
                secondaryAction: secondaryAction,
                cancelButtonText: cancelButtonText,
                isPrimaryDestructive: isPrimaryDestructive,
                icon: icon,
                iconColor: iconColor
            )
        )
    }
}

#Preview {
    VStack {
        Text("Content behind the dialog")
            .font(.title)
        
        Spacer()
    }
    .frame(width: 600, height: 400)
    .confirmationDialog(
        isPresented: .constant(true),
        title: "Delete Message?",
        message: "Are you sure you want to delete this message? This action cannot be undone.",
        primaryButtonText: "Delete",
        primaryAction: {},
        secondaryButtonText: "Archive Instead",
        secondaryAction: {},
        cancelButtonText: "Cancel",
        isPrimaryDestructive: true,
        icon: "trash",
        iconColor: .red
    )
}