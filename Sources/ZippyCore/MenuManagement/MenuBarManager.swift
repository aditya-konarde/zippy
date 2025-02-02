import Cocoa
import AppKit
import Network
import os.log
import Networking

@available(macOS 11.0, *)
public class MenuBarManager: NSObject {
    private let statusItem: NSStatusItem
    private let menu: NSMenu
    private var networkManager: Networking.ConnectionManager?
    private var connectionItems: [Networking.ConnectionType: NSMenuItem] = [:]
    private var bondStatusItem: NSMenuItem?
    private var bondingModeItems: [Networking.BondingMode: NSMenuItem] = [:]
    private var hotspotDevices: [NSMenuItem] = []
    private let logger = Logger(subsystem: "com.zippy.menumanagement", category: "MenuBarManager")

    public override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        super.init()
        setupMenu()
    }

    private func setupMenu() {
        statusItem.menu = menu
        statusItem.button?.image = NSImage(systemSymbolName: "network", accessibilityDescription: "Network Status")

        // Add Wi-Fi item with icon
        let wifiItem = createConnectionMenuItem(
            type: Networking.ConnectionType.wifi,
            icon: "wifi",
            title: "Wi-Fi"
        )
        connectionItems[.wifi] = wifiItem
        menu.addItem(wifiItem)

        // Add Ethernet item with icon
        let ethernetItem = createConnectionMenuItem(
            type: Networking.ConnectionType.ethernet,
            icon: "cable.connector",
            title: "Ethernet"
        )
        connectionItems[.ethernet] = ethernetItem
        menu.addItem(ethernetItem)

        // Add separator before hotspot section
        menu.addItem(NSMenuItem.separator())

        // Add iPhone Hotspot section
        let hotspotSection = NSMenuItem(title: "iPhone Hotspots", action: nil, keyEquivalent: "")
        hotspotSection.image = NSImage(systemSymbolName: "iphone", accessibilityDescription: "iPhone Hotspots")
        let hotspotMenu = NSMenu()
        
        // Add "Looking for iPhones..." item initially
        let searchingItem = NSMenuItem(title: "Looking for iPhones...", action: nil, keyEquivalent: "")
        searchingItem.isEnabled = false
        hotspotMenu.addItem(searchingItem)
        
        hotspotSection.submenu = hotspotMenu
        menu.addItem(hotspotSection)

        menu.addItem(NSMenuItem.separator())

        // Add bond status item with detailed information
        bondStatusItem = NSMenuItem(title: "No Active Bonds", action: nil, keyEquivalent: "")
        bondStatusItem?.image = NSImage(systemSymbolName: "link.badge.plus", accessibilityDescription: "Bond Status")
        menu.addItem(bondStatusItem!)

        // Add bonding mode submenu with descriptive options
        let bondingModeItem = NSMenuItem(title: "Bonding Mode", action: nil, keyEquivalent: "")
        bondingModeItem.image = NSImage(systemSymbolName: "link.circle", accessibilityDescription: "Bonding Mode")
        bondingModeItem.toolTip = "Configure how multiple network connections work together"
        let bondingModeMenu = NSMenu()
        
        let modes: [(Networking.BondingMode, String, String)] = [
            (.activeBackup, "Active Backup", "power"),
            (.loadBalance, "Load Balance", "speedometer"),
            (.broadcast, "Broadcast", "arrow.triangle.branch")
        ]
        
        modes.forEach { mode, title, icon in
            let item = NSMenuItem(title: title, action: #selector(selectBondingMode(_:)), keyEquivalent: "")
            item.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
            item.target = self
            item.toolTip = getBondingModeTooltip(for: mode)
            bondingModeItems[mode] = item
            bondingModeMenu.addItem(item)
        }
        
        bondingModeItem.submenu = bondingModeMenu
        menu.addItem(bondingModeItem)

        // Add quit item
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Quit")
        menu.addItem(quitItem)

        // Start scanning for hotspots
        startHotspotDiscovery()
    }

    private func createConnectionMenuItem(type: Networking.ConnectionType, icon: String, title: String) -> NSMenuItem {
        print("Creating menu item for \(type.rawValue)")
        let item = NSMenuItem(title: title, action: #selector(toggleConnection(_:)), keyEquivalent: "")
        item.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
        item.target = self
        item.toolTip = getConnectionTooltip(for: type)
        item.representedObject = type
        print("Menu item created - title: \(title), has target: \(item.target != nil), has action: \(item.action != nil)")
        return item
    }

    private func getConnectionTooltip(for type: Networking.ConnectionType) -> String {
        switch type {
        case .wifi:
            return "Turn Wi-Fi On or Off"
        case .ethernet:
            return "Enable or disable Ethernet connection"
        case .hotspot:
            return "Connect to iPhone Personal Hotspot"
        }
    }

    private func getBondingModeTooltip(for mode: Networking.BondingMode) -> String {
        switch mode {
        case .activeBackup:
            return "Use a single network connection at a time, with automatic failover"
        case .loadBalance:
            return "Distribute traffic evenly across all connections"
        case .broadcast:
            return "Send all traffic through all available connections"
        case .adaptive:
            return "Adaptive configuration"
        }
    }

    @objc private func toggleConnection(_ sender: NSMenuItem) {
        print("Toggle connection called for menu item: \(sender.title)")
        if let type = sender.representedObject as? Networking.ConnectionType {
            print("Connection type: \(type.rawValue)")
            networkManager?.toggleConnection(for: type)
        } else {
            print("No connection type found in representedObject")
        }
    }

    @objc private func connectToHotspot(_ sender: NSMenuItem) {
        print("Connect to hotspot called for menu item: \(sender.title)")
        if let deviceName = sender.representedObject as? String {
            print("Device name: \(deviceName)")
            networkManager?.connectToHotspot(deviceName: deviceName)
        } else {
            print("No device name found in representedObject")
        }
    }

    private func startHotspotDiscovery() {
        // In a real implementation, we would use NEHotspotHelper
        // For now, simulate iPhone discovery
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateHotspotDevices([
                "Aditya's iPhone",
                "iPhone (2)"
            ])
        }
    }

    private func updateHotspotDevices(_ devices: [String]) {
        guard let hotspotMenu = menu.item(withTitle: "iPhone Hotspots")?.submenu else { return }
        
        // Clear existing items
        hotspotMenu.removeAllItems()
        hotspotDevices.removeAll()
        
        if devices.isEmpty {
            let noDevicesItem = NSMenuItem(title: "No iPhones Found", action: nil, keyEquivalent: "")
            noDevicesItem.isEnabled = false
            hotspotMenu.addItem(noDevicesItem)
        } else {
            devices.forEach { device in
                let item = NSMenuItem(title: device, action: #selector(connectToHotspot(_:)), keyEquivalent: "")
                item.image = NSImage(systemSymbolName: "iphone.radiowaves.left.and.right", accessibilityDescription: "iPhone Hotspot")
                item.target = self
                item.representedObject = device
                hotspotDevices.append(item)
                hotspotMenu.addItem(item)
            }
        }
    }

    @objc private func selectBondingMode(_ sender: NSMenuItem) {
        print("Select bonding mode called for menu item: \(sender.title)")
        if let mode = bondingModeItems.first(where: { $0.value == sender })?.key {
            print("Bonding mode: \(String(describing: mode))")
            networkManager?.setBondingMode(mode)
            updateBondingModeSelection(mode)
        } else {
            print("No bonding mode found for menu item")
        }
    }

    private func updateBondingModeSelection(_ selectedMode: Networking.BondingMode) {
        bondingModeItems.forEach { mode, item in
            item.state = mode == selectedMode ? NSControl.StateValue.on : NSControl.StateValue.off
        }
    }

    public func setNetworkManager(_ manager: Networking.ConnectionManager) {
        print("Setting network manager in MenuBarManager")
        networkManager = manager
    }

    // Update menu bar icon based on bond status
    private func updateBondStatus(_ status: Networking.BondStatus) {
        print("MenuBarManager: Updating bond status to \(status)")
        
        if let button = statusItem.button {
            switch status {
            case .active:
                button.image = NSImage(systemSymbolName: "network.badge.shield.half.filled", accessibilityDescription: "Active Bond")
                button.toolTip = "Network Bond Active"
                
            case .inactive:
                button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "Network Status")
                button.toolTip = "Network Bond Inactive"
                
            case .error(let message):
                button.image = NSImage(systemSymbolName: "network.badge.shield.half.filled.slash", accessibilityDescription: "Bond Error")
                button.toolTip = "Network Bond Error: \(message)"
            }
        }
    }
}

