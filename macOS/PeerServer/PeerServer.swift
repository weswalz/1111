//
//  PeerServer.swift
//  LED Messenger macOS
//
//  Created on April 17, 2025
//

import Foundation
import MultipeerConnectivity
import Combine

/// Protocol defining the requirements for a peer server implementation
public protocol PeerServerProtocol {
    /// Start advertising to peers
    func startAdvertising()
    
    /// Stop advertising to peers
    func stopAdvertising()
    
    /// Disconnect from all connected peers
    func disconnectAllPeers()
    
    /// Send data to all connected peers
    /// - Parameters:
    ///   - data: The data to send
    ///   - messageType: The type of message
    /// - Returns: Whether the send operation was successful
    func sendDataToAllPeers(_ data: Data, messageType: PeerMessageType) -> Bool
    
    /// Send data to a specific peer
    /// - Parameters:
    ///   - data: The data to send
    ///   - messageType: The type of message
    ///   - peerID: The peer to send to
    /// - Returns: Whether the send operation was successful
    func sendData(_ data: Data, messageType: PeerMessageType, toPeer peerID: MCPeerID) -> Bool
    
    /// Accept an incoming connection request
    /// - Parameters:
    ///   - invite: The invitation to accept
    ///   - peerID: The peer requesting connection
    func acceptInvitation(_ invite: MCSession, fromPeer peerID: MCPeerID)
    
    /// Reject an incoming connection request
    /// - Parameters:
    ///   - invite: The invitation to reject
    ///   - peerID: The peer requesting connection
    func rejectInvitation(_ invite: MCSession, fromPeer peerID: MCPeerID)
    
    /// The list of connected peers
    var connectedPeers: [MCPeerID] { get }
    
    /// The current server state
    var serverState: PeerServerState { get }
    
    /// Publisher for server state changes
    var serverStatePublisher: AnyPublisher<PeerServerState, Never> { get }
    
    /// Publisher for connection events
    var connectionEventPublisher: AnyPublisher<PeerConnectionEvent, Never> { get }
    
    /// Publisher for received messages
    var messagePublisher: AnyPublisher<PeerMessage, Error> { get }
}

/// Represents the state of a peer server
public enum PeerServerState: Equatable {
    /// Not advertising to peers
    case inactive
    
    /// Advertising to peers
    case advertising
    
    /// Advertising failed
    case failed(Error)
    
    /// A description of the server state
    public var description: String {
        switch self {
        case .inactive:
            return "Inactive"
        case .advertising:
            return "Advertising for connections"
        case .failed(let error):
            return "Failed: \(error.localizedDescription)"
        }
    }
    
    /// Whether the state represents active advertising
    public var isAdvertising: Bool {
        if case .advertising = self {
            return true
        }
        return false
    }
    
