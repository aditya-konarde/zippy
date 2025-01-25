import Foundation
import Network
import os.log

@available(macOS 11.0, *)
/// Manages network connections and monitors network status
open class NetworkManager {
    /// Logger for network-related events
    private let logger = Logger(subsystem: "com.zippy.networking", category: "NetworkManager")
    /// Monitors network path changes
    public let monitor: NetworkMonitor
    /// Manages individual connections
    private let connectionManager: ConnectionManager
    /// Manages network bonding
    private let bondManager: NetworkBondManager
    /// Delegate for receiving network updates
    public weak var delegate: NetworkManagerDelegate?
    /// Enables or disables network functionality
    public var isEnabled = true
    /// Currently available hotspot devices
    private var availableHotspots: Set<String> = []
    /// Manages MPTCP connections
    private let mptcpManager: MPTCPConnectionManager
    /// Current bonding mode
    private var currentMode: NetworkBondManager.BondingMode = .activeBackup

    public init() {
        logger.info("Initializing NetworkManager")
        
        // Initialize components
        monitor = NetworkMonitor()
        connectionManager = ConnectionManager(monitor: monitor)
        mptcpManager = MPTCPConnectionManager(monitor: monitor)
        bondManager = NetworkBondManager(connectionManager: connectionManager, mptcpManager: mptcpManager)
        
        // Set up delegates
        monitor.delegate = self
        mptcpManager.delegate = self
        bondManager.delegate = self
        
        // Start monitoring
        monitor.startMonitoring()
        logger.info("Network monitoring started")
        
        startHotspotDiscovery()
    }

    /// Toggles a specific network connection
    /// - Parameter type: The type of connection to toggle
    open func toggleConnection(for type: ConnectionType) {
        logger.info("Toggling connection for type: \(String(describing: type))")
        connectionManager.toggleConnection(for: type)
    }

    /// Connects to a specific iPhone hotspot
    /// - Parameter deviceName: The name of the iPhone to connect to
    open func connectToHotspot(deviceName: String) {
        guard availableHotspots.contains(deviceName) else {
            logger.error("Hotspot device \(deviceName) not found")
            return
        }

        // In a real implementation, we would use NEHotspotHelper to connect
        // For now, simulate the connection
        logger.info("Connecting to hotspot: \(deviceName)")
        
        // Simulate connection process
        Task {
            delegate?.networkManager(self, didUpdateStatus: NWPath.Status.requiresConnection, for: ConnectionType.hotspot)
            try? await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
            delegate?.networkManager(self, didUpdateStatus: NWPath.Status.satisfied, for: ConnectionType.hotspot)
        }
    }

    public func disableAllConnections() {
        logger.info("Disabling all connections")
        ConnectionType.allCases.forEach { type in
            connectionManager.teardownConnection(for: type)
        }
    }
    
    private func startHotspotDiscovery() {
        // Start monitoring for hotspot devices
        logger.info("Starting hotspot discovery")
        
        // Simulate discovery of hotspot devices
        Task {
            try? await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
            let devices = ["iPhone 14 Pro", "iPhone 13"]
            delegate?.networkManager(self, didUpdateHotspotDevices: devices)
        }
    }

    private func handleConnectionChange(for interface: NWInterface) {
        if let type = interfaceTypeToConnectionType(interface.type) {
            connectionManager.setupNewConnection(for: type)
        }
    }

    /// Toggles network functionality on or off
    open func toggleNetwork() {
        self.isEnabled.toggle()
        logger.log("Network \(self.isEnabled ? "enabled" : "disabled")")

        if !self.isEnabled {
            // Disconnect all interfaces when disabled
            ConnectionType.allCases.forEach { type in
                connectionManager.teardownConnection(for: type)
            }
        } else {
            monitor.updateConnectionStatus() // Reconnect when enabled
        }
    }

    /// Sets the bonding mode for network connections
    /// - Parameter mode: The desired bonding mode
    open func setBondingMode(_ mode: NetworkBondManager.BondingMode) {
        logger.info("Setting bonding mode: \(String(describing: mode))")
        bondManager.setBondingMode(mode)
    }

    /// Retrieves an endpoint for the specified connection type
    /// - Parameter type: The connection type to get the endpoint for
    /// - Returns: An NWEndpoint if available, otherwise nil
    public func getEndpoint(for type: ConnectionType) -> NWEndpoint? {
        switch type {
        case .wifi:
            return NWEndpoint.hostPort(host: "wifi.example.com", port: 80)
        case .ethernet:
            return NWEndpoint.hostPort(host: "ethernet.example.com", port: 80)
        case .hotspot:
            return NWEndpoint.hostPort(host: "hotspot.example.com", port: 80)
        }
    }

    /// Converts a network interface type to a connection type
    /// - Parameter type: The network interface type to convert
    /// - Returns: The corresponding ConnectionType or nil if not applicable
    private func interfaceTypeToConnectionType(_ type: NWInterface.InterfaceType) -> ConnectionType? {
        switch type {
        case .wifi:
            return .wifi
        case .wiredEthernet:
            return .ethernet
        default:
            return nil
        }
    }
}

// MARK: - NetworkMonitorDelegate
extension NetworkManager: NetworkMonitorDelegate {
    /// Called when the network monitor updates the connection status
    /// - Parameters:
    ///   - monitor: The network monitor reporting the change
    ///   - status: The new network status
    ///   - type: The connection type affected
    public func networkMonitor(_ monitor: NetworkMonitor, didUpdateStatus status: NWPath.Status, for type: ConnectionType) {
        logger.info("Network status updated - type: \(String(describing: type)), status: \(String(describing: status))")
        delegate?.networkManager(self, didUpdateStatus: status, for: type)
    }
}

// MARK: - NetworkBondManagerDelegate
extension NetworkManager: NetworkBondManagerDelegate {
    public func networkBondManager(_ manager: NetworkBondManager, didUpdateBondStatus status: BondStatus) {
        logger.info("Bond status updated: \(String(describing: status))")
        delegate?.networkManager(self, didUpdateBondStatus: status)
    }
    
    public func networkBondManager(_ manager: NetworkBondManager, didUpdateActiveConnection type: ConnectionType) {
        logger.info("Active bonded connection updated: \(String(describing: type))")
        delegate?.networkManager(self, didUpdateStatus: .satisfied, for: type)
    }
}

// MARK: - MPTCPConnectionManagerDelegate
extension NetworkManager: MPTCPConnectionManagerDelegate {
    public func mptcpManager(_ manager: MPTCPConnectionManager, didUpdateStatus status: NWPath.Status) {
        logger.info("MPTCP status updated: \(String(describing: status))")
        // Update both Wi-Fi and Ethernet status since MPTCP affects both
        delegate?.networkManager(self, didUpdateStatus: status, for: .wifi)
        delegate?.networkManager(self, didUpdateStatus: status, for: .ethernet)
    }
    
    public func mptcpManager(_ manager: MPTCPConnectionManager, didUpdateInterfaces interfaces: [NWInterface]) {
        logger.info("MPTCP interfaces updated: \(interfaces.map { $0.name })")
        // Update bond status based on available interfaces
        let bondStatus: BondStatus = interfaces.count > 1 ? .active : .inactive
        delegate?.networkManager(self, didUpdateBondStatus: bondStatus)
    }
    
    public func mptcpManager(_ manager: MPTCPConnectionManager, didUpdateMetrics metrics: MPTCPConnectionMetrics) {
        logger.info("""
            MPTCP metrics updated:
            - Status: \(String(describing: metrics.status))
            - Interfaces: \(metrics.interfaces.map { $0.name })
            - Expensive: \(metrics.isExpensive)
            - Constrained: \(metrics.isConstrained)
            - Subflow count: \(metrics.subflowCount)
            - Preferred path available: \(metrics.preferredPathAvailable)
            """)
        
        // Update bond status based on metrics
        let bondStatus: BondStatus = metrics.interfaces.count > 1 ? .active : .inactive
        delegate?.networkManager(self, didUpdateBondStatus: bondStatus)
    }
}