@available(macOS 11.0, *)
extension MenuBarManager: Networking.ConnectionManagerDelegate {
    public func connectionManager(_ manager: Networking.ConnectionManager, didUpdateStatus status: NWPath.Status, for type: Networking.ConnectionType) {
        logger.info("Status update for \(type.rawValue, privacy: .public): \(String(describing: status), privacy: .public)")
        
        // Update menu item state
        if let menuItem = connectionItems[type] {
            switch status {
            case .satisfied:
                menuItem.state = NSControl.StateValue.on
                menuItem.image = NSImage(systemSymbolName: type == .wifi ? "wifi" : "cable.connector", accessibilityDescription: nil)
            case .unsatisfied:
                menuItem.state = NSControl.StateValue.off
                menuItem.image = NSImage(systemSymbolName: type == .wifi ? "wifi.slash" : "cable.connector.slash", accessibilityDescription: nil)
            case .requiresConnection:
                menuItem.state = NSControl.StateValue.mixed
                menuItem.image = NSImage(systemSymbolName: type == .wifi ? "wifi.exclamationmark" : "cable.connector.slash", accessibilityDescription: nil)
            @unknown default:
                menuItem.state = NSControl.StateValue.off
                menuItem.image = NSImage(systemSymbolName: type == .wifi ? "wifi.slash" : "cable.connector.slash", accessibilityDescription: nil)
            }
            logger.info("Updated menu item for \(type.rawValue) - state: \(menuItem.state.rawValue)")
        }
        
        // Update status item image based on overall connection status
        updateStatusItemImage()
    }
    
