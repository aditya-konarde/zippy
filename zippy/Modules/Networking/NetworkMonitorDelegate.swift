import Foundation
import Network

@available(macOS 11.0, *)
public protocol NetworkMonitorDelegate: AnyObject {
    func networkMonitor(_ monitor: NetworkMonitor, didUpdateStatus status: NWPath.Status, for type: ConnectionType)
}
