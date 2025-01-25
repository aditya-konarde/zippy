import Foundation
import Network
import os.log

@available(macOS 11.0, *)
public final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let logger = Logger(subsystem: "com.zippy.networking", category: "NetworkMonitor")
    private var interfaceStates: [String: Bool] = [:]  // Track interface states
    
    public weak var delegate: NetworkMonitorDelegate?
    
    public var currentPath: NWPath {
        return monitor.currentPath
    }
    
    init() {
        logger.info("Setting up monitor")
        setupMonitor()
    }
    
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
    }
    
    public func startMonitoring() {
        logger.info("Starting monitoring")
        monitor.start(queue: .main)
        updateConnectionStatus()
    }
    
    public func stopMonitoring() {
        logger.info("Stopping monitoring")
        monitor.cancel()
    }
    
    public func updateConnectionStatus() {
        logger.info("Updating connection status")
        let path = monitor.currentPath
        logger.info("Current path status: \(String(describing: path.status))")
        logger.info("Available interfaces: \(path.availableInterfaces.map { $0.name })")
        
        // Reset interface states
        interfaceStates = [:]
        
        // Update interface states
        path.availableInterfaces.forEach { interface in
            interfaceStates[interface.name] = true
            
            logger.info("Interface \(interface.name) (\(String(describing: interface.type))) is \(String(describing: path.status))")
            
            if let type = getConnectionType(for: interface) {
                delegate?.networkMonitor(self, didUpdateStatus: path.status, for: type)
            }
        }
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        logger.info("Path update received")
        updateConnectionStatus()
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
    
    private func getConnectionType(for interfaceName: String) -> ConnectionType? {
        // Common naming conventions for interfaces
        if interfaceName.starts(with: "en") {
            if interfaceName == "en0" {
                return .ethernet
            } else if interfaceName == "en1" {
                return .wifi
            }
        }
        return nil
    }
    
    deinit {
        stopMonitoring()
    }
}
