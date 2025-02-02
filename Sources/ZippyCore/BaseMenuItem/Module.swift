import Foundation
import AppKit
import MenuItemProtocol

public class BaseMenuItem: NSMenuItem {
    public override init(title string: String, action selector: Selector?, keyEquivalent charCode: String) {
        super.init(title: string, action: selector, keyEquivalent: charCode)
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
    }
} 