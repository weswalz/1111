# XcodeGen Setup Instructions

To set up the LED Messenger V2 project using XcodeGen, follow these steps:

## Prerequisites

1. Install XcodeGen if you haven't already:
```bash
brew install xcodegen
```

## Generate the Xcode Project

1. Navigate to the project directory:
```bash
cd "/Users/wesleywalz/DEV/LED MESSENGER V2"
```

2. Generate the Xcode project:
```bash
xcodegen generate
```

3. Open the generated project:
```bash
open LEDMESSENGER.xcodeproj
```

## Before Building

1. Set your Development Team in the project settings or create a `.xcconfig` file:
```
DEVELOPMENT_TEAM = YOUR_TEAM_ID
```

## Running Test Builds

1. For iPad:
   - Select the "LEDMESSENGER_iPad" scheme
   - Choose an iPad simulator
   - Click Run

2. For macOS:
   - Select the "LEDMESSENGER_macOS" scheme
   - Click Run

## Troubleshooting

If you encounter any issues:

1. Make sure all required files exist:
   - Info.plist files for each target
   - Entitlements files
   - Launch screen storyboard

2. Check the project structure:
   - Ensure folder paths match those defined in project.yml
   - Verify assets are properly referenced

3. Verify code signing:
   - Set development team in project settings
   - Check entitlements match capabilities requirements

## Additional Notes

- The `.entitlements` files are configured for proper network and Bluetooth access
- Launch screen is set up for iPad
- Test target is configured for both platforms
- Both macOS and iOS targets are set up with appropriate frameworks and dependencies