# LED Messenger Development Guide

This guide provides detailed information for developers working on the LED Messenger codebase.

## Project Structure

The project is organized into several key directories:

```
LED MESSENGER V2/
├── CLAUDE.md                # Claude AI instructions for this codebase
├── Shared/                  # Shared code between platforms
│   ├── Extensions/          # Swift extension methods
│   ├── Models/              # Data models
│   ├── Services/            # Core services
│   │   ├── Logging/         # Logging infrastructure
│   │   ├── OSC/             # OSC protocol implementation
│   │   ├── Persistence/     # Data storage
│   │   └── Settings/        # Settings management
│   └── Utilities/           # Shared utility functions
├── iOS/                     # iOS-specific code
│   ├── Views/               # iOS UI components
│   │   ├── Common/          # Shared UI components for iOS
│   │   ├── Solo/            # Solo mode UI
│   │   └── Paired/          # Paired mode UI
│   ├── ViewModels/          # iOS view models
│   └── PeerClient/          # iPad peer client implementation
├── macOS/                   # macOS-specific code
│   ├── Views/               # macOS UI components
│   ├── ViewModels/          # macOS view models
│   └── PeerServer/          # Mac peer server implementation
├── LEDMESSENGERTests/       # Unit tests
└── project.yml             # XcodeGen project definition
```

## Architecture

LED Messenger follows the MVVM (Model-View-ViewModel) architecture pattern:

### Models

Located in `Shared/Models/`, these represent the core data structures of the application:

- `Message`: Represents a text message with formatting
- `MessageQueue`: Collection of messages in a specified order
- `Settings`: Application settings and configuration

### Views

Platform-specific UI components:

- iOS views in `iOS/Views/`
- macOS views in `macOS/Views/`

All views use SwiftUI and follow platform-specific design patterns.

### ViewModels

Mediators between the views and models:

- iOS view models in `iOS/ViewModels/`
- macOS view models in `macOS/ViewModels/`

ViewModels expose observed properties and methods for the views to bind to.

### Services

Provide business logic and functionality:

- `LoggingService`: Structured logging
- `OSCService`: Open Sound Control protocol implementation
- `PersistenceManager`: Data storage
- `SettingsManager`: Application settings
- `MessageQueueController`: Message queue management
- `ResolumeConnector`: Resolume Arena communication
- `PeerServer` & `PeerClient`: Device-to-device communication

## Coding Standards

### Code Style

- Use Swift's native naming conventions
- Prefer Swift's native types
- Use `//MARK:` comments to organize code sections
- Limit file size to 500 lines maximum; split into extension files if needed
- All public interfaces should have doc comments (`///`)

### SwiftUI Patterns

- Use SwiftUI's property wrappers appropriately
- Separate complex views into smaller components
- Use `ViewModifier` for reusable style elements
- Use `EnvironmentObject` for dependency injection

### Concurrency

- Use Swift Concurrency (async/await) for asynchronous operations
- Use Combine for reactive programming patterns
- Ensure thread safety in services

## OSC Implementation

The OSC protocol is implemented in the `Shared/Services/OSC` directory:

- `OSCMessage.swift`: Defines the message structure
- `OSCService.swift`: Protocol for OSC communication
- `ResolumeConnector.swift`: Resolume-specific integration

### Resolume Integration

The application communicates with Resolume Arena using the following OSC address patterns:

- `/composition/layers/{layerIndex}/clips/{clipIndex}/video/source/text`
- `/composition/layers/{layerIndex}/clips/{clipIndex}/connect`
- `/composition/layers/{layerIndex}/clips/{clearClip}/connect`

## Networking Architecture

### Peer-to-Peer Communication

Uses Apple's Multipeer Connectivity framework:

- `PeerServer`: Implemented in `macOS/PeerServer/`
- `PeerClient`: Implemented in `iOS/PeerClient/`

### Message Protocol

Messages between devices use a custom protocol defined in `Shared/Models/Message.swift`. The protocol handles:

- Message serialization
- Queue synchronization
- Settings distribution
- Connection management

## Performance Optimization

- Use `OSCPerformanceManager` for network optimization
- Implement UI performance modifiers from `UIPerformanceModifiers.swift`
- Use `MessageQueueOptimizer` for efficient message handling
- Implement caching for frequently accessed data

## Testing

- Unit tests in `LEDMESSENGERTests/`
- Tests for models, services, and view models
- UI testing for key workflows

Run tests using:

```bash
xcodebuild test -project LEDMESSENGER.xcodeproj -scheme LEDMESSENGER_iPad -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)'
```

## macOS-Specific Implementation

### macOS Architecture

The macOS version of LED Messenger serves as the control center, capable of:

