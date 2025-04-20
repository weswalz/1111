//
//  ConnectionsView.swift
//  LED Messenger macOS
//
//  Created on April 18, 2025
//

import SwiftUI
import Combine

/// View for managing connections to Resolume and iPad clients
struct ConnectionsView: View {
    // MARK: - Environment Objects
    
    /// The Resolume connector
    @EnvironmentObject var resolumeConnector: ResolumeConnector
    
    /// The peer server
    @EnvironmentObject var peerServer: PeerServer
    
    /// App coordinator for showing notifications
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    // MARK: - State
    
    /// Filter for connection logs
    @State private var logFilter: LogCategory? = nil
    
    /// Whether to show OSC connection settings
    @State private var showingOSCSettings = false
    
    /// Selected log entry
    @State private var selectedLogEntry: ConnectionLog? = nil
    
    /// Log entries
    @State private var logEntries: [ConnectionLog] = []
    
    /// Subscription cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()
                .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Main content
            HSplitView {
                // Status and clients section
                VStack(spacing: 0) {
                    // Status section
                    statusSection
                        .padding()
                    
                    Divider()
                    
                    // Clients section
                    clientsSection
                        .padding()
                }
                .frame(minWidth: 300, maxWidth: 400)
                
                // Log section
                VStack(spacing: 0) {
                    // Log filter header
                    logFilterHeader
                        .padding()
                        .background(Color.gray.opacity(0.1))
                    
                    Divider()
                    
                    // Log entries
                    if logEntries.isEmpty {
                        emptyLogView
                    } else {
                        logEntriesView
                    }
                }
            }
        }
        .onAppear {
            setupLogEntries()
            setupSubscriptions()
        }
        .sheet(isPresented: $showingOSCSettings) {
            OSCConnectionSettingsView(
                oscSettings: Binding(
                    get: { resolumeConnector.oscSettings },
                    set: { settings in
                        resolumeConnector.oscSettings = settings
                    }
                ),
                resolumeConnector: resolumeConnector
            )
            .frame(width: 500, height: 600)
        }
    }
    
    // MARK: - Header View
    
    /// Header view with title and actions
    private var headerView: some View {
        HStack {
            Text("Connections")
                .font(.headline)
            
            Spacer()
            
            // Help button
            Button(action: {
                // Show help information
                appCoordinator.showNotification(
                    message: "Connection management for Resolume Arena and iPad clients",
                    type: .info,
                    duration: 3.0
                )
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("Connection Help")
        }
    }
    
    // MARK: - Status Section
    
    /// Section showing connection status
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text("Connection Status")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            // Resolume status
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Resolume status label
                    Text("Resolume")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(resolumeConnectionColor)
                            .frame(width: 8, height: 8)
                        
                        Text(resolumeConnectionStatus)
                            .font(.caption)
                            .foregroundColor(resolumeConnectionColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .stroke(resolumeConnectionColor, lineWidth: 1)
                    )
                }
                
                // Connection details
                if resolumeConnector.connectionState == .connected {
                    VStack(alignment: .leading, spacing: 4) {
                        // IP address
                        HStack {
                            Text("IP:")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Text(resolumeConnector.oscSettings.ipAddress)
                                .font(.caption)
                        }
                        
                        // Port
                        HStack {
                            Text("Port:")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Text("\(resolumeConnector.oscSettings.port)")
                                .font(.caption)
                        }
                    }
                    .padding(.leading, 4)
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    // Toggle connection button
                    Button(action: toggleResolumeConnection) {
                        Text(resolumeConnector.connectionState == .connected ? "Disconnect" : "Connect")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(resolumeConnector.connectionState == .connecting)
                    
                    // Settings button
                    Button(action: {
                        showingOSCSettings = true
                    }) {
                        Text("Settings")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            .background(AppTheme.Colors.surface)
            .cornerRadius(8)
            
            // iPad clients status
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // iPad clients label
                    Text("iPad Clients")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(peerStatusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(peerStatusText)
                            .font(.caption)
                            .foregroundColor(peerStatusColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .stroke(peerStatusColor, lineWidth: 1)
                    )
                }
                
                // Connection details
                if peerServer.serverState.isAdvertising {
                    VStack(alignment: .leading, spacing: 4) {
                        // Client count
                        HStack {
                            Text("Connected:")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Text("\(peerServer.clients.count) client\(peerServer.clients.count == 1 ? "" : "s")")
                                .font(.caption)
                        }
                        
                        // Service name
                        HStack {
                            Text("Service:")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Text(peerServer.serviceType)
                                .font(.caption)
                        }
                    }
                    .padding(.leading, 4)
                }
                
                // Action button
                Button(action: toggleAdvertising) {
                    Text(peerServer.serverState.isAdvertising ? "Stop Advertising" : "Start Advertising")
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(AppTheme.Colors.surface)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Clients Section
    
    /// Section showing connected clients
    private var clientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text("Connected Clients")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            // Client list
            if peerServer.clients.isEmpty {
                // No clients connected
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "ipad")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                    
                    Text("No Clients Connected")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    if !peerServer.serverState.isAdvertising {
                        Text("Start advertising to allow iPad clients to connect")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: toggleAdvertising) {
                            Text("Start Advertising")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Colors.surface)
                .cornerRadius(8)
                
            } else {
                // Connected clients
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(peerServer.clients, id: \.id) { client in
                            clientRow(client)
                        }
                    }
                }
                .padding()
                .background(AppTheme.Colors.surface)
                .cornerRadius(8)
            }
        }
    }
    
    /// Row for an individual client
    /// - Parameter client: The client to display
    private func clientRow(_ client: PeerClient) -> some View {
        HStack {
            // Device icon
            Image(systemName: "ipad")
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                // Device name
                Text(client.displayName)
                    .fontWeight(.medium)
                
                // Connection time
                if let connectedAt = client.connectedAt {
                    Text("Connected \(timeAgo(connectedAt))")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Disconnect button
            Button(action: {
                disconnectClient(client)
            }) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(AppTheme.Colors.error)
            }
            .buttonStyle(.plain)
            .help("Disconnect \(client.displayName)")
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Log Filter Header
    
    /// Header for log filtering
    private var logFilterHeader: some View {
        HStack {
            Text("Connection Log")
                .font(.headline)
            
            Spacer()
            
            // Filter menu
            Menu {
                Button(action: {
                    logFilter = nil
                }) {
                    HStack {
                        Text("All")
                        if logFilter == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                ForEach([LogCategory.osc, LogCategory.peer, LogCategory.network], id: \.self) { category in
                    Button(action: {
                        logFilter = category
                    }) {
                        HStack {
                            Text(category.rawValue.capitalized)
                            if logFilter == category {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(logFilter == nil ? "All" : logFilter!.rawValue.capitalized)
                    Image(systemName: "chevron.down")
                }
                .font(.subheadline)
            }
            .menuStyle(.borderlessButton)
            
            // Clear log button
            Button(action: clearLogs) {
                Text("Clear")
                    .font(.subheadline)
            }
        }
    }
    
    // MARK: - Log Entries View
    
    /// View for empty log
    private var emptyLogView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
            
            Text("No Connection Logs")
                .font(.title3)
                .foregroundColor(AppTheme.Colors.text)
            
            Text("Connection events will appear here")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(40)
    }
    
    /// View for log entries
    private var logEntriesView: some View {
        let filteredLogs = logFilter == nil ? logEntries : logEntries.filter { $0.category == logFilter }
        
        return HSplitView {
            // Log entries list
            List(filteredLogs, id: \.id, selection: $selectedLogEntry) { log in
                logEntryRow(log)
                    .tag(log)
            }
            .listStyle(.plain)
            
            // Details pane
            if let selectedLog = selectedLogEntry {
                logDetailView(selectedLog)
                    .frame(minWidth: 300)
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                    
                    Text("Select a log entry to view details")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding(20)
                .frame(minWidth: 300)
            }
        }
    }
    
    /// Row for a log entry
    /// - Parameter log: The log entry to display
    private func logEntryRow(_ log: ConnectionLog) -> some View {
        HStack(spacing: 12) {
            // Log category indicator
            Image(systemName: iconForCategory(log.category))
                .foregroundColor(colorForLogType(log.type))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                // Log message
                Text(log.message)
                    .lineLimit(1)
                
                // Timestamp
                Text(formatTimestamp(log.timestamp))
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Detail view for a log entry
    /// - Parameter log: The log entry to display
    private func logDetailView(_ log: ConnectionLog) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Log Details")
                    .font(.headline)
                
                Spacer()
                
                // Type indicator
                Text(log.type.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(colorForLogType(log.type))
                    )
            }
            .padding(.bottom, 8)
            
            // Category and timestamp
            HStack {
                Label(log.category.rawValue.capitalized, systemImage: iconForCategory(log.category))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Text(formatFullTimestamp(log.timestamp))
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .font(.subheadline)
            
            Divider()
            
            // Message
            VStack(alignment: .leading, spacing: 4) {
                Text("Message")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(log.message)
                    .font(.body)
            }
            
            // Details if present
            if let details = log.details, !details.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(details)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.surface)
    }
    
    // MARK: - Setup
    
    /// Set up initial log entries
    private func setupLogEntries() {
        // Add initial log entry
        logEntries.append(ConnectionLog(
            message: "Connection management initialized",
            category: .app,
            type: .info,
            details: "Ready to monitor connections for Resolume Arena and iPad clients"
        ))
        
        // Add current status logs
        if resolumeConnector.connectionState == .connected {
            logEntries.append(ConnectionLog(
                message: "Resolume connection active",
                category: .osc,
                type: .success,
                details: "Connected to Resolume at \(resolumeConnector.oscSettings.ipAddress):\(resolumeConnector.oscSettings.port)"
            ))
        }
        
        if peerServer.serverState.isAdvertising {
            logEntries.append(ConnectionLog(
                message: "iPad client advertising active",
                category: .peer,
                type: .success,
                details: "Advertising service '\(peerServer.serviceType)' for iPad connections"
            ))
        }
        
        // Add logs for each connected client
        for client in peerServer.clients {
            logEntries.append(ConnectionLog(
                message: "iPad client connected: \(client.displayName)",
                category: .peer,
                type: .success,
                details: "Client ID: \(client.id.uuidString)\nConnected at: \(formatFullTimestamp(client.connectedAt ?? Date()))"
            ))
        }
    }
    
    /// Set up subscriptions for state changes
    private func setupSubscriptions() {
        // Monitor Resolume connection state changes
        resolumeConnector.$connectionState
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .connected:
                    self.addLog(
                        message: "Connected to Resolume",
                        category: .osc,
                        type: .success,
                        details: "Connected to Resolume Arena at \(self.resolumeConnector.oscSettings.ipAddress):\(self.resolumeConnector.oscSettings.port)"
                    )
                    
                case .disconnected:
                    self.addLog(
                        message: "Disconnected from Resolume",
                        category: .osc,
                        type: .warning,
                        details: "OSC connection to Resolume Arena closed"
                    )
                    
                case .connecting:
                    self.addLog(
                        message: "Connecting to Resolume",
                        category: .osc,
                        type: .info,
                        details: "Attempting to connect to Resolume Arena at \(self.resolumeConnector.oscSettings.ipAddress):\(self.resolumeConnector.oscSettings.port)"
                    )
                    
                case .failed:
                    self.addLog(
                        message: "Resolume connection failed",
                        category: .osc,
                        type: .error,
                        details: "Failed to establish OSC connection to Resolume Arena at \(self.resolumeConnector.oscSettings.ipAddress):\(self.resolumeConnector.oscSettings.port)"
                    )
                }
            }
            .store(in: &cancellables)
        
        // Monitor peer server state changes
        peerServer.$serverState
            .sink { [weak self] state in
                guard let self = self else { return }
                
                if state.isAdvertising {
                    self.addLog(
                        message: "Started advertising to iPad clients",
                        category: .peer,
                        type: .success,
                        details: "Advertising service '\(self.peerServer.serviceType)' for iPad connections"
                    )
                } else {
                    self.addLog(
                        message: "Stopped advertising to iPad clients",
                        category: .peer,
                        type: .warning,
                        details: "No longer accepting new iPad connections"
                    )
                }
            }
            .store(in: &cancellables)
        
        // Monitor client connections
        peerServer.clientConnectedPublisher
            .sink { [weak self] client in
                guard let self = self else { return }
                
                self.addLog(
                    message: "iPad client connected: \(client.displayName)",
                    category: .peer,
                    type: .success,
                    details: "Client ID: \(client.id.uuidString)\nConnected at: \(formatFullTimestamp(client.connectedAt ?? Date()))"
                )
            }
            .store(in: &cancellables)
        
        // Monitor client disconnections
        peerServer.clientDisconnectedPublisher
            .sink { [weak self] client in
                guard let self = self else { return }
                
                self.addLog(
                    message: "iPad client disconnected: \(client.displayName)",
                    category: .peer,
                    type: .warning,
                    details: "Client ID: \(client.id.uuidString)"
                )
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    /// Toggle Resolume connection
    private func toggleResolumeConnection() {
        if resolumeConnector.connectionState == .connected {
            // Disconnect
            resolumeConnector.disconnect()
        } else {
            // Connect
            let validationResult = resolumeConnector.oscSettings.validate()
            if !validationResult.isValid {
                // Show validation error
                appCoordinator.showNotification(
                    message: "Invalid OSC settings: \(validationResult.error ?? "Unknown error")",
                    type: .error
                )
                
                // Log the validation error
                addLog(
                    message: "Invalid OSC settings",
                    category: .osc,
                    type: .error,
                    details: validationResult.error
                )
                
                return
            }
            
            // Connect to Resolume
            resolumeConnector.connect { _ in
                // Connection result handled by the subscription
            }
        }
    }
    
    /// Toggle advertising for peer clients
    private func toggleAdvertising() {
        if peerServer.serverState.isAdvertising {
            // Stop advertising
            peerServer.stopAdvertising()
        } else {
            // Start advertising
            peerServer.startAdvertising()
        }
    }
    
    /// Disconnect a client
    /// - Parameter client: The client to disconnect
    private func disconnectClient(_ client: PeerClient) {
        peerServer.disconnectClient(client.id)
        
        // Log the action
        addLog(
            message: "Manually disconnected client: \(client.displayName)",
            category: .peer,
            type: .info,
            details: "Client ID: \(client.id.uuidString)"
        )
    }
    
    /// Clear all logs
    private func clearLogs() {
        logEntries.removeAll()
        selectedLogEntry = nil
        
        // Add a log entry for clearing
        addLog(
            message: "Connection logs cleared",
            category: .app,
            type: .info,
            details: nil
        )
    }
    
    /// Add a log entry
    /// - Parameters:
    ///   - message: The log message
    ///   - category: The log category
    ///   - type: The log type
    ///   - details: Optional details
    private func addLog(message: String, category: LogCategory, type: LogType, details: String?) {
        let log = ConnectionLog(
            message: message,
            category: category,
            type: type,
            details: details
        )
        
        // Add to the beginning of the array
        DispatchQueue.main.async {
            self.logEntries.insert(log, at: 0)
            
            // Limit log entries to 100
            if self.logEntries.count > 100 {
                self.logEntries.removeLast()
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// Color for Resolume connection status
    private var resolumeConnectionColor: Color {
        switch resolumeConnector.connectionState {
        case .connected:
            return AppTheme.Colors.success
        case .connecting:
            return AppTheme.Colors.warning
        case .disconnected:
            return AppTheme.Colors.textSecondary
        case .failed:
            return AppTheme.Colors.error
        }
    }
    
    /// Text for Resolume connection status
    private var resolumeConnectionStatus: String {
        switch resolumeConnector.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .failed:
            return "Failed"
        }
    }
    
    /// Color for peer status
    private var peerStatusColor: Color {
        if peerServer.serverState.isAdvertising {
            return peerServer.clients.isEmpty ? AppTheme.Colors.warning : AppTheme.Colors.success
        } else {
            return AppTheme.Colors.textSecondary
        }
    }
    
    /// Text for peer status
    private var peerStatusText: String {
        if peerServer.serverState.isAdvertising {
            return peerServer.clients.isEmpty ? "Waiting" : "Active"
        } else {
            return "Inactive"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Format a timestamp as a relative time
    /// - Parameter date: The date to format
    /// - Returns: A formatted relative time string
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Format a timestamp as a time
    /// - Parameter date: The date to format
    /// - Returns: A formatted time string
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Format a timestamp as a full date and time
    /// - Parameter date: The date to format
    /// - Returns: A formatted date and time string
    private func formatFullTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Get an icon for a log category
    /// - Parameter category: The log category
    /// - Returns: A system image name
    private func iconForCategory(_ category: LogCategory) -> String {
        switch category {
        case .osc:
            return "music.note.list"
        case .peer:
            return "ipad.and.iphone"
        case .network:
            return "network"
        case .app:
            return "app.fill"
        default:
            return "doc.text"
        }
    }
    
    /// Get a color for a log type
    /// - Parameter type: The log type
    /// - Returns: A color
    private func colorForLogType(_ type: LogType) -> Color {
        switch type {
        case .success:
            return AppTheme.Colors.success
        case .info:
            return AppTheme.Colors.primary
        case .warning:
            return AppTheme.Colors.warning
        case .error:
            return AppTheme.Colors.error
        }
    }
}

// MARK: - Log Models

/// Types of log entries
enum LogType: String {
    case success
    case info
    case warning
    case error
}

/// A connection log entry
struct ConnectionLog: Identifiable, Hashable {
    /// The unique identifier
    let id = UUID()
    
    /// The log message
    let message: String
    
    /// The log category
    let category: LogCategory
    
    /// The log type
    let type: LogType
    
    /// Optional details
    let details: String?
    
    /// The timestamp
    let timestamp = Date()
    
    /// Equatable implementation
    static func == (lhs: ConnectionLog, rhs: ConnectionLog) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Preview for the connections view
struct ConnectionsView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionsView()
            .environmentObject(ResolumeConnector(settings: Settings().oscSettings))
            .environmentObject(PeerServer())
            .environmentObject(AppCoordinator())
            .frame(width: 800, height: 600)
    }
}