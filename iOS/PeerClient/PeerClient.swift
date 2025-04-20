//
//  PeerClient.swift
//  LED Messenger iOS
//
//  Created on April 17, 2025
//

import Foundation
import MultipeerConnectivity
import Combine

/// Protocol defining the requirements for a peer client implementation
public protocol PeerClientProtocol {
    /// Start browsing for peers
    func startBrowsing()
    
    /// Stop browsing for peers
    func stopBrowsing()
    
    /// Connect to a peer
    /// - Parameter peer: The peer to connect to
    /// - Returns: Whether the connection attempt was successful
    func connectToPeer(_ peer: MCPeerID) -> Bool
    
    /// Disconnect from the current peer
    func disconnect()
    
    /// Send data to the connected peer
    /// - Parameters:
    ///   - data: The data to send
    ///   - messageType: The type of message
    /// - Returns: Whether the send operation was successful
    func sendData(_ data: Data, messageType: PeerMessageType) -> Bool
    
    /// The list of discovered peers
    var discoveredPeers: [MCPeerID] { get }
    
    /// The current connection state
    var connectionState: PeerConnectionState { get }
    
    /// Publisher for connection state changes
    var connectionStatePublisher: AnyPublisher<PeerConnectionState, Never> { get }
    
    /// Publisher for received messages
    var messagePublisher: AnyPublisher<PeerMessage, Error> { get }
}

/// Represents the connection state of a peer client
public enum PeerConnectionState: Equatable {
    /// Not connected to a peer
    case disconnected
    
    /// Looking for peers
    case browsing
    
    /// Sending an invitation to a peer
    case inviting(MCPeerID)
    
    /// Connected to a peer
    case connected(MCPeerID)
    
    /// Connection failed
    case failed(Error)
    
    /// A description of the connection state
    public var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .browsing:
            return "Looking for Mac hosts..."
        case .inviting(let peer):
            return "Connecting to \(peer.displayName)..."
        case .connected(let peer):
            return "Connected to \(peer.displayName)"
        case .failed(let error):
            return "Connection failed: \(error.localizedDescription)"
        }
    }
    
    /// Whether the state represents an active connection
    public var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    /// For Equatable conformance
    public static func == (lhs: PeerConnectionState, rhs: PeerConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected):
            return true
        case (.browsing, .browsing):
            return true
        case (.inviting(let lhsPeer), .inviting(let rhsPeer)):
            return lhsPeer == rhsPeer
        case (.connected(let lhsPeer), .connected(let rhsPeer)):
            return lhsPeer == rhsPeer
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// Types of messages that can be sent between peers
public enum PeerMessageType: String, Codable {
    /// Settings synchronization
    case settings
    
    /// Message queue data
    case messageQueue
    
    /// Status update
    case status
    
    /// Message sent event
    case messageSent
    
    /// Command (e.g., send, clear)
    case command
    
    /// Connection handshake
    case handshake
    
    /// Heartbeat to maintain connection
    case heartbeat
}

/// A message sent between peers
public struct PeerMessage: Codable {
    /// The type of message
    public let type: PeerMessageType
    
    /// The message content
    public let data: Data
    
    /// The timestamp when the message was created
    public let timestamp: Date
    
    /// Create a new peer message
    /// - Parameters:
    ///   - type: The message type
    ///   - data: The message content
    public init(type: PeerMessageType, data: Data) {
        self.type = type
        self.data = data
        self.timestamp = Date()
    }
}

/// Errors that can occur in peer operations
public enum PeerError: Error, LocalizedError {
    /// Not connected to a peer
    case notConnected
    
    /// Failed to encode data
    case encodingFailed
    
    /// Failed to decode data
    case decodingFailed
    
    /// Sending data failed
    case sendFailed(String)
    
    /// Connection failed
    case connectionFailed(String)
    
    /// A localized description of the error
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to a peer"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .sendFailed(let reason):
            return "Failed to send data: \(reason)"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        }
    }
}

/// Implementation of PeerClientProtocol using MultipeerConnectivity
public class PeerClient: NSObject, PeerClientProtocol {
    
    // MARK: - Properties
    
    /// The service type for peer discovery
    private let serviceType = "led-messenger"
    
