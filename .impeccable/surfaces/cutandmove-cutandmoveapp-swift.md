---
version: 1
slug: "cutandmove-cutandmoveapp-swift"
primary_target: "CutAndMove/CutAndMoveApp.swift"
related_targets: ["CutAndMove/PermissionsView.swift","CutAndMove/AboutView.swift","CutAndMoveFinder/FinderSync.swift"]
---

# Native menu, permissions, About, and Finder menus

Mode: Operate. Platform: macOS (SwiftUI/AppKit), not iOS or a web view.
Primary target: CutAndMove/CutAndMoveApp.swift. Related: PermissionsView.swift,
AboutView.swift, CutAndMoveFinder/FinderSync.swift. User job: inspect readiness,
recover permission/monitoring, manage login, and move/cancel a Finder selection.
Use native semantic typography, menu density, symbols, and system controls.
Keep keyboard, extension, login approval, and actual operation state distinct.
Recovery should remain readable; success must not disappear on a timer. Preserve
cut/clipboard/source/destination safety and partial-failure messages.
This is an existing-interface refinement, not a new visual world. Verify native
states where the app can be captured; label source-only findings and historical
assets explicitly. Browser detectors and mobile touch-target rules do not apply.
No layout choice or reviewer result proves live Finder or signed-release safety.
