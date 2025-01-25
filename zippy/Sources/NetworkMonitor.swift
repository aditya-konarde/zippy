import Foundation
import Network
import os.log

@available(macOS 11.0, *)
public final class NetworkMonitor {
    private let logger = Logger(subsystem: "com.example.zippy", category: "NetworkMonitor")
    private let monitor = NWPathMonitor()
    private let qualityMonitorInterval: TimeInterval
    private var qualityMonitorTimer: Timer?
    
    public weak var delegate: NetworkMonitorDelegate?
    
    public init(qualityMonitorInterval: TimeInterval = 5) {
        self.qualityMonitorInterval = qualityMonitorInterval
    }
    
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.delegate?.networkMonitor(self, didUpdatePath: path)
                
                // Calculate connection quality based on path properties
                let quality = self.calculateConnectionQuality(path)
                self.delegate?.networkMonitor(self, didUpdateQuality: quality, for: path)
            }
        }
        
        monitor.start(queue: .main)
        startQualityMonitoring()
    }
    
    public func stopMonitoring() {
        monitor.cancel()
        qualityMonitorTimer?.invalidate()
    }
    
    private func startQualityMonitoring() {
        qualityMonitorTimer?.invalidate()
        qualityMonitorTimer = Timer.scheduledTimer(withTimeInterval: qualityMonitorInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                if let path = self?.monitor.currentPath {
                    self?.monitorConnectionQuality(path)
                }
            }
        }
    }
    
    @MainActor
    private func monitorConnectionQuality(_ path: NWPath) {
        let quality = calculateConnectionQuality(path)
        delegate?.networkMonitor(self, didUpdateQuality: quality, for: path)
    }
    
    private func calculateConnectionQuality(_ path: NWPath) -> Double {
        var quality = 1.0
        
        // Reduce quality for expensive paths
        if path.isExpensive {
            quality *= 0.8
        }
        
        // Reduce quality for constrained paths
        if path.isConstrained {
            quality *= 0.7
        }
        
        return quality
    }
    
    @MainActor
    private func handlePathUpdate(_ path: NWPath) {
        logPathInfo(path)
        delegate?.networkMonitor(self, didUpdatePath: path)
    }
    
    private func logPathInfo(_ path: NWPath) {
        let pathInfo = """
        Network path update:
        Status: \(path.status)
        Is Expensive: \(path.isExpensive)
        Is Constrained: \(path.isConstrained)
        Uses WiFi: \(path.usesInterfaceType(.wifi))
        Uses Cellular: \(path.usesInterfaceType(.cellular))
        Uses Ethernet: \(path.usesInterfaceType(.wiredEthernet))
        """
        logger.debug("\(pathInfo)")
        
        let interfaces = path.availableInterfaces.map { interface -> String in
            let type = interface.type
            let name = interface.name
            let isExpensive = path.isExpensive ? " (expensive)" : ""
            let isConstrained = path.isConstrained ? " (constrained)" : ""
            
            switch type {
            case .wifi: return "WiFi (\(name))\(isExpensive)\(isConstrained)"
            case .wiredEthernet: return "Ethernet (\(name))\(isExpensive)\(isConstrained)"
            case .cellular: return "Cellular (\(name))\(isExpensive)\(isConstrained)"
            case .loopback: return "Loopback (\(name))"
            case .other: return "Other (\(name))\(isExpensive)\(isConstrained)"
            @unknown default: return "Unknown (\(name))\(isExpensive)\(isConstrained)"
            }
        }.joined(separator: ", ")
        logger.debug("Available interfaces: \(interfaces)")
    }
    
    private func getConnectionType(for interface: NWInterface) -> ConnectionType? {
        switch interface.type {
        case .wifi:
            return .wifi
        case .wiredEthernet:
            return .ethernet
        default:
            return nil
        }
    }
    
    deinit {
        stopMonitoring()
    }
} 