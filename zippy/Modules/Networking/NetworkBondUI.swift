import Foundation
import AppKit
import Network

@available(macOS 11.0, *)
class NetworkBondUI: NSViewController {
    private let connectionManager: ConnectionManager
    private let bondManager: NetworkBondManager
    private var availableInterfaces: [(name: String, type: NWInterface.InterfaceType)] = []
    private let monitor = NWPathMonitor()
    private var currentPath: NWPath?
    
    @IBOutlet weak var tableView: NSTableView!
    
    override init(nibName: NSNib.Name?, bundle: Bundle?) {
        let monitor = NetworkMonitor()
        connectionManager = ConnectionManager(monitor: monitor)
        let mptcpManager = MPTCPConnectionManager(monitor: monitor)
        bondManager = NetworkBondManager(connectionManager: connectionManager, mptcpManager: mptcpManager)
        super.init(nibName: nibName, bundle: bundle)
    }
    
    required init?(coder: NSCoder) {
        let monitor = NetworkMonitor()
        connectionManager = ConnectionManager(monitor: monitor)
        let mptcpManager = MPTCPConnectionManager(monitor: monitor)
        bondManager = NetworkBondManager(connectionManager: connectionManager, mptcpManager: mptcpManager)
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMonitor()
    }
    
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentPath = path
            self?.loadInterfaceList()
        }
        monitor.start(queue: .main)
    }
    
    private func loadInterfaceList() {
        availableInterfaces = currentPath?.availableInterfaces.map { interface in
            return (name: interface.name, type: interface.type)
        } ?? []
        tableView.reloadData()
    }
    
    deinit {
        monitor.cancel()
    }
}

extension NetworkBondUI: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return availableInterfaces.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let interface = availableInterfaces[row]
        switch tableColumn?.identifier.rawValue {
        case "name":
            return interface.name
        case "type":
            switch interface.type {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .wiredEthernet: return "Ethernet"
            case .loopback: return "Loopback"
            case .other: return "Other"
            @unknown default: return "Unknown"
            }
        default:
            return nil
        }
    }
}