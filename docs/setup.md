# Setup Guide

> How to build, install, and configure **Cut & Move** on macOS.

## Contents

- [Prerequisites](#prerequisites)
- [Building from Source](#building-from-source)
- [Granting Accessibility Permissions](#granting-accessibility-permissions)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Build Settings Notes](#build-settings-notes)

---

## Prerequisites

- **macOS 26.1** or later
- **Xcode** (latest version recommended)

## Building from Source

1. Clone the repository.
2. Open `CutAndMove.xcodeproj` in Xcode.
3. Select the **CutAndMove** scheme and a **My Mac** destination.
4. Build and run with **⌘R**.

The app will appear as a **scissors icon** in your menu bar.

## Granting Accessibility Permissions

Cut & Move requires **Accessibility** permissions to intercept keyboard events. Without these, the app cannot function.

### On first launch

1. The menu bar will show **"Permissions Missing"** in the dropdown.
2. Click **Fix Permissions…** to open the permissions window.
3. Click **Open System Settings**.
4. In System Settings, navigate to **Privacy & Security → Accessibility**.
5. Find **Cut & Move** in the list and toggle it **on**.
6. You may need to unlock the settings with your password.

The permissions window auto-dismisses once access is granted.

### If permissions were denied

1. Open **System Settings → Privacy & Security → Accessibility**.
2. If Cut & Move is listed but disabled, toggle it **on**.
3. If Cut & Move is not listed, remove and re-add it, or restart the app.

### Why Accessibility permissions?

The app uses a low-level `CGEvent` tap to intercept keyboard events before they reach Finder. macOS requires Accessibility permissions for any app that monitors or modifies input events from other applications — a security measure to prevent keyloggers.

**Cut & Move only intercepts events when Finder is the active application.** It never records, logs, or transmits keystrokes.

## Configuration

### Launch at login

From the menu bar dropdown, click **Launch at Login** to toggle auto-start. A checkmark indicates it's enabled.

This uses the macOS `SMAppService` API — no login items or LaunchAgents are created manually.

### Quitting

Click the scissors icon in the menu bar, then click **Quit**.

## Troubleshooting

| Problem | Solution |
| :--- | :--- |
| **Scissors icon not in menu bar** | Build and run from Xcode; the app has no Dock icon by design. |
| **"Permissions Missing" won't go away** | Restart the app after granting Accessibility permissions. |
| **Cmd+X does nothing in Finder** | Check that Accessibility permissions are granted and the menu shows **"Ready to Cut"**. |
| **Cut mode stuck (filled icon)** | Press **Escape** or **Cmd+C** to cancel, or switch away from Finder. |
| **App Sandbox errors** | The app requires sandbox to be disabled — verify in Xcode build settings. |

## Build Settings Notes

| Setting | Value |
| :--- | :--- |
| **App Sandbox** | Disabled *(required for `CGEvent` tap)* |
| **Hardened Runtime** | Enabled |
| **Code Signing** | Automatic |
| **Deployment Target** | macOS 26.1 |
