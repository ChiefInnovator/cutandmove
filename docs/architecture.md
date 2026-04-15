# Architecture

> Internal technical design of **Cut & Move** — how the macOS menu bar utility intercepts keyboard events and turns Cmd+X / Cmd+V into Finder's native cut-and-move.

## Contents

- [Overview](#overview)
- [Component Diagram](#component-diagram)
- [Key Design Decisions](#key-design-decisions)
- [Event Flow](#event-flow)
- [Files](#files)

---

## Overview

Cut & Move is a macOS menu bar utility built with **SwiftUI**. It intercepts keyboard events system-wide (while Finder is active) using a low-level `CGEvent` tap, converting the user's `Cmd+X` / `Cmd+V` sequence into Finder's native cut-and-move operation (`Cmd+Option+V`).

## Component Diagram

```text
┌──────────────────────────────────────────────────┐
│            CutAndMoveApp (Entry Point)           │
│           MenuBarExtra + Window Scenes           │
└──────┬────────────────────────────┬──────────────┘
       │                            │
┌──────▼─────────┐      ┌────────────▼─────────────┐
│     AppMenu    │      │      Window Scenes       │
│  (menu items)  │      │   • AboutView            │
│                │      │   • PermissionsView      │
└──────┬─────────┘      └──────────────────────────┘
       │
┌──────▼──────────────────────────────────┐
│   GlobalKeyboardHandler (Singleton)     │
│   • CGEvent tap via CFMachPort          │
│   • Keyboard event interception         │
│   • Accessibility permission checks     │
│   • @Published state for SwiftUI        │
└──────┬──────────────────────────────────┘
       │
┌──────▼──────────────────────────────────┐
│   LaunchManager (Singleton)             │
│   • SMAppService for login items        │
│   • @Published state for SwiftUI        │
└─────────────────────────────────────────┘
```

## Key Design Decisions

### CGEvent tap for keyboard interception

The app uses `CGEvent.tapCreate()` with a `CFMachPort` to intercept keyboard events at the macOS session level. This is the lowest-level approach available without a kernel extension, chosen because it can:

- **Suppress** events — return `nil` to swallow `Cmd+X` entirely.
- **Modify** events in flight — inject the `Option` flag into `Cmd+V`.
- **Run before delivery** — events are processed before any application receives them.

This approach requires Accessibility permissions and the App Sandbox must be **disabled**.

### Magic number tagging (`0xCAFE`)

When the app simulates a `Cmd+C` keystroke (after intercepting `Cmd+X`), the simulated event would itself be intercepted by the same event tap, creating an infinite loop.

To prevent this, simulated events are tagged with a magic number (`0xCAFE`) in the `eventSourceUserData` field. The handler checks for this tag and passes tagged events through without processing.

### Finder-only scope

The event handler checks `NSWorkspace.shared.frontmostApplication` on every keyboard event. If the active app is **not** Finder (`com.apple.finder`), the event passes through unmodified.

This ensures the app never interferes with keyboard shortcuts in any other application.

### Singleton pattern

Both `GlobalKeyboardHandler` and `LaunchManager` use the singleton pattern:

- The keyboard handler must be a single instance because only one `CGEvent` tap should exist.
- Both singletons conform to `ObservableObject` so SwiftUI views can reactively bind to their state.

## Event Flow

### Cut operation — `Cmd+X`

```text
User presses Cmd+X in Finder
  ↓
CGEvent tap intercepts keyDown
  ↓
Handler verifies Finder is frontmost
  ↓
Handler sets isCutModeActive = true
  ↓
Handler simulates Cmd+C (tagged with 0xCAFE)
  ↓
Handler returns nil (suppresses original Cmd+X)
  ↓
Menu bar icon changes to filled scissors
```

### Move operation — `Cmd+V` (after cut)

```text
User presses Cmd+V in Finder (cut mode active)
  ↓
CGEvent tap intercepts keyDown
  ↓
Handler verifies Finder is frontmost AND cut mode is active
  ↓
Handler injects .maskAlternate flag into the event
  ↓
Modified event (now Cmd+Option+V) continues to Finder
  ↓
Finder performs "Move Item Here" instead of "Paste Item"
  ↓
Handler sets isCutModeActive = false
  ↓
Menu bar icon returns to normal scissors
```

### Cancel — `Escape` or `Cmd+C`

```text
User presses Escape or Cmd+C
  ↓
Handler sets isCutModeActive = false
  ↓
Menu bar icon returns to normal
  ↓
Original event passes through normally
```

## Files

|File|Lines|Purpose|
|:---|---:|:---|
|[`CutAndMoveApp.swift`](../CutAndMove/CutAndMoveApp.swift)|92|App entry point, `MenuBarExtra` definition, `AppMenu` view, window scenes|
|[`GlobalKeyboardHandler.swift`](../CutAndMove/GlobalKeyboardHandler.swift)|174|Core keyboard interception, event processing, permission management|
|[`LaunchManager.swift`](../CutAndMove/LaunchManager.swift)|43|Launch-at-login toggle via the ServiceManagement framework|
|[`PermissionsView.swift`](../CutAndMove/PermissionsView.swift)|66|UI for requesting and confirming Accessibility permissions|
|[`AboutView.swift`](../CutAndMove/AboutView.swift)|83|About window with app info, version, and links|