    public func connectionManager(_ manager: Networking.ConnectionManager, didUpdateBondStatus status: Networking.BondStatus) {
        logger.info("Bond status update: \(String(describing: status), privacy: .public)")
        
        // Update bond status menu item
        if let bondStatusItem = bondStatusItem {
            switch status {
            case .active:
                bondStatusItem.title = "Network Bonding: Active"
                bondStatusItem.image = NSImage(systemSymbolName: "link.circle.fill", accessibilityDescription: nil)
            case .inactive:
                bondStatusItem.title = "Network Bonding: Not Active"
                bondStatusItem.image = NSImage(systemSymbolName: "link.circle", accessibilityDescription: nil)
            case .error(let message):
                bondStatusItem.title = "Network Bonding: Error"
                bondStatusItem.image = NSImage(systemSymbolName: "exclamationmark.circle", accessibilityDescription: nil)
                bondStatusItem.toolTip = message
            }
            logger.info("Updated bond status item - title: \(bondStatusItem.title)")
        }
        
        // Update status item image
        updateStatusItemImage()
    }
    
    private func updateStatusItemImage() {
        // Check if any connections are active
        let hasActiveConnection = connectionItems.values.contains { $0.state == NSControl.StateValue.on }
        let bondingActive = bondStatusItem?.title.contains("Active") ?? false
        
        if bondingActive {
            statusItem.button?.image = NSImage(systemSymbolName: "network.badge.shield.half.filled", accessibilityDescription: "Network Status - Bonded")
        } else if hasActiveConnection {
            statusItem.button?.image = NSImage(systemSymbolName: "network", accessibilityDescription: "Network Status - Connected")
        } else {
            statusItem.button?.image = NSImage(systemSymbolName: "network.slash", accessibilityDescription: "Network Status - Disconnected")
        }
        
        logger.info("Updated status item image - bonding: \(String(describing: bondingActive), privacy: .public), active connection: \(String(describing: hasActiveConnection), privacy: .public)")
    }

    public func connectionManager(_ manager: Networking.ConnectionManager, didUpdateHotspotDevices devices: [String]) {
        Task { @MainActor in
            updateHotspotDevices(devices)
        }
    }

    // Add missing ConnectionManagerDelegate methods
    public func connectionManager(_ manager: Networking.ConnectionManager, didUpdatePath path: NWPath) {}
    public func connectionManager(_ manager: Networking.ConnectionManager, didUpdateQuality quality: Double, for path: NWPath) {}
}
