import Network

public class NetworkManager {
    private let logger = Logger(subsystem: "com.zippy.networking", category: "NetworkManager")
    public let monitor: NetworkMonitor
    private let connectionManager: ConnectionManager
    private let bondManager: NetworkBondManager
    public weak var delegate: NetworkManagerDelegate?
    public var isEnabled = true
    private var availableHotspots: Set<String> = []
    private let mptcpManager: MPTCPConnectionManager
    private var currentMode: NetworkBondManager.BondingMode = .activeBackup
    
    public init() {
        let monitor = NetworkMonitor()
        self.monitor = monitor
        self.connectionManager = ConnectionManager(monitor: monitor)
        self.mptcpManager = MPTCPConnectionManager(monitor: monitor)
        self.bondManager = NetworkBondManager(connectionManager: connectionManager, mptcpManager: mptcpManager)
        
        monitor.delegate = self
        connectionManager.delegate = self
        bondManager.delegate = self
        mptcpManager.delegate = self
        
        logger.info("NetworkManager initialized with components")
    }
    
    // MARK: - Connection Management
    
    open func toggleConnection(for type: ConnectionType) {
        connectionManager.toggleConnection(for: type)
    }
    
    open func connectToHotspot(deviceName: String) {
        // Implementation for hotspot connection
    }
    
    public func disableAllConnections() {
        connectionManager.connections.forEach { $0.value.cancel() }
        connectionManager.connections.removeAll()
    }
    
    // MARK: - Hotspot Discovery
    
    private func startHotspotDiscovery() {
        availableHotspots = ["iPhone 14 Pro", "iPhone 13"]
        logger.debug("Discovered hotspots: \(availableHotspots)")
    }
    
    // MARK: - Network Monitoring
    
    open func toggleNetwork() {
        isEnabled.toggle()
        logger.info("Network monitoring \(isEnabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Bonding Configuration
    
    open func setBondingMode(_ mode: NetworkBondManager.BondingMode) {
        do {
            try bondManager.setBondingMode(mode)
            currentMode = mode
            logger.info("Bonding mode set to \(mode)")
        } catch {
            logger.error("Failed to set bonding mode: \(error)")
        }
    }
    
    // MARK: - Delegate Methods
    
    public func networkMonitor(_ monitor: NetworkMonitor, didUpdateStatus status: NWPath.Status, for type: ConnectionType) {
        logger.debug("Network status changed for \(type): \(status)")
    }
    
    public func networkBondManager(_ manager: NetworkBondManager, didUpdateBondStatus status: BondStatus) {
        logger.info("Bond status updated: \(status)")
    }
    
    public func mptcpManager(_ manager: MPTCPConnectionManager, didUpdateStatus status: NWPath.Status) {
        logger.debug("MPTCP connection status: \(status)")
    }
}
