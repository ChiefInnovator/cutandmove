import Cocoa

/// Synchronous state owned by the main-run-loop event tap. No system side effects.
struct ShortcutState {
    private var expectedClipboard: Int?
    private var cutKeyHeld = false
    private var moveKeyHeld = false
    private var blockedMoveKeys = Set<Int64>()
    var isCutModeActive: Bool { expectedClipboard != nil }
    var cutClipboard: Int? { expectedClipboard }

    mutating func armCut(clipboard: Int) {
        reset()
        expectedClipboard = clipboard
    }

    mutating func reset() {
        expectedClipboard = nil
        cutKeyHeld = false
        moveKeyHeld = false
        blockedMoveKeys.removeAll()
    }

    /// Returns false for repeats or shortcut pairs blocked during a menu move.
    mutating func process(_ event: CGEvent, fileContext: Bool, clipboard: Int, hasFiles: Bool, fileMoveInProgress: Bool = false) -> Bool {
        let key = event.getIntegerValueField(.keyboardEventKeycode)
        let down = event.type == .keyDown
        let up = event.type == .keyUp
        let repeated = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        guard down || up else { return true }

        if blockedMoveKeys.contains(key) {
            if up { blockedMoveKeys.remove(key) }
            return false
        }

        // Finish pairs even if Command was released before the letter key.
        if key == 7 && cutKeyHeld {
            if up {
                cutKeyHeld = false
                remapToCopy(event)
                event.flags.insert(.maskCommand)
            }
            return up
        }
        if key == 9 && moveKeyHeld {
            if up {
                moveKeyHeld = false
                event.flags.formUnion([.maskCommand, .maskAlternate])
            }
            return up
        }
        guard down else { return true }
        let modifiers = event.flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])
        let commandOnly = modifiers == .maskCommand
        if key == 53 || (key == 8 && event.flags.contains(.maskCommand)) {
            expectedClipboard = nil
        }
        guard fileContext else {
            expectedClipboard = nil
            return true
        }
        if fileMoveInProgress && commandOnly && (key == 7 || key == 9) {
            blockedMoveKeys.insert(key)
            return false
        }
        guard commandOnly, !repeated else { return true }
        if key == 7 {
            expectedClipboard = clipboard + 1
            cutKeyHeld = true
            // Transform the real event, avoiding asynchronous synthetic Cmd+C races.
            remapToCopy(event)
        } else if key == 9, let expected = expectedClipboard {
            expectedClipboard = nil
            guard clipboard == expected, hasFiles else { return true }
            event.flags.insert(.maskAlternate)
            moveKeyHeld = true
        }
        return true
    }

    private func remapToCopy(_ event: CGEvent) {
        event.setIntegerValueField(.keyboardEventKeycode, value: 8)
        // Let macOS translate the keycode. An explicit Unicode payload makes Finder
        // treat the remapped shortcut as text instead of executing its Copy command.
    }
}
