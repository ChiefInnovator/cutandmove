//
//  CutAndMoveTests.swift
//  CutAndMoveTests
//
//  Created by Richard Crane on 11/19/25.
//

import Cocoa
import ServiceManagement
import Testing
@testable import CutAndMove

@MainActor
struct CutAndMoveTests {
    func event(_ key: CGKeyCode, down: Bool = true, flags: CGEventFlags = .maskCommand, repeatKey: Bool = false) -> CGEvent {
        let e = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: down)!
        e.flags = flags
        e.setIntegerValueField(.keyboardEventAutorepeat, value: repeatKey ? 1 : 0)
        return e
    }
    @Test func cutAndMovePairs() {
        var s = ShortcutState()
        let cut = event(7)
        #expect({ s.process(cut, fileContext: true, clipboard: 10, hasFiles: false) }())
        #expect(cut.getIntegerValueField(.keyboardEventKeycode) == 8)
        let cutUp = event(7, down: false, flags: [])
        #expect({ s.process(cutUp, fileContext: true, clipboard: 11, hasFiles: true) }())
        #expect(cutUp.getIntegerValueField(.keyboardEventKeycode) == 8)
        #expect(cutUp.flags.contains(.maskCommand))
        let paste = event(9)
        #expect({ s.process(paste, fileContext: true, clipboard: 11, hasFiles: true) }())
        #expect(paste.flags.contains(.maskAlternate))
        #expect(!s.isCutModeActive)
        let up = event(9, down: false, flags: [])
        #expect({ s.process(up, fileContext: true, clipboard: 11, hasFiles: true) }())
        #expect(up.flags.contains([.maskCommand, .maskAlternate]))
    }
    @Test(arguments: [CGEventFlags.maskShift, .maskAlternate, .maskControl])
    func extraModifiersPassThrough(extra: CGEventFlags) {
        var s = ShortcutState()
        let cut = event(7, flags: [.maskCommand, extra])
        #expect({ s.process(cut, fileContext: true, clipboard: 0, hasFiles: true) }())
        #expect(cut.getIntegerValueField(.keyboardEventKeycode) == 7)
        #expect(!s.isCutModeActive)
    }
    @Test func textAndCapsLock() {
        var s = ShortcutState()
        let text = event(7)
        _ = s.process(text, fileContext: false, clipboard: 0, hasFiles: false)
        #expect(text.getIntegerValueField(.keyboardEventKeycode) == 7)
        let cut = event(7, flags: [.maskCommand, .maskAlphaShift])
        _ = s.process(cut, fileContext: true, clipboard: 0, hasFiles: true)
        #expect(cut.getIntegerValueField(.keyboardEventKeycode) == 8)
    }
    @Test(arguments: [CGKeyCode(53), 8])
    func cancellation(key: CGKeyCode) {
        var s = ShortcutState()
        _ = s.process(event(7), fileContext: true, clipboard: 0, hasFiles: true)
        _ = s.process(event(key), fileContext: true, clipboard: 1, hasFiles: true)
        #expect(!s.isCutModeActive)
    }
    @Test func invalidClipboardNeverMoves() {
        for (count, files) in [(10, true), (11, false), (12, true)] {
            var s = ShortcutState()
            _ = s.process(event(7), fileContext: true, clipboard: 10, hasFiles: true)
            let paste = event(9)
            _ = s.process(paste, fileContext: true, clipboard: count, hasFiles: files)
            #expect(!paste.flags.contains(.maskAlternate))
        }
    }
    @Test func repeatAndSwitch() {
        var s = ShortcutState()
        _ = s.process(event(7), fileContext: true, clipboard: 0, hasFiles: false)
        #expect({ !s.process(event(7, repeatKey: true), fileContext: true, clipboard: 1, hasFiles: true) }())
        _ = s.process(event(9), fileContext: true, clipboard: 1, hasFiles: true)
        #expect({ !s.process(event(9, repeatKey: true), fileContext: true, clipboard: 1, hasFiles: true) }())
        s.reset()
        _ = s.process(event(7), fileContext: true, clipboard: 1, hasFiles: true)
        #expect(s.isCutModeActive)
        s.reset() // Mouse-only application activation, without an intervening key.
        let paste = event(9)
        _ = s.process(paste, fileContext: true, clipboard: 2, hasFiles: true)
        #expect(!paste.flags.contains(.maskAlternate))
    }

    @Test(arguments: ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField", "AXButton"])
    func unsafeFocus(role: String) {
        #expect(!FinderFocus.allowsFileShortcuts(roles: [role, "AXScrollArea"], editable: false))
    }
    @Test func knownFileFocus() {
        #expect(FinderFocus.allowsFileShortcuts(roles: ["AXOutline"], editable: false))
        #expect(FinderFocus.allowsFileShortcuts(roles: ["AXCell", "AXTable"], editable: false))
        #expect(FinderFocus.allowsFileShortcuts(roles: ["AXGroup", "AXScrollArea"], editable: false))
        #expect(!FinderFocus.allowsFileShortcuts(roles: ["AXGroup", "AXWindow"], editable: false))
        #expect(!FinderFocus.allowsFileShortcuts(roles: ["AXGroup", "AXTextField", "AXScrollArea"], editable: false))
        #expect(!FinderFocus.allowsFileShortcuts(roles: ["AXOutline"], editable: true))
        #expect(!FinderFocus.allowsFileShortcuts(roles: [], editable: false))
    }
    @Test func permissionAndTapRecoveryDecisions() {
        #expect(GlobalKeyboardHandler.monitoringAction(trusted: false, hasTap: true, enabled: true) == .stop)
        #expect(GlobalKeyboardHandler.monitoringAction(trusted: false, hasTap: false, enabled: false) == .stop)
        #expect(GlobalKeyboardHandler.monitoringAction(trusted: true, hasTap: false, enabled: false) == .start)
        #expect(GlobalKeyboardHandler.monitoringAction(trusted: true, hasTap: true, enabled: false) == .enable)
        #expect(GlobalKeyboardHandler.monitoringAction(trusted: true, hasTap: true, enabled: true) == .none)
    }
    @Test func unicodeMatchesRemappedKey() {
        var s = ShortcutState()
        let cut = event(7)
        _ = s.process(cut, fileContext: true, clipboard: 0, hasFiles: false)
        var character: UniChar = 0
        var length = 0
        cut.keyboardGetUnicodeString(maxStringLength: 1, actualStringLength: &length, unicodeString: &character)
        #expect(length == 1)
        #expect(character == 99)
    }
    @Test func loginStatusAndErrors() {
        var status = SMAppService.Status.notRegistered
        var opened = false
        let manager = LaunchManager(readStatus: { status }, register: { status = .requiresApproval }, unregister: { status = .notRegistered }, openSettings: { opened = true })
        manager.toggle()
        #expect(manager.requiresApproval)
        #expect(!manager.isEnabled)
        manager.toggle()
        #expect(opened)
        status = .enabled
        manager.checkStatus()
        #expect(manager.isEnabled)
        manager.toggle()
        #expect(!manager.isEnabled)
        let failed = LaunchManager(readStatus: { .notRegistered }, register: { throw NSError(domain: "test", code: 1) })
        failed.toggle()
        #expect(failed.errorMessage != nil)
        #expect(!failed.isEnabled)
    }
}
