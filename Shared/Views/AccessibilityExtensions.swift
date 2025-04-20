//
//  AccessibilityExtensions.swift
//  LED Messenger
//
//  Created on April 18, 2025
//

import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    /// Add accessibility value with numeric formatting
    /// - Parameters:
    ///   - value: The numeric value
    ///   - unit: The unit of the value
    ///   - formatter: The formatter to use
    /// - Returns: The modified view
    func accessibilityValue<T: Numeric>(
        _ value: T,
        unit: String? = nil,
        formatter: NumberFormatter? = nil
    ) -> some View {
        let formattedValue: String
        
        if let formatter = formatter {
            formattedValue = formatter.string(from: NSNumber(value: Double("\(value)") ?? 0)) ?? "\(value)"
        } else {
            formattedValue = "\(value)"
        }
        
        let valueWithUnit = unit != nil ? "\(formattedValue) \(unit!)" : formattedValue
        
        return self.accessibilityValue(Text(valueWithUnit))
    }
    
    /// Add accessibility hint with proper formatting
    /// - Parameters:
    ///   - hint: The hint text
    ///   - condition: Optional condition to determine if hint should be added
    /// - Returns: The modified view
    func accessibilityHintIf(
        _ hint: String,
        if condition: Bool = true
    ) -> some View {
        condition ? self.accessibilityHint(Text(hint)) : self
    }
    
    /// Add accessibility action
    /// - Parameters:
    ///   - name: The name of the action
    ///   - action: The action to perform
    /// - Returns: The modified view
    func accessibilityAction(named name: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(.init(name: Text(name), action: action))
    }
    
    /// Group accessibility elements
    /// - Parameters:
    ///   - label: The label for the group
    ///   - shouldGroup: Whether the elements should be grouped
    /// - Returns: The modified view
    func accessibilityGroup(
        label: String,
        shouldGroup: Bool = true
    ) -> some View {
        if shouldGroup {
            return self
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(label))
        } else {
            return self
        }
    }
    
    /// Make the view accessible for dynamic type size changes
    /// - Parameters:
    ///   - minSize: The minimum content size category
    ///   - maxSize: The maximum content size category
    /// - Returns: The modified view
    func dynamicTypeSize(
        min minSize: ContentSizeCategory = .small,
        max maxSize: ContentSizeCategory = .accessibilityExtraExtraExtraLarge
    ) -> some View {
        self.dynamicTypeSize(DynamicTypeSize.small...DynamicTypeSize.accessibility5)
    }
    
    /// Add accessibility toggle tip
    /// - Parameters:
    ///   - title: The title of the tip
    ///   - message: The message of the tip
    ///   - show: Whether to show the tip
    /// - Returns: The modified view
    @ViewBuilder
    func accessibilityTip(
        title: String,
        message: String,
        show: Bool
    ) -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            self.accessibilityHint(Text("\(title): \(message)"))
        } else {
            self.accessibilityHint(Text(message))
        }
    }
}

// MARK: - Accessibility Components

/// A view with improved accessibility for buttons
struct AccessibleButton<Label: View>: View {
    /// The action to perform
    var action: () -> Void
    
    /// The label for the button
    @ViewBuilder var label: () -> Label
    
    /// The accessibility label
    var accessibilityLabel: String?
    
    /// The accessibility hint
    var accessibilityHint: String?
    
    /// Whether the button is disabled
    var isDisabled: Bool = false
    
    /// The body of the view
    var body: some View {
        Button(action: action) {
            label()
        }
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel.map { Text($0) } ?? Text(""))
        .accessibilityHintIf(accessibilityHint ?? "", if: accessibilityHint != nil)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isDisabled ? .isEnabled : [])
    }
}

/// A view with improved accessibility for toggles
struct AccessibleToggle<Label: View>: View {
    /// The binding for the toggle
    @Binding var isOn: Bool
    
    /// The label for the toggle
    @ViewBuilder var label: () -> Label
    
    /// The accessibility label
    var accessibilityLabel: String?
    
    /// The accessibility hint
    var accessibilityHint: String?
    
