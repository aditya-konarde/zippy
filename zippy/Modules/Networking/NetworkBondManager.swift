import Foundation
import Network
import os.log

@available(macOS 11.0, *)
public enum BondStatus {
    case active
    case inactive
    case error(String)
}

@available(macOS 11.0, *)
open class NetworkBondManager {
    public enum BondingMode: String, CaseIterable {
        case activeBackup = "Active Backup"
        case loadBalance = "Load Balance"
        case broadcast = "Broadcast"
    }
    
    private let logger = Logger(subsystem: "com.zippy.networking", category: "NetworkBondManager")
    private let connectionManager: ConnectionManager
    private let mptcpManager: MPTCPConnectionManager
    private var currentMode: BondingMode = .activeBackup
    internal var activeConnections: Set<ConnectionType> = []
    
    public weak var delegate: NetworkBondManagerDelegate?
    
    public init(connectionManager: ConnectionManager, mptcpManager: MPTCPConnectionManager) {
        self.connectionManager = connectionManager
        self.mptcpManager = mptcpManager
        connectionManager.delegate = self
        logger.info("NetworkBondManager initialized with mode: \(String(describing: self.currentMode))")
    }
    
    open func setBondingMode(_ mode: BondingMode) {
        logger.info("Setting bonding mode to: \(String(describing: mode))")
        currentMode = mode
        
        // Configure MPTCP based on bonding mode
        switch mode {
        case .activeBackup:
            configureMPTCP(serviceType: .handover)
            
        case .loadBalance:
            configureMPTCP(serviceType: .aggregate)
            
        case .broadcast:
            configureMPTCP(serviceType: .interactive)
        }
        
        // Notify delegate of mode change
        delegate?.networkBondManager(self, didUpdateBondStatus: BondStatus.active)
    }
    
    open func getCurrentMode() -> BondingMode {
        return currentMode
    }
    
    private func configureMPTCP(serviceType: NWParameters.MultipathServiceType) {
        if #available(macOS 13.0, *) {
            logger.info("Configuring MPTCP with service type: \(String(describing: serviceType))")
            
            // Create new MPTCP connection with appropriate service type
            mptcpManager.createMPTCPConnection(serviceType: serviceType)
            
            // Start metrics monitoring
            startMetricsMonitoring()
        } else {
            logger.warning("MPTCP not available on this macOS version")
        }
    }
    
    private func startMetricsMonitoring() {
        // Periodically update MPTCP metrics
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if !Task.isCancelled {
                    updateMetrics()
                } else {
                    break
                }
            }
        }
    }
    
    private func updateMetrics() {
        // Get current connection status
        let activeConnections = ConnectionType.allCases.filter { type in
            if let connection = connectionManager.getConnection(for: type) {
                return connection.state == .ready
            }
            return false
        }
        
        // Update bond status based on active connections
        if activeConnections.count > 1 {
            delegate?.networkBondManager(self, didUpdateBondStatus: .active)
            if let activeType = activeConnections.first {
                delegate?.networkBondManager(self, didUpdateActiveConnection: activeType)
            }
        } else {
            delegate?.networkBondManager(self, didUpdateBondStatus: .inactive)
        }
    }
    
    open func evaluateConnections() {
        switch currentMode {
        case .activeBackup:
            handleActiveBackup()
        case .loadBalance:
            handleLoadBalance()
        case .broadcast:
            handleBroadcast()
        }
    }
    
    open func handleActiveBackup() {
        // In active backup mode, we want only one connection active at a time
        // Priority order: Ethernet > Wi-Fi > Hotspot
        let priorityOrder: [ConnectionType] = [.ethernet, .wifi, .hotspot]
        
        guard let activeConnection = priorityOrder.first(where: { activeConnections.contains($0) }) else {
            logger.warning("No active connections available for Active Backup mode")
            return
        }
        
        // Disable all connections except the highest priority active one
        activeConnections.forEach { type in
            if type != activeConnection {
                // Use toggleConnection to disable other connections
                if connectionManager.isEnabled(type) {
                    connectionManager.toggleConnection(for: type)
                }
            }
        }
        
        delegate?.networkBondManager(self, didUpdateActiveConnection: activeConnection)
    }
    
    open func handleLoadBalance() {
        // In load balance mode, we use all available connections
        // No need to disable any connections
        activeConnections.forEach { type in
            delegate?.networkBondManager(self, didUpdateActiveConnection: type)
        }
    }
    
    open func handleBroadcast() {
        // In broadcast mode, we use all available connections simultaneously
        // Similar to load balance, but with different packet distribution
        activeConnections.forEach { type in
            delegate?.networkBondManager(self, didUpdateActiveConnection: type)
        }
    }
    
    open func connectionManager(_ manager: ConnectionManager, didUpdateStatus status: NWPath.Status, for type: ConnectionType) {
        switch status {
        case .satisfied:
            activeConnections.insert(type)
        case .unsatisfied, .requiresConnection:
            activeConnections.remove(type)
        @unknown default:
            logger.error("Unknown connection status for \(type.rawValue)")
            activeConnections.remove(type)
        }
        
        evaluateConnections()
    }
}

extension NetworkBondManager: ConnectionManagerDelegate {}