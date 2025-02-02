import Foundation
import AppKit

public protocol MenuItemProtocol {
    static var title: String { get }
    static var action: Selector { get }
    var target: AnyObject? { get set }
    
    init(title: String, action: Selector, keyEquivalent: String)
}