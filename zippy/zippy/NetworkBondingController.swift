import Cocoa
import Network
import Networking

class NetworkBondingController: NSViewController {
    private let bondManager = NetworkBondManager()
    private var availableInterfaces: [NWInterface] = []
    private var selectedInterfaces: [NWInterface] = []
    
    @IBOutlet weak var interfaceTableView: NSTableView!
    @IBOutlet weak var createBondButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        availableInterfaces = NWInterface.interfaces()
        interfaceTableView.dataSource = self
        interfaceTableView.delegate = self
        updateButtonState()
    }
    
    @IBAction func createBond(_ sender: NSButton) {
        do {
            let bondedInterface = try bondManager.createBondedInterface(with: selectedInterfaces)
            if let interface = bondedInterface {
                print("Successfully created bonded interface: \(interface.name)")
                // Update UI to reflect successful bonding
            }
        } catch {
            print("Failed to create bonded interface: \(error.localizedDescription)")
            // Update UI to show error message
        }
    }
    
    private func updateButtonState() {
        createBondButton.isEnabled = !selectedInterfaces.isEmpty
    }
}

extension NetworkBondingController: NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, numberOfRowsInSection section: Int) -> Int {
        return availableInterfaces.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor row: Int, column: Int) -> Any? {
        return availableInterfaces[row].name
    }
}

extension NetworkBondingController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let interface = availableInterfaces[row]
        if selectedInterfaces.contains(interface) {
            selectedInterfaces.removeAll(where: { $0 === interface })
        } else {
            selectedInterfaces.append(interface)
        }
        updateButtonState()
        return true
    }
}