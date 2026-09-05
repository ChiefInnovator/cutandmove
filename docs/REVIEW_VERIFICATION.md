# Mixed keyboard/context-menu verification — v2.0.0 (build 5)

Completed on September 5, 2026 against the actual universal Developer ID signed
app and embedded Finder Sync extension, built from `8fd379d` (merged as
`afb23a3`). This test did not substitute a diagnostic keyboard event tap for the
running app.

| Finder view | Cmd+X → context-menu Move Here | Context-menu Cut → Cmd+V |
| --- | --- | --- |
| List | Passed | Passed |
| Icon | Passed | Passed |
| Column | Passed | Passed |
| Gallery | Passed | Passed |

All eight cases verified removal from the source, byte-for-byte preservation at
the destination, no text-clipping output, and cleared pending-cut state. Automated
keyboard Cut cases began with text on the clipboard to exercise the original reported
failure. Context-menu actions were selected through Finder's actual UI, not by
writing requests directly to the app-group bridge. Column-view cases used the
visible Finder menu after the automation could not locate its menu hierarchy.

The initial run found a stale local registration pointing to an Xcode archive
staging directory that no longer existed. That registration was removed and
Finder was restarted with the signed app's existing embedded extension
registered. The successful tests used
`build/export-2.0.0-validated/CutAndMove.app`; app and extension signature
verification passed. No production-code changes were required.

This completes the previously outstanding mixed keyboard/context-menu smoke
test. It does not constitute notarization, publication, or installation of a new
DMG, nor does it claim exhaustive coverage of every filesystem or Finder view.

---

# Finder shortcut fix — unreleased after 1.0.3

The explicit `keyboardSetUnicodeString` override on the remapped Cmd+X event
prevented Finder from executing Copy in a live test. The clipboard retained its
previous text, so the subsequent ordinary Paste could create a text clipping.
The fix changes only the virtual keycode and lets macOS perform key translation.

## Live regression coverage

Run `make test-finder` with Accessibility and Finder Automation access. This is
an opt-in desktop test: do not type while it runs. It compiles the production
shortcut state and focus guard into a temporary event-tap harness, opens only
disposable Finder fixtures, restores the previous clipboard if unchanged by
another application, and removes its own fixtures. It does not test the packaged
app's permissions or startup lifecycle.

- The pre-fix shortcut state fails: Cmd+X does not place the selected file URL on
  the clipboard. The fixed state passes.
- List, icon, column, and gallery (`flow`) views: Cmd+X/Cmd+V moves the file,
  removes the source, preserves bytes, and creates no text clipping.
- Ordinary Cmd+C/Cmd+V still copies in all four views.
- The harness waits for file focus after switching view styles before sending
  keyboard input. Text-field/unknown-focus protection remains unchanged.
- The unit regression checks that remapping preserves the original Unicode
  payload while AppKit translates the new keycode as Copy.

These checks do not constitute publication or installation of a new release.

---

# Historical review fix verification — 1.0.2

## Completed

- Finder focus guards for text editors and unknown/inaccessible controls.
- Disabled event-tap recovery, trust revocation teardown, and honest monitoring status.
- Synchronous state, mouse-only app-switch cancellation, precise modifier matching, paired key events, Unicode remapping, repeat suppression, and clipboard freshness/file guards.
- User-visible login-item errors and approval-required guidance.
- Native Accessibility prompt at launch and automatic permission refresh.
- Library validation enabled in Debug and Release; hosted unit tests signed with the app's team.
- Consistent copyright/support information; personal Xcode files untracked with local copies retained.
- Full-bleed icon in all seven sizes, also referenced by the website.

## Verified locally

- 18 parameterized unit-test executions passed (11 test functions).
- All 4 UI-test executions passed after Apple-account access was restored (22 total test executions).
- Universal Release archive built successfully with hardened runtime; release entitlements contain no library-validation exception.
- Icon dimensions verified from 16 to 1024 pixels; 1024 and 128 pixel artwork visually inspected.
- Git whitespace validation passed.

## Distribution validation

- MILL5 Developer ID signing, Apple notarization, stapled-ticket validation, and Gatekeeper assessment passed.
- The exported app's bundled icon was extracted and visually checked: it contains the full-bleed replacement, not the old gray surround.

## Remaining interactive verification

- Real Finder file moves/search/rename and permission-revocation smoke tests have not been completed for this build. Unit focus tests exercise classification rather than live Finder AX queries.

Earlier Xcode account and UI-runner environment blockers were resolved. The previous 1.0.1 release and its local artifacts were preserved.
