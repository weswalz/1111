//
//  TooltipView.swift
//  LED Messenger
//
//  Created on April 19, 2025
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Tooltip view for displaying information when hovering over an element
public struct TooltipView<Content: View>: View {
    // MARK: - Properties
    
    /// The content of the tooltip
    let content: Content
    
    /// The background color of the tooltip
    let backgroundColor: Color
    
    /// The text color of the tooltip
    let textColor: Color
    
    /// The arrow position
    let arrowPosition: ArrowPosition
    
    /// Whether the tooltip has a shadow
    let hasShadow: Bool
    
    /// The corner radius of the tooltip
    let cornerRadius: CGFloat
    
    /// The padding of the tooltip content
    let contentPadding: EdgeInsets
    
    /// The direction of the tooltip
    let direction: TooltipDirection
    
    // MARK: - Initialization
    
    /// Initialize with content
    /// - Parameters:
    ///   - content: The content to display
    ///   - backgroundColor: The background color
    ///   - textColor: The text color
    ///   - arrowPosition: The arrow position
    ///   - hasShadow: Whether to show a shadow
    ///   - cornerRadius: The corner radius
    ///   - contentPadding: The content padding
    ///   - direction: The tooltip direction
    public init(
        @ViewBuilder content: () -> Content,
        backgroundColor: Color = Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.9),
        textColor: Color = .primary,
        arrowPosition: ArrowPosition = .middle,
        hasShadow: Bool = true,
        cornerRadius: CGFloat = 8,
        contentPadding: EdgeInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12),
        direction: TooltipDirection = .top
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.arrowPosition = arrowPosition
        self.hasShadow = hasShadow
        self.cornerRadius = cornerRadius
        self.contentPadding = contentPadding
        self.direction = direction
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Background with arrow
            TooltipShape(
                arrowPosition: arrowPosition,
                cornerRadius: cornerRadius,
                direction: direction
            )
            .fill(backgroundColor)
            
            // Content
            content
                .foregroundColor(textColor)
                .padding(contentPadding)
        }
        .compositingGroup() // Group for better shadow performance
        .modifier(ShadowModifier(hasShadow: hasShadow))
    }
}

// MARK: - Shadow Modifier
struct ShadowModifier: ViewModifier {
    let hasShadow: Bool
    
    func body(content: Content) -> some View {
        if hasShadow {
            content.shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        } else {
            content
        }
    }
}

// MARK: - Tooltip Arrow Position

/// Position of the tooltip arrow
public enum ArrowPosition {
    /// At the start of the tooltip
    case start
    
    /// In the middle of the tooltip
    case middle
    
    /// At the end of the tooltip
    case end
    
    /// At a specific percentage (0-1) along the tooltip
    case custom(CGFloat)
}

// MARK: - Tooltip Direction

/// Direction of the tooltip
public enum TooltipDirection {
    /// Above the element
    case top
    
    /// Below the element
    case bottom
    
    /// To the left of the element
    case left
    
    /// To the right of the element
    case right
}

// MARK: - Tooltip Shape

/// Shape for the tooltip with an arrow
struct TooltipShape: Shape {
    // MARK: - Properties
    
    /// The position of the arrow
    let arrowPosition: ArrowPosition
    
    /// The corner radius
    let cornerRadius: CGFloat
    
    /// The direction of the tooltip
    let direction: TooltipDirection
    
    /// The size of the arrow
    private let arrowSize: CGFloat = 8
    
    // MARK: - Path
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Calculate arrow position
        let arrowOffset: CGFloat
        switch arrowPosition {
        case .start:
            arrowOffset = cornerRadius * 2
        case .middle:
            arrowOffset = rect.width / 2
        case .end:
            arrowOffset = rect.width - (cornerRadius * 2)
        case .custom(let percentage):
            arrowOffset = rect.width * max(0, min(1, percentage))
        }
        
        switch direction {
        case .top:
            path = topDirectionPath(rect: rect, arrowOffset: arrowOffset)
        case .bottom:
            path = bottomDirectionPath(rect: rect, arrowOffset: arrowOffset)
        case .left:
            path = leftDirectionPath(rect: rect, arrowOffset: arrowOffset)
        case .right:
            path = rightDirectionPath(rect: rect, arrowOffset: arrowOffset)
        }
        
