import Foundation
import Network

@available(macOS 11.0, *)
public protocol NetworkMonitorDelegate: AnyObject {
    func networkMonitor(_ monitor: NetworkMonitor, didUpdatePath path: NWPath)
    func networkMonitor(_ monitor: NetworkMonitor, didUpdateQuality quality: Double, for path: NWPath)
} 