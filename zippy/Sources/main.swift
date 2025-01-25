import Cocoa
import Foundation
import AppKit
import Network
import Networking
import MenuManagement

// Ensure we're running on macOS 12.0 or later
guard #available(macOS 12.0, *) else {
    fatalError("This app requires macOS 12.0 or later")
}

// Create an application delegate to keep the app running
class AppDelegate: NSObject, NSApplicationDelegate {
    private var networkManager: AppNetworkManager!
    private var menuBarManager: MenuBarManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the network manager
        networkManager = AppNetworkManager()
        
        // Initialize the menu bar manager
        menuBarManager = MenuBarManager()
        menuBarManager.setNetworkManager(networkManager)
        
        // Start network monitoring
        networkManager.monitor.startMonitoring()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources
        networkManager.toggleNetwork()
    }
}

// Initialize the application
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Set up the delegate
let delegate = AppDelegate()
app.delegate = delegate

// Run the application
app.run()