1. Sending messages directly to Resolume Arena
2. Acting as a server for iPad clients
3. Managing message queues and settings

#### Key Components

- **AppCoordinator**: Central coordinator for app-wide state and actions
- **MacMenuBarView**: Menu bar integration for quick actions
- **KeyboardShortcutManager**: Global keyboard shortcut handling
- **PeerServer**: Server for iPad client connections
- **NotificationBanner**: Custom notification system
- **ConfirmationDialog**: Custom dialog implementation

### Menu Bar Integration

LED Messenger integrates with the macOS menu bar:

```swift
MenuBarExtra("LED Messenger", systemImage: "message.fill") {
    MacMenuBarView()
        .environmentObject(appCoordinator)
        .environmentObject(messageQueueController)
        .environmentObject(peerServer)
        .environmentObject(resolumeConnector)
}
.menuBarExtraStyle(.window)
```

### Keyboard Shortcuts

The application provides robust keyboard shortcut support:

1. **Global Shortcuts**:
   - New Queue: ⌘N
   - New Message: ⌘⇧N
   - Edit Message: ⌘E
   - Delete Message: ⌘⌫
   - Save Changes: ⌘S
   - Send Message: Space
   - Clear Message: ⌘⌥X

2. **Navigation Shortcuts**:
   - Previous/Next Message: ↑/↓
   - Previous/Next Queue: ←/→

3. **Connection Shortcuts**:
   - Connect/Disconnect: ⌘⌥C
   - Refresh Connection: ⌘R

### macOS UI Components

- **TaggableViewRepresentable**: Protocol for NSView tagging to support keyboard shortcuts
- **NSViewExtensions**: Extensions for SwiftUI-NSView interoperability
- **MessageQueueDetailView**: Specialized view for macOS with advanced controls
- **MessageEditorSheet**: Editing interface optimized for desktop

### SwiftUI-AppKit Integration

The macOS app integrates with AppKit when necessary:

```swift
// Example: Opening a file dialog
func openFileDialog() -> URL? {
    let dialog = NSOpenPanel()
    dialog.title = "Choose a file"
    dialog.showsResizeIndicator = true
    dialog.allowsMultipleSelection = false
    dialog.canChooseDirectories = false
    dialog.allowedFileTypes = ["json"]
    
    if dialog.runModal() == NSApplication.ModalResponse.OK {
        return dialog.url
    }
    return nil
}
```

### Appearance Customization

The macOS app supports advanced appearance customization:

1. **Theme Management**: System, Light, Dark
2. **High Contrast Mode**: Enhanced visibility
3. **Custom Accent Colors**: User-defined accent colors
4. **Text Size Adjustment**: Multiple text size options

### Sound Effects

The macOS app integrates with macOS sound APIs:

```swift
// Play sound effect
func playSound(_ effect: SoundEffect) {
    if let sound = NSSound(named: effect.fileName) {
        sound.volume = Float(UserDefaults.standard.float(forKey: "soundVolume"))
        sound.play()
    }
}
```

## Building the Project

### Project Generation

The project uses XcodeGen for project file generation:

```bash
xcodegen generate
```

### Build Commands

#### iPad Build

```bash
xcodebuild build -project LEDMESSENGER.xcodeproj -scheme LEDMESSENGER_iPad -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)'
```

#### macOS Build

```bash
xcodebuild build -project LEDMESSENGER.xcodeproj -scheme LEDMESSENGER_macOS -destination 'platform=macOS'
```

### macOS Development Requirements

- macOS 12.0+ for development
- Xcode 14.0+ for building
- Swift 5.7+
- AppKit integration knowledge for advanced features

## Deployment

### macOS Deployment

1. Archive the application from Xcode
2. Validate and distribute through the App Store or directly
3. For direct distribution, notarize the application

### iOS Deployment

1. Archive the application from Xcode
2. Validate and submit to App Store Connect
3. Complete the App Store distribution process

## Troubleshooting

### Logging

LED Messenger uses a structured logging system:

```swift
logger.info(
    category: .osc,
    message: "Connected to Resolume",
    metadata: ["ipAddress": .string("127.0.0.1"), "port": .int(7000)]
)
```

View logs with:

```bash
log show --predicate 'subsystem == "com.ledmessenger.app"' --last 1h
```

### Common Issues

- **OSC Connection Issues**: Verify network settings and firewall rules
- **Peer Connection Issues**: Check Bluetooth and WiFi settings
- **Build Issues**: Run `xcodegen generate` and clean the build folder

## Resources

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [OSC Specification](http://opensoundcontrol.org/spec-1_0)
- [Resolume OSC API](https://resolume.com/support/en/osc)