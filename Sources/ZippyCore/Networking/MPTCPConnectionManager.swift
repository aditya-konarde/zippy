import Network

public class MPTCPConnectionManager {
    private let logger = Logger(subsystem: "com.zippy.networking", category: "MPTCPConnectionManager")
    private var connection: NWConnection?
    private let monitor: NetworkMonitor
    public weak var delegate: MPTCPConnectionManagerDelegate?
    
    init(monitor: NetworkMonitor) {
        self.monitor = monitor
        self.delegate = nil
    }
    
    public func createMPTCPConnection(serviceType: NWParameters.MultipathServiceType) {
        let parameters = NWParameters.tcp
        parameters.serviceType = serviceType
        parameters.allowMultipath = true
        
        let endpoint = NWEndpoint.hostPort(host: "localhost", port: 80)
        connection = NWConnection(to: endpoint, using: parameters)
        
        setupConnectionStateHandler()
        logger.info("MPTCP connection created with service type: \(serviceType)")
    }
    
    private func setupConnectionStateHandler() {
        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            logger.info("MPTCP connection is ready")
            delegate?.mptcpManager(self, didUpdateStatus: .satisfied)
        case .setup:
            logger.debug("MPTCP connection setting up")
        case .waiting:
            logger.debug("MPTCP connection waiting")
        case .failed(let error):
            logger.error("MPTCP connection failed: \(error)")
            delegate?.mptcpManager(self, didUpdateStatus: .unavailable)
        case .cancelled:
            logger.debug("MPTCP connection cancelled")
        @unknown default:
            logger.debug("MPTCP connection state changed to: \(state)")
        }
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        let interfaces = path.availableInterfaces
        let status = path.status
        
        logger.debug("MPTCP path updated - Status: \(status), Interfaces: \(interfaces.map { $0.name })")
        
        delegate?.mptcpManager(self, didUpdateInterfaces: interfaces)
    }
    
    public func stopConnection() {
        connection?.cancel()
        connection = nil
        logger.info("MPTCP connection stopped")
    }
    
    deinit {
        stopConnection()
        logger.info("MPTCPConnectionManager deallocated")
    }
}

public protocol MPTCPConnectionManagerDelegate: AnyObject {
    func mptcpManager(_ manager: MPTCPConnectionManager, didUpdateStatus status: NWPath.Status)
    func mptcpManager(_ manager: MPTCPConnectionManager, didUpdateInterfaces interfaces: [NWInterface])
}