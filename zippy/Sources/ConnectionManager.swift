import Foundation
import Network
import os.log
import Networking

@available(macOS 11.0, *)
public class ConnectionManager {
    private let logger: Logger = Logger(subsystem: "com.example.zippy", category: "ConnectionManager")
    private var connections: [Networking.ConnectionType: NWConnection] = [:]
    private var connectionRetryCount: [Networking.ConnectionType: Int] = [:]
    private var isEnabled: [Networking.ConnectionType: Bool] = [:]
    private let maxRetryAttempts = 3
    private let monitor: NWPathMonitor
    
    public weak var delegate: ConnectionManagerDelegate?
    
    public init() {
        monitor = NWPathMonitor()
        monitor.start(queue: .global(qos: .utility))
    }
    
    deinit {
        monitor.cancel()
    }
    
    public func toggleConnection(for type: Networking.ConnectionType) {
        if isEnabled[type] ?? false {
            teardownConnection(for: type)
            isEnabled[type] = false
            delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
        } else {
            isEnabled[type] = true
            // For hotspot, we'll just update the status since actual connection is handled elsewhere
            if type == .hotspot {
                delegate?.connectionManager(self, didUpdateStatus: .satisfied, for: type)
                return
            }
            
            // For other connections, set up the connection
            let interface = monitor.currentPath.availableInterfaces.first { $0.type == type.interfaceType }
            guard let interface = interface else {
                logger.error("No interface found for \(type.rawValue)")
                delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
                return
            }
            
            let endpoint = NWEndpoint.hostPort(
                host: NWEndpoint.Host(interface.name),
                port: NWEndpoint.Port(integerLiteral: 80)
            )
            setupNewConnection(for: type, endpoint: endpoint)
        }
    }
    
    public func setupNewConnection(for type: Networking.ConnectionType, endpoint: NWEndpoint) {
        // Don't setup if connection already exists
        guard connections[type] == nil else { return }
        
        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = type.interfaceType
        
        let connection = NWConnection(to: endpoint, using: parameters)
        connections[type] = connection
        
        setupConnectionStateHandler(for: connection, type: type)
        connection.start(queue: .main)
        
        logger.log("Setting up new connection for \(type.rawValue)")
    }
    
    public func teardownConnection(for type: Networking.ConnectionType) {
        guard let connection = connections[type] else { return }
        connection.cancel()
        connections.removeValue(forKey: type)
        connectionRetryCount.removeValue(forKey: type)
        logger.log("Tearing down connection for \(type.rawValue)")
    }
    
    public func getConnection(for type: Networking.ConnectionType) -> NWConnection? {
        return connections[type]
    }
    
    private func setupConnectionStateHandler(for connection: NWConnection, type: Networking.ConnectionType) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            
            switch state {
            case .ready:
                self.connectionRetryCount[type] = 0
                self.delegate?.connectionManager(self, didUpdateStatus: .satisfied, for: type)
                self.logger.log("Connection ready for \(type.rawValue)")
                
            case .failed(let error):
                self.logger.error("Connection failed for \(type.rawValue): \(error.localizedDescription)")
                self.handleConnectionFailure(type: type, error: error)
                
            case .cancelled:
                self.connectionRetryCount[type] = 0
                self.delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
                self.logger.log("Connection cancelled for \(type.rawValue)")
                
            default:
                break
            }
        }
    }
    
    private func handleConnectionFailure(type: Networking.ConnectionType, error: Error) {
        guard let retryCount = connectionRetryCount[type], retryCount < maxRetryAttempts else {
            delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
            return
        }
        
        connectionRetryCount[type] = retryCount + 1
        retryConnection(type: type, after: Double(retryCount + 1))
    }
    
    private func retryConnection(type: Networking.ConnectionType, after delay: TimeInterval) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
            if let connection = connections[type] {
                connection.restart()
            }
        }
    }
    
    @MainActor
    private func handleConnectionTimeout(type: Networking.ConnectionType, connection: NWConnection) {
        logger.warning("Connection timeout for \(type.rawValue)")
        connection.cancel()
        delegate?.connectionManager(self, didUpdateStatus: .unsatisfied, for: type)
    }
}

