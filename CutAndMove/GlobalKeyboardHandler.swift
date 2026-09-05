import Cocoa
import Combine

class GlobalKeyboardHandler: ObservableObject {
    static let shared = GlobalKeyboardHandler()
    @Published private(set) var hasPermissions = false
    @Published private(set) var isMonitoring = false
    @Published private(set) var isCutModeActive = false
    @Published private(set) var monitoringError: String?
    private var state = ShortcutState()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?
    var cutDidChange: ((Int?) -> Void)?
    var fileMoveInProgress = false

    private init() {
        checkPermissions()
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appDidBecomeActive), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkPermissions() }
        }
    }

    @objc func appDidBecomeActive() {
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier != "com.apple.finder" {
            resetCutMode()
        }
        checkPermissions()
    }

    private func resetCutMode() {
        let wasActive = state.isCutModeActive
        state.reset()
        isCutModeActive = false
        if wasActive { cutDidChange?(nil) }
    }

    func cancelCut() { resetCutMode() }

    func armCut(clipboard: Int) {
        state.armCut(clipboard: clipboard)
        isCutModeActive = true
        cutDidChange?(clipboard)
    }

    func requestPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        checkPermissions()
    }

    func checkPermissions() {
        hasPermissions = AXIsProcessTrusted()
        switch Self.monitoringAction(trusted: hasPermissions, hasTap: eventTap != nil, enabled: eventTap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false) {
        case .stop:
            stopWatching()
        case .start:
            startWatching()
        case .enable:
            resetCutMode()
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                isMonitoring = CGEvent.tapIsEnabled(tap: eventTap)
            }
        case .none: break
        }
    }

    enum MonitoringAction { case stop, start, enable, none }
    static func monitoringAction(trusted: Bool, hasTap: Bool, enabled: Bool) -> MonitoringAction {
        if !trusted { return .stop }
        if !hasTap { return .start }
        return enabled ? .none : .enable
    }

    func openSystemSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    private func startWatching() {
        guard eventTap == nil, hasPermissions else { return }
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: CGEventMask(mask), callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                return MainActor.assumeIsolated {
                    Unmanaged<GlobalKeyboardHandler>.fromOpaque(refcon).takeUnretainedValue().handle(type: type, event: event)
                }
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()),
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
                isMonitoring = false
                monitoringError = "Keyboard monitoring could not start. Check Accessibility access, then retry."
                return
            }
        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isMonitoring = CGEvent.tapIsEnabled(tap: tap)
        monitoringError = isMonitoring ? nil : "Keyboard monitoring is paused. Retry Accessibility access."
    }

    private func stopWatching() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
        monitoringError = nil
        resetCutMode()
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            resetCutMode()
            checkPermissions()
            return Unmanaged.passUnretained(event)
        }
        guard hasPermissions, let app = NSWorkspace.shared.frontmostApplication,
              app.bundleIdentifier == "com.apple.finder" else {
            resetCutMode()
            return Unmanaged.passUnretained(event)
        }
        let key = event.getIntegerValueField(.keyboardEventKeycode)
        // AX and pasteboard reads are only needed for the two relevant shortcuts.
        let relevant = type == .keyDown && (key == 7 || key == 9) && event.flags.contains(.maskCommand)
        let fileContext = !relevant || FinderFocus.isFileContext(pid: app.processIdentifier)
        if fileMoveInProgress && fileContext && (key == 7 || key == 9) && event.flags.contains(.maskCommand) { return nil }
        let board = NSPasteboard.general
        let count = relevant ? board.changeCount : 0
        let files = relevant && board.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
        let previous = state.cutClipboard
        let pass = state.process(event, fileContext: fileContext, clipboard: count, hasFiles: files)
        isCutModeActive = state.isCutModeActive
        if previous != state.cutClipboard { cutDidChange?(state.cutClipboard) }
        return pass ? Unmanaged.passUnretained(event) : nil
    }
}

/// Fail closed on missing AX information, text editors, search fields, or unknown controls.
enum FinderFocus {
    static func allowsFileShortcuts(roles: [String], editable: Bool) -> Bool {
        guard !editable, !roles.isEmpty else { return false }
        let textRoles = ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"]
        guard !roles.contains(where: { textRoles.contains($0) }) else { return false }
        return ["AXOutline", "AXTable", "AXList", "AXBrowser", "AXScrollArea"].contains(roles[0])
            || (["AXCell", "AXRow", "AXImage", "AXGroup"].contains(roles[0]) && roles.contains(where: { ["AXOutline", "AXTable", "AXList", "AXBrowser", "AXScrollArea"].contains($0) }))
    }

    static func isFileContext(pid: pid_t) -> Bool {
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.02)
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let focused, CFGetTypeID(focused) == AXUIElementGetTypeID() else { return false }
        var element = focused as! AXUIElement
        var roles: [String] = []
        for _ in 0..<4 {
            AXUIElementSetMessagingTimeout(element, 0.02)
            var role: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success,
                  let name = role as? String else { return false }
            roles.append(name)
            var editable: DarwinBoolean = false
            if AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &editable) == .success, editable.boolValue {
                return false
            }
            if ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"].contains(name) { return false }
            if allowsFileShortcuts(roles: roles, editable: false) { return true }
            var parent: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &parent) == .success,
                  let parent, CFGetTypeID(parent) == AXUIElementGetTypeID() else { return false }
            element = parent as! AXUIElement
        }
        return false
    }
}
