import Foundation
import Network
import os.log

@available(macOS 11.0, *)
public final class ConnectionManager {
    private let logger = Logger(subsystem: "com.zippy.networking", category: "ConnectionManager")
    private var connections: [ConnectionType: NWConnection] = [:]
    private var connectionRetryCount: [ConnectionType: Int] = [:]
    private var isEnabled: [ConnectionType: Bool] = [:]
    private let maxRetryAttempts = 3
    private let retryInterval: TimeInterval = 5.0
    private let monitor: NetworkMonitor
    
    public weak var delegate: ConnectionManagerDelegate?
    
    public init(monitor: NetworkMonitor) {
        self.monitor = monitor
        // Enable all connection types by default
        ConnectionType.allCases.forEach { isEnabled[$0] = true }
        logger.info("ConnectionManager initialized")
    }
    
    deinit {
        connections.forEach { $0.value.cancel() }
        connections.removeAll()
    }
    
    public func toggleConnection(for type: ConnectionType) {
        logger.info("Toggling connection for \(type.rawValue)")
        
        // Toggle enabled state
        isEnabled[type] = !(isEnabled[type] ?? true)
        
        if isEnabled[type] == true {
            // If enabling, check if interface is available
            let currentPath = monitor.currentPath
            if currentPath.availableInterfaces.contains(where: { matchesType($0.type, connectionType: type) }) {
                setupNewConnection(for: type)
            } else {
                logger.warning("No available interface for \(type.rawValue)")
                delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
            }
        } else {
            // If disabling, tear down the connection
            teardownConnection(for: type)
            delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
        }
    }
    
    private func matchesType(_ interfaceType: NWInterface.InterfaceType, connectionType: ConnectionType) -> Bool {
        switch (interfaceType, connectionType) {
        case (.wifi, .wifi):
            return true
        case (.wiredEthernet, .ethernet):
            return true
        default:
            return false
        }
    }
    
    public func updateConnectionStatus() {
        let currentPath = monitor.currentPath
        
        // Update status for each connection type based on interface availability and enabled state
        Networking.ConnectionType.allCases.forEach { type in
            let isInterfaceAvailable = currentPath.availableInterfaces.contains { matchesType($0.type, connectionType: type) }
            let isTypeEnabled = isEnabled[type] ?? true
            
            if isInterfaceAvailable && isTypeEnabled {
                delegate?.connectionManager(self, didUpdateStatus: currentPath.status, for: type)
            } else {
                delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
            }
        }
    }
    
    internal func setupNewConnection(for type: ConnectionType) {
        logger.info("Setting up new connection for \(type.rawValue)")
        
        // Cancel any existing connection
        teardownConnection(for: type)
        
        // Create endpoint based on connection type
        let endpoint = NWEndpoint.hostPort(host: "localhost", port: 80)
        
        // Create the connection
        let connection = NWConnection(to: endpoint, using: .tcp)
        connections[type] = connection
        
        // Set up state handler
        setupConnectionStateHandler(connection, for: type)
        
        // Start the connection
        connection.start(queue: .main)
    }
    
    internal func teardownConnection(for type: ConnectionType) {
        logger.info("Tearing down connection for \(type.rawValue)")
        if let connection = connections[type] {
            connection.cancel()
            connections.removeValue(forKey: type)
            connectionRetryCount[type] = 0
        }
    }
    
    public func getConnection(for type: ConnectionType) -> NWConnection? {
        return connections[type]
    }
    
    private func setupConnectionStateHandler(_ connection: NWConnection, for type: ConnectionType) {
        let handler: (NWConnection.State) -> Void = { [weak self] state in
            guard let self = self else { return }
            
            self.logger.info("Connection state update for \(type.rawValue): \(String(describing: state))")
            
            switch state {
            case .setup:
                self.delegate?.connectionManager(self, didUpdateStatus: .requiresConnection, for: type)
                
            case .preparing:
                self.delegate?.connectionManager(self, didUpdateStatus: .requiresConnection, for: type)
                
            case .ready:
                self.connectionRetryCount[type] = 0
                self.delegate?.connectionManager(self, didUpdateStatus: .satisfied, for: type)
                
            case .failed(let error):
                self.logger.error("Connection failed for \(type.rawValue): \(error)")
                self.handleConnectionFailure(for: type)
                
            case .cancelled:
                self.delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
                
            case .waiting(let error):
                self.logger.warning("Connection waiting for \(type.rawValue): \(error)")
                self.delegate?.connectionManager(self, didUpdateStatus: .requiresConnection, for: type)
                
            @unknown default:
                self.logger.error("Unknown connection state for \(type.rawValue)")
                self.delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
            }
        }
        
        connection.stateUpdateHandler = handler
    }
    
    private func handleConnectionFailure(for type: ConnectionType) {
        let retryCount = connectionRetryCount[type] ?? 0
        if retryCount < 3 {
            connectionRetryCount[type] = retryCount + 1
            logger.info("Retrying connection for \(type.rawValue) (attempt \(retryCount + 1))")
            setupNewConnection(for: type)
        } else {
            logger.error("Max retry attempts reached for \(type.rawValue)")
            delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
        }
    }
    
    public func isEnabled(_ type: ConnectionType) -> Bool {
        return isEnabled[type] ?? true
    }
} 