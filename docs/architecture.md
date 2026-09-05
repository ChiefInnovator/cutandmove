# Architecture

Cut & Move is a SwiftUI menu-bar app with a main-run-loop CGEvent tap. It changes Finder file shortcuts, not filesystem contents: Finder remains responsible for all copy/move operations and conflict dialogs.

## Keyboard path

1. The tap handles disabled-tap notifications before ordinary events. It clears pending cut state and rechecks trust before re-enabling.
2. Events outside Finder pass through unchanged and clear pending state. Workspace activation notifications also clear state immediately, including mouse-only application switches.
3. Relevant Cmd+X/Cmd+V key-downs query Finder's focused Accessibility element with a bounded messaging timeout. Known file views are allowed; editable fields, unknown controls, and failed AX queries are not.
4. `ShortcutState` transforms a real Cmd+X key-down and its matching key-up into Cmd+C, including the Unicode character. It records the expected pasteboard change count.
5. A plain Cmd+V becomes Cmd+Option+V only when the clipboard has the expected new change count and contains file URLs. A failed copy, non-file copy, or replacement clipboard does not become a move.
6. Matching key-up events keep the transformed modifiers even if Command was released first. Held-key repeats cannot copy or move repeatedly.
7. Escape and Cmd+C cancel pending cut state. Shift/Option/Control combinations are not treated as plain Command shortcuts; Caps Lock is harmless.

The state machine is synchronous; there are no queued cut-state updates and no synthetic event posting. A successful move consumes cut mode. The icon indicates a pending cut, not a guarantee that Finder has completed a filesystem operation.

## Permissions and monitoring

`GlobalKeyboardHandler` owns the tap and its run-loop source, plus published UI status. It requests the native Accessibility prompt at application launch, rechecks every second and on app activation, tears down monitoring when trust is revoked, and retries creation/re-enabling while authorized. The menu reports readiness only when the tap is enabled. Creation failures are visible in the permissions window.

## Launch at login

`LaunchManager` reads `SMAppService.mainApp.status`, distinguishes approval-required from enabled/disabled, opens Login Items settings for approval, and publishes registration errors. Its service operations are injectable for tests; production uses ServiceManagement directly.

## Files

- `CutAndMoveApp.swift`: app lifecycle, menu, status and windows.
- `GlobalKeyboardHandler.swift`: tap lifecycle, permissions, Finder AX focus checks.
- `ShortcutState.swift`: deterministic shortcut and clipboard state machine.
- `LaunchManager.swift`: login-item status and actions.
- `PermissionsView.swift`, `AboutView.swift`: user-facing guidance and app information.

## Verification boundaries

Unit tests exercise event pairs, modifiers, repeats, cancellation, clipboard guards, focus classification, monitoring decisions, Unicode remapping, and login-item outcomes. Existing UI tests exercise launch behavior. AX role classification and clipboard timing in real Finder views still require interactive smoke testing; unit tests do not replace that.

Release builds retain hardened runtime and library validation. Distribution is Developer ID signed and Apple notarized, through private GitHub Releases rather than the Mac App Store. See the README for the release commands.
