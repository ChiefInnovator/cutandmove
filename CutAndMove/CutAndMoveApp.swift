//
//  CutAndMoveApp.swift
//  CutAndMove
//
//  Created by Richard Crane on 11/19/25.
//

import SwiftUI

@main
struct CutAndMoveApp: App {
    // Changed to ObservedObject to fix conformance error
    @ObservedObject var keyHandler = GlobalKeyboardHandler.shared
    
    var body: some Scene {
        MenuBarExtra("Finder Cut", systemImage: keyHandler.isCutModeActive ? "scissors.circle.fill" : "scissors") {
            
            Button("Status: \(keyHandler.hasPermissions ? "Active" : "Permissions Needed")") {
            }
            .disabled(true)
            
            Divider()
            
            if !keyHandler.hasPermissions {
                Button("Fix Permissions") {
                    keyHandler.openSystemSettings()
                }
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.menu)
        
        Window("Permissions Required", id: "permissions-window") {
            PermissionsView()
        }
        .defaultSize(width: 400, height: 300)
        .windowResizability(.contentSize)
    }
}
