import Foundation
import Network

@available(macOS 11.0, *)
public enum ConnectionType: String, CaseIterable {
    case wifi = "Wi-Fi"
    case ethernet = "Ethernet"
    case hotspot = "iPhone Hotspot"
    
    public var interfaceType: NWInterface.InterfaceType {
        switch self {
        case .wifi, .hotspot:
            return .wifi
        case .ethernet:
            return .wiredEthernet
        }
    }
    
    var systemIcon: String {
        switch self {
        case .wifi:
            return "wifi"
        case .ethernet:
            return "cable.connector"
        case .hotspot:
            return "iphone.radiowaves.left.and.right"
        }
    }
    
    var systemIconDisabled: String {
        switch self {
        case .wifi:
            return "wifi.slash"
        case .ethernet:
            return "cable.connector.slash"
        case .hotspot:
            return "iphone.slash"
        }
    }
} 