import Foundation

// Instantiate the real production implementations
let realConnectionManager = RealConnectionManager()
let realMPTCPManager = RealMPTCPManager()
let bondManager = RealNetworkBondManager(connectionManager: realConnectionManager, mptcpManager: realMPTCPManager)

// A simple delegate to print status updates
class BondDelegate: NetworkBondManagerDelegate {
    func networkBondManager(_ manager: NetworkBondManager, didUpdateBondStatus status: BondStatus) {
        print("Bond status updated: \(status)")
    }
    
    func networkBondManager(_ manager: NetworkBondManager, didUpdateActiveConnection type: ConnectionType) {
        print("Active connection updated: \(type)")
    }
    
    func networkBondManager(_ manager: NetworkBondManager, didEncounterError error: NetworkBondError) {
        print("Encountered error: \(error)")
    }
}

let delegate = BondDelegate()
bondManager.delegate = delegate

// Start connection monitoring
realConnectionManager.startMonitoring()

// Try setting a bonding mode (using the real implementations)
do {
    try bondManager.setBondingMode(.activeBackup)
    print("Bonding mode set to activeBackup")
} catch {
    print("Failed to set bonding mode: \(error)")
}

// Allow some time for monitoring and connection updates to be processed.
RunLoop.main.run(until: Date().addingTimeInterval(5))

// Clean up monitoring
realConnectionManager.stopMonitoring() 