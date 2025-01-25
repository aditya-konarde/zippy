import Foundation
import Network

@available(macOS 11.0, *)
public struct MPTCPConnectionMetrics {
    public let status: NWPath.Status
    public let interfaces: [NWInterface]
    public let isExpensive: Bool
    public let isConstrained: Bool
    public let subflowCount: Int
    public let preferredPathAvailable: Bool
    
    public init(
        status: NWPath.Status,
        interfaces: [NWInterface],
        isExpensive: Bool,
        isConstrained: Bool,
        subflowCount: Int = 0,
        preferredPathAvailable: Bool = false
    ) {
        self.status = status
        self.interfaces = interfaces
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.subflowCount = subflowCount
        self.preferredPathAvailable = preferredPathAvailable
    }
} 