    /// The local peer ID
    private let localPeerID: MCPeerID
    
    /// The advertiser for discovery
    private var browser: MCNearbyServiceBrowser?
    
    /// The session for communication
    private var session: MCSession?
    
    /// The list of discovered peers
    @Published public private(set) var discoveredPeers: [MCPeerID] = []
    
    /// The current connection state
    @Published public private(set) var connectionState: PeerConnectionState = .disconnected
    
    /// Publisher for connection state changes
    public var connectionStatePublisher: AnyPublisher<PeerConnectionState, Never> {
        $connectionState.eraseToAnyPublisher()
    }
    
    /// Subject for received messages
    private let messageSubject = PassthroughSubject<PeerMessage, Error>()
    
    /// Publisher for received messages
    public var messagePublisher: AnyPublisher<PeerMessage, Error> {
        messageSubject.eraseToAnyPublisher()
    }
    
    /// The device name
    private var deviceName: String {
        #if os(iOS)
        return UIDevice.current.name
        #else
        return Host.current().localizedName ?? "Unknown Device"
        #endif
    }
    
    // MARK: - Initialization
    
    /// Initialize the peer client
    public override init() {
        // Create a peer ID with the device name
        self.localPeerID = MCPeerID(displayName: "\(deviceName) (iPad)")
        
        super.init()
        
        // Create a session
        setupSession()
        
        logInfo("PeerClient initialized with peer ID: \(localPeerID.displayName)", category: .peer)
    }
    
