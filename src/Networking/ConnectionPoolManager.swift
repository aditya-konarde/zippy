import Network
import os.log

@available(macOS 11.0, *)
public class ConnectionPoolManager {
    private var activeConnections: [NWConnection] = []
    private var standbyConnections: [NWConnection] = []
    private let connectionFactory: () -> NWConnection?
    private let logger = OSLog(subsystem: "com.zippy.network", category: "ConnectionPool")
    
    public init(connectionFactory: @escaping () -> NWConnection?) {
        self.connectionFactory = connectionFactory
    }
    
    public func maintainConnections(minActive: Int, maxStandby: Int) {
        // Maintain active connections
        while activeConnections.count < minActive {
            guard let conn = connectionFactory() else { break }
            activeConnections.append(conn)
            conn.stateUpdateHandler = { [weak self] state in
                self?.handleConnectionStateChange(conn, state: state)
            }
            conn.start(queue: .global())
        }
        
        // Maintain standby connections
        while standbyConnections.count < maxStandby {
            guard let conn = connectionFactory() else { break }
            standbyConnections.append(conn)
            conn.stateUpdateHandler = { [weak self] state in
                self?.handleConnectionStateChange(conn, state: state)
            }
            conn.start(queue: .global())
        }
    }
    
    private func handleConnectionStateChange(_ connection: NWConnection, state: NWConnection.State) {
        switch state {
        case .failed(let error):
            os_log("Connection failed with error: %{public}@", log: logger, type: .error, error.localizedDescription)
            handleConnectionFailure(connection)
        case .waiting(let error):
            os_log("Connection waiting: %{public}@", log: logger, type: .info, error.localizedDescription)
        case .ready:
            os_log("Connection ready", log: logger, type: .info)
        case .preparing:
            os_log("Connection preparing", log: logger, type: .debug)
        case .setup:
            os_log("Connection setup", log: logger, type: .debug)
        case .cancelled:
            os_log("Connection cancelled", log: logger, type: .info)
            handleConnectionFailure(connection)
        @unknown default:
            os_log("Unknown connection state", log: logger, type: .error)
        }
    }
    
    public func handleConnectionFailure(_ connection: NWConnection) {
        if let index = activeConnections.firstIndex(where: { $0 === connection }) {
            activeConnections.remove(at: index)
            os_log("Removed failed connection from active pool", log: logger, type: .info)
            
            // Promote standby connection if available
            if let standby = standbyConnections.first {
                standbyConnections.removeFirst()
                activeConnections.append(standby)
                os_log("Promoted standby connection to active pool", log: logger, type: .info)
            }
        }
    }
    
    public func getActiveConnections() -> [NWConnection] {
        return activeConnections
    }
    
    public func getStandbyConnections() -> [NWConnection] {
        return standbyConnections
    }
}
