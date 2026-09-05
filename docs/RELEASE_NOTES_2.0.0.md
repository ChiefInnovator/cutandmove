# Cut & Move v2.0.0

Version 2.0.0 (build 5). Direct download for macOS, signed by MILL5 and notarized by Apple.

- Native Finder Sync extension with **Cut with Cut & Move**, **Move Here**, and **Cancel Cut** contextual actions.
- Finder toolbar menu and scissors badges on items waiting to move.
- Shared cut selection: keyboard Cut can be completed through the Finder menu, and menu Cut can be completed with Cmd+V when keyboard monitoring is enabled.
- Finder extension enablement status in the app menu, with automatic coverage for all local folders and mounted drives. No folder picker or allowlist.
- Menu-driven moves reject existing destinations, stale/replaced sources, duplicate selections, and moving a folder into itself. Partial failures retain the remaining selection and display a status message; no automatic overwrites.
- Keyboard remapping fix: preserve native key translation rather than injecting Unicode text, preventing the stale-text clipboard/text-clipping failure.
- No App Store dependency. The embedded extension and app use MILL5 signing and a local shared app-group container.

Enable the extension using **Enable / Manage Finder Extension…** in Cut & Move. In Finder, use **Customize Toolbar…** to add the Cut & Move button if it is not shown. Folder coverage is automatic; protected/read-only locations still obey macOS permissions, and virtual views may not expose a destination. Other Finder extensions and cloud providers can affect which badges Finder displays. Accessibility permission is still required for Cmd+X/Cmd+V remapping, not for the Finder menu commands.