    /// Set up the MultipeerConnectivity session
    private func setupSession() {
        // Create a session for secure communication
        session = MCSession(
            peer: localPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session?.delegate = self
        
        logDebug("Session created", category: .peer)
    }
    
    // MARK: - PeerClientProtocol Implementation
    
    /// Start browsing for peers
    public func startBrowsing() {
        // Don't start if already browsing or connected
        guard case .disconnected = connectionState else {
            logWarning("Cannot start browsing: Not in disconnected state", category: .peer)
            return
        }
        
        // Create a browser
        browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        browser?.delegate = self
        
        // Start browsing
        browser?.startBrowsingForPeers()
        connectionState = .browsing
        
        logInfo("Started browsing for peers", category: .peer)
    }
    
    /// Stop browsing for peers
    public func stopBrowsing() {
        // Only stop if currently browsing
        guard case .browsing = connectionState else {
            logWarning("Cannot stop browsing: Not in browsing state", category: .peer)
            return
        }
        
        // Stop browsing
        browser?.stopBrowsingForPeers()
        browser = nil
        discoveredPeers = []
        connectionState = .disconnected
        
        logInfo("Stopped browsing for peers", category: .peer)
    }
    
    /// Connect to a peer
    /// - Parameter peer: The peer to connect to
    /// - Returns: Whether the connection attempt was successful
    public func connectToPeer(_ peer: MCPeerID) -> Bool {
        // Must be in browsing state to connect
        guard case .browsing = connectionState else {
            logWarning("Cannot connect to peer: Not in browsing state", category: .peer)
            return false
        }
        
        // Make sure we have a browser
        guard let browser = browser, let session = session else {
            logError("Browser or session is nil", category: .peer)
            return false
        }
        
        // Update state
        connectionState = .inviting(peer)
        
        // Send an invitation
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        
        logInfo("Invited peer: \(peer.displayName)", category: .peer)
        return true
    }
    
    /// Disconnect from the current peer
    public func disconnect() {
        // Only disconnect if connected or inviting
        guard case .connected = connectionState || case .inviting = connectionState else {
            logWarning("Cannot disconnect: Not connected or inviting", category: .peer)
            return
        }
        
        // Close the session
        session?.disconnect()
        
        // Clean up
        discoveredPeers = []
        connectionState = .disconnected
        
        // Restart browsing
        startBrowsing()
        
        logInfo("Disconnected from peer", category: .peer)
    }
    
    /// Send data to the connected peer
    /// - Parameters:
    ///   - data: The data to send
    ///   - messageType: The type of message
    /// - Returns: Whether the send operation was successful
    public func sendData(_ data: Data, messageType: PeerMessageType) -> Bool {
        // Must be connected to send
        guard case .connected(let peer) = connectionState else {
            logWarning("Cannot send data: Not connected to a peer", category: .peer)
            return false
        }
        
        do {
            // Create a peer message
            let message = PeerMessage(type: messageType, data: data)
            
            // Encode the message
            let encoder = JSONEncoder()
            let messageData = try encoder.encode(message)
            
            // Send the data
            try session?.send(messageData, toPeers: [peer], with: .reliable)
            
            logDebug("Sent \(messageType) message to \(peer.displayName)", category: .peer)
            return true
        } catch {
            logError("Failed to send data: \(error.localizedDescription)", category: .peer)
            return false
        }
    }
    
    /// Send a typed object to the connected peer
    /// - Parameters:
    ///   - object: The object to send
    ///   - messageType: The type of message
    /// - Returns: Whether the send operation was successful
    public func sendObject<T: Encodable>(_ object: T, messageType: PeerMessageType) -> Bool {
        do {
            // Encode the object
            let encoder = JSONEncoder()
            let objectData = try encoder.encode(object)
            
            // Send the encoded data
            return sendData(objectData, messageType: messageType)
        } catch {
            logError("Failed to encode object: \(error.localizedDescription)", category: .peer)
            return false
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PeerClient: MCNearbyServiceBrowserDelegate {
    
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Make sure we're still browsing
        guard case .browsing = connectionState else {
            return
        }
        
        // Add the peer to our list if not already there
        if !discoveredPeers.contains(peerID) {
            discoveredPeers.append(peerID)
            logInfo("Found peer: \(peerID.displayName)", category: .peer)
        }
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Remove the peer from our list
        if let index = discoveredPeers.firstIndex(of: peerID) {
            discoveredPeers.remove(at: index)
            logInfo("Lost peer: \(peerID.displayName)", category: .peer)
        }
        
        // If we were connected to this peer, disconnect
        if case .connected(let connectedPeer) = connectionState, connectedPeer == peerID {
            connectionState = .disconnected
            startBrowsing() // Start browsing again
        }
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        // Update state to failed
        connectionState = .failed(error)
        logError("Failed to start browsing: \(error.localizedDescription)", category: .peer)
    }
}

// MARK: - MCSessionDelegate

extension PeerClient: MCSessionDelegate {
    
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .connected:
                // Update state to connected
                self.connectionState = .connected(peerID)
                
                // Stop browsing
                self.browser?.stopBrowsingForPeers()
                
                // Clear discovered peers list
                self.discoveredPeers.removeAll()
                
                // Send a handshake
                self.sendHandshake()
                
                logInfo("Connected to peer: \(peerID.displayName)", category: .peer)
                
            case .connecting:
                // Already handled by inviting state
                logDebug("Connecting to peer: \(peerID.displayName)", category: .peer)
                
            case .notConnected:
                // If we were connected to this peer, update state
                if case .connected(let connectedPeer) = self.connectionState, connectedPeer == peerID {
                    self.connectionState = .disconnected
                    
                    // Start browsing again
                    self.startBrowsing()
                    
                    logInfo("Disconnected from peer: \(peerID.displayName)", category: .peer)
                }
                
            @unknown default:
                logWarning("Unknown session state for peer: \(peerID.displayName)", category: .peer)
            }
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Decode the message
        do {
            let decoder = JSONDecoder()
            let message = try decoder.decode(PeerMessage.self, from: data)
            
            logDebug("Received \(message.type) message from \(peerID.displayName)", category: .peer)
            
            // Process special message types
            if message.type == .heartbeat {
                // Heartbeats don't need to be forwarded to subscribers
                return
            } else if message.type == .handshake {
                // Respond to handshake
                sendHandshake()
                return
            }
            
            // Forward other messages to subscribers
            messageSubject.send(message)
        } catch {
            logError("Failed to decode message: \(error.localizedDescription)", category: .peer)
            messageSubject.send(completion: .failure(PeerError.decodingFailed))
        }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used
    }
    
    // MARK: - Private Methods
    
    /// Send a handshake message to confirm connection
    private func sendHandshake() {
        // Create a simple handshake with device info
        let info = [
            "device": "iPad",
            "name": deviceName,
            "version": AppConstants.App.version
        ]
        
        // Send the handshake
        sendObject(info, messageType: .handshake)
    }
}
