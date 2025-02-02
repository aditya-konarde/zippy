import Foundation
import AppKit
import Network
import Networking
import MenuItemProtocol
import BaseMenuItem
import NetworkMenuManager

@MainActor
public class MenuBarManager: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var errorMenuItem: NSMenuItem?
    private let networkManager: NetworkManager
    private var connectionMenuItems: [ConnectionType: NSMenuItem] = [:]
    private let statusAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.textColor,
        .font: NSFont.menuBarFont(ofSize: 14)
    ]

    public init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        super.init()
        self.networkManager.menuBarManager = self

        setupStatusItem()
        setupMenu()
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.statusAvailableName)
        }
    }

    private func setupMenu() {
        let menu = NSMenu()
        
        // Add status items for each connection type
        for connectionType in ConnectionType.allCases {
            let statusItem = NSMenuItem(title: "\(connectionType.rawValue): Checking...", action: nil, keyEquivalent: "")
            statusItem.tag = connectionType.hashValue
            connectionMenuItems[connectionType] = statusItem
            menu.addItem(statusItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Add toggle items for common network actions
        let toggleWiFiAction = #selector(toggleWiFi)
        let toggleWiFi = NSMenuItem(title: "Toggle Wi-Fi", action: toggleWiFiAction, keyEquivalent: "")
        toggleWiFi.target = self
        menu.addItem(toggleWiFi)
        
        let toggleMobileHotspotAction = #selector(toggleMobileHotspot)
        let toggleMobileHotspot = NSMenuItem(title: "Toggle Mobile Hotspot", action: toggleMobileHotspotAction, keyEquivalent: "")
        toggleMobileHotspot.target = self
        menu.addItem(toggleMobileHotspot)
        
        let toggleEthernetAction = #selector(toggleEthernet)
        let toggleEthernet = NSMenuItem(title: "Toggle Ethernet", action: toggleEthernetAction, keyEquivalent: "")
        toggleEthernet.target = self
        menu.addItem(toggleEthernet)
        
        statusItem.menu = menu
    }

    public func showConnectionType(_ type: ConnectionType, visible: Bool) {
        if let menuItem = connectionMenuItems[type] {
            menuItem.isHidden = !visible
        }
    }

    public func displayError(_ error: Error) {
        if let errorMenuItem = self.errorMenuItem {
            errorMenuItem.title = "Error: \(error.localizedDescription)"
        } else {
            let errorItem = NSMenuItem(title: "Error: \(error.localizedDescription)", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            self.statusItem.menu?.addItem(errorItem)
            self.errorMenuItem = errorItem
        }
        
        // Remove error message after a timeout
        Task {
            try? await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
            await MainActor.run {
                self.errorMenuItem?.title = ""
            }
        }
    }

    @objc private func toggleWiFi() {
        networkManager.toggleNetwork()
    }

    @objc private func toggleMobileHotspot() {
        networkManager.toggleNetwork()
    }

    @objc private func toggleEthernet() {
        networkManager.toggleNetwork()
    }

    public func updateNetworkStatus(for type: ConnectionType, status: NWPath.Status) {
        guard statusItem.menu != nil else { return }
        
        if let menuItem = connectionMenuItems[type] {
            let statusText: String
            let statusColor: NSColor
            
            switch status {
            case .satisfied:
                statusText = "Connected"
                statusColor = .systemGreen
            case .unsatisfied:
                statusText = "Disconnected"
                statusColor = .systemRed
            case .requiresConnection:
                statusText = "Connecting..."
                statusColor = .systemYellow
            @unknown default:
                statusText = "Unknown"
                statusColor = .systemGray
            }
            
            menuItem.title = "\(type.rawValue): \(statusText)"
            menuItem.attributedTitle = NSAttributedString(string: menuItem.title, attributes: [.foregroundColor: statusColor])
        }
        
        // Update the main status item icon color based on any satisfied connection
        if let button = statusItem.button {
            if status == .satisfied {
                button.contentTintColor = .systemGreen
            } else {
                button.contentTintColor = .systemRed
            }
        }
    }

    public func updateConnectionQuality(for type: ConnectionType, quality: Double) {
        if let menuItem = connectionMenuItems[type] {
            let qualityText = String(format: "%.0f%%", quality * 100)
            menuItem.title = "\(type.rawValue): \(qualityText)"
        }
    }
} 