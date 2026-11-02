//
//  PermissionsView.swift
//  CutAndMove
//
//  Created by Richard Crane on 11/19/25.
//

import SwiftUI

struct PermissionsView: View {
    @ObservedObject var keyHandler = GlobalKeyboardHandler.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: keyHandler.isMonitoring ? "checkmark.circle.fill" : "hand.raised.fill")
                .font(.system(size: 50))
                .foregroundColor(keyHandler.isMonitoring ? .green : .orange)
                .padding(.top, 20)
                .accessibilityHidden(true)
            
            Text(keyHandler.isMonitoring ? "Keyboard Shortcuts Ready" :
                    keyHandler.hasPermissions ? "Keyboard Monitoring Unavailable" : "Accessibility Permission Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(keyHandler.isMonitoring ? "You can now use Command+X and Command+V to move files in Finder." :
                    keyHandler.hasPermissions ? "Accessibility access is enabled, but keyboard monitoring has not started. Retry monitoring or check System Settings." :
                    "Accessibility access lets Cut & Move detect Command+X in Finder. Shortcuts in other apps stay unchanged.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if keyHandler.isMonitoring {
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            } else {
                if let error = keyHandler.monitoringError {
                    Text(error).font(.caption).foregroundStyle(.red)
                        .textSelection(.enabled)
                }
                if keyHandler.hasPermissions {
                    Button("Retry Monitoring") {
                        keyHandler.checkPermissions()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button(action: {
                    keyHandler.openSystemSettings()
                }) {
                    Text("Open System Settings")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 20)
            }
            
            if !keyHandler.isMonitoring {
                Text("Go to Privacy & Security > Accessibility")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(20)
        .frame(width: 400)
    }
}
