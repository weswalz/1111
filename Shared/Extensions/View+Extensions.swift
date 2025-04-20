//
//  View+Extensions.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import SwiftUI

// MARK: - View Modifiers

extension View {
    
    /// Apply a conditional modifier to the view
    /// - Parameters:
    ///   - condition: The condition to evaluate
    ///   - transform: The modifier to apply if the condition is true
    /// - Returns: The modified view if the condition is true, otherwise the original view
    @ViewBuilder
    public func conditionalModifier<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply different modifiers based on a condition
    /// - Parameters:
    ///   - condition: The condition to evaluate
    ///   - ifTransform: The modifier to apply if the condition is true
    ///   - elseTransform: The modifier to apply if the condition is false
    /// - Returns: The modified view based on the condition
    @ViewBuilder
    public func conditionalContent<TrueContent: View, FalseContent: View>(
        _ condition: @autoclosure () -> Bool,
        ifTrue: (Self) -> TrueContent,
        ifFalse: (Self) -> FalseContent
    ) -> some View {
        if condition() {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }
    
    /// Applies the given transform if the given value exists
    /// - Parameters:
    ///   - value: The optional value
    ///   - transform: The transform to apply if the value is not nil
    /// - Returns: The transformed view if the value exists, otherwise the original view
    @ViewBuilder
    public func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
    
    /// Apply a fixed frame size to the view
    /// - Parameter size: The size to apply
    /// - Returns: The view with the fixed frame
    public func frame(size: CGFloat) -> some View {
        self.frame(width: size, height: size)
    }
    
    /// Apply standard card styling
    /// - Parameters:
    ///   - backgroundColor: The background color for the card
    ///   - cornerRadius: The corner radius for the card
    ///   - shadowRadius: The shadow radius for the card
    /// - Returns: The styled view
    public func cardStyle(
        backgroundColor: Color = AppConstants.Colors.surface,
        cornerRadius: CGFloat = AppConstants.UI.cornerRadius,
        shadowRadius: CGFloat = 4
    ) -> some View {
        self
            .padding(AppConstants.UI.standardPadding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(radius: shadowRadius)
    }
    
    /// Apply responsive padding that adapts to screen size
    /// - Parameter edges: The edges to apply padding to
    /// - Returns: The padded view
    public func responsivePadding(_ edges: Edge.Set = .all) -> some View {
        #if os(iOS)
        let horizontalPadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 
            AppConstants.UI.largePadding : AppConstants.UI.standardPadding
        let verticalPadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 
            AppConstants.UI.standardPadding : AppConstants.UI.smallPadding
        #else
        let horizontalPadding: CGFloat = AppConstants.UI.standardPadding
        let verticalPadding: CGFloat = AppConstants.UI.standardPadding
        #endif
        
        return self.padding(
            EdgeInsets(
                top: edges.contains(.top) ? verticalPadding : 0,
                leading: edges.contains(.leading) ? horizontalPadding : 0,
                bottom: edges.contains(.bottom) ? verticalPadding : 0,
                trailing: edges.contains(.trailing) ? horizontalPadding : 0
            )
        )
    }
    
    /// Apply a minimum tap target size to a view
    /// - Parameter size: The minimum size
    /// - Returns: The modified view
    public func minimumTapTarget(size: CGFloat = AppConstants.UI.minimumTouchTarget) -> some View {
        self.frame(minWidth: size, minHeight: size)
    }
    
    /// Add a standard close button to a view
    /// - Parameter action: The action to perform when the button is tapped
    /// - Returns: The view with a close button
    public func withCloseButton(action: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            self
            
            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding(AppConstants.UI.smallPadding)
                    .minimumTapTarget()
            }
        }
    }
    
    /// Apply a centered loading overlay with optional text
    /// - Parameters:
    ///   - isLoading: Whether the overlay is visible
    ///   - text: Optional text to display
    /// - Returns: The view with a loading overlay if applicable
    public func loadingOverlay(isLoading: Bool, text: String? = nil) -> some View {
        ZStack {
            self
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)
            
            if isLoading {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        if let text = text {
                            Text(text)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(AppConstants.UI.largePadding)
                    .background(AppConstants.Colors.surface)
                    .cornerRadius(AppConstants.UI.cornerRadius)
                    .shadow(radius: 10)
                }
                .transition(.opacity)
            }
        }
    }
    
    /// Set the horizontal alignment of a view
    /// - Parameter alignment: The alignment to apply
    /// - Returns: The aligned view
    public func horizontalAlignment(_ alignment: HorizontalAlignment) -> some View {
        HStack {
            switch alignment {
            case .leading:
                self
                Spacer()
                
            case .center:
                Spacer()
                self
                Spacer()
                
            case .trailing:
                Spacer()
                self
                
            default:
                self
            }
        }
    }
    
    /// Set the vertical alignment of a view
    /// - Parameter alignment: The alignment to apply
    /// - Returns: The aligned view
    public func verticalAlignment(_ alignment: VerticalAlignment) -> some View {
        VStack {
            switch alignment {
            case .top:
                self
                Spacer()
                
            case .center:
                Spacer()
                self
                Spacer()
                
            case .bottom:
                Spacer()
                self
                
            default:
                self
            }
        }
    }
    
    /// Apply a color-adjustable border to a view
    /// - Parameters:
    ///   - content: The border color
    ///   - width: The border width
    ///   - cornerRadius: The corner radius
    /// - Returns: The view with a border
    public func border<S>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat = AppConstants.UI.cornerRadius) -> some View where S: ShapeStyle {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(content, lineWidth: width)
        )
    }
}

// MARK: - Platform-Specific Extensions

#if os(macOS)
extension View {
    /// Apply a hover effect to a macOS view
    /// - Parameters:
    ///   - isHovered: Binding to track hover state
    ///   - transform: Transform to apply when hovered
    /// - Returns: The view with hover effect
    public func hoverEffect<Content: View>(
        isHovered: Binding<Bool>,
        transform: @escaping (Self) -> Content
    ) -> some View {
        self
            .onHover { hovering in
                isHovered.wrappedValue = hovering
            }
            .conditionalModifier(isHovered.wrappedValue) { view in
                transform(view)
            }
    }
}
#endif

#if os(iOS)
extension View {
    /// Hide the keyboard when tapping outside an input field
    public func hideKeyboardWhenTappedAround() -> some View {
        return self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    /// Add an adaptive navigation title that changes based on size class
    /// - Parameters:
    ///   - title: The title to display
    ///   - displayMode: The display mode for regular width
    /// - Returns: The view with an adaptive title
    public func adaptiveNavigationTitle(
        _ title: String,
        displayMode: NavigationBarItem.TitleDisplayMode = .automatic
    ) -> some View {
        self.modifier(AdaptiveNavigationTitleModifier(title: title, displayMode: displayMode))
    }
}

/// Modifier to adapt navigation title based on size class
struct AdaptiveNavigationTitleModifier: ViewModifier {
    let title: String
    let displayMode: NavigationBarItem.TitleDisplayMode
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(horizontalSizeClass == .compact ? .inline : displayMode)
    }
}
#endif
