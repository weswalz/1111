//
//  MessageEditorView.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import SwiftUI
import Combine

/// View for creating and editing messages
struct MessageEditorView: View {
    // MARK: - Properties
    
    /// The message being edited
    @Binding var message: Message
    
    /// Whether the view is in edit mode
    @Binding var isEditing: Bool
    
    /// Action to perform when saving
    var onSave: (Message) -> Void
    
    /// Action to perform when canceling
    var onCancel: () -> Void
    
    /// Whether the editor is showing advanced options
    @State private var showingAdvancedOptions = false
    
    /// Message text entry
    @State private var text: String
    
    /// Message note entry
    @State private var note: String
    
    /// Local copy of formatting for editing
    @State private var formatting: MessageFormatting
    
    /// Display duration in seconds (nil means indefinite)
    @State private var displayDuration: Double?
    
    /// Whether to show the color picker
    @State private var showingColorPicker = false
    
    /// Which color is being edited (text, background, etc.)
    @State private var editingColorType: ColorType = .text
    
    /// Font size adjustment step
    private let fontSizeStep: Double = 2.0
    
    /// Available countdown duration options in seconds
    private let durationOptions: [Double?] = [nil, 60, 120, 180, 240, 300, 600]
    
    // MARK: - Initialization
    
    init(message: Binding<Message>, isEditing: Binding<Bool>, onSave: @escaping (Message) -> Void, onCancel: @escaping () -> Void) {
        self._message = message
        self._isEditing = isEditing
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize state properties with message values
        self._text = State(initialValue: message.wrappedValue.text)
        self._note = State(initialValue: message.wrappedValue.note ?? "")
        self._formatting = State(initialValue: message.wrappedValue.formatting)
        self._displayDuration = State(initialValue: message.wrappedValue.displayDuration)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Editor header
            editorHeader
                .padding(.horizontal)
                .padding(.top)
            
            // Main editor area
            ScrollView {
                VStack(spacing: 16) {
                    // Text preview
                    messagePreview
                        .padding(.vertical)
                    
                    // Text input
                    textEditor
                        .padding(.horizontal)
                    
                    // Note input
                    noteEditor
                        .padding(.horizontal)
                    
                    // Basic formatting controls
                    basicFormattingControls
                        .padding(.horizontal)
                    
                    // Advanced formatting toggle
                    advancedFormattingToggle
                        .padding(.horizontal)
                    
                    // Advanced formatting controls (conditional)
                    if showingAdvancedOptions {
                        advancedFormattingControls
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerView(
                color: binding(for: editingColorType),
                title: "\(editingColorType.description) Color"
            )
        }
        .background(AppTheme.Colors.background)
    }
    
    // MARK: - Header
    
    /// Editor header with title and save/cancel buttons
    private var editorHeader: some View {
        HStack {
            // Cancel button
            Button(action: {
                onCancel()
            }) {
                Text("Cancel")
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            Spacer()
            
            // Title
            Text(isEditing ? "Edit Message" : "New Message")
                .font(.headline)
            
            Spacer()
            
            // Save button
            Button(action: {
                saveMessage()
            }) {
                Text("Save")
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Message Preview
    
    /// Message preview showing how the message will look
    private var messagePreview: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(Color.black)
                .frame(height: 150)
                .padding(.horizontal)
            
            // Message text with styling
            VStack {
                Text(text.isEmpty ? "Message Preview" : text)
                    .font(.system(size: formatting.fontSize))
                    .fontWeight(fontWeight(from: formatting.fontWeight))
                    .foregroundColor(formatting.textColor.toColor())
                    .multilineTextAlignment(textAlignment(from: formatting.alignment))
                    .padding()
                    .background(formatting.backgroundColor.toColor())
                    .if(formatting.strokeColor != nil) { view in
                        view.overlay(
                            Text(text.isEmpty ? "Message Preview" : text)
                                .font(.system(size: formatting.fontSize))
                                .fontWeight(fontWeight(from: formatting.fontWeight))
                                .foregroundColor(.clear)
                                .multilineTextAlignment(textAlignment(from: formatting.alignment))
                                .padding()
                                .overlay(
                                    Text(text.isEmpty ? "Message Preview" : text)
                                        .font(.system(size: formatting.fontSize))
                                        .fontWeight(fontWeight(from: formatting.fontWeight))
                                        .foregroundColor(.clear)
                                        .multilineTextAlignment(textAlignment(from: formatting.alignment))
                                        .padding()
                                        .stroke(
                                            formatting.strokeColor?.toColor() ?? Color.clear,
                                            lineWidth: formatting.strokeWidth
                                        )
                                )
                        )
                    }
                    .if(formatting.hasShadow) { view in
                        view.shadow(
                            color: formatting.shadowColor.toColor(),
                            radius: formatting.shadowRadius,
                            x: formatting.shadowOffsetX,
                            y: formatting.shadowOffsetY
                        )
                    }
            }
            .padding()
        }
    }
    
    // MARK: - Text Editor
    
    /// Text input for the message
    private var textEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message Text")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.Colors.text.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: text) { _ in
                    // Auto-update the message as text changes
                    updateMessageWithCurrentValues()
                }
        }
    }
    
    // MARK: - Note Editor
    
    /// Note input for the message (not sent to LED wall)
    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note (not displayed on LED wall)")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            TextField("Optional note", text: $note)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.Colors.text.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: note) { _ in
                    // Auto-update the message as note changes
                    updateMessageWithCurrentValues()
                }
        }
    }
    
    // MARK: - Basic Formatting Controls
    
    /// Basic formatting controls for the message
    private var basicFormattingControls: some View {
        VStack(spacing: 16) {
            // Text alignment control
            HStack {
                Text("Alignment")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                // Alignment buttons
                HStack(spacing: 16) {
                    ForEach(MessageFormatting.TextAlignment.allCases, id: \.self) { alignment in
                        Button(action: {
                            formatting.alignment = alignment
                            updateMessageWithCurrentValues()
                        }) {
                            Image(systemName: imageName(for: alignment))
                                .foregroundColor(
                                    formatting.alignment == alignment ? 
                                    AppTheme.Colors.primary : AppTheme.Colors.text.opacity(0.5)
                                )
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(
                                            formatting.alignment == alignment ? 
                                            AppTheme.Colors.primary.opacity(0.1) : Color.clear
                                        )
                                )
                        }
                    }
                }
            }
            
            // Font size control
            HStack {
                Text("Font Size")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                // Decrease button
                Button(action: {
                    if formatting.fontSize > 12 {
                        formatting.fontSize -= fontSizeStep
                        updateMessageWithCurrentValues()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.title2)
                }
                
                // Font size display
                Text("\(Int(formatting.fontSize))")
                    .frame(width: 40)
                    .foregroundColor(AppTheme.Colors.text)
                
                // Increase button
                Button(action: {
                    if formatting.fontSize < 120 {
                        formatting.fontSize += fontSizeStep
                        updateMessageWithCurrentValues()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.title2)
                }
            }
            
            // Font weight control
            HStack {
                Text("Font Weight")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                // Weight picker
                Picker("", selection: $formatting.fontWeight) {
                    ForEach(MessageFormatting.FontWeight.allCases, id: \.self) { weight in
                        Text(weight.rawValue).tag(weight)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: formatting.fontWeight) { _ in
                    updateMessageWithCurrentValues()
                }
            }
            
            // Color controls
            HStack {
                Text("Colors")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                // Text color button
                Button(action: {
                    editingColorType = .text
                    showingColorPicker = true
                }) {
                    colorButton(color: formatting.textColor.toColor(), label: "T")
                }
                
                // Background color button
                Button(action: {
                    editingColorType = .background
                    showingColorPicker = true
                }) {
                    colorButton(color: formatting.backgroundColor.toColor(), label: "B")
                }
            }
        }
    }
    
    // MARK: - Advanced Formatting Toggle
    
    /// Toggle for showing/hiding advanced formatting options
    private var advancedFormattingToggle: some View {
        Button(action: {
            withAnimation {
                showingAdvancedOptions.toggle()
            }
        }) {
            HStack {
                Text(showingAdvancedOptions ? "Hide Advanced Options" : "Show Advanced Options")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.subheadline)
                
                Spacer()
                
                Image(systemName: showingAdvancedOptions ? "chevron.up" : "chevron.down")
                    .foregroundColor(AppTheme.Colors.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Advanced Formatting Controls
    
    /// Advanced formatting controls for the message
    private var advancedFormattingControls: some View {
        VStack(spacing: 16) {
            // Stroke controls
            VStack(spacing: 12) {
                Toggle("Enable Stroke", isOn: Binding(
                    get: { formatting.strokeColor != nil },
                    set: { newValue in
                        if newValue {
                            formatting.strokeColor = MessageColor(red: 0, green: 0, blue: 0)
                        } else {
                            formatting.strokeColor = nil
                        }
                        updateMessageWithCurrentValues()
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.Colors.primary))
                
                if formatting.strokeColor != nil {
                    HStack {
                        // Stroke width control
                        HStack {
                            Text("Width")
                                .foregroundColor(AppTheme.Colors.text)
                            
                            Spacer()
                            
                            // Decrease button
                            Button(action: {
                                if formatting.strokeWidth > 1 {
                                    formatting.strokeWidth -= 1
                                    updateMessageWithCurrentValues()
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                            
                            // Stroke width display
                            Text("\(Int(formatting.strokeWidth))")
                                .frame(width: 30)
                                .foregroundColor(AppTheme.Colors.text)
                            
                            // Increase button
                            Button(action: {
                                if formatting.strokeWidth < 10 {
                                    formatting.strokeWidth += 1
                                    updateMessageWithCurrentValues()
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                        }
                        
                        Spacer()
                        
                        // Stroke color button
                        Button(action: {
                            editingColorType = .stroke
                            showingColorPicker = true
                        }) {
                            colorButton(
                                color: formatting.strokeColor?.toColor() ?? Color.black,
                                label: "S"
                            )
                        }
                    }
                }
            }
            
            // Shadow controls
            VStack(spacing: 12) {
                Toggle("Enable Shadow", isOn: $formatting.hasShadow)
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.Colors.primary))
                    .onChange(of: formatting.hasShadow) { _ in
                        updateMessageWithCurrentValues()
                    }
                
                if formatting.hasShadow {
                    // Shadow color
                    HStack {
                        Text("Shadow Color")
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        Button(action: {
                            editingColorType = .shadow
                            showingColorPicker = true
                        }) {
                            colorButton(
                                color: formatting.shadowColor.toColor(),
                                label: "S"
                            )
                        }
                    }
                    
                    // Shadow radius
                    HStack {
                        Text("Radius")
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Slider(value: $formatting.shadowRadius, in: 0...20, step: 1)
                            .accentColor(AppTheme.Colors.primary)
                            .onChange(of: formatting.shadowRadius) { _ in
                                updateMessageWithCurrentValues()
                            }
                        
                        Text("\(Int(formatting.shadowRadius))")
                            .frame(width: 30)
                            .foregroundColor(AppTheme.Colors.text)
                    }
                    
                    // Shadow offset
                    HStack {
                        Text("Offset")
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        VStack {
                            HStack {
                                Text("X")
                                    .foregroundColor(AppTheme.Colors.text)
                                
                                Slider(value: $formatting.shadowOffsetX, in: -20...20, step: 1)
                                    .accentColor(AppTheme.Colors.primary)
                                    .onChange(of: formatting.shadowOffsetX) { _ in
                                        updateMessageWithCurrentValues()
                                    }
                                
                                Text("\(Int(formatting.shadowOffsetX))")
                                    .frame(width: 30)
                                    .foregroundColor(AppTheme.Colors.text)
                            }
                            
                            HStack {
                                Text("Y")
                                    .foregroundColor(AppTheme.Colors.text)
                                
                                Slider(value: $formatting.shadowOffsetY, in: -20...20, step: 1)
                                    .accentColor(AppTheme.Colors.primary)
                                    .onChange(of: formatting.shadowOffsetY) { _ in
                                        updateMessageWithCurrentValues()
                                    }
                                
                                Text("\(Int(formatting.shadowOffsetY))")
                                    .frame(width: 30)
                                    .foregroundColor(AppTheme.Colors.text)
                            }
                        }
                    }
                }
            }
            
            // Animation selection
            VStack(spacing: 12) {
                HStack {
                    Text("Animation")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Spacer()
                }
                
                Picker("", selection: $formatting.animation) {
                    ForEach(MessageFormatting.MessageAnimation.allCases, id: \.self) { animation in
                        Text(animation.rawValue).tag(animation)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: formatting.animation) { _ in
                    updateMessageWithCurrentValues()
                }
            }
            
            // Countdown duration selection
            VStack(spacing: 12) {
                HStack {
                    Text("Display Duration")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Spacer()
                }
                
                Picker("", selection: $displayDuration) {
                    Text("Indefinite").tag(nil as Double?)
                    Text("1 minute").tag(60.0 as Double?)
                    Text("2 minutes").tag(120.0 as Double?)
                    Text("3 minutes").tag(180.0 as Double?)
                    Text("4 minutes").tag(240.0 as Double?)
                    Text("5 minutes").tag(300.0 as Double?)
                    Text("10 minutes").tag(600.0 as Double?)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: displayDuration) { _ in
                    updateMessageWithCurrentValues()
                }
                
                if displayDuration != nil {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("Message will automatically clear after \(formatDuration(displayDuration ?? 0))")
                            .font(.footnote)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    
    /// Update the message with current values
    private func updateMessageWithCurrentValues() {
        var updatedMessage = message
        updatedMessage.text = text
        updatedMessage.note = note.isEmpty ? nil : note
        updatedMessage.formatting = formatting
        updatedMessage.displayDuration = displayDuration
        message = updatedMessage
    }
    
    /// Save the message and exit editing mode
    private func saveMessage() {
        updateMessageWithCurrentValues()
        onSave(message)
    }
    
    /// Format duration in seconds to a readable string
    /// - Parameter seconds: Duration in seconds
    /// - Returns: Formatted duration string
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if remainingSeconds == 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") \(remainingSeconds) second\(remainingSeconds == 1 ? "" : "s")"
        }
    }
    
    /// Get the SwiftUI TextAlignment from MessageFormatting.TextAlignment
    private func textAlignment(from alignment: MessageFormatting.TextAlignment) -> TextAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
    
    /// Get the SwiftUI Font.Weight from MessageFormatting.FontWeight
    private func fontWeight(from weight: MessageFormatting.FontWeight) -> Font.Weight {
        switch weight {
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        }
    }
    
    /// Get the system image name for a text alignment
    private func imageName(for alignment: MessageFormatting.TextAlignment) -> String {
        switch alignment {
        case .leading:
            return "text.alignleft"
        case .center:
            return "text.aligncenter"
        case .trailing:
            return "text.alignright"
        }
    }
    
    /// Create a color button view
    private func colorButton(color: Color, label: String) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(radius: 1)
            
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(
                    color.brightness > 0.7 ? Color.black : Color.white
                )
        }
    }
    
    /// Get a binding for the appropriate color based on the color type
    private func binding(for colorType: ColorType) -> Binding<MessageColor> {
        switch colorType {
        case .text:
            return $formatting.textColor
        case .background:
            return $formatting.backgroundColor
        case .stroke:
            // Create safe binding that handles nil
            return Binding(
                get: { formatting.strokeColor ?? MessageColor(red: 0, green: 0, blue: 0) },
                set: { formatting.strokeColor = $0 }
            )
        case .shadow:
            return $formatting.shadowColor
        }
    }
    
    /// Types of colors that can be edited
    enum ColorType {
        case text
        case background
        case stroke
        case shadow
        
        var description: String {
            switch self {
            case .text:
                return "Text"
            case .background:
                return "Background"
            case .stroke:
                return "Stroke"
            case .shadow:
                return "Shadow"
            }
        }
    }
}

/// Color picker view for selecting message colors
struct ColorPickerView: View {
    /// The color being edited
    @Binding var color: MessageColor
    
    /// Title for the color picker
    let title: String
    
    /// RGB components
    @State private var red: Double
    @State private var green: Double
    @State private var blue: Double
    @State private var alpha: Double
    
    /// Hex code
    @State private var hexCode: String = ""
    
    /// Initialize with the color binding
    init(color: Binding<MessageColor>, title: String) {
        self._color = color
        self.title = title
        self._red = State(initialValue: color.wrappedValue.red)
        self._green = State(initialValue: color.wrappedValue.green)
        self._blue = State(initialValue: color.wrappedValue.blue)
        self._alpha = State(initialValue: color.wrappedValue.alpha)
        
        // Initialize hex code
        let r = Int(color.wrappedValue.red * 255) & 0xFF
        let g = Int(color.wrappedValue.green * 255) & 0xFF
        let b = Int(color.wrappedValue.blue * 255) & 0xFF
        self._hexCode = State(initialValue: String(format: "#%02X%02X%02X", r, g, b))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Color preview
                ZStack {
                    // Checkboard pattern for transparent colors
                    CheckerboardPattern()
                        .frame(height: 100)
                        .overlay(
                            Rectangle()
                                .fill(Color(
                                    red: red,
                                    green: green,
                                    blue: blue,
                                    opacity: alpha
                                ))
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                        .padding()
                }
                
                // Color components
                VStack(spacing: 20) {
                    // RGB sliders
                    VStack(spacing: 12) {
                        colorSlider(value: $red, color: .red, label: "R")
                        colorSlider(value: $green, color: .green, label: "G")
                        colorSlider(value: $blue, color: .blue, label: "B")
                        colorSlider(value: $alpha, color: .gray, label: "A")
                    }
                    
                    // Hex code input
                    HStack {
                        Text("Hex")
                            .frame(width: 40, alignment: .leading)
                        
                        TextField("", text: $hexCode)
                            .frame(height: 36)
                            .padding(.horizontal, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                            .onChange(of: hexCode) { newValue in
                                if newValue.hasPrefix("#") && newValue.count == 7 {
                                    if let color = MessageColor(hex: newValue) {
                                        red = color.red
                                        green = color.green
                                        blue = color.blue
                                        // Alpha is not updated from hex
                                    }
                                }
                            }
                        
                        Button(action: {
                            updateHexFromRGB()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                    
                    // Preset colors
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(presetColors, id: \.self) { presetColor in
                                Button(action: {
                                    setColor(presetColor)
                                }) {
                                    Circle()
                                        .fill(Color(
                                            red: presetColor.red,
                                            green: presetColor.green,
                                            blue: presetColor.blue
                                        ))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                        .shadow(radius: 1)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitle(title, displayMode: .inline)
            .onChange(of: red) { _ in updateColorFromComponents() }
            .onChange(of: green) { _ in updateColorFromComponents() }
            .onChange(of: blue) { _ in updateColorFromComponents() }
            .onChange(of: alpha) { _ in updateColorFromComponents() }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Color is updated continuously, so just dismiss
                    }
                }
            }
        }
    }
    
    /// Color slider component
    private func colorSlider(value: Binding<Double>, color: Color, label: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 40, alignment: .leading)
            
            Slider(value: value, in: 0...1)
                .accentColor(color)
            
            Text("\(Int(value.wrappedValue * 255))")
                .frame(width: 40)
        }
    }
    
    /// Update the color from RGB components
    private func updateColorFromComponents() {
        color = MessageColor(red: red, green: green, blue: blue, alpha: alpha)
        updateHexFromRGB()
    }
    
    /// Update the hex code from RGB values
    private func updateHexFromRGB() {
        let r = Int(red * 255) & 0xFF
        let g = Int(green * 255) & 0xFF
        let b = Int(blue * 255) & 0xFF
        hexCode = String(format: "#%02X%02X%02X", r, g, b)
    }
    
    /// Set the color from a MessageColor
    private func setColor(_ messageColor: MessageColor) {
        red = messageColor.red
        green = messageColor.green
        blue = messageColor.blue
        // Don't change alpha when using presets
        updateColorFromComponents()
    }
    
    /// Preset colors for quick selection
    private var presetColors: [MessageColor] {
        [
            MessageColor(red: 1, green: 1, blue: 1), // White
            MessageColor(red: 0, green: 0, blue: 0), // Black
            MessageColor(red: 1, green: 0, blue: 0), // Red
            MessageColor(red: 0, green: 1, blue: 0), // Green
            MessageColor(red: 0, green: 0, blue: 1), // Blue
            MessageColor(red: 1, green: 1, blue: 0), // Yellow
            MessageColor(red: 1, green: 0, blue: 1), // Magenta
            MessageColor(red: 0, green: 1, blue: 1), // Cyan
            MessageColor(red: 1, green: 0.5, blue: 0), // Orange
            MessageColor(red: 0.5, green: 0, blue: 0.5), // Purple
            MessageColor(red: 0, green: 0.5, blue: 0), // Dark Green
            MessageColor(red: 0, green: 0, blue: 0.5), // Navy
        ]
    }
}

/// Checkerboard pattern view for transparent color backgrounds
struct CheckerboardPattern: View {
    var size: CGFloat = 10
    var color1: Color = Color.gray.opacity(0.3)
    var color2: Color = Color.white
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let rows = Int(geometry.size.height / size) + 1
                let columns = Int(geometry.size.width / size) + 1
                
                for row in 0..<rows {
                    for col in 0..<columns {
                        let offsetX = CGFloat(col) * size
                        let offsetY = CGFloat(row) * size
                        let isEven = (row + col) % 2 == 0
                        
                        path.addRect(CGRect(
                            x: offsetX,
                            y: offsetY,
                            width: size,
                            height: size
                        ))
                    }
                }
            }
            .fill(color1)
            .background(color2)
        }
    }
}

// MARK: - Extensions

extension Color {
    /// Calculate the brightness of a color (approximation)
    var brightness: CGFloat {
        do {
            let uiColor = UIColor(self)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            // Perceived brightness formula (YIQ)
            return (red * 0.299 + green * 0.587 + blue * 0.114)
        } catch {
            // Fallback if conversion fails
            return 0.5
        }
    }
}
