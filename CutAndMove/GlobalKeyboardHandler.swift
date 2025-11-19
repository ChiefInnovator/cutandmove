//
//  GlobalKeyboardHandler.swift
//  CutAndMove
//
//  Created by Richard Crane on 11/19/25.
//

import Cocoa
import SwiftUI
import Combine

class GlobalKeyboardHandler: ObservableObject {
    static let shared = GlobalKeyboardHandler()
    
    @Published var hasPermissions: Bool = false
    @Published var isCutModeActive: Bool = false
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private init() {
        checkPermissions()
        if hasPermissions {
            startWatching()
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appDidBecomeActive), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }
    
    @objc func appDidBecomeActive() {
        checkPermissions()
    }
    
    func checkPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        DispatchQueue.main.async {
            self.hasPermissions = trusted
            if trusted && self.eventTap == nil {
                self.startWatching()
            }
        }
    }
    
    func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    func startWatching() {
        // We now listen for keyUp as well to ensure clean handling
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                return Unmanaged<GlobalKeyboardHandler>.fromOpaque(refcon!).takeUnretainedValue().handle(event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    func handle(event: CGEvent) -> Unmanaged<CGEvent>? {
        // 0. IGNORE OUR OWN SIMULATED EVENTS
        // If the event has our magic number (0xCAFE), let it pass through but don't process logic
        if event.getIntegerValueField(.eventSourceUserData) == 0xCAFE {
            return Unmanaged.passUnretained(event)
        }

        // 1. Only run if Finder is Active
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier == "com.apple.finder" else {
            if isCutModeActive {
                DispatchQueue.main.async { self.isCutModeActive = false }
            }
            return Unmanaged.passUnretained(event)
        }
        
        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        // Check if Command is pressed
        let isCmd = flags.contains(.maskCommand)
        
        // -------------------------------------------------------------
        // CMD + X (Cut) -> Suppress and Simulate Cmd+C
        // -------------------------------------------------------------
        // We only trigger on KeyDown to avoid double firing
        if event.type == .keyDown, isCmd, keyCode == 7 {
            
            DispatchQueue.main.async { self.isCutModeActive = true }
            
            // Simulate Cmd+C (Copy)
            simulateKeystroke(keyCode: 8, flags: [.maskCommand])
            
            // Suppress the original Cmd+X
            return nil
        }
        
        // -------------------------------------------------------------
        // CMD + V (Paste) -> Modify to Cmd+Option+V
        // -------------------------------------------------------------
        // We check KeyDown OR KeyUp so we can modify both parts of the key press
        if (event.type == .keyDown || event.type == .keyUp), isCmd, keyCode == 9 {
            
            if isCutModeActive {
                // Instead of simulating a new event, we MODIFY the existing one.
                // We inject the "Option" (Alternate) flag into the user's real keypress.
                var newFlags = event.flags
                newFlags.insert(.maskAlternate)
                event.flags = newFlags
                
                // If this was the KeyDown, we can now reset the cut mode
                if event.type == .keyDown {
                    DispatchQueue.main.async { self.isCutModeActive = false }
                }
                
                // Let the modified event continue to Finder
                return Unmanaged.passUnretained(event)
            }
        }
        
        // -------------------------------------------------------------
        // CMD + C (Copy) -> Cancel Cut Mode
        // -------------------------------------------------------------
        if event.type == .keyDown, isCmd, keyCode == 8 {
            DispatchQueue.main.async { self.isCutModeActive = false }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    func simulateKeystroke(keyCode: CGKeyCode, flags: CGEventFlags) {
        // Use a nil source for cleaner injection
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        
        keyDown?.flags = flags
        keyUp?.flags = flags
        
        // TAG THE EVENT so we know it's ours
        keyDown?.setIntegerValueField(.eventSourceUserData, value: 0xCAFE)
        keyUp?.setIntegerValueField(.eventSourceUserData, value: 0xCAFE)
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
