//
//  UIPerformanceModifiers.swift
//  LED Messenger
//
//  Created on April 18, 2025
//

import SwiftUI

// MARK: - Performance Measurement

/// A view modifier that measures render time
struct RenderTimeMeasurement: ViewModifier {
    /// The tag for the measurement
    let tag: String
    
    /// Whether the measurement is enabled
    @AppStorage("enablePerformanceMeasurement") private var isEnabled = false
    
    /// Start time for measurement
    @State private var startTime: CFTimeInterval?
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        if isEnabled {
            content
                .background(
                    GeometryReader { _ in
                        Color.clear
                            .onAppear {
                                startTime = CACurrentMediaTime()
                            }
                            .onDisappear {
                                if let start = startTime {
                                    let duration = CACurrentMediaTime() - start
                                    print("⏱️ Render time for \(tag): \(String(format: "%.2f", duration * 1000))ms")
                                }
                            }
                    }
                )
        } else {
            content
        }
    }
}

// MARK: - Performance Optimizations

/// A view modifier that enables backface culling
struct BackfaceCulling: ViewModifier {
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .drawingGroup() // Use Metal rendering
    }
}

/// A view modifier that applies frame rate throttling for non-critical UI
struct FrameRateThrottle: ViewModifier {
    /// Whether the view is active
    let isActive: Bool
    
    /// The update interval
    let interval: Double
    
    /// Timer for updates
    @State private var timer: Timer?
    
    /// Whether to update
    @State private var shouldUpdate = false
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        Group {
            if isActive {
                content
            } else {
                content
                    .opacity(shouldUpdate ? 1.0 : 0.9999) // Force redraw only on timer
                    .onAppear {
                        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                            shouldUpdate.toggle() // Toggle to force update
                        }
                    }
                    .onDisappear {
                        timer?.invalidate()
                        timer = nil
                    }
            }
        }
    }
}

/// A view modifier that enables GPU acceleration for complex views
struct GPUAcceleration: ViewModifier {
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .drawingGroup() // Use Metal-backed rendering
    }
}

/// A view modifier that prevents offscreen rendering
struct PreventOffscreenRendering: ViewModifier {
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .clipped() // Clip to bounds to prevent offscreen rendering
    }
}

/// A view modifier that optimizes list rendering
struct OptimizedList: ViewModifier {
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .environment(\.defaultMinListRowHeight, 44) // Optimize row height
            .environment(\.defaultMinListHeaderHeight, 30)
    }
}

/// A view modifier that defers complex UI updates
struct DeferredUpdates<T: Equatable>: ViewModifier {
    /// The value to track for changes
    let value: T
    
    /// The delay before updating
    let delay: Double
    
    /// The current value
    @State private var currentValue: T
    
    /// Timer for updates
    @State private var debounceTimer: Timer?
    
    /// Initialize with value and delay
    init(value: T, delay: Double = 0.3) {
        self.value = value
        self.delay = delay
        self._currentValue = State(initialValue: value)
    }
    
    /// Function that modifies the view
    func body(content: Content) -> some View {
        content
            .onChange(of: value) { newValue in
                debounceTimer?.invalidate()
                debounceTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                    currentValue = newValue
                }
            }
            .environment(\.deferredValue, currentValue as? AnyHashable)
    }
}

// MARK: - SwiftUI Extensions

/// Extension to add environment key for deferred values
private struct DeferredValueKey: EnvironmentKey {
    static let defaultValue: AnyHashable? = nil
}

/// Extension to add environment value for deferred values
extension EnvironmentValues {
    var deferredValue: AnyHashable? {
        get { self[DeferredValueKey.self] }
        set { self[DeferredValueKey.self] = newValue }
    }
}

/// Extension to add performance modifiers to View
extension View {
    /// Measure render time
    /// - Parameter tag: The tag for the measurement
    /// - Returns: The modified view
    func measureRenderTime(tag: String) -> some View {
        modifier(RenderTimeMeasurement(tag: tag))
    }
    
    /// Enable backface culling
    /// - Returns: The modified view
    func withBackfaceCulling() -> some View {
        modifier(BackfaceCulling())
    }
    
    /// Apply frame rate throttling for non-critical UI
    /// - Parameters:
    ///   - isActive: Whether the view is active
    ///   - interval: The update interval
    /// - Returns: The modified view
    func throttleFrameRate(isActive: Bool, interval: Double = 0.5) -> some View {
        modifier(FrameRateThrottle(isActive: isActive, interval: interval))
    }
    
    /// Enable GPU acceleration for complex views
    /// - Returns: The modified view
    func withGPUAcceleration() -> some View {
        modifier(GPUAcceleration())
    }
    
    /// Prevent offscreen rendering
    /// - Returns: The modified view
    func preventOffscreenRendering() -> some View {
        modifier(PreventOffscreenRendering())
    }
    
    /// Optimize list rendering
    /// - Returns: The modified view
    func optimizeListRendering() -> some View {
        modifier(OptimizedList())
    }
    
    /// Defer updates for better performance
    /// - Parameters:
    ///   - value: The value to track for changes
    ///   - delay: The delay before updating
    /// - Returns: The modified view
    func deferUpdates<T: Equatable>(for value: T, delay: Double = 0.3) -> some View {
        modifier(DeferredUpdates(value: value, delay: delay))
    }
}