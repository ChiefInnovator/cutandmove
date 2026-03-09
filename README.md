# Cut & Move

**The missing Cut & Move for macOS Finder.**

macOS Finder has no native Cmd+X to cut and move files. Cut & Move fixes that. It's a lightweight menu bar utility that intercepts Cmd+X in Finder, turning it into a true cut-and-move operation -- just like you'd expect.

## How It Works

1. **Cmd+X** in Finder -- the app copies the selected files (Cmd+C) and enters "cut mode"
2. **Cmd+V** in Finder -- the app converts the paste into a move (Cmd+Option+V), relocating the files instead of duplicating them
3. The menu bar scissors icon fills in while cut mode is active

Cancel cut mode at any time with **Escape** or **Cmd+C**.

## Requirements

- macOS 26.1+
- **Accessibility permissions** -- the app needs to monitor keyboard events in Finder. You'll be prompted to grant this on first launch.

## Installation

1. Open `CutAndMove.xcodeproj` in Xcode
2. Build and run (Cmd+R)
3. Grant Accessibility permissions when prompted (System Settings > Privacy & Security > Accessibility)

## Features

- **Menu bar app** -- lives in your menu bar with a scissors icon, no Dock clutter
- **Launch at Login** -- optional auto-start via the menu bar dropdown
- **Visual feedback** -- scissors icon changes when cut mode is active
- **Finder-only** -- only intercepts keyboard events when Finder is the active app
- **Zero dependencies** -- pure Swift using system frameworks only

## Architecture

```
CutAndMove/
  CutAndMoveApp.swift          # App entry point, menu bar UI, window definitions
  GlobalKeyboardHandler.swift  # Core keyboard interception via CGEvent tap
  LaunchManager.swift          # Launch-at-login via ServiceManagement
  PermissionsView.swift        # Accessibility permissions request UI
  AboutView.swift              # About window
  Assets.xcassets/             # App icons and colors
```

The keyboard interception uses a `CGEvent` tap (`CFMachPort`) at the session level. Events are tagged with a magic number (`0xCAFE`) to prevent infinite loops when simulating keystrokes.

## Tech Stack

- **Swift** + **SwiftUI** + **Cocoa**
- CGEvent / CFMachPort for low-level keyboard access
- ServiceManagement (SMAppService) for login items
- No third-party dependencies

## Credits

Created by **Richard Crane** with **Gemini**.

Website: https://inventingfirewith.ai
Support: support@inventingfirewith.ai

## License

(c) 2025 Richard Crane. All rights reserved.
