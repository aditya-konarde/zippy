// This file defines stubs for ConnectionManager and associated types used by MenuManagement

import Foundation
import Network

public enum ConnectionType: String, CaseIterable {
    case wifi = "wifi"
    case ethernet = "ethernet"
    case hotspot = "hotspot"
}

public protocol ConnectionManagerDelegate: AnyObject {
    func connectionManager(_ manager: ConnectionManager, didUpdateStatus status: NWPath.Status, for type: ConnectionType)
    func connectionManager(_ manager: ConnectionManager, didUpdateBondStatus status: BondStatus)
    func connectionManager(_ manager: ConnectionManager, didUpdateHotspotDevices devices: [String])
    func connectionManager(_ manager: ConnectionManager, didUpdatePath path: NWPath)
    func connectionManager(_ manager: ConnectionManager, didUpdateQuality quality: Double, for path: NWPath)
}

public protocol ConnectionManager {
    var delegate: ConnectionManagerDelegate? { get set }
    func toggleConnection(for type: ConnectionType)
    func getConnection(for type: ConnectionType) -> Any?
    func connectToHotspot(deviceName: String)
    func setBondingMode(_ mode: BondingMode)
}

public extension ConnectionType {
    var interfaceType: NWInterface.InterfaceType {
        switch self {
        case .wifi, .hotspot:
            return .wifi
        case .ethernet:
            return .wiredEthernet
        }
    }
}