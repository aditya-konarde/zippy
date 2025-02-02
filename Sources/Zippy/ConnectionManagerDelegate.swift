import Foundation
import Network
import Networking

@available(macOS 11.0, *)
public protocol ConnectionManagerDelegate: AnyObject {
    func connectionManager(_ manager: ConnectionManager, didUpdateStatus status: NWPath.Status, for type: Networking.ConnectionType)
}