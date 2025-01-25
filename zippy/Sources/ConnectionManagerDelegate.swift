import Foundation
import Network
import Networking

public protocol ConnectionManagerDelegate: AnyObject {
    func connectionManager(_ manager: ConnectionManager, didUpdateStatus status: NWPath.Status, for type: Networking.ConnectionType)
} 