import Cocoa
import Network
import Networking
import os.log

class NetworkBondingController: NSViewController {
    private let bondManager = NetworkBondManager()
    private var availableInterfaces: [NWInterface] = []
    private var selectedInterfaces: [NWInterface] = []
    private let logger = Logger(subsystem: "com.zippy.networking", category: "NetworkBondingController")
    private let maxInterfaces = 4  // Maximum interfaces that can be bonded
    
    @IBOutlet weak var interfaceTableView: NSTableView!
    @IBOutlet weak var createBondButton: NSButton!
    @IBOutlet weak var statusLabel: NSTextField!
    
    deinit {
        // Clean up delegates to prevent retain cycles
        interfaceTableView.delegate = nil
        interfaceTableView.dataSource = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAvailableInterfaces()
    }
    
    private func setupUI() {
        interfaceTableView.dataSource = self
        interfaceTableView.delegate = self
        statusLabel.stringValue = ""
    }
    
    private func loadAvailableInterfaces() {
        availableInterfaces = NWInterface.interfaces().filter { interface in
            // Only allow interfaces that support bonding
            return interface.supportsFeature(.bonding)
        }
        interfaceTableView.reloadData()
        updateButtonState()
    }
    
    @IBAction func createBond(_ sender: NSButton) {
        guard !selectedInterfaces.isEmpty else {
            showError("Please select at least one interface")
            return
        }
        
        guard selectedInterfaces.count <= maxInterfaces else {
            showError("Maximum \(maxInterfaces) interfaces can be bonded")
            return
        }
        
        // Validate interface compatibility
        guard validateInterfaceCompatibility() else {
            showError("Selected interfaces are not compatible for bonding")
            return
        }
        
        do {
            let bondedInterface = try bondManager.createBondedInterface(with: selectedInterfaces)
            if let interface = bondedInterface {
                logger.info("Successfully created bonded interface: \(interface.name)")
                showSuccess("Successfully created bonded interface: \(interface.name)")
                // Reset selection after successful bonding
                selectedInterfaces.removeAll()
                updateButtonState()
            }
        } catch NetworkBondError.incompatibleInterfaces {
            showError("Selected interfaces are not compatible")
        } catch NetworkBondError.insufficientPermissions {
            showError("Insufficient permissions to create bond")
        } catch NetworkBondError.systemError(let message) {
            showError("System error: \(message)")
        } catch {
            logger.error("Unexpected error during bond creation: \(error.localizedDescription)")
            showError("Failed to create bonded interface: \(error.localizedDescription)")
        }
    }
    
    private func validateInterfaceCompatibility() -> Bool {
        // Check if all selected interfaces support the same speed
        let speeds = Set(selectedInterfaces.map { $0.maximumTransmissionUnit })
        return speeds.count == 1
    }
    
    private func showError(_ message: String) {
        statusLabel.textColor = .systemRed
        statusLabel.stringValue = message
        logger.error("\(message)")
    }
    
    private func showSuccess(_ message: String) {
        statusLabel.textColor = .systemGreen
        statusLabel.stringValue = message
        logger.info("\(message)")
    }
    
    private func updateButtonState() {
        createBondButton.isEnabled = !selectedInterfaces.isEmpty && selectedInterfaces.count <= maxInterfaces
    }
}

// MARK: - TableView DataSource
extension NetworkBondingController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return availableInterfaces.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < availableInterfaces.count else { return nil }
        return availableInterfaces[row].name
    }
}

// MARK: - TableView Delegate
extension NetworkBondingController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelect tableColumn: NSTableColumn?, row: Int) -> Bool {
        guard row < availableInterfaces.count else { return false }
        
        let interface = availableInterfaces[row]
        if selectedInterfaces.contains(interface) {
            selectedInterfaces.removeAll(where: { $0 === interface })
        } else if selectedInterfaces.count < maxInterfaces {
            selectedInterfaces.append(interface)
        } else {
            showError("Cannot select more than \(maxInterfaces) interfaces")
            return false
        }
        
        updateButtonState()
        return true
    }
}