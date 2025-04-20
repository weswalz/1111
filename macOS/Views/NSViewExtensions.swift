//
//  NSViewExtensions.swift
//  LED Messenger macOS
//
//  Created on April 18, 2025
//

import Cocoa
import SwiftUI

// MARK: - NSView Extensions

/// Extension to add tag-based view traversal to NSView
extension NSView {
    /// Tags this view with a unique identifier that can be used for keyboard shortcuts
    /// - Parameter id: The unique identifier
    /// - Returns: Self for chaining
    @discardableResult
    func tagForKeyboardShortcuts(id: UUID) -> Self {
        // Set a value in the view's associated objects dictionary
        objc_setAssociatedObject(
            self,
            &AssociatedKeys.viewID,
            id,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return self
    }
    
    /// Gets the unique identifier for this view
    var viewID: UUID? {
        return objc_getAssociatedObject(self, &AssociatedKeys.viewID) as? UUID
    }
    
    /// Find all descendant views matching a predicate
    /// - Parameter predicate: The predicate to match
    /// - Returns: An array of matching views
    func findViews(where predicate: (NSView) -> Bool) -> [NSView] {
        var result: [NSView] = []
        
        // Check if this view matches
        if predicate(self) {
            result.append(self)
        }
        
        // Check subviews
        for subview in subviews {
            result.append(contentsOf: subview.findViews(where: predicate))
        }
        
        return result
    }
    
    /// Find the first descendant view matching a predicate
    /// - Parameter predicate: The predicate to match
    /// - Returns: The first matching view, or nil if none found
    func findView(where predicate: (NSView) -> Bool) -> NSView? {
        // Check if this view matches
        if predicate(self) {
            return self
        }
        
        // Check subviews
        for subview in subviews {
            if let match = subview.findView(where: predicate) {
                return match
            }
        }
        
        return nil
    }
    
    /// Find a tagged view with a specific ID
    /// - Parameter id: The view ID to look for
    /// - Returns: The view with the specified ID, or nil if not found
    func findViewWithID(_ id: UUID) -> NSView? {
        return findView { view in
            return view.viewID == id
        }
    }
}

// MARK: - Associated Keys

/// Keys for associated objects
private struct AssociatedKeys {
    /// Key for view ID
    static var viewID = "viewID"
}

// MARK: - NSViewRepresentable Extension

/// A representable that can be tagged with a unique identifier
protocol ViewIDTaggable {
    /// Set the view ID for this representable
    /// - Parameter id: The unique identifier
    func tagWithID(_ id: UUID)
}

/// A SwiftUI wrapper that makes an NSView identifiable for keyboard shortcuts
struct TaggableView<Content: View>: View {
    /// The content view
    let content: Content
    
    /// The unique identifier for this view
    let id: UUID
    
    /// The view's body
    var body: some View {
        content
            .background(
                ViewTagModifier(id: id)
            )
    }
}

/// A view modifier that applies a tag to an NSView
struct ViewTagModifier: NSViewRepresentable {
    /// The unique identifier for this view
    let id: UUID
    
    /// Create the NSView
    func makeNSView(context: Context) -> NSView {
        // Create a simple view that will tag its parent
        let view = TaggableNSView(id: id)
        return view
    }
    
    /// Update the NSView
    func updateNSView(_ nsView: NSView, context: Context) {
        // Nothing to do here
    }
}

/// An NSView that can be tagged with a unique identifier
class TaggableNSView: NSView, TaggableViewRepresentable {
    /// The unique identifier for this view
    let viewID: UUID
    
    /// Initialize with a unique identifier
    /// - Parameter id: The unique identifier
    init(id: UUID) {
        self.viewID = id
        super.init(frame: .zero)
    }
    
    /// Required initializer
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View Extensions

/// Extension to add tagging capabilities to SwiftUI views
extension View {
    /// Tag this view for keyboard shortcuts
    /// - Parameter id: The unique identifier
    /// - Returns: The tagged view
    func tagForKeyboardShortcuts(id: UUID = UUID()) -> some View {
        TaggableView(content: self, id: id)
    }
}