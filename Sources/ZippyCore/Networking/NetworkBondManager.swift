import Network

public enum NetworkBondError: Error {
    case invalidMode
    case noActiveConnections
}

public enum BondStatus {
    case active
    case inactive
    case failed(Error)
}

public protocol NetworkBondManagerDelegate: AnyObject {
    func networkBondManager(_ manager: NetworkBondManager, didUpdateBondStatus status: BondStatus)
    func networkBondManager(_ manager: NetworkBondManager, didUpdateActiveConnection type: ConnectionType)
}

open class NetworkBondManager {
    public enum BondingMode: String, CaseIterable {
        case activeBackup
        case loadBalance
        case broadcast
    }
    
    private let logger = Logger(subsystem: "com.zippy.networking", category: "NetworkBondManager")
    private let connectionManager: ConnectionManager
    private let mptcpManager: MPTCPConnectionManager
    private var currentMode: BondingMode = .activeBackup
    private var _activeConnections: Set<ConnectionType> = []
    internal var activeConnections: Set<ConnectionType> {
        get { queue.sync { _activeConnections } }
        set { queue.sync { _activeConnections = newValue } }
    }
    private var metricsTask: Task<Void, Never>?
    private let metricsInterval: TimeInterval = 1.0
    
    public weak var delegate: NetworkBondManagerDelegate?
    
    public init(connectionManager: ConnectionManager, mptcpManager: MPTCPConnectionManager) {
        self.connectionManager = connectionManager
        self.mptcpManager = mptcpManager
        queue.async { [weak self] in
            self?.startMetricsMonitoring()
        }
    }
    
    deinit {
        stopMetricsMonitoring()
        logger.info("NetworkBondManager deallocated")
    }
    
    open func setBondingMode(_ mode: BondingMode) throws {
        guard validateModeChange(to: mode) else {
            throw NetworkBondError.invalidMode
        }
        
        currentMode = mode
        logger.info("Bonding mode set to \(mode)")
        configureBonding()
    }
    
    open func getCurrentMode() -> BondingMode {
        return currentMode
    }
    
    private func validateModeChange(to mode: BondingMode) -> Bool {
        return true
    }
    
    private func configureBonding() {
        switch currentMode {
        case .activeBackup:
            handleActiveBackup()
        case .loadBalance:
            handleLoadBalance()
        case .broadcast:
            handleBroadcast()
        }
    }
    
    private func startMetricsMonitoring() {
        stopMetricsMonitoring()
        
        metricsTask = Task {
            while true {
                updateMetrics()
                try Task.sleep(nanoseconds: UInt64(metricsInterval * 1_000_000_000))
            }
        }
    }
    
    private func stopMetricsMonitoring() {
        metricsTask?.cancel()
        metricsTask = nil
    }
    
    private func updateMetrics() async {
        guard let path = NWPathMonitor().currentPath else { return }
        
        let metrics = MPTCPConnectionMetrics(
            status: path.status,
            interfaces: path.availableInterfaces,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained,
            subflowCount: 0,
            preferredPathAvailable: false
        )
        
        delegate?.mptcpManager(self, didUpdateMetrics: metrics)
    }
    
    open func evaluateConnections() {
        let activeTypes = connectionManager.connections.keys.filter { connectionManager.isEnabled[$0] ?? false }
        activeConnections = Set(activeTypes)
        logger.debug("Active connections updated: \(activeTypes)")
        
        delegate?.networkBondManager(self, didUpdateActiveConnection: activeTypes.first ?? .wifi)
    }
    
    private func handleActiveBackup() {
        let priorityOrder: [ConnectionType] = [.ethernet, .wifi, .hotspot]
        let activeType = priorityOrder.first { connectionManager.isEnabled[$0] ?? false }
        
        if let activeType = activeType {
            connectionManager.toggleConnection(for: activeType)
            logger.info("Active backup connection set to \(activeType)")
        } else {
            logger.warning("No active connection available for active backup")
        }
    }
    
    private func handleLoadBalance() {
        let availableTypes = connectionManager.connections.keys.filter { connectionManager.isEnabled[$0] ?? false }
        logger.info("Load balancing across connections: \(availableTypes)")
    }
    
    private func handleBroadcast() {
        let availableTypes = connectionManager.connections.keys.filter { connectionManager.isEnabled[$0] ?? false }
        logger.info("Broadcasting across connections: \(availableTypes)")
    }
    
    // MARK: - Delegate Methods
    
    public func connectionManager(_ manager: ConnectionManager, didUpdateStatus status: NWPath.Status, for type: ConnectionType) {
        logger.debug("Connection status changed for \(type): \(status)")
        evaluateConnections()
    }
}