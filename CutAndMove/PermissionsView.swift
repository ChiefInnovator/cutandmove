//
//  PermissionsView.swift
//  CutAndMove
//
//  Created by Richard Crane on 11/19/25.
//

import SwiftUI

struct PermissionsView: View {
    // Changed to ObservedObject to fix conformance error
    @ObservedObject var keyHandler = GlobalKeyboardHandler.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .padding(.top, 20)
            
            Text("Permission Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("To detect Command+X in Finder, this app needs Accessibility permissions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if keyHandler.hasPermissions {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.largeTitle)
                    Text("You're all set!")
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        dismiss()
                    }
                }
            } else {
                Button(action: {
                    keyHandler.openSystemSettings()
                }) {
                    Text("Open System Settings")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Text("Go to Privacy & Security > Accessibility")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
        .frame(width: 400, height: 300)
    }
}