    /// For Equatable conformance
    public static func == (lhs: PeerServerState, rhs: PeerServerState) -> Bool {
        switch (lhs, rhs) {
        case (.inactive, .inactive):
            return true
        case (.advertising, .advertising):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// Represents a peer connection event
public enum PeerConnectionEvent {
    /// A peer connected
    case peerConnected(MCPeerID)
    
    /// A peer disconnected
    case peerDisconnected(MCPeerID)
    
    /// A peer is requesting connection
    case connectionRequest(MCPeerID, MCSession)
}

/// Implementation of PeerServerProtocol using MultipeerConnectivity
public class PeerServer: NSObject, PeerServerProtocol {
    
    // MARK: - Properties
    
    /// The service type for peer discovery
    private let serviceType = "led-messenger"
    
    /// The local peer ID
    private let localPeerID: MCPeerID
    
    /// The advertiser for discovery
    private var advertiser: MCNearbyServiceAdvertiser?
    
    /// The session for communication
    private var session: MCSession?
    
    /// The list of connected peers
    @Published public private(set) var connectedPeers: [MCPeerID] = []
    
    /// The current server state
    @Published public private(set) var serverState: PeerServerState = .inactive
    
    /// Publisher for server state changes
    public var serverStatePublisher: AnyPublisher<PeerServerState, Never> {
        $serverState.eraseToAnyPublisher()
    }
    
    /// Subject for connection events
    private let connectionEventSubject = PassthroughSubject<PeerConnectionEvent, Never>()
    
    /// Publisher for connection events
    public var connectionEventPublisher: AnyPublisher<PeerConnectionEvent, Never> {
        connectionEventSubject.eraseToAnyPublisher()
    }
    
    /// Subject for received messages
    private let messageSubject = PassthroughSubject<PeerMessage, Error>()
    
    /// Publisher for received messages
    public var messagePublisher: AnyPublisher<PeerMessage, Error> {
        messageSubject.eraseToAnyPublisher()
    }
    
    /// Whether to automatically accept incoming connections
    private let autoAcceptConnections: Bool
    
    /// The device name
    private var deviceName: String {
        #if os(iOS)
        return UIDevice.current.name
        #else
        return Host.current().localizedName ?? "Unknown Device"
        #endif
    }
    
    /// Dictionary to track peer sessions (for multi-peer support)
    private var peerSessions: [MCPeerID: MCSession] = [:]
    
    /// Whether the server supports multiple connected peers
    private let supportMultiplePeers: Bool
    
    // MARK: - Initialization
    
    /// Initialize the peer server
    /// - Parameters:
    ///   - autoAcceptConnections: Whether to automatically accept incoming connections
    ///   - supportMultiplePeers: Whether to support multiple connected peers
    public init(autoAcceptConnections: Bool = true, supportMultiplePeers: Bool = true) {
        // Create a peer ID with the device name
        self.localPeerID = MCPeerID(displayName: "\(deviceName) (Mac)")
        self.autoAcceptConnections = autoAcceptConnections
        self.supportMultiplePeers = supportMultiplePeers
        
        super.init()
        
        // Create a session
        setupSession()
        
        logInfo("PeerServer initialized with peer ID: \(localPeerID.displayName)", category: .peer)
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
    
    // MARK: - PeerServerProtocol Implementation
    
    /// Start advertising to peers
    public func startAdvertising() {
        // Don't start if already advertising
        guard case .inactive = serverState else {
            logWarning("Cannot start advertising: Not in inactive state", category: .peer)
            return
        }
        
        // Create an advertiser
        advertiser = MCNearbyServiceAdvertiser(
            peer: localPeerID,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        advertiser?.delegate = self
        
        // Start advertising
        advertiser?.startAdvertisingPeer()
        serverState = .advertising
        
        logInfo("Started advertising for peers", category: .peer)
    }
    
    /// Stop advertising to peers
    public func stopAdvertising() {
        // Only stop if currently advertising
        guard case .advertising = serverState else {
            logWarning("Cannot stop advertising: Not in advertising state", category: .peer)
            return
        }
        
        // Stop advertising
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        serverState = .inactive
        
        logInfo("Stopped advertising for peers", category: .peer)
    }
    
    /// Disconnect from all connected peers
    public func disconnectAllPeers() {
        // Disconnect all sessions
        session?.disconnect()
        
        // Disconnect individual peer sessions
        for (peer, session) in peerSessions {
            session.disconnect()
            logInfo("Disconnected from peer: \(peer.displayName)", category: .peer)
        }
        
        // Clear connected peers
        connectedPeers = []
        peerSessions.removeAll()
        
        logInfo("Disconnected from all peers", category: .peer)
    }
    
    /// Send data to all connected peers
    /// - Parameters:
    ///   - data: The data to send
    ///   - messageType: The type of message
    /// - Returns: Whether the send operation was successful
    public func sendDataToAllPeers(_ data: Data, messageType: PeerMessageType) -> Bool {
        // Must have connected peers to send
        guard !connectedPeers.isEmpty else {
            logWarning("Cannot send data: No connected peers", category: .peer)
            return false
        }
        
        do {
            // Create a peer message
            let message = PeerMessage(type: messageType, data: data)
            
            // Encode the message
            let encoder = JSONEncoder()
            let messageData = try encoder.encode(message)
            
            // Send to each peer using the appropriate session
            var success = true
            for peer in connectedPeers {
                if let session = peerSessions[peer] {
                    // Send using individual session
                    try session.send(messageData, toPeers: [peer], with: .reliable)
                } else if let mainSession = session {
                    // Send using main session
                    try mainSession.send(messageData, toPeers: [peer], with: .reliable)
                } else {
                    // No session found
                    success = false
                    logError("No session found for peer: \(peer.displayName)", category: .peer)
                }
            }
            
            logDebug("Sent \(messageType) message to \(connectedPeers.count) peers", category: .peer)
            return success
        } catch {
            logError("Failed to send data to all peers: \(error.localizedDescription)", category: .peer)
            return false
        }
    }
    
    /// Send data to a specific peer
    /// - Parameters:
    ///   - data: The data to send
    ///   - messageType: The type of message
    ///   - peerID: The peer to send to
    /// - Returns: Whether the send operation was successful
    public func sendData(_ data: Data, messageType: PeerMessageType, toPeer peerID: MCPeerID) -> Bool {
        // Must be connected to the peer to send
        guard connectedPeers.contains(peerID) else {
            logWarning("Cannot send data: Not connected to peer \(peerID.displayName)", category: .peer)
            return false
        }
        
        do {
            // Create a peer message
            let message = PeerMessage(type: messageType, data: data)
            
            // Encode the message
            let encoder = JSONEncoder()
            let messageData = try encoder.encode(message)
            
            // Determine which session to use
            if let peerSession = peerSessions[peerID] {
                // Use individual session
                try peerSession.send(messageData, toPeers: [peerID], with: .reliable)
            } else if let mainSession = session {
                // Use main session
                try mainSession.send(messageData, toPeers: [peerID], with: .reliable)
            } else {
                // No session found
                logError("No session found for peer: \(peerID.displayName)", category: .peer)
                return false
            }
            
            logDebug("Sent \(messageType) message to \(peerID.displayName)", category: .peer)
            return true
        } catch {
            logError("Failed to send data to peer \(peerID.displayName): \(error.localizedDescription)", category: .peer)
            return false
        }
    }
    
    /// Send a typed object to a specific peer
    /// - Parameters:
    ///   - object: The object to send
    ///   - messageType: The type of message
    ///   - peerID: The peer to send to
    /// - Returns: Whether the send operation was successful
    public func sendObject<T: Encodable>(_ object: T, messageType: PeerMessageType, toPeer peerID: MCPeerID) -> Bool {
        do {
            // Encode the object
            let encoder = JSONEncoder()
            let objectData = try encoder.encode(object)
            
            // Send the encoded data
            return sendData(objectData, messageType: messageType, toPeer: peerID)
        } catch {
            logError("Failed to encode object: \(error.localizedDescription)", category: .peer)
            return false
        }
    }
    
    /// Send a typed object to all connected peers
    /// - Parameters:
    ///   - object: The object to send
    ///   - messageType: The type of message
    /// - Returns: Whether the send operation was successful
    public func sendObjectToAllPeers<T: Encodable>(_ object: T, messageType: PeerMessageType) -> Bool {
        do {
            // Encode the object
            let encoder = JSONEncoder()
            let objectData = try encoder.encode(object)
            
            // Send the encoded data
            return sendDataToAllPeers(objectData, messageType: messageType)
        } catch {
            logError("Failed to encode object: \(error.localizedDescription)", category: .peer)
            return false
        }
    }
    
    /// Accept an incoming connection request
    /// - Parameters:
    ///   - invite: The invitation to accept
    ///   - peerID: The peer requesting connection
    public func acceptInvitation(_ invite: MCSession, fromPeer peerID: MCPeerID) {
        if !supportMultiplePeers && !connectedPeers.isEmpty {
            // Disconnect existing peers first if not supporting multiple
            disconnectAllPeers()
        }
        
        // Accept the invitation
        advertiser?.acceptInvitation(to: invite, fromPeer: peerID, withContext: nil)
        
        // Store the session if using multiple peers
        if supportMultiplePeers {
            invite.delegate = self
            peerSessions[peerID] = invite
        }
        
        logInfo("Accepted invitation from peer: \(peerID.displayName)", category: .peer)
    }
    
    /// Reject an incoming connection request
    /// - Parameters:
    ///   - invite: The invitation to reject
    ///   - peerID: The peer requesting connection
    public func rejectInvitation(_ invite: MCSession, fromPeer peerID: MCPeerID) {
        // Reject the invitation
        advertiser?.denyInvitation(from: peerID)
        
        logInfo("Rejected invitation from peer: \(peerID.displayName)", category: .peer)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension PeerServer: MCNearbyServiceAdvertiserDelegate {
    
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        logInfo("Received invitation from peer: \(peerID.displayName)", category: .peer)
        
        // Create a session for this invitation
        let inviteSession = MCSession(
            peer: localPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        inviteSession.delegate = self
        
        if autoAcceptConnections {
            // Auto-accept if enabled
            if !supportMultiplePeers && !connectedPeers.isEmpty {
                // Reject if already connected and not supporting multiple peers
                invitationHandler(false, nil)
                logInfo("Rejected invitation from \(peerID.displayName): Already connected", category: .peer)
            } else {
                // Accept the invitation
                invitationHandler(true, inviteSession)
                
                // Store the session if using multiple peers
                if supportMultiplePeers {
                    peerSessions[peerID] = inviteSession
                }
                
                logInfo("Auto-accepted invitation from: \(peerID.displayName)", category: .peer)
            }
        } else {
            // Notify delegate to handle the invitation
            connectionEventSubject.send(.connectionRequest(peerID, inviteSession))
            
            // The delegate should call acceptInvitation or rejectInvitation
        }
    }
    
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        // Update state to failed
        serverState = .failed(error)
        logError("Failed to start advertising: \(error.localizedDescription)", category: .peer)
    }
}

// MARK: - MCSessionDelegate

extension PeerServer: MCSessionDelegate {
    
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .connected:
                // Add to connected peers if not already there
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    
                    // Notify of connection
                    self.connectionEventSubject.send(.peerConnected(peerID))
                    
                    // Send a handshake
                    self.sendHandshake(to: peerID)
                    
                    logInfo("Peer connected: \(peerID.displayName)", category: .peer)
                }
                
            case .connecting:
                logDebug("Peer connecting: \(peerID.displayName)", category: .peer)
                
            case .notConnected:
                // Remove from connected peers
                if let index = self.connectedPeers.firstIndex(of: peerID) {
                    self.connectedPeers.remove(at: index)
                    
                    // Remove from peer sessions
                    self.peerSessions.removeValue(forKey: peerID)
                    
                    // Notify of disconnection
                    self.connectionEventSubject.send(.peerDisconnected(peerID))
                    
                    logInfo("Peer disconnected: \(peerID.displayName)", category: .peer)
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
                sendHandshake(to: peerID)
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
    /// - Parameter peerID: The peer to send to
    private func sendHandshake(to peerID: MCPeerID) {
        // Create a simple handshake with device info
        let info = [
            "device": "Mac",
            "name": deviceName,
            "version": AppConstants.App.version
        ]
        
        // Send the handshake
        sendObject(info, messageType: .handshake, toPeer: peerID)
    }
}
