# Architecture

Cut & Move v2.0.0 combines a SwiftUI menu-bar app, a main-run-loop CGEvent tap, and a sandboxed Finder Sync extension. Keyboard moves use Finder's native commands. Explicit Finder-extension menu moves use the main app's validated file-move service.

## Keyboard path

1. The tap handles disabled-tap notifications before ordinary events. It clears pending cut state and rechecks trust before re-enabling.
2. Events outside Finder pass through unchanged and clear pending state. Workspace activation notifications also clear state immediately, including mouse-only application switches.
3. Relevant Cmd+X/Cmd+V key-downs query Finder's focused Accessibility element with a bounded messaging timeout. Known file views are allowed; editable fields, unknown controls, and failed AX queries are not.
4. `ShortcutState` transforms a real Cmd+X key-down and its matching key-up into Cmd+C by changing the virtual keycode only. Explicit Unicode injection broke Finder's Copy command and is deliberately avoided. It records the expected pasteboard change count.
5. A plain Cmd+V becomes Cmd+Option+V only when the clipboard has the expected new change count and contains file URLs. A failed copy, non-file copy, or replacement clipboard does not become a move.
6. Matching key-up events keep the transformed modifiers even if Command was released first. Held-key repeats cannot copy or move repeatedly.
7. Escape and Cmd+C cancel pending cut state. Shift/Option/Control combinations are not treated as plain Command shortcuts; Caps Lock is harmless.

The state machine is synchronous; there are no queued cut-state updates and no synthetic event posting. A successful move consumes cut mode. The icon indicates a pending cut, not a guarantee that Finder has completed a filesystem operation.

## Finder extension and menu moves

`CutAndMoveFinder.appex` supplies contextual actions, a toolbar menu, and pending-cut badges in configured directories. Finder supplies selected/target URLs within menu callbacks. The extension snapshots each menu's action context; it cannot replace Finder's built-in keyboard handling.

`Shared/FinderBridge.swift` exchanges immutable request files and atomic status snapshots in the `FS6453639M.CutAndMove` app group. Both targets are signed by MILL5. The extension is sandboxed and has no general file-write entitlement. It launches its containing app without activating it. The host alone performs file operations and owns an exclusive lock to prevent duplicate request consumers. Commands expire after 30 seconds; a move must match the current cut UUID and clipboard generation. Claimed requests are removed before execution, so a restart cannot repeat a destructive command.

`FinderIntegration` captures fresh keyboard file URLs after Finder completes Copy, and publishes the same selection to the extension. Menu Cut writes file URLs and arms the keyboard helper when available. Clipboard replacement/cancellation clears badges. Menus can work without Accessibility; keyboard actions still require it. File-access permissions are never bypassed.

`FileMoveService` snapshots source device/inode identity, preflights the full batch, and rejects replaced/missing sources, collisions, overlapping selections, same-folder moves, and destinations inside a source folder. Symbolic links are moved as links. Foundation handles cross-volume moves and refuses existing destinations. Work runs off the main actor. This is not an all-or-nothing transaction: partial I/O failures report how many moved and retain only remaining sources. It cannot eliminate every filesystem race caused by concurrent external changes. Quit is refused during a move; a crash may leave a partial operation requiring user inspection.

Finder Sync requires directory registration, so the extension automatically registers the filesystem root and all mounted volume roots, refreshing coverage as drives mount or unmount. Apple's `directoryURLs` API applies recursively to subdirectories. There is no user-configured folder allowlist, and old preview folder preferences are ignored. Registration does not enumerate file contents or grant permissions. Virtual Finder views may lack a destination URL, and badges are advisory and can be affected by other Finder extensions. See [Apple's directoryURLs documentation](https://developer.apple.com/documentation/findersync/fifindersynccontroller/directoryurls).

## Keyboard permissions and monitoring

`GlobalKeyboardHandler` owns the tap and its run-loop source, plus published UI status. It requests the native Accessibility prompt at application launch, rechecks every second and on app activation, tears down monitoring when trust is revoked, and retries creation/re-enabling while authorized. The menu reports readiness only when the tap is enabled. Creation failures are visible in the permissions window.

## Launch at login

`LaunchManager` reads `SMAppService.mainApp.status`, distinguishes approval-required from enabled/disabled, opens Login Items settings for approval, and publishes registration errors. Its service operations are injectable for tests; production uses ServiceManagement directly.

## Files

- `CutAndMoveApp.swift`: app lifecycle, menu, status and windows.
- `GlobalKeyboardHandler.swift`: tap lifecycle, permissions, Finder AX focus checks.
- `ShortcutState.swift`: deterministic shortcut and clipboard state machine.
- `LaunchManager.swift`: login-item status and actions.
- `FinderIntegration.swift`, `FileMoveService.swift`: shared cut state and validated menu moves.
- `Shared/FinderBridge.swift`: app-group requests, status, and menu action snapshots.
- `CutAndMoveFinder/FinderSync.swift`: native Finder menus, toolbar, and badges.
- `PermissionsView.swift`, `AboutView.swift`: user-facing guidance and app information.

## Verification boundaries

Unit tests exercise event pairs, modifiers, repeats, cancellation, clipboard guards, focus classification, monitoring decisions, Unicode remapping, login-item outcomes, menu snapshots, app-group storage, and safe file moves. Existing UI tests exercise launch behavior. The opt-in `make test-finder` harness checks keyboard moves and ordinary copies in real Finder views. Native toolbar Cut and Move Here have also been smoke-tested with source removal and content preservation verified. Live tests of the signed v2.0.0 app passed both keyboard Cut → context-menu Move Here and context-menu Cut → keyboard Paste in list, icon, column, and gallery views. All eight cases preserved file bytes, removed the source, created no text clipping, and cleared pending cut state. See [verification results](REVIEW_VERIFICATION.md); these smoke tests do not replace broader filesystem and permission testing.

Release builds retain hardened runtime and library validation. Both app and embedded extension use the same full version and MILL5 team. Distribution uses Developer ID signing and Apple notarization through GitHub Releases, not the Mac App Store. See the README for the release commands.
