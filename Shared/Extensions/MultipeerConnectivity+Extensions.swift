//
//  MultipeerConnectivity+Extensions.swift
//  LED Messenger
//
//  Created on April 19, 2025
//

import Foundation
import MultipeerConnectivity

// Extension to add PeerID management functionality to MCPeerID
extension MCPeerID {
    
    /// Clear up any cached peer IDs that might cause CFAssertMismatchedTypeID errors
    static func removeCachedPeers() {
        let peerIDCache = MCPeerIDCacheDirectory()
        
        #if DEBUG
        print("🧹 Cleaning PeerID cache at: \(peerIDCache)")
        #endif
        
        do {
            // Delete contents of the peer ID cache directory
            if FileManager.default.fileExists(atPath: peerIDCache) {
                try FileManager.default.removeItem(atPath: peerIDCache)
                print("✅ Successfully cleaned PeerID cache - this should fix CFAssertMismatchedTypeID errors")
            }
        } catch {
            #if DEBUG
            print("⚠️ Could not clean PeerID cache: \(error.localizedDescription)")
            #endif
        }
    }
    
    /// Get the path of the MCPeerID cache directory
    private static func MCPeerIDCacheDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cacheDir = paths[0]
        return "\(cacheDir)/com.apple.MultipeerConnectivity"
    }
}