    /// Whether the toggle is disabled
    var isDisabled: Bool = false
    
    /// The body of the view
    var body: some View {
        Toggle(isOn: $isOn) {
            label()
        }
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel.map { Text($0) } ?? Text(""))
        .accessibilityHintIf(accessibilityHint ?? "", if: accessibilityHint != nil)
        .accessibilityValue(isOn ? "enabled" : "disabled")
        .accessibilityAddTraits(.isToggle)
        .accessibilityRemoveTraits(isDisabled ? .isEnabled : [])
    }
}

/// A container that groups elements for accessibility
struct AccessibilityGroup<Content: View>: View {
    /// The label for the group
    var label: String
    
    /// Whether the elements should be grouped
    var shouldGroup: Bool = true
    
    /// The content of the group
    @ViewBuilder var content: () -> Content
    
    /// The body of the view
    var body: some View {
        if shouldGroup {
            content()
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(label))
        } else {
            content()
        }
    }
}

// MARK: - Text Size Scaling

/// A modifier that scales text for accessibility
struct ScaledFont: ViewModifier {
    /// The base size of the font
    let baseSize: CGFloat
    
    /// The minimum scale factor
    let minScaleFactor: CGFloat
    
    /// The font weight
    let weight: Font.Weight
    
    /// The text design
    let design: Font.Design
    
    /// Initialize with base size and options
    /// - Parameters:
    ///   - baseSize: The base size of the font
    ///   - minScaleFactor: The minimum scale factor
    ///   - weight: The font weight
    ///   - design: The text design
    init(
        baseSize: CGFloat,
        minScaleFactor: CGFloat = 0.5,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) {
        self.baseSize = baseSize
        self.minScaleFactor = minScaleFactor
        self.weight = weight
        self.design = design
    }
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .font(.system(size: baseSize, weight: weight, design: design))
            .minimumScaleFactor(minScaleFactor)
            .lineLimit(1)
    }
}

/// Extension to add scaled font to Text
extension Text {
    /// Apply a scaled font
    /// - Parameters:
    ///   - baseSize: The base size of the font
    ///   - minScaleFactor: The minimum scale factor
    ///   - weight: The font weight
    ///   - design: The text design
    /// - Returns: The modified text
    func scaledFont(
        baseSize: CGFloat,
        minScaleFactor: CGFloat = 0.5,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        self.modifier(ScaledFont(
            baseSize: baseSize,
            minScaleFactor: minScaleFactor,
            weight: weight,
            design: design
        ))
    }
}

// MARK: - Accessibility Context Menu

/// A view that adds accessibility context menu actions
struct AccessibilityContextMenuModifier: ViewModifier {
    /// The actions for the context menu
    let actions: [AccessibilityAction]
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .contextMenu {
                ForEach(actions) { action in
                    Button(action: action.action) {
                        Label(action.name, systemImage: action.iconName)
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityActions {
                ForEach(actions) { action in
                    AccessibilityActionButton(name: action.name, action: action.action)
                }
            }
    }
}

/// An accessibility action button
struct AccessibilityActionButton: AccessibilityActionRepresentable {
    /// The name of the action
    let name: String
    
    /// The action to perform
    let action: () -> Void
    
    /// Create the accessibility action
    func makeAccessibilityAction() -> AccessibilityActionKind {
        return .init(name: Text(name), action: action)
    }
}

/// An accessibility action
struct AccessibilityAction: Identifiable {
    /// The unique identifier
    let id = UUID()
    
    /// The name of the action
    let name: String
    
    /// The icon name
    let iconName: String
    
    /// The action to perform
    let action: () -> Void
}

/// Protocol for accessibility action representable
protocol AccessibilityActionRepresentable {
    /// Create the accessibility action
    func makeAccessibilityAction() -> AccessibilityActionKind
}

/// Extension to add accessibility context menu to View
extension View {
    /// Add accessibility context menu
    /// - Parameter actions: The actions for the context menu
    /// - Returns: The modified view
    func accessibilityContextMenu(_ actions: [AccessibilityAction]) -> some View {
        self.modifier(AccessibilityContextMenuModifier(actions: actions))
    }
}