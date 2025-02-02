import Cocoa
import Foundation
import AppKit
import Network
import Networking
import MenuManagement
import os

// Ensure we're running on macOS 12.0 or later
guard #available(macOS 12.0, *) else {
    fatalError("This app requires macOS 12.0 or later")
}

// Create an application delegate to keep the app running
@available(macOS 11.0, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    private var networkManager: AppNetworkManager!
    private var menuBarManager: MenuBarManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the network manager
        networkManager = AppNetworkManager()
        
        // Initialize the menu bar manager
        menuBarManager = MenuBarManager()
        
        // Set up the delegate relationships
        menuBarManager.setNetworkManager(networkManager)
        networkManager.delegate = menuBarManager
        
        // Start network monitoring
        networkManager.monitor.startMonitoring()
        
        // Log startup
        let logger = Logger(subsystem: "com.example.zippy", category: "AppDelegate")
        logger.info("Application initialized and monitoring started")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources
        networkManager.toggleNetwork()
    }
}

// Initialize the application
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Set up logging
if #available(macOS 11.0, *) {
    let logger = Logger(subsystem: "com.example.zippy", category: "main")
    logger.info("Zippy application starting...")
} else {
    print("Zippy application starting...")
}

// Set up the delegate
if #available(macOS 11.0, *) {
    let delegate = AppDelegate()
    app.delegate = delegate
}

// Run the application
NSApp.activate(ignoringOtherApps: true)
app.run()
