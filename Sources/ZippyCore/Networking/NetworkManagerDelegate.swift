import Foundation
import Network

@available(macOS 11.0, *)
public protocol NetworkManagerDelegate: AnyObject {
    func networkManager(_ manager: NetworkManager, didUpdateStatus status: NWPath.Status, for type: ConnectionType)
    func networkManager(_ manager: NetworkManager, didUpdateBondStatus status: BondStatus)
    func networkManager(_ manager: NetworkManager, didUpdateHotspotDevices devices: [String])
} 