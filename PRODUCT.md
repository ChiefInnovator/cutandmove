# Product: Cut & Move

<!-- impeccable:product-schema 1 -->

## Platform

web

This field scopes Impeccable's web tools to the static marketing surface,
index.html. The shipped product is a native macOS SwiftUI/AppKit menu-bar app,
not a browser app or an iOS app. Its surface brief declares macOS explicitly;
never apply web detector results or mobile touch sizing to native source.
Impeccable 4.8.0 has no macOS-specific platform enum/reference.

## Users

Mac users who reach for Cmd+X/Cmd+V when organizing files in Finder, and visitors
evaluating whether to download the utility. This audience is derived from the
README and current interface; no narrower market segment has been established.

## Product Purpose

Move selected Finder files using familiar cut/paste keys or native Finder menus.
Success means files reach the requested destination without unintended copying,
overwriting, text clipping, or interference with text editing and other apps.

## Positioning

A small native Finder utility: keyboard moves reuse Finder's Move Item Here;
explicit extension-menu moves use the containing app's validated file service.
The Finder toolbar, context menu, badges, and keyboard helper share pending state.

## Operating Context

The app lives in the menu bar without a Dock icon. Accessibility access is needed
for keyboard interception; extension menus have a separate enablement state.
Users select in Finder, cut, navigate, paste/move, or cancel with Escape/Cmd+C.
Launch at Login is optional and may require macOS approval. No account is needed.

## Capabilities and Constraints

- Version sources: Xcode `MARKETING_VERSION` for current source and marketing.json
  `released_version` for the published download. The generated README shows both.
- macOS 26.1+, Apple silicon only (M1 or later).
- GitHub Releases distributes Developer ID signed/notarized DMG and ZIP;
  no Mac App Store version.
- No keystroke recording, app telemetry, file-content upload, or third-party
  runtime dependencies. The marketing page naturally links to external sites.
- Menu moves reject conflicts/changed sources and retain remaining items after
  partial failure. They are not an all-or-nothing transaction or crash recovery.
- Finder badges are advisory. Filesystem permissions still apply. Virtual Finder
  views may lack a usable destination.
- License: PolyForm Strict 1.0.0; do not call it unrestricted open source.

## Brand Commitments

Use Cut & Move, existing scissors/face app icon, Richard Crane/MILL5 attribution,
and rich@mill5.com support. Preserve factual claims. Current website is the
existing identity reference; this task refines it without commissioning a rebrand.

## Evidence on Hand

README.md, docs/architecture.md, docs/setup.md, source/tests, and the release
record marketing.json. About Image.png and app icons are incumbent raster assets.
docs/REVIEW_VERIFICATION.md is dated historical v2.0.0 evidence, not this tree's
runtime acceptance. No customer testimonials or performance benchmarks supplied.

## Product Principles

- Preserve Finder and macOS conventions; do not replace file management.
- Fail closed on ambiguous keyboard context or stale destructive requests.
- Show pending selection, actual readiness, and recoverable operation errors.
- Keep permission, extension enablement, and login approval states distinct.
- Separate source/build, desktop behavior, signed-package, and release evidence.

## Accessibility & Inclusion

Use native semantic controls, readable status/error text, stable recovery actions,
and keyboard navigation. Website refinements target WCAG AA text contrast and
preserve its existing focus-visible/reduced-motion support; no full conformance
certification is claimed. Native VoiceOver and large-text acceptance require
runtime verification; do not infer them from a successful build.
