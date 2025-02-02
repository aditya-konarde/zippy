import Foundation
import Network
import os
import Networking

@available(macOS 11.0, *)
public class AppNetworkManager: Networking.ConnectionManager {
    private let appLogger: Logger = Logger(subsystem: "com.example.zippy", category: "AppNetworkManager")
    public let monitor: NetworkMonitor = NetworkMonitor()
    public var delegate: Networking.ConnectionManagerDelegate?
    private var bondManager: Networking.NetworkBondManager!
    private var mptcpManager: Networking.MPTCPConnectionManager!
    
    public init() {
        mptcpManager = RealMPTCPManager()
        bondManager = RealNetworkBondManager(
            connectionManager: self,
            mptcpManager: mptcpManager,
            connectionFactory: { [weak self] in
                return self?.createConnection()
            }
        )
        bondManager.delegate = self
    }
    
    public func toggleConnection(for type: Networking.ConnectionType) {
        appLogger.info("Toggle connection for: \(String(describing: type))")
    }
    
    public func getConnection(for type: Networking.ConnectionType) -> Any? {
        // Return dummy connections for now to enable bonding
        return type
    }
    
    public func connectToHotspot(deviceName: String) {
        appLogger.info("Connect to hotspot: \(deviceName)")
    }
    
    public func setBondingMode(_ mode: Networking.BondingMode) {
        do {
            try bondManager.setBondingMode(mode)
            appLogger.info("Successfully set bonding mode to: \(String(describing: mode))")
        } catch {
            appLogger.error("Failed to set bonding mode: \(error.localizedDescription)")
            delegate?.connectionManager(self, didUpdateBondStatus: .error(description: error.localizedDescription))
        }
    }
    
    public func connectionManager(_ manager: Networking.ConnectionManager, didUpdateBondStatus status: Networking.BondStatus) {
        delegate?.connectionManager(self, didUpdateBondStatus: status)
        appLogger.info("Bond status updated: \(String(describing: status))")
    }

    public func connectionManager(_ manager: Networking.ConnectionManager, didUpdateHotspotDevices devices: [String]) {
        delegate?.connectionManager(self, didUpdateHotspotDevices: devices)
        appLogger.info("Hotspot devices updated: \(devices)")
    }
    
    public func connectionManager(_ manager: Networking.ConnectionManager, didUpdatePath path: NWPath) {
        delegate?.connectionManager(self, didUpdatePath: path)
        appLogger.info("Network path updated: \(String(describing: path.status))")
    }
    
    public func connectionManager(_ manager: Networking.ConnectionManager, didUpdateQuality quality: Double, for path: NWPath) {
        delegate?.connectionManager(self, didUpdateQuality: quality, for: path)
        appLogger.info("Network quality updated: \(quality) for path: \(String(describing: path))")
    }
    
    public func toggleNetwork() {
        appLogger.info("Toggling network connection")
    }
    
    private func createConnection() -> NWConnection? {
        // Try to create a connection using the best available interface
        let wifiEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host("localhost"), port: NWEndpoint.Port(integerLiteral: 8080))
        return NWConnection(to: wifiEndpoint, using: .tcp)
    }
}

@available(macOS 11.0, *)
extension AppNetworkManager: Networking.NetworkBondManagerDelegate {
    public func networkBondManager(_ manager: Networking.NetworkBondManager, didUpdateBondStatus status: Networking.BondStatus) {
        delegate?.connectionManager(self, didUpdateBondStatus: status)
    }
    
    public func networkBondManager(_ manager: Networking.NetworkBondManager, didUpdateActiveConnection type: Networking.ConnectionType) {
        // Update UI or notify about active connection change
        appLogger.info("Active connection updated to: \(String(describing: type))")
    }
    
    public func networkBondManager(_ manager: Networking.NetworkBondManager, didEncounterError error: Networking.NetworkBondError) {
        delegate?.connectionManager(self, didUpdateBondStatus: .error(description: error.localizedDescription))
    }
}
