import Network

public class NetworkingModule {
    public static func initialize() {
        // Initialize all networking components
        let monitor = NetworkMonitor()
        let connectionManager = ConnectionManager(monitor: monitor)
        let mptcpManager = MPTCPConnectionManager(monitor: monitor)
        let bondManager = NetworkBondManager(connectionManager: connectionManager, mptcpManager: mptcpManager)
        
        // Setup logging
        Logger(subsystem: "com.zippy.networking", category: "Module").info("Networking module initialized")
        
        return (connectionManager, mptcpManager, bondManager)
    }
}