import Foundation
import AppKit
import Network
import Networking

// Exports all public types and interfaces for the MenuManagement module
@available(macOS 11.0, *)
public typealias MenuItemProtocolType = MenuItemProtocol
@available(macOS 11.0, *)
public typealias BaseMenuItemType = BaseMenuItem
@available(macOS 11.0, *)
public typealias StatusMenuManagerType = StatusMenuManager
@available(macOS 11.0, *)
public typealias NetworkMenuManagerType = NetworkMenuManager
@available(macOS 11.0, *)
public typealias MenuBarManagerType = MenuBarManager

public class MenuManagementModule {
    public static func initialize() {
        // Initialize any module-level setup here
    }
}
