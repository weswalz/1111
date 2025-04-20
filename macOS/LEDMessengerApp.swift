//
//  LEDMessengerApp.swift
//  LEDMESSENGER
//
//  Created on April 19, 2025
//

import SwiftUI

// Simple ContentView for the macOS app
struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.fill")
                .font(.system(size: 72))
                .foregroundColor(.blue)
            
            Text("LED Messenger for macOS")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Control your LED displays from your Mac")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 300)
    }
}

@main
struct LEDMessengerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