        return path
    }
    
    // MARK: - Path Builders
    
    /// Build a path for a tooltip pointing up
    private func topDirectionPath(rect: CGRect, arrowOffset: CGFloat) -> Path {
        var path = Path()
        
        // Start at the arrow tip
        let safeArrowOffset = min(max(arrowOffset, cornerRadius + arrowSize), rect.width - cornerRadius - arrowSize)
        
        // Top side with arrow
        path.move(to: CGPoint(x: safeArrowOffset - arrowSize, y: arrowSize))
        path.addLine(to: CGPoint(x: safeArrowOffset, y: 0))
        path.addLine(to: CGPoint(x: safeArrowOffset + arrowSize, y: arrowSize))
        
        // Rest of the outline
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: arrowSize))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: arrowSize + cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        
        path.addLine(to: CGPoint(x: 0, y: arrowSize + cornerRadius))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: arrowSize + cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        
        path.addLine(to: CGPoint(x: safeArrowOffset - arrowSize, y: arrowSize))
        
        return path
    }
    
    /// Build a path for a tooltip pointing down
    private func bottomDirectionPath(rect: CGRect, arrowOffset: CGFloat) -> Path {
        var path = Path()
        
        // Start at top left corner
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - arrowSize - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: rect.height - arrowSize - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        
        // Bottom edge with arrow
        let safeArrowOffset = min(max(arrowOffset, cornerRadius + arrowSize), rect.width - cornerRadius - arrowSize)
        path.addLine(to: CGPoint(x: safeArrowOffset + arrowSize, y: rect.height - arrowSize))
        path.addLine(to: CGPoint(x: safeArrowOffset, y: rect.height))
        path.addLine(to: CGPoint(x: safeArrowOffset - arrowSize, y: rect.height - arrowSize))
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height - arrowSize))
        
        // Left edge
        path.addArc(
            center: CGPoint(x: cornerRadius, y: rect.height - arrowSize - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        
        return path
    }
    
    /// Build a path for a tooltip pointing left
    private func leftDirectionPath(rect: CGRect, arrowOffset: CGFloat) -> Path {
        var path = Path()
        
        // Safe arrow offset based on height for left/right
        let safeArrowOffset = min(max(arrowOffset, cornerRadius + arrowSize), rect.height - cornerRadius - arrowSize)
        
        // Start at the arrow tip
        path.move(to: CGPoint(x: 0, y: safeArrowOffset))
        path.addLine(to: CGPoint(x: arrowSize, y: safeArrowOffset - arrowSize))
        path.addLine(to: CGPoint(x: arrowSize, y: cornerRadius))
        
        // Top edge
        path.addArc(
            center: CGPoint(x: arrowSize + cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        
        // Right edge
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 270),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        
        // Bottom edge
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: arrowSize + cornerRadius, y: rect.height))
        
        // Left edge with arrow
        path.addArc(
            center: CGPoint(x: arrowSize + cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: arrowSize, y: safeArrowOffset + arrowSize))
        path.addLine(to: CGPoint(x: 0, y: safeArrowOffset))
        
        return path
    }
    
    /// Build a path for a tooltip pointing right
    private func rightDirectionPath(rect: CGRect, arrowOffset: CGFloat) -> Path {
        var path = Path()
        
        // Safe arrow offset based on height for left/right
        let safeArrowOffset = min(max(arrowOffset, cornerRadius + arrowSize), rect.height - cornerRadius - arrowSize)
        
        // Start at top left
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.width - arrowSize - cornerRadius, y: 0))
        path.addArc(
            center: CGPoint(x: rect.width - arrowSize - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 270),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        
        // Right edge with arrow
        path.addLine(to: CGPoint(x: rect.width - arrowSize, y: safeArrowOffset - arrowSize))
        path.addLine(to: CGPoint(x: rect.width, y: safeArrowOffset))
        path.addLine(to: CGPoint(x: rect.width - arrowSize, y: safeArrowOffset + arrowSize))
        path.addLine(to: CGPoint(x: rect.width - arrowSize, y: rect.height - cornerRadius))
        
        // Bottom edge
        path.addArc(
            center: CGPoint(x: rect.width - arrowSize - cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        
        // Left edge
        path.addArc(
            center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        
        return path
    }
}

// MARK: - Tooltip Modifier

/// View modifier to add a tooltip to a view
public struct TooltipModifier: ViewModifier {
    // MARK: - Properties
    
    /// The tooltip text
    let text: String
    
    /// The tooltip position
    let position: TooltipDirection
    
    /// Whether the tooltip is always visible
    let alwaysVisible: Bool
    
    /// The background color
    let backgroundColor: Color
    
    /// The text color
    let textColor: Color
    
    /// The arrow position
    let arrowPosition: ArrowPosition
    
    /// State for whether the tooltip is visible
    @State private var isVisible = false
    
    /// Settings manager to check if tooltips are enabled
    @EnvironmentObject var settingsManager: SettingsManager
    
    // MARK: - Body
    
    public func body(content: Content) -> some View {
        ZStack(alignment: alignmentForPosition) {
            content
                #if os(macOS)
                .onHover { hovering in
                    if alwaysVisible {
                        isVisible = true
                    } else if settingsManager.settings.uiSettings.showTooltips {
                        isVisible = hovering
                    }
                }
                #else
                .onTapGesture {
                    if settingsManager.settings.uiSettings.showTooltips && !alwaysVisible {
                        withAnimation {
                            isVisible.toggle()
                        }
                        
                        // Auto-hide after 3 seconds
                        if isVisible {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    isVisible = false
                                }
                            }
                        }
                    }
                }
                #endif
            
            if isVisible || alwaysVisible {
                TooltipView(
                    content: {
                        Text(text)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                    },
                    backgroundColor: backgroundColor,
                    textColor: textColor,
                    arrowPosition: arrowPosition,
                    direction: position
                )
                .fixedSize()
                .padding(paddingForPosition)
                .offset(offsetForPosition)
                .transition(transitionForPosition)
                .zIndex(1)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// Get the alignment based on the tooltip position
    private var alignmentForPosition: Alignment {
        switch position {
        case .top: return .top
        case .bottom: return .bottom
        case .left: return .leading
        case .right: return .trailing
        }
    }
    
    /// Get the padding based on the tooltip position
    private var paddingForPosition: EdgeInsets {
        switch position {
        case .top: return EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0)
        case .bottom: return EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)
        case .left: return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)
        case .right: return EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0)
        }
    }
    
    /// Get the offset based on the tooltip position
    private var offsetForPosition: CGSize {
        switch position {
        case .top: return CGSize(width: 0, height: -8)
        case .bottom: return CGSize(width: 0, height: 8)
        case .left: return CGSize(width: -8, height: 0)
        case .right: return CGSize(width: 8, height: 0)
        }
    }
    
    /// Get the transition based on the tooltip position
    private var transitionForPosition: AnyTransition {
        switch position {
        case .top: return .offset(y: -8).combined(with: .opacity)
        case .bottom: return .offset(y: 8).combined(with: .opacity)
        case .left: return .offset(x: -8).combined(with: .opacity)
        case .right: return .offset(x: 8).combined(with: .opacity)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Add a tooltip to a view with a specific position
    /// - Parameters:
    ///   - text: The tooltip text
    ///   - position: The tooltip position
    ///   - alwaysVisible: Whether the tooltip is always visible
    ///   - backgroundColor: The background color
    ///   - textColor: The text color
    ///   - arrowPosition: The arrow position
    /// - Returns: The view with a tooltip
    public func tooltip(
        _ text: String,
        position: TooltipDirection = .top,
        alwaysVisible: Bool = false,
        backgroundColor: Color = Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.9),
        textColor: Color = .primary,
        arrowPosition: ArrowPosition = .middle
    ) -> some View {
        self.modifier(
            TooltipModifier(
                text: text,
                position: position,
                alwaysVisible: alwaysVisible,
                backgroundColor: backgroundColor,
                textColor: textColor,
                arrowPosition: arrowPosition
            )
        )
    }
    
    /// Apply a modifier conditionally
    /// - Parameters:
    ///   - condition: The condition to check
    ///   - transform: The transform to apply if the condition is true
    /// - Returns: The transformed view if the condition is true, otherwise the original view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Previews

struct TooltipView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Top tooltip
            VStack {
                Spacer()
                
                TooltipView(content: {
                    Text("This is a tooltip pointing up")
                })
                .previewDisplayName("Top Tooltip")
                
                Button("Hover Me") {}
                    .buttonStyle(.bordered)
                
                Spacer()
            }
            
            // Bottom tooltip
            VStack {
                Spacer()
                
                Button("Hover Me") {}
                    .buttonStyle(.bordered)
                
                TooltipView(
                    content: {
                        Text("This is a tooltip pointing down")
                    },
                    direction: .bottom
                )
                .previewDisplayName("Bottom Tooltip")
                
                Spacer()
            }
            
            // Left tooltip
            HStack {
                Spacer()
                
                TooltipView(
                    content: {
                        Text("This is a tooltip pointing left")
                    },
                    direction: .left
                )
                .previewDisplayName("Left Tooltip")
                
                Button("Hover Me") {}
                    .buttonStyle(.bordered)
                
                Spacer()
            }
            
            // Right tooltip
            HStack {
                Spacer()
                
                Button("Hover Me") {}
                    .buttonStyle(.bordered)
                
                TooltipView(
                    content: {
                        Text("This is a tooltip pointing right")
                    },
                    direction: .right
                )
                .previewDisplayName("Right Tooltip")
                
                Spacer()
            }
            
            // Modifier example
            Button("Button with Tooltip") {}
                .buttonStyle(.bordered)
                .tooltip("This is a button with a tooltip")
                .previewDisplayName("Tooltip Modifier")
        }
        .padding(50)
        .environmentObject(SettingsManager())
    }
}