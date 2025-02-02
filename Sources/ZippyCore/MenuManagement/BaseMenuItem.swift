import Foundation
import AppKit

public class BaseMenuItem: NSMenuItem {
    override init(title string: String, action selector: Selector?, keyEquivalent charCode: String) {
        super.init(title: string, action: selector, keyEquivalent: charCode)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}