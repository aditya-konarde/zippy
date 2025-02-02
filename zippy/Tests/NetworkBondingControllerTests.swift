import XCTest
@testable import Zippy
import Network
import Networking

class MockNWInterface: NWInterface {
    let interfaceName: String
    let mtu: Int
    let supportsFeature: Bool
    
    init(name: String, mtu: Int, supportsFeature: Bool = true) {
        self.interfaceName = name
        self.mtu = mtu
        self.supportsFeature = supportsFeature
    }
    
    override var name: String { return interfaceName }
    override var maximumTransmissionUnit: Int { return mtu }
    override func supportsFeature(_ feature: NWInterface.Feature) -> Bool {
        return supportsFeature
    }
}

class NetworkBondingControllerTests: XCTestCase {
    var controller: NetworkBondingController!
    var interfaceTableView: NSTableView!
    var createBondButton: NSButton!
    var statusLabel: NSTextField!
    
    override func setUp() {
        super.setUp()
        controller = NetworkBondingController()
        
        // Create UI elements
        interfaceTableView = NSTableView()
        createBondButton = NSButton()
        statusLabel = NSTextField()
        
        // Set up outlets
        controller.setValue(interfaceTableView, forKey: "interfaceTableView")
        controller.setValue(createBondButton, forKey: "createBondButton")
        controller.setValue(statusLabel, forKey: "statusLabel")
        
        // Load view
        controller.viewDidLoad()
    }
    
    override func tearDown() {
        controller = nil
        interfaceTableView = nil
        createBondButton = nil
        statusLabel = nil
        super.tearDown()
    }
    
    // MARK: - Interface Loading Tests
    
    func testLoadAvailableInterfaces() {
        // Create test interfaces
        let interface1 = MockNWInterface(name: "en0", mtu: 1500)
        let interface2 = MockNWInterface(name: "en1", mtu: 1500)
        let unsupportedInterface = MockNWInterface(name: "en2", mtu: 1500, supportsFeature: false)
        
        // Set up test environment
        NWInterface.setInterfaces([interface1, interface2, unsupportedInterface])
        
        // Reload interfaces
        controller.loadAvailableInterfaces()
        
        // Verify only supported interfaces are loaded
        XCTAssertEqual(controller.numberOfRows(in: interfaceTableView), 2)
        XCTAssertEqual(controller.tableView(interfaceTableView, objectValueFor: nil, row: 0) as? String, "en0")
        XCTAssertEqual(controller.tableView(interfaceTableView, objectValueFor: nil, row: 1) as? String, "en1")
    }
    
    // MARK: - Interface Selection Tests
    
    func testInterfaceSelection() {
        // Set up test interfaces
        let interface1 = MockNWInterface(name: "en0", mtu: 1500)
        let interface2 = MockNWInterface(name: "en1", mtu: 1500)
        NWInterface.setInterfaces([interface1, interface2])
        controller.loadAvailableInterfaces()
        
        // Test selection
        XCTAssertTrue(controller.tableView(interfaceTableView, shouldSelect: nil, row: 0))
        XCTAssertTrue(createBondButton.isEnabled)
        
        // Test deselection
        XCTAssertTrue(controller.tableView(interfaceTableView, shouldSelect: nil, row: 0))
        XCTAssertFalse(createBondButton.isEnabled)
    }
    
    func testMaxInterfaceSelection() {
        // Set up max+1 interfaces
        var interfaces: [MockNWInterface] = []
        for i in 0...4 {
            interfaces.append(MockNWInterface(name: "en\(i)", mtu: 1500))
        }
        NWInterface.setInterfaces(interfaces)
        controller.loadAvailableInterfaces()
        
        // Select max interfaces
        for i in 0...3 {
            XCTAssertTrue(controller.tableView(interfaceTableView, shouldSelect: nil, row: i))
        }
        
        // Try to select one more
        XCTAssertFalse(controller.tableView(interfaceTableView, shouldSelect: nil, row: 4))
        XCTAssertEqual(statusLabel.stringValue, "Cannot select more than 4 interfaces")
    }
    
    // MARK: - Interface Compatibility Tests
    
    func testInterfaceCompatibilityValidation() {
        // Set up interfaces with different MTUs
        let interface1 = MockNWInterface(name: "en0", mtu: 1500)
        let interface2 = MockNWInterface(name: "en1", mtu: 9000)
        NWInterface.setInterfaces([interface1, interface2])
        controller.loadAvailableInterfaces()
        
        // Select both interfaces
        controller.tableView(interfaceTableView, shouldSelect: nil, row: 0)
        controller.tableView(interfaceTableView, shouldSelect: nil, row: 1)
        
        // Try to create bond
        controller.createBond(createBondButton)
        
        // Verify error message
        XCTAssertEqual(statusLabel.stringValue, "Selected interfaces are not compatible for bonding")
        XCTAssertEqual(statusLabel.textColor, .systemRed)
    }
    
    // MARK: - Error Handling Tests
    
    func testInsufficientPermissionsError() {
        // Set up test interface
        let interface = MockNWInterface(name: "en0", mtu: 1500)
        NWInterface.setInterfaces([interface])
        controller.loadAvailableInterfaces()
        
        // Select interface
        controller.tableView(interfaceTableView, shouldSelect: nil, row: 0)
        
        // Simulate insufficient permissions error
        // This would typically come from the bond manager, but we can simulate it here
        controller.createBond(createBondButton)
        
        // Verify error handling
        XCTAssertEqual(statusLabel.stringValue, "Insufficient permissions to create bond")
        XCTAssertEqual(statusLabel.textColor, .systemRed)
    }
}

// MARK: - Test Helpers
extension NWInterface {
    static var mockInterfaces: [NWInterface] = []
    
    static func setInterfaces(_ interfaces: [NWInterface]) {
        mockInterfaces = interfaces
    }
    
    static func interfaces() -> [NWInterface] {
        return mockInterfaces
    }
} 