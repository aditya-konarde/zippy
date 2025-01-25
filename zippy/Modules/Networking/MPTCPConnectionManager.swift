import Foundation
import Network
import os.log

@available(macOS 11.0, *)
public class MPTCPConnectionManager {
    private let logger = Logger(subsystem: "com.zippy.networking", category: "MPTCPConnectionManager")
    private var connection: NWConnection?
    private let monitor: NetworkMonitor
    
    public weak var delegate: MPTCPConnectionManagerDelegate?
    
    public init(monitor: NetworkMonitor) {
        self.monitor = monitor
        logger.info("MPTCPConnectionManager initialized")
    }
    
    public func createMPTCPConnection(serviceType: NWParameters.MultipathServiceType) {
        logger.info("Creating MPTCP connection")
        
        // Create parameters for the connection
        let parameters = NWParameters.tcp
        
        if #available(macOS 13.0, *) {
            logger.info("Enabling MPTCP support")
            // Use the appropriate API for enabling MPTCP
            parameters.multipathServiceType = serviceType
            
            logger.info("MPTCP parameters configured with service type: \(String(describing: serviceType))")
        } else {
            logger.warning("MPTCP not available on this macOS version")
        }
        
        // Create endpoint (using localhost for testing)
        let endpoint = NWEndpoint.hostPort(host: "localhost", port: 80)
        
        // Create the connection
        connection = NWConnection(to: endpoint, using: parameters)
        
        // Set up state handler
        setupConnectionStateHandler()
        
        // Start the connection
        connection?.start(queue: .main)
    }
    
    private func setupConnectionStateHandler() {
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            self.handleConnectionState(state)
        }
        
        connection?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.handlePathUpdate(path)
        }
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        logger.info("Connection state changed: \(String(describing: state))")
        
        switch state {
        case .ready:
            delegate?.mptcpManager(self, didUpdateStatus: .satisfied)
        case .failed, .cancelled:
            delegate?.mptcpManager(self, didUpdateStatus: .unsatisfied)
        case .preparing:
            delegate?.mptcpManager(self, didUpdateStatus: .requiresConnection)
        default:
            break
        }
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        logger.info("Path update received")
        
        // Update interfaces
        let interfaces = path.availableInterfaces
        delegate?.mptcpManager(self, didUpdateInterfaces: interfaces)
        
        // Update metrics
        if #available(macOS 13.0, *) {
            let status = path.status
            let interfaces = path.availableInterfaces
            let isExpensive = path.isExpensive
            let isConstrained = path.isConstrained
            
            let logMessage = """
                MPTCP Metrics:
                - Status: \(status)
                - Interfaces: \(interfaces.map { $0.name })
                - Expensive: \(isExpensive)
                - Constrained: \(isConstrained)
                """
            logger.info("\(logMessage)")
            
            // Create metrics object
            let metrics = MPTCPConnectionMetrics(
                status: status,
                interfaces: interfaces,
                isExpensive: isExpensive,
                isConstrained: isConstrained,
                subflowCount: interfaces.count,
                preferredPathAvailable: status == .satisfied
            )
            
            delegate?.mptcpManager(self, didUpdateMetrics: metrics)
        }
    }
    
    public func stopConnection() {
        logger.info("Stopping MPTCP connection")
        connection?.cancel()
        connection = nil
    }
    
    deinit {
        stopConnection()
    }
} 