import Foundation
import AppKit
import MenuItemProtocol
import BaseMenuItem

public class StatusMenuManager {
    private let statusItem: NSStatusItem
    
    public init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        statusItem.menu = menu
    }
    
    public func addMenuItem(_ item: NSMenuItem) {
        statusItem.menu?.addItem(item)
    }
    
    public func addSeparator() {
        statusItem.menu?.addItem(NSMenuItem.separator())
    }
    
    public func removeAllItems() {
        statusItem.menu?.removeAllItems()
    }
    
    public func updateMenuItem(withTitle title: String, newTitle: String) {
        if let item = statusItem.menu?.item(withTitle: title) {
            item.title = newTitle
        }
    }
    
    public func updateMenuItem(withTag tag: Int, newTitle: String) {
        if let item = statusItem.menu?.items.first(where: { $0.tag == tag }) {
            item.title = newTitle
        }
    }
} 