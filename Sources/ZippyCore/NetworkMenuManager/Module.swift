import Foundation
import AppKit
import Network
import Networking
import MenuItemProtocol
import BaseMenuItem

public class NetworkMenuManager {
    private let networkManager: NetworkManager
    private weak var statusItem: NSStatusItem?
    
    public init(networkManager: NetworkManager, statusItem: NSStatusItem) {
        self.networkManager = networkManager
        self.statusItem = statusItem
        setupMenu()
    }
    
    private func setupMenu() {
        guard let menu = statusItem?.menu else { return }
        menu.addItems(setupToggleItems())
        menu.addItem(NSMenuItem.separator())
        menu.addItems(setupStatusItems())
    }
    
    public func setupToggleItems() -> [NSMenuItem] {
        return [
            ToggleWiFiItem(),
            ToggleMobileHotspotItem(),
            ToggleEthernetItem()
        ]
    }
    
    public func setupStatusItems() -> [NSMenuItem] {
        var items = [NSMenuItem]()
        for type in ConnectionType.allCases {
            let item = NSMenuItem(title: "\(type.rawValue): Checking...", action: nil, keyEquivalent: "")
            item.tag = type.hashValue
            items.append(item)
        }
        return items
    }
    
    public func updateConnectionStatus(for type: ConnectionType, status: NWPath.Status) {
        guard let menu = statusItem?.menu else { return }
        if let menuItem = menu.items.first(where: { $0.tag == type.hashValue }) {
            menuItem.title = "\(type.rawValue): \(status)"
        }
    }
}

public class ToggleWiFiItem: BaseMenuItem {
    public override init(title: String = "Toggle Wi-Fi", action: Selector? = #selector(NetworkManager.toggleNetwork), keyEquivalent: String = "") {
        super.init(title: title, action: action, keyEquivalent: keyEquivalent)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}

public class ToggleMobileHotspotItem: BaseMenuItem {
    public override init(title: String = "Toggle Mobile Hotspot", action: Selector? = #selector(NetworkManager.toggleNetwork), keyEquivalent: String = "") {
        super.init(title: title, action: action, keyEquivalent: keyEquivalent)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}

public class ToggleEthernetItem: BaseMenuItem {
    public override init(title: String = "Toggle Ethernet", action: Selector? = #selector(NetworkManager.toggleNetwork), keyEquivalent: String = "") {
        super.init(title: title, action: action, keyEquivalent: keyEquivalent)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
} 