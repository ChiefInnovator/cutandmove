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

1. Sign in to GitHub with access to this private repository and download `CutAndMove.dmg` from [Releases](https://github.com/ChiefInnovator/cutandmove/releases/latest).
2. Open the DMG and drag CutAndMove into Applications, then launch it.
3. Grant Accessibility permissions when prompted (System Settings > Privacy & Security > Accessibility)

The app is signed with MILL5's Developer ID and notarized by Apple. It is distributed directly, not through the Mac App Store. A ZIP is also available.

## Build and Release

Open `CutAndMove.xcodeproj` in Xcode to develop locally, or use `make build` and `make test`.

Releases follow MacEdgeLight's workflow: archive → Developer ID upload for notarization → export the notarized app → verify → package a signed DMG and ZIP → private GitHub Release.

Requirements: full Xcode selected with `xcode-select` (or `DEVELOPER_DIR`), the MILL5 Apple account configured in Xcode, its Developer ID Application certificate/private key, `create-dmg`, and authenticated GitHub CLI access.

```sh
make release
# Commit the release changes, then create and push the matching vVERSION tag.
make publish
```

Update `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, website/llms version, and `docs/RELEASE_NOTES_VERSION.md` before releasing. `make release` waits for notarization and checks the signature, stapled ticket, and Gatekeeper acceptance before packaging. It refuses to overwrite existing DMG/ZIP files; move previous artifacts aside before rerunning. `make publish` requires the tag to exist on GitHub and verifies package checksums.

The export plists use `method=developer-id`; `destination=upload` sends to Apple's notary service, **not App Store Connect publishing**. Keep the bundle identifier `M5.CutAndMove` and team `FS6453639M`. Downloads remain private and require repository access.

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

Created by **[Richard Crane](https://mvp.microsoft.com/en-US/MVP/profile/10ce0bc0-7536-43f6-b28c-e9601a4a0d0d)** — Microsoft MVP and founder of **[MILL5](https://mill5.com)** — with **Gemini**.

- **MILL5:** [mill5.com](https://mill5.com)
- **Microsoft MVP profile:** [mvp.microsoft.com/…/Richard-Crane](https://mvp.microsoft.com/en-US/MVP/profile/10ce0bc0-7536-43f6-b28c-e9601a4a0d0d)
- **Podcast — *Inventing Fire with AI*:** [inventingfirewith.ai](https://inventingfirewith.ai)
- **Support:** [rich@mill5.com](mailto:rich@mill5.com)

Built in [Visual Studio Code](https://code.visualstudio.com) and shipped on [GitHub](https://github.com/ChiefInnovator).

## License

Licensed under [PolyForm Strict 1.0.0](LICENSE). Copyright © 2025-2026 [Richard Crane](https://mill5.com).

Free for uses permitted by the license. See the full terms for restrictions on use, modification, and distribution.

---

*Powered by [MILL5](https://www.mill5.com).*
