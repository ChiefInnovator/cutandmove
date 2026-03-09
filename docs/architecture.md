# Architecture

## Overview

Cut & Move is a macOS menu bar utility built with SwiftUI. It intercepts keyboard events system-wide (when Finder is active) using a low-level CGEvent tap, converting Cmd+X/Cmd+V into Finder's native cut-and-move operation (Cmd+Option+V).

## Component Diagram

```
┌──────────────────────────────────────────────────┐
│             CutAndMoveApp (Entry Point)          │
│           MenuBarExtra + Window Scenes           │
└──────┬────────────────────────────┬──────────────┘
       │                            │
┌──────▼──────────┐     ┌──────────▼──────────────┐
│    AppMenu       │     │   Window Scenes         │
│  (Menu Content)  │     │  - AboutView            │
│                  │     │  - PermissionsView       │
└──────┬──────────┘     └──────────────────────────┘
       │
┌──────▼──────────────────────────────────┐
│   GlobalKeyboardHandler (Singleton)     │
│   - CGEvent tap via CFMachPort          │
│   - Keyboard event interception         │
│   - Accessibility permission checks     │
│   - @Published state for SwiftUI        │
└──────┬──────────────────────────────────┘
       │
┌──────▼──────────────────────────────────┐
│   LaunchManager (Singleton)             │
│   - SMAppService for login items        │
│   - @Published state for SwiftUI        │
└─────────────────────────────────────────┘
```

## Key Design Decisions

### CGEvent Tap for Keyboard Interception

The app uses `CGEvent.tapCreate()` with a `CFMachPort` to intercept keyboard events at the macOS session level. This is the lowest-level approach available without a kernel extension, chosen because:

- It can **suppress** events (return `nil` to swallow Cmd+X)
- It can **modify** events in-flight (inject the Option flag into Cmd+V)
- It operates before events reach any application

This requires Accessibility permissions and the App Sandbox to be **disabled**.

### Magic Number Tagging (0xCAFE)

When the app simulates a Cmd+C keystroke (after intercepting Cmd+X), the simulated event would itself be intercepted by the same event tap, creating an infinite loop. To prevent this, simulated events are tagged with a magic number (`0xCAFE`) in the `eventSourceUserData` field. The handler checks for this tag and passes tagged events through without processing.

### Finder-Only Scope

The event handler checks `NSWorkspace.shared.frontmostApplication` on every keyboard event. If the active app is not Finder (`com.apple.finder`), the event passes through unmodified. This ensures the app never interferes with keyboard shortcuts in other applications.

### Singleton Pattern

Both `GlobalKeyboardHandler` and `LaunchManager` use the singleton pattern. The keyboard handler must be a single instance because only one CGEvent tap should exist. Both singletons conform to `ObservableObject` so SwiftUI views can reactively bind to their state.

## Event Flow

### Cut Operation (Cmd+X)

```
User presses Cmd+X in Finder
  → CGEvent tap intercepts keyDown
  → Handler verifies Finder is frontmost
  → Handler sets isCutModeActive = true
  → Handler simulates Cmd+C (tagged with 0xCAFE)
  → Handler returns nil (suppresses original Cmd+X)
  → Menu bar icon changes to filled scissors
```

### Move Operation (Cmd+V after cut)

```
User presses Cmd+V in Finder (while cut mode active)
  → CGEvent tap intercepts keyDown
  → Handler verifies Finder is frontmost and cut mode is active
  → Handler injects .maskAlternate flag into the event
  → Modified event (now Cmd+Option+V) continues to Finder
  → Finder performs "Move Item Here" instead of "Paste Item"
  → Handler sets isCutModeActive = false
  → Menu bar icon returns to normal scissors
```

### Cancel

```
User presses Escape or Cmd+C
  → Handler sets isCutModeActive = false
  → Menu bar icon returns to normal
  → Original event passes through normally
```

## Files

| File | Lines | Purpose |
|------|-------|---------|
| `CutAndMoveApp.swift` | 92 | App entry point, MenuBarExtra definition, AppMenu view, window scenes |
| `GlobalKeyboardHandler.swift` | 174 | Core keyboard interception, event processing, permission management |
| `LaunchManager.swift` | 43 | Launch-at-login toggle using ServiceManagement framework |
| `PermissionsView.swift` | 66 | UI for requesting and confirming Accessibility permissions |
| `AboutView.swift` | 83 | About window with app info, version, links |
