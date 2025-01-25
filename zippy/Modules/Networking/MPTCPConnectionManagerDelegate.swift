import Foundation
import Network

@available(macOS 11.0, *)
public protocol MPTCPConnectionManagerDelegate: AnyObject {
    /// Called when the MPTCP connection status changes
    func mptcpManager(_ manager: MPTCPConnectionManager, didUpdateStatus status: NWPath.Status)
    
    /// Called when available interfaces for MPTCP change
    func mptcpManager(_ manager: MPTCPConnectionManager, didUpdateInterfaces interfaces: [NWInterface])
    
    /// Called when connection metrics are updated
    func mptcpManager(_ manager: MPTCPConnectionManager, didUpdateMetrics metrics: MPTCPConnectionMetrics)
} 