//
//  CutAndMoveApp.swift
//  CutAndMove
//
//  Created by Richard Crane on 11/19/25.
//

import SwiftUI

@main
struct CutAndMoveApp: App {
    @ObservedObject var keyHandler = GlobalKeyboardHandler.shared
    @ObservedObject var launchManager = LaunchManager.shared
    
    var body: some Scene {
        // 1. The Menu Bar Icon
        MenuBarExtra("Cut & Move", systemImage: keyHandler.isCutModeActive ? "scissors.circle.fill" : "scissors") {
            // We extract the menu content to a separate view so it can use Environment actions
            AppMenu(keyHandler: keyHandler, launchManager: launchManager)
        }
        .menuBarExtraStyle(.menu)
        
        // 2. The Custom About Window
        Window("About Cut & Move", id: "about-window") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 350, height: 420)
        
        // 3. The Permissions Window
        Window("Permissions Required", id: "permissions-window") {
            PermissionsView()
        }
        .defaultSize(width: 400, height: 300)
        .windowResizability(.contentSize)
    }
}

// This struct handles the buttons inside the menu
struct AppMenu: View {
    @ObservedObject var keyHandler: GlobalKeyboardHandler
    @ObservedObject var launchManager: LaunchManager
    
    // This specific command allows us to open the windows defined above
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        // STATUS SECTION
        Button(action: {}) {
            if keyHandler.hasPermissions {
                Label("Ready to Cut", systemImage: "checkmark.circle")
            } else {
                Label("Permissions Missing", systemImage: "exclamationmark.triangle")
            }
        }
        .disabled(true)
        
        Divider()
        
        // SETTINGS SECTION
        Button(action: {
            launchManager.toggle()
        }) {
            if launchManager.isEnabled {
                Label("Launch at Login", systemImage: "checkmark")
            } else {
                Text("Launch at Login")
            }
        }
        
        if !keyHandler.hasPermissions {
            Button("Fix Permissions...") {
                openWindow(id: "permissions-window")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
        
        Divider()
        
        // APP SECTION
        Button("About Cut & Move") {
            // This opens our new custom view
            openWindow(id: "about-window")
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
