import XCTest
@testable import Zippy
import Network
import Networking

class MockConnectionManager: ConnectionManager {
    var connections: [ConnectionType: Bool] = [:]
    var delegate: ConnectionManagerDelegate?
    
    func getConnection(for type: ConnectionType) -> NWConnection? {
        return connections[type] != nil ? NWConnection(host: "test", port: 80, using: .tcp) : nil
    }
    
    func toggleConnection(for type: ConnectionType, enabled: Bool) {
        connections[type] = enabled
    }
    
    func isEnabled(_ type: ConnectionType) -> Bool {
        return connections[type] ?? false
    }
    
    func simulateConnectionStatus(_ status: NWPath.Status, for type: ConnectionType) {
        delegate?.connectionManager(self, didUpdateStatus: status, for: type)
    }
}

class MockMPTCPManager: MPTCPConnectionManager {
    var lastServiceType: NWParameters.MultipathServiceType?
    var shouldThrowError = false
    
    func createMPTCPConnection(serviceType: NWParameters.MultipathServiceType) throws {
        if shouldThrowError {
            throw NetworkBondError.systemError("MPTCP creation failed")
        }
        lastServiceType = serviceType
    }
}

class NetworkBondingTests: XCTestCase {
    var bondManager: NetworkBondManager!
    var mockConnectionManager: MockConnectionManager!
    var mockMPTCPManager: MockMPTCPManager!
    var delegateCalled = false
    var lastBondStatus: BondStatus?
    var lastActiveConnection: ConnectionType?
    var lastError: NetworkBondError?
    
    override func setUp() {
        super.setUp()
        mockConnectionManager = MockConnectionManager()
        mockMPTCPManager = MockMPTCPManager()
        bondManager = NetworkBondManager(connectionManager: mockConnectionManager, mptcpManager: mockMPTCPManager)
        bondManager.delegate = self
        delegateCalled = false
        lastBondStatus = nil
        lastActiveConnection = nil
        lastError = nil
    }
    
    override func tearDown() {
        bondManager = nil
        mockConnectionManager = nil
        mockMPTCPManager = nil
        super.tearDown()
    }
    
    // MARK: - Mode Change Tests
    
    func testSetBondingModeActiveBackup() throws {
        try bondManager.setBondingMode(.activeBackup)
        XCTAssertEqual(bondManager.getCurrentMode(), .activeBackup)
        XCTAssertEqual(mockMPTCPManager.lastServiceType, .handover)
    }
    
    func testSetBondingModeLoadBalanceWithInsufficientConnections() {
        XCTAssertThrowsError(try bondManager.setBondingMode(.loadBalance)) { error in
            XCTAssertEqual(error as? NetworkBondError, .invalidConfiguration)
        }
    }
    
    // MARK: - Connection Management Tests
    
    func testActiveBackupPriorityOrder() {
        // Simulate active ethernet and wifi
        mockConnectionManager.simulateConnectionStatus(.satisfied, for: .ethernet)
        mockConnectionManager.simulateConnectionStatus(.satisfied, for: .wifi)
        
        // Verify ethernet is chosen as primary
        XCTAssertEqual(lastActiveConnection, .ethernet)
        XCTAssertFalse(mockConnectionManager.isEnabled(.wifi))
    }
    
    func testLoadBalanceRequiresTwoConnections() {
        // Try to enable load balance with one connection
        mockConnectionManager.simulateConnectionStatus(.satisfied, for: .wifi)
        
        XCTAssertThrowsError(try bondManager.setBondingMode(.loadBalance))
        XCTAssertEqual(bondManager.getCurrentMode(), .activeBackup)
    }
    
    // MARK: - Error Handling Tests
    
    func testMPTCPConfigurationError() {
        mockMPTCPManager.shouldThrowError = true
        
        try? bondManager.setBondingMode(.activeBackup)
        
        XCTAssertNotNil(lastError)
        if case .systemError = lastError {
            // Error was properly propagated
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected system error")
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentConnectionUpdates() {
        let expectation = XCTestExpectation(description: "Concurrent updates complete")
        
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            mockConnectionManager.simulateConnectionStatus(.satisfied, for: .wifi)
            mockConnectionManager.simulateConnectionStatus(.unsatisfied, for: .wifi)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
        // If we reach here without crashes, thread safety is working
    }
    
    // MARK: - Metrics Monitoring Tests
    
    func testMetricsUpdatesOnConnectionChange() {
        let expectation = XCTestExpectation(description: "Metrics updated")
        
        mockConnectionManager.simulateConnectionStatus(.satisfied, for: .ethernet)
        mockConnectionManager.simulateConnectionStatus(.satisfied, for: .wifi)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.lastBondStatus, .active)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
}

// MARK: - NetworkBondManagerDelegate
extension NetworkBondingTests: NetworkBondManagerDelegate {
    func networkBondManager(_ manager: NetworkBondManager, didUpdateBondStatus status: BondStatus) {
        delegateCalled = true
        lastBondStatus = status
    }
    
    func networkBondManager(_ manager: NetworkBondManager, didUpdateActiveConnection type: ConnectionType) {
        delegateCalled = true
        lastActiveConnection = type
    }
    
    func networkBondManager(_ manager: NetworkBondManager, didEncounterError error: NetworkBondError) {
        delegateCalled = true
        lastError = error
    }
} 