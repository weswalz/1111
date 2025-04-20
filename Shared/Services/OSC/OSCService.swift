//
//  OSCService.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation
import Network

/// Protocol defining the requirements for an OSC communication service
public protocol OSCService {
    
    /// Send an OSC message
    /// - Parameters:
    ///   - message: The OSC message to send
    ///   - completion: Optional completion handler called when the send operation completes
    func send(message: OSCMessage, completion: ((Result<Void, Error>) -> Void)?)
    
    /// Connect to the OSC server
    /// - Parameter completion: Optional completion handler called when the connection attempt completes
    func connect(completion: ((Result<Void, Error>) -> Void)?)
    
    /// Disconnect from the OSC server
    func disconnect()
    
    /// Check if connected to the OSC server
    /// - Returns: True if connected, false otherwise
    var isConnected: Bool { get }
    
    /// Get the current connection state
    var connectionState: OSCConnectionState { get }
}

/// Represents the connection state of an OSC service
public enum OSCConnectionState: Equatable {
    public static func == (lhs: OSCConnectionState, rhs: OSCConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected),
             (.canceling, .canceling),
             (.suspended, .suspended):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
    /// Not connected
    case disconnected
    
    /// In the process of connecting
    case connecting
    
    /// Connected and ready to send messages
    case connected
    
    /// Connection is being canceled
    case canceling
    
    /// Connection is temporarily suspended
    case suspended
    
    /// An error occurred
    case failed(Error)
    
    /// A description of the connection state
    public var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .canceling:
            return "Canceling..."
        case .suspended:
            return "Suspended"
        case .failed(let error):
            return "Failed: \(error.localizedDescription)"
        }
    }
    
    /// Whether the state represents an active connection
    public var isConnected: Bool {
        switch self {
        case .connected:
            return true
        default:
            return false
        }
    }
}

/// Errors that can occur in OSC operations
public enum OSCError: Error, LocalizedError {
    /// The service is not connected to a server
    case notConnected
    
    /// The connection attempt failed
    case connectionFailed(String)
    
    /// Sending a message failed
    case sendFailed(String)
    
    /// An internal error occurred
    case internalError(String)
    
    /// Invalid settings provided
    case invalidSettings(String)
    
    /// A localized description of the error
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to OSC server"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .sendFailed(let reason):
            return "Failed to send message: \(reason)"
        case .internalError(let reason):
            return "Internal error: \(reason)"
        case .invalidSettings(let reason):
            return "Invalid settings: \(reason)"
        }
    }
}

/// Implementation of OSCService using Network framework
public class NetworkOSCService: OSCService {
    
    // MARK: - Properties
    
    /// The IP address of the OSC server
    private let ipAddress: String
    
    /// The port of the OSC server
    private let port: UInt16
    
    /// The NWConnection used for network communication
    private var connection: NWConnection?
    
    /// Queue for processing network events
    private let queue = DispatchQueue(label: "com.ledmessenger.osc.network", qos: .userInitiated)
    
    /// Current connection state
    private var _connectionState: OSCConnectionState = .disconnected
    
    /// Thread-safe access to connection state
    public var connectionState: OSCConnectionState {
        get {
            queue.sync { _connectionState }
        }
    }
    
    /// Whether the service is currently connected
    public var isConnected: Bool {
        connectionState.isConnected
    }
    
    // MARK: - Initialization
    
    /// Initialize with server address and port
    /// - Parameters:
    ///   - ipAddress: The IP address of the OSC server
    ///   - port: The port of the OSC server
    public init(ipAddress: String, port: Int) {
        self.ipAddress = ipAddress
        self.port = UInt16(port)
        
        logDebug("OSC service initialized with IP: \(ipAddress), Port: \(port)", category: .osc)
    }
    
    // MARK: - OSCService Protocol Implementation
    
    /// Connect to the OSC server
    /// - Parameter completion: Optional completion handler called when the connection attempt completes
    public func connect(completion: ((Result<Void, Error>) -> Void)?) {
        // Don't reconnect if already connected or connecting
        guard case .disconnected = connectionState else {
            logWarning("Attempted to connect while already in state: \(connectionState.description)", category: .osc)
            completion?(.success(()))
            return
        }
        
        logInfo("Connecting to OSC server at \(ipAddress):\(port)", category: .osc)
        
        // Create NWEndpoint for the server
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(ipAddress),
            port: NWEndpoint.Port(rawValue: port)!
        )
        
        // Set up UDP connection
        let connection = NWConnection(to: endpoint, using: .udp)
        
        // Set up state handler
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            
            switch state {
            case .ready:
                logInfo("Connected to OSC server", category: .osc)
                self.queue.sync {
                    self._connectionState = .connected
                }
                completion?(.success(()))
                
            case .failed(let error):
                logError("OSC connection failed: \(error.localizedDescription)", category: .osc)
                self.queue.sync {
                    self._connectionState = .failed(error)
                }
                completion?(.failure(OSCError.connectionFailed(error.localizedDescription)))
                
            case .waiting(let error):
                logWarning("OSC connection waiting: \(error.localizedDescription)", category: .osc)
                
            case .preparing:
                logDebug("OSC connection preparing", category: .osc)
                self.queue.sync {
                    self._connectionState = .connecting
                }
                
            case .setup:
                logDebug("OSC connection setup", category: .osc)
                
            case .cancelled:
                logInfo("OSC connection cancelled", category: .osc)
                self.queue.sync {
                    self._connectionState = .disconnected
                }
                
            @unknown default:
                logWarning("Unknown OSC connection state", category: .osc)
            }
        }
        
        // Start the connection
        connection.start(queue: queue)
        self.connection = connection
    }
    
    /// Disconnect from the OSC server
    public func disconnect() {
        guard let connection = connection else {
            logWarning("Attempted to disconnect when no connection exists", category: .osc)
            return
        }
        
        logInfo("Disconnecting from OSC server", category: .osc)
        
        queue.sync {
            self._connectionState = .canceling
        }
        
        connection.cancel()
        self.connection = nil
        
        queue.sync {
            self._connectionState = .disconnected
        }
    }
    
    /// Send an OSC message
    /// - Parameters:
    ///   - message: The OSC message to send
    ///   - completion: Optional completion handler called when the send operation completes
    public func send(message: OSCMessage, completion: ((Result<Void, Error>) -> Void)?) {
        // Check if connected
        guard let connection = connection, isConnected else {
            logError("Cannot send OSC message: Not connected", category: .osc)
            completion?(.failure(OSCError.notConnected))
            return
        }
        
        // Convert message to binary data
        let messageData = message.toData()
        
        logDebug("Sending OSC message to \(message.address) with \(message.arguments.count) arguments", category: .osc)
        
        // Send the data
        connection.send(content: messageData, completion: .contentProcessed { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                logError("Failed to send OSC message: \(error.localizedDescription)", category: .osc)
                completion?(.failure(OSCError.sendFailed(error.localizedDescription)))
            } else {
                logDebug("OSC message sent successfully", category: .osc)
                completion?(.success(()))
            }
        })
    }
}
