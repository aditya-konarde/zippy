import Foundation
import Network
import os.log
import Networking

@available(macOS 11.0, *)
public class AppNetworkManager: Networking.NetworkManager {
    private let appLogger = Logger(subsystem: "com.example.zippy", category: "AppNetworkManager")
    
    public override func toggleConnection(for type: Networking.ConnectionType) {
        super.toggleConnection(for: type)
        appLogger.info("Toggled network connection: \(type.rawValue)")
    }
    
    public override func setBondingMode(_ mode: Networking.NetworkBondManager.BondingMode) {
        super.setBondingMode(mode)
        appLogger.info("Bonding mode changed to \(String(describing: mode))")
    }
}
