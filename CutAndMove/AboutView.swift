//
//  AboutView.swift
//  CutAndMove
//
//  Created by Richard Crane on 11/19/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // 1. Dynamic App Icon
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(radius: 10)
            
            // 2. App Info
            VStack(spacing: 5) {
                Text("Cut & Move")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Version \(appVersion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("The missing Cut & Move for macOS Finder. Vibe coded for you by Richard Crane and Gemini.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 5)
            
            // 3. Action Buttons
            HStack(spacing: 20) {
                Button("Website") {
                    openURL("https://inventingfirewith.ai")
                }
                .buttonStyle(.link)
                
                Button("Support") {
                    openURL("mailto:support@inventingfirewith.ai")
                }
                .buttonStyle(.link)
            }
            
            Spacer()
            
            // 4. Footer
            Text("© 2025 Richard Crane. All rights reserved.")
                .font(.caption2)
                // FIX: Changed .tertiary to .secondary because .tertiary doesn't exist on Color
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .frame(width: 350, height: 420)
    }
    
    // Helper to get version from Info.plist
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// Preview for Xcode
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
