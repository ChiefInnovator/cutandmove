<!-- overview:start -->
# Cut & Move v2.0.1 — Cmd+X Cut and Paste for macOS Finder

Cut & Move is a native macOS menu bar app that adds **Cmd+X → Cmd+V file moves to Finder**. Use familiar cut-and-paste shortcuts while Finder handles the actual move and any conflicts.

**Current source: v2.0.1 (published release). Published download: v2.0.1.**

[Download v2.0.1](https://github.com/ChiefInnovator/cutandmove/releases/tag/v2.0.1) · [Marketing page](https://chiefinnovator.github.io/cutandmove/) · [Setup guide](docs/setup.md) · [v2.0.1 release notes](docs/RELEASE_NOTES_2.0.1.md)

| Product fact | Details |
| :--- | :--- |
| Published version | v2.0.1 — signed and notarized DMG / ZIP |
| Current source | v2.0.1 — published release |
| Compatibility | macOS 26.1 or later; Apple silicon only (M1 or later) |
| Permission | Accessibility access for Finder keyboard shortcuts |
| License | Free for uses permitted by [PolyForm Strict 1.0.0](LICENSE) |
| Distribution | GitHub Releases; no Mac App Store version |
| Privacy | No keystroke recording, analytics, or application network requests |
| Creator and support | Richard Crane, MILL5 · [rich@mill5.com](mailto:rich@mill5.com) |
<!-- overview:end -->

## Features

- **Menu bar app** -- lives in your menu bar with a scissors icon, no Dock clutter
- **Launch at Login** -- optional auto-start via the menu bar dropdown
- **Visual feedback** -- scissors icon changes when cut mode is active
- **Finder-only** -- only intercepts keyboard events when Finder is the active app
- **Zero dependencies** -- pure Swift using system frameworks only

## How It Works

1. **Cmd+X** in Finder -- the app copies the selected files (Cmd+C) and enters "cut mode"
2. **Cmd+V** in Finder -- the app converts the paste into a move (Cmd+Option+V), relocating the files instead of duplicating them
3. The menu bar scissors icon fills in while cut mode is active

Cancel cut mode at any time with **Escape** or **Cmd+C**.

## Requirements

- macOS 26.1+
- **Accessibility permissions** -- the app needs permission to modify Finder keyboard events. It requests access at launch and rechecks permission automatically; enable access in System Settings when prompted.

## Installation

1. Download `CutAndMove.dmg` from [Releases](https://github.com/ChiefInnovator/cutandmove/releases/latest).
2. Open the DMG and drag CutAndMove into Applications, then launch it.
3. Grant Accessibility permissions when prompted (System Settings > Privacy & Security > Accessibility)

The app is signed with MILL5's Developer ID and notarized by Apple. It is distributed directly, not through the Mac App Store. A ZIP is also available.

## Build and Release

Open `CutAndMove.xcodeproj` in Xcode to develop locally, or use `make build` and `make test`.

Releases follow MacEdgeLight's workflow: archive → Developer ID upload for notarization → export the notarized app → verify → package a signed DMG and ZIP → GitHub Release.

Requirements: full Xcode selected with `xcode-select` (or `DEVELOPER_DIR`), the MILL5 Apple account configured in Xcode, its Developer ID Application certificate/private key, `create-dmg`, and authenticated GitHub CLI access.

```sh
make release
# Commit the release changes, then create and push the matching vVERSION tag.
make publish
```

Update `MARKETING_VERSION` (always major.minor.patch), `CURRENT_PROJECT_VERSION`, and `docs/RELEASE_NOTES_VERSION.md` before releasing. Run `make marketing` to synchronize the full version across this README, the marketing page, metadata, FAQs, and `llms.txt`. `make marketing-check` and CI reject stale generated content. The current version comes from Xcode; the published download version comes from `marketing.json`. `make release` waits for notarization and checks the signature, stapled ticket, and Gatekeeper acceptance before packaging. It refuses to overwrite existing DMG/ZIP files; move previous artifacts aside before rerunning. `make publish` requires the tag to exist on GitHub and verifies package checksums.

The export plists use `method=developer-id`; `destination=upload` sends to Apple's notary service, **not App Store Connect publishing**. Keep the bundle identifier `M5.CutAndMove` and team `FS6453639M`. Downloads are available from GitHub Releases. Update `marketing.json` only after a new release is actually published.

<!-- preview-version:start -->
## New in v2.0.1

Published release. The enhancements below describe the current source, not an older download.
<!-- preview-version:end -->

- **Finder Sync extension:** right-click Cut, Move Here, and Cancel Cut commands.
- **Visible cut selection:** scissors badges and a Finder toolbar menu.
- **Keyboard + mouse:** share pending files between the keyboard helper and Finder actions.
- **Safe menu moves:** reject collisions and changed sources; retain unmoved items after partial failures.
- **All-folder coverage:** enable the extension once; local folders and mounted drives are covered automatically.
- **Correct keyboard remapping:** fix the Unicode override that could leave text on the clipboard.

See [verification status](docs/REVIEW_VERIFICATION.md) for test coverage and remaining live-Finder checks.

<!-- faq:start -->
## Frequently asked questions

### What is Cut & Move?

Cut & Move is a native macOS menu bar utility that adds Cmd+X followed by Cmd+V for moving files in Finder. It uses Finder's built-in Move Item Here command rather than replacing Finder.

### How do I cut and paste files on a Mac?

Without an app, select files in Finder, press Cmd+C, open the destination, then press Cmd+Option+V to move them. With Cut & Move running, use Cmd+X followed by Cmd+V instead.

### Which version can I download?

The published download is Cut & Move v2.0.1, available as a Developer ID signed, Apple-notarized DMG or ZIP on GitHub Releases. The current source is v2.0.1 (published release). It is not distributed through the Mac App Store.

### What are the macOS and hardware requirements?

Cut & Move v2.0.1 requires macOS 26.1 or later and supports Apple silicon only (M1 or later).

### Why does Cut & Move need Accessibility permission?

Accessibility permission lets the app intercept and modify keyboard events for Finder shortcuts. The app does not record keystrokes, collect analytics, or transmit file contents. You can revoke access in System Settings > Privacy & Security > Accessibility.

### Does Cut & Move change shortcuts in other apps?

Cut & Move targets Finder. Other apps keep their normal Cmd+X and Cmd+V behavior. Keyboard moves use Finder's Move Item Here command and conflict dialogs.

### What does Finder integration add in v2.0.1?

The v2.0.1 current source adds a Finder Sync extension with right-click Cut, Move Here, and Cancel Cut, a toolbar menu, and pending-cut badges. Enable it once for automatic coverage of local folders and mounted drives; no folder setup is needed. macOS permissions still apply. The main app performs menu-driven moves without automatic overwrites. These features require the current source version; check the published download version before installing.

### How do I cancel cut mode?

Press Escape or Cmd+C to cancel a pending cut. The menu bar scissors icon indicates whether cut mode is active.

### Is Cut & Move free or open source?

Cut & Move is free for uses permitted by PolyForm Strict 1.0.0. Its source is available on GitHub, but it is not offered under an unrestricted open-source license. Read LICENSE for use, modification, and distribution restrictions.

### Who makes Cut & Move and how do I get support?

Cut & Move was created by Richard Crane, Microsoft MVP and founder of MILL5. Contact rich@mill5.com for support.
<!-- faq:end -->

## Architecture


```
CutAndMove/
  CutAndMoveApp.swift          # App entry point, menu bar UI, window definitions
  GlobalKeyboardHandler.swift  # Core keyboard interception via CGEvent tap
  FinderIntegration.swift      # Shared keyboard/menu cut state and requests
  FileMoveService.swift        # Validated menu-driven file moves
  LaunchManager.swift          # Launch-at-login via ServiceManagement
  PermissionsView.swift        # Accessibility permissions request UI
  AboutView.swift              # About window
  Assets.xcassets/             # App icons and colors
CutAndMoveFinder/
  FinderSync.swift             # Native Finder menus, toolbar, and badges
Shared/
  FinderBridge.swift           # Local app-group communication
```

The keyboard interception uses a `CGEvent` tap (`CFMachPort`) on the main run loop. A tested synchronous state machine transforms real key-down/key-up pairs; it does not inject synthetic keystrokes. Accessibility focus checks protect text fields, and disabled event taps are automatically recovered.

## Tech Stack

- **Swift** + **SwiftUI** + **Cocoa**
- CGEvent / CFMachPort for low-level keyboard access
- ServiceManagement (SMAppService) for login items
- Finder Sync for contextual actions, toolbar, and pending-cut badges
- No third-party dependencies

## Credits

Created by **[Richard Crane](https://mvp.microsoft.com/en-US/MVP/profile/10ce0bc0-7536-43f6-b28c-e9601a4a0d0d)** — Microsoft MVP and founder of **[MILL5](https://mill5.com)**.

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
