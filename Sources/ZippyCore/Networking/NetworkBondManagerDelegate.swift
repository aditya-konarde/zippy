import Foundation
import Network

@available(macOS 11.0, *)
public protocol NetworkBondManagerDelegate: AnyObject {
    func networkBondManager(_ manager: NetworkBondManager, didUpdateActiveConnection type: ConnectionType)
    func networkBondManager(_ manager: NetworkBondManager, didUpdateBondStatus status: BondStatus)
} 