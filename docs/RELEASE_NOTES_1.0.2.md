# Cut & Move 1.0.2

- Full-bleed app icon without the old gray surround or inset border, at every icon size.
- Finder search and rename fields retain native text editing. Unknown or inaccessible controls are left unchanged.
- Plain Command shortcuts are matched precisely, with consistent key-down/key-up transformations and repeat suppression.
- Cut state is synchronous and clears on application switches, including mouse-only switches.
- Paste becomes a move only after a fresh file copy; stale or replaced clipboards do not become moves.
- Disabled keyboard taps recover automatically; revoking Accessibility access stops monitoring. Readiness reflects actual tap status.
- Native Accessibility permission prompting at launch, automatic permission rechecks, and visible monitoring errors.
- Launch-at-login approval guidance and user-visible errors.
- Hardened-runtime library validation enabled, hosted test signing aligned, support/copyright information corrected, and personal Xcode metadata removed from version control.
- Regression coverage for shortcuts, focus classification, clipboard safety, monitoring decisions, and login-item outcomes.

Requires macOS 26.1+. Developer ID signed and Apple notarized; downloads are available through GitHub Releases. The macOS icon presentation may apply its own mask. No App Store submission.
