//
//  AnimatedTransitions.swift
//  LED Messenger
//
//  Created on April 18, 2025
//

import SwiftUI

// MARK: - Custom Transitions

/// A transition that slides and fades in from the side
struct SlideWithOpacity: ViewModifier {
    /// The animation state
    let isActive: Bool
    
    /// The edge to slide from
    let edge: Edge
    
    /// The offset amount
    let offset: CGFloat
    
    /// The animation
    let animation: Animation
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(
                x: edge == .leading ? (isActive ? 0 : -offset) : 
                   edge == .trailing ? (isActive ? 0 : offset) : 0,
                y: edge == .top ? (isActive ? 0 : -offset) : 
                   edge == .bottom ? (isActive ? 0 : offset) : 0
            )
            .animation(animation, value: isActive)
    }
}

/// A transition that scales and fades in
struct ScaleWithOpacity: ViewModifier {
    /// The animation state
    let isActive: Bool
    
    /// The scale to start from
    let scale: CGFloat
    
    /// The animation
    let animation: Animation
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : scale)
            .animation(animation, value: isActive)
    }
}

/// A transition that flips the view
struct FlipTransition: ViewModifier {
    /// The animation state
    let isActive: Bool
    
    /// The axis to flip around
    let axis: Axis
    
    /// The animation
    let animation: Animation
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isActive ? 0 : 180),
                axis: axis == .horizontal ? (0, 1, 0) : (1, 0, 0),
                anchor: .center
            )
            .opacity(isActive ? 1 : 0)
            .animation(animation, value: isActive)
    }
}

/// A transition that bounces in
struct BounceTransition: ViewModifier {
    /// The animation state
    let isActive: Bool
    
    /// The edge to bounce from
    let edge: Edge
    
    /// The offset amount
    let offset: CGFloat
    
    /// The animation
    let animation: Animation
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(
                x: edge == .leading ? (isActive ? 0 : -offset) : 
                   edge == .trailing ? (isActive ? 0 : offset) : 0,
                y: edge == .top ? (isActive ? 0 : -offset) : 
                   edge == .bottom ? (isActive ? 0 : offset) : 0
            )
            .animation(animation, value: isActive)
    }
}

// MARK: - Extensions for Standard Transitions

extension AnyTransition {
    /// A slide transition with opacity
    /// - Parameters:
    ///   - edge: The edge to slide from
    ///   - offset: The offset amount
    /// - Returns: The transition
    static func slideWithOpacity(edge: Edge, offset: CGFloat = 50) -> AnyTransition {
        AnyTransition.asymmetric(
            insertion: .opacity.combined(with: .move(edge: edge)),
            removal: .opacity.combined(with: .move(edge: edge))
        )
    }
    
    /// A scale transition with opacity
    /// - Parameter scale: The scale to start from
    /// - Returns: The transition
    static func scaleWithOpacity(scale: CGFloat = 0.8) -> AnyTransition {
        AnyTransition.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: scale)),
            removal: .opacity.combined(with: .scale(scale: scale))
        )
    }
    
    /// A flip transition
    /// - Parameter axis: The axis to flip around
    /// - Returns: The transition
    static func flip(axis: Axis = .horizontal) -> AnyTransition {
        AnyTransition.modifier(
            active: FlipModifier(axis: axis, rotation: 180),
            identity: FlipModifier(axis: axis, rotation: 0)
        )
    }
    
    /// A bounce transition
    /// - Parameter edge: The edge to bounce from
    /// - Returns: The transition
    static func bounce(edge: Edge) -> AnyTransition {
        AnyTransition.asymmetric(
            insertion: .spring(edge: edge),
            removal: .opacity.combined(with: .move(edge: edge))
        )
    }
    
    /// A spring transition from an edge
    /// - Parameter edge: The edge to spring from
    /// - Returns: The transition
    private static func spring(edge: Edge) -> AnyTransition {
        AnyTransition.modifier(
            active: SpringModifier(edge: edge, offset: 50),
            identity: SpringModifier(edge: edge, offset: 0)
        )
    }
}

// MARK: - Helper Modifier Types

/// A flip modifier
struct FlipModifier: ViewModifier {
    /// The axis to flip around
    let axis: Axis
    
    /// The rotation amount
    let rotation: Double
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotation),
                axis: axis == .horizontal ? (0, 1, 0) : (1, 0, 0),
                anchor: .center
            )
            .opacity(rotation == 0 ? 1 : 0)
    }
}

/// A spring modifier
struct SpringModifier: ViewModifier {
    /// The edge to spring from
    let edge: Edge
    
    /// The offset amount
    let offset: CGFloat
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? -offset : 
                   edge == .trailing ? offset : 0,
                y: edge == .top ? -offset : 
                   edge == .bottom ? offset : 0
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply a slide transition with opacity
    /// - Parameters:
    ///   - isActive: The animation state
    ///   - edge: The edge to slide from
    ///   - offset: The offset amount
    ///   - animation: The animation
    /// - Returns: The modified view
    func slideWithOpacity(
        isActive: Bool,
        edge: Edge,
        offset: CGFloat = 50,
        animation: Animation = .easeOut(duration: 0.3)
    ) -> some View {
        modifier(SlideWithOpacity(
            isActive: isActive,
            edge: edge,
            offset: offset,
            animation: animation
        ))
    }
    
    /// Apply a scale transition with opacity
    /// - Parameters:
    ///   - isActive: The animation state
    ///   - scale: The scale to start from
    ///   - animation: The animation
    /// - Returns: The modified view
    func scaleWithOpacity(
        isActive: Bool,
        scale: CGFloat = 0.8,
        animation: Animation = .easeOut(duration: 0.3)
    ) -> some View {
        modifier(ScaleWithOpacity(
            isActive: isActive,
            scale: scale,
            animation: animation
        ))
    }
    
    /// Apply a flip transition
    /// - Parameters:
    ///   - isActive: The animation state
    ///   - axis: The axis to flip around
    ///   - animation: The animation
    /// - Returns: The modified view
    func flip(
        isActive: Bool,
        axis: Axis = .horizontal,
        animation: Animation = .easeInOut(duration: 0.5)
    ) -> some View {
        modifier(FlipTransition(
            isActive: isActive,
            axis: axis,
            animation: animation
        ))
    }
    
    /// Apply a bounce transition
    /// - Parameters:
    ///   - isActive: The animation state
    ///   - edge: The edge to bounce from
    ///   - offset: The offset amount
    ///   - animation: The animation
    /// - Returns: The modified view
    func bounce(
        isActive: Bool,
        edge: Edge,
        offset: CGFloat = 50,
        animation: Animation = .spring(response: 0.3, dampingFraction: 0.6)
    ) -> some View {
        modifier(BounceTransition(
            isActive: isActive,
            edge: edge,
            offset: offset,
            animation: animation
        ))
    }
}