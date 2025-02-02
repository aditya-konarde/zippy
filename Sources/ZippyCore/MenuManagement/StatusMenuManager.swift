import Foundation
import AppKit
import Networking

public class StatusMenuManager {
    private let statusItem: NSStatusItem
    private var errorMenuItem: NSMenuItem?
    
    public init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupMenu()
    }
    
    private func setupMenu() {
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "Network Status")
            } else {
                // Fallback for earlier macOS versions; ensure an asset named "network" exists
                button.image = NSImage(named: "network")
            }
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
}