//
//  TaggableViewRepresentable.swift
//  LED Messenger macOS
//
//  Created on April 18, 2025
//

import Cocoa
import SwiftUI

/// A protocol for views that can be tagged with a unique identifier
protocol TaggableViewRepresentable {
    /// The unique identifier for this view
    var viewID: UUID { get }
    
    /// Tag the parent view with the view's ID
    func tagParentView()
}

/// Default implementation of TaggableViewRepresentable
extension TaggableViewRepresentable where Self: NSView {
    /// Tag the parent view with the view's ID
    func tagParentView() {
        // Find the first parent that can be tagged
        var currentView: NSView? = self.superview
        while currentView != nil {
            // If we find a SwiftUI hosting view, tag it
            if let hostingView = currentView as? NSHostingView<AnyView> {
                hostingView.tagForKeyboardShortcuts(id: viewID)
                break
            }
            currentView = currentView?.superview
        }
    }
}

/// A view host that can be used to tag an NSView
struct NSViewHost<Content: NSView>: NSViewRepresentable {
    /// The content view
    let content: Content
    
    /// The unique identifier to tag the view with
    let id: UUID
    
    /// Create the NSView
    func makeNSView(context: Context) -> Content {
        // Tag the content with the ID
        content.tagForKeyboardShortcuts(id: id)
        return content
    }
    
    /// Update the NSView
    func updateNSView(_ nsView: Content, context: Context) {
        // Nothing to update
    }
}

/// Extension to make NSHostingView taggable
extension NSHostingView {
    /// The view controller that owns this view
    var viewController: NSViewController? {
        var responder: NSResponder? = self
        while responder != nil {
            if let viewController = responder as? NSViewController {
                return viewController
            }
            responder = responder?.nextResponder
        }
        return nil
    }
}

/// A view modifier that wraps a view in an NSViewHost
struct NSViewHostModifier: ViewModifier {
    /// The unique identifier to tag the view with
    let id: UUID
    
    /// Apply the modifier to the view
    func body(content: Content) -> some View {
        content
            .background(NSViewTagger(id: id))
    }
}

/// A view that tags its parent NSView
struct NSViewTagger: NSViewRepresentable {
    /// The unique identifier to tag the view with
    let id: UUID
    
    /// Create the NSView
    func makeNSView(context: Context) -> NSTagView {
        let view = NSTagView()
        view.id = id
        return view
    }
    
    /// Update the NSView
    func updateNSView(_ nsView: NSTagView, context: Context) {
        nsView.id = id
    }
    
    /// The NSView that tags its parent
    class NSTagView: NSView {
        /// The unique identifier to tag the view with
        var id: UUID = UUID() {
            didSet {
                if let hostingView = self.superview as? NSHostingView<AnyView> {
                    hostingView.tagForKeyboardShortcuts(id: id)
                }
            }
        }
        
        /// Called when the view is added to a window
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            
            // Find and tag the hosting view
            if let hostingView = self.superview as? NSHostingView<AnyView> {
                hostingView.tagForKeyboardShortcuts(id: id)
            }
        }
    }
}

/// Extension to make SwiftUI views taggable
extension View {
    /// Tag this view for keyboard shortcuts
    /// - Parameter id: The unique identifier
    /// - Returns: The tagged view
    func nsViewHost(id: UUID = UUID()) -> some View {
        modifier(NSViewHostModifier(id: id))
    }
}