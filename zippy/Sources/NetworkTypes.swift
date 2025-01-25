import Foundation
import Network

/// Represents the type of network connection.
public enum ConnectionType: String, CaseIterable, Hashable, Comparable {
    case ethernet = "Ethernet"
    case cellular = "Cellular"
    case wifi = "Wi-Fi"
    case hotspot = "Mobile Hotspot"
    
    public static func < (lhs: ConnectionType, rhs: ConnectionType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var interfaceType: NWInterface.InterfaceType {
        switch self {
        case .ethernet: return .wiredEthernet
        case .cellular: return .cellular
        case .wifi, .hotspot: return .wifi
        }
    }
    
    public var displayName: String {
        return rawValue
    }
} 