//
//  PeerDiscoveryView.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import SwiftUI
import MultipeerConnectivity

/// View for discovering and connecting to Mac peers
struct PeerDiscoveryView: View {
    // MARK: - Properties
    
    /// The peer client
    let peerClient: PeerClient
    
    /// Action to perform when connection is successful
    let onConnectionSuccess: () -> Void
    
    /// Mode manager
    @EnvironmentObject var modeManager: ModeManager
    
    /// Whether the peer client is in browsing state
    @State private var isBrowsing = false
    
    /// The selected peer for connection
    @State private var selectedPeer: MCPeerID?
    
    /// Whether a connection attempt is in progress
    @State private var isConnecting = false
    
    /// Connection error message
    @State private var errorMessage: String?
    
    /// Discovery refresh timer
    @State private var refreshTimer: Timer?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            Spacer()
            
            // Connection status
            connectionStatusView
            
            // Discovered peers list or empty state
            if peerClient.discoveredPeers.isEmpty {
                emptyStateView
            } else {
                discoveredPeersView
            }
            
            Spacer()
            
            // Mode switch button
            switchModeButton
                .padding(.bottom, 20)
        }
        .padding()
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .onAppear {
            // Start browsing when view appears
            startBrowsing()
            
            // Set up refresh timer
            setupRefreshTimer()
        }
        .onDisappear {
            // Stop refresh timer
            refreshTimer?.invalidate()
            refreshTimer = nil
            
            // Only stop browsing if we successfully connected
            if !peerClient.connectionState.isConnected {
                peerClient.stopBrowsing()
            }
        }
    }
    
    // MARK: - Header View
    
    /// View for the header
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "ipad.and.iphone")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.primary)
                .padding(.bottom, 8)
            
            Text("LED Messenger")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.text)
            
            Text("PAIRED MODE")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .stroke(AppTheme.Colors.primary, lineWidth: 1)
                )
        }
        .padding(.top, 40)
    }
    
    // MARK: - Connection Status View
    
    /// View for showing connection status
    private var connectionStatusView: some View {
        VStack(spacing: 10) {
            // Connection state
            HStack(spacing: 10) {
                // Status indicator
                Circle()
                    .fill(connectionStateColor)
                    .frame(width: 12, height: 12)
                
                // Status text
                Text(connectionStateText)
                    .font(.headline)
                    .foregroundColor(connectionStateColor)
            }
            
            // Error message if any
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Empty State View
    
    /// View shown when no peers are discovered
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "radar")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                .padding(.bottom, 8)
            
            Text("Searching for Mac Hosts...")
                .font(.title3)
                .foregroundColor(AppTheme.Colors.text)
            
            Text("Make sure the Mac app is running and on the same network")
                .font(.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                // Stop and restart browsing
                peerClient.stopBrowsing()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    peerClient.startBrowsing()
                }
                
                // Reset error message
                errorMessage = nil
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppTheme.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 16)
        }
        .padding()
    }
    
    // MARK: - Discovered Peers View
    
    /// View showing discovered peers
    private var discoveredPeersView: some View {
        VStack(spacing: 16) {
            Text("Available Mac Hosts")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(peerClient.discoveredPeers, id: \.self) { peer in
                        Button(action: {
                            connectToPeer(peer)
                        }) {
                            HStack {
                                // Mac icon
                                Image(systemName: "desktopcomputer")
                                    .font(.title3)
                                    .foregroundColor(AppTheme.Colors.primary)
                                
                                // Peer name
                                Text(peer.displayName)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.Colors.text)
                                
                                Spacer()
                                
                                // Selected indicator
                                if isConnecting && selectedPeer == peer {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.Colors.surface)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                        }
                        .disabled(isConnecting)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 300)
            
            // Refresh button
            Button(action: {
                // Stop and restart browsing
                peerClient.stopBrowsing()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    peerClient.startBrowsing()
                }
                
                // Reset error message
                errorMessage = nil
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.Colors.primary, lineWidth: 1)
                )
                .foregroundColor(AppTheme.Colors.primary)
            }
            .disabled(isConnecting)
        }
        .padding()
    }
    
    // MARK: - Switch Mode Button
    
    /// Button to switch back to Solo mode
    private var switchModeButton: some View {
        Button(action: {
            // Stop browsing
            peerClient.stopBrowsing()
            
            // Switch to Solo mode
            modeManager.setMode(.solo)
        }) {
            HStack {
                Image(systemName: "arrow.left")
                Text("Switch to Solo Mode")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.Colors.text.opacity(0.5), lineWidth: 1)
            )
            .foregroundColor(AppTheme.Colors.text.opacity(0.8))
        }
    }
    
    // MARK: - Helper Properties
    
    /// Color for the connection state
    private var connectionStateColor: Color {
        switch peerClient.connectionState {
        case .disconnected:
            return AppTheme.Colors.textSecondary
        case .browsing:
            return AppTheme.Colors.warning
        case .inviting:
            return AppTheme.Colors.warning
        case .connected:
            return AppTheme.Colors.success
        case .failed:
            return AppTheme.Colors.error
        }
    }
    
    /// Text for the connection state
    private var connectionStateText: String {
        switch peerClient.connectionState {
        case .disconnected:
            return "Disconnected"
        case .browsing:
            return "Browsing for Mac hosts..."
        case .inviting(let peer):
            return "Connecting to \(peer.displayName)..."
        case .connected(let peer):
            return "Connected to \(peer.displayName)"
        case .failed:
            return "Connection Failed"
        }
    }
    
    // MARK: - Actions
    
    /// Start browsing for peers
    private func startBrowsing() {
        // Only start if not already browsing
        guard !isBrowsing else { return }
        
        // Reset state
        selectedPeer = nil
        isConnecting = false
        errorMessage = nil
        
        // Start browsing
        peerClient.startBrowsing()
        isBrowsing = true
    }
    
    /// Connect to a peer
    /// - Parameter peer: The peer to connect to
    private func connectToPeer(_ peer: MCPeerID) {
        // Set selected peer
        selectedPeer = peer
        isConnecting = true
        errorMessage = nil
        
        // Try to connect
        if !peerClient.connectToPeer(peer) {
            // Connection attempt failed
            isConnecting = false
            errorMessage = "Failed to initiate connection. Please try again."
            return
        }
        
        // Connection attempt started, wait for result
        // This will be handled by the connectionStatePublisher in PairedModeRootView
    }
    
    /// Set up a timer to periodically refresh peer discovery
    private func setupRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            // Only refresh if we're in browsing state
            if case .browsing = peerClient.connectionState {
                // Stop and restart browsing
                peerClient.stopBrowsing()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    peerClient.startBrowsing()
                }
            }
        }
    }
}

struct PeerDiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        PeerDiscoveryView(
            peerClient: PeerClient(),
            onConnectionSuccess: {}
        )
        .environmentObject(ModeManager())
    }
}
