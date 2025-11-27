//
//  LaunchManager.swift
//  CutAndMove
//
//  Created by Richard Crane on 11/19/25.
//

import Foundation
import ServiceManagement
import Combine
import SwiftUI

class LaunchManager: ObservableObject {
    static let shared = LaunchManager()
    
    @Published var isEnabled: Bool = false
    
    init() {
        checkStatus()
    }
    
    func checkStatus() {
        // Check if the app is currently set to launch at login
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    func toggle() {
        do {
            let service = SMAppService.mainApp
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
            // Delay check slightly to allow system to update status
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.checkStatus()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }
}
