import Foundation
import AppKit
import Network
import Networking

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
        
        // Add toggle items
        for type in ConnectionType.allCases {
            let item = NSMenuItem(title: type.rawValue,
                                action: #selector(toggleConnection(_:)),
                                keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Add network toggle
        let toggleItem = NSMenuItem(title: "Toggle Network",
                                  action: #selector(toggleNetwork(_:)),
                                  keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
    }
    
    @objc private func toggleConnection(_ sender: NSMenuItem) {
        if let type = ConnectionType.allCases.first(where: { $0.rawValue == sender.title }) {
            networkManager.toggleConnection(for: type)
        }
    }
    
    @objc private func toggleNetwork(_ sender: NSMenuItem) {
        networkManager.toggleNetwork()
    }
}