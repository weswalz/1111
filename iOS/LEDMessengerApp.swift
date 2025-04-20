//
//  LEDMessengerApp.swift
//  LEDMESSENGER
//
//  Created on April 19, 2025
//

import SwiftUI

// Simple ContentView for the iPad app
struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "message.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.blue)
                
                Text("LED Messenger for iPad")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Ready to send messages to your LED display")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("LED Messenger")
            .navigationBarTitleDisplayMode(.inline)
        }
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
