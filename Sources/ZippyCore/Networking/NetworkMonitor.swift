import Network

public final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let logger = Logger(subsystem: "com.zippy.networking", category: "NetworkMonitor")
    private var interfaceStates: [String: Bool] = [:]
    
    public weak var delegate: NetworkMonitorDelegate?
    
    public var currentPath: NWPath {
        return monitor.currentPath
    }
    
    init() {
        setupMonitor()
        logger.info("NetworkMonitor initialized")
    }
    
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
    }
    
    public func startMonitoring() {
        monitor.start()
        logger.info("Network monitoring started")
    }
    
    public func stopMonitoring() {
        monitor.stop()
        logger.info("Network monitoring stopped")
    }
    
    public func updateConnectionStatus() {
        let path = monitor.currentPath
        handlePathUpdate(path)
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        logger.debug("Network path updated: \(path)")
        
        let status = path.status
        let interfaces = path.availableInterfaces
        
        // Track interface states
        for interface in interfaces {
            let interfaceName = interface.name
            let isInterfaceUp = interface.status == .satisfied
            if interfaceStates[interfaceName] != isInterfaceUp {
                interfaceStates[interfaceName] = isInterfaceUp
                logger.debug("Interface \(interfaceName) status changed to \(isInterfaceUp)")
            }
        }
        
        delegate?.networkMonitor(self, didUpdateStatus: status, for: getConnectionType(for: path))
    }
    
    private func getConnectionType(for interface: NWInterface) -> ConnectionType? {
        return ConnectionType(rawValue: interface.type.rawValue)
    }
    
    private func getConnectionType(for interfaceName: String) -> ConnectionType? {
        guard let interface = NWInterface.interface(withName: interfaceName) else { return nil }
        return getConnectionType(for: interface)
    }
    
    deinit {
        stopMonitoring()
        logger.info("NetworkMonitor deallocated")
    }
}

public protocol NetworkMonitorDelegate: AnyObject {
    func networkMonitor(_ monitor: NetworkMonitor, didUpdateStatus status: NWPath.Status, for type: ConnectionType?)
}
