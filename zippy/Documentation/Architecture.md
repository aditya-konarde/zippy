# Architecture Overview

## System Components

### Core Components

#### NetworkManager
- Central coordinator for all network operations
- Manages connection state and bonding modes
- Implements delegate pattern for status updates
- Coordinates between ConnectionManager and MPTCPConnectionManager

```swift
open class NetworkManager {
    public let monitor: NetworkMonitor
    private let connectionManager: ConnectionManager
    private let mptcpManager: MPTCPConnectionManager
    private let bondManager: NetworkBondManager
    
    // Manages overall network state and coordinates between components
}
```

#### ConnectionManager
- Handles individual network interface connections
- Manages connection lifecycle (setup, teardown)
- Implements retry logic with exponential backoff
- Monitors connection health and status

```swift
public class ConnectionManager {
    private let monitor: NetworkMonitor
    private var connections: [ConnectionType: NWConnection]
    
    // Manages individual interface connections
}
```

#### MPTCPConnectionManager
- Implements MPTCP functionality
- Manages subflow creation and monitoring
- Handles fallback to single-path TCP
- Collects and reports connection metrics

```swift
public class MPTCPConnectionManager {
    private var connection: NWConnection?
    private let monitor: NetworkMonitor
    
    // Manages MPTCP connections and subflows
}
```

#### NetworkBondManager
- Implements network bonding logic
- Manages different bonding modes
- Handles interface prioritization
- Coordinates failover between interfaces

```swift
open class NetworkBondManager {
    public enum BondingMode {
        case activeBackup
        case loadBalance
        case broadcast
    }
    
    // Manages network bonding and interface coordination
}
```

### UI Components

#### MenuBarManager
- Manages menu bar interface
- Updates status icons and menu items
- Handles user interactions
- Reflects network state changes

```swift
public class MenuBarManager {
    private let statusItem: NSStatusItem
    private var connectionItems: [ConnectionType: NSMenuItem]
    
    // Manages menu bar UI and user interactions
}
```

## Data Flow

1. **Network Status Updates**
   ```
   NetworkMonitor -> NetworkManager -> MenuBarManager
   ```

2. **User Actions**
   ```
   MenuBarManager -> NetworkManager -> ConnectionManager/MPTCPManager
   ```

3. **Bonding Mode Changes**
   ```
   MenuBarManager -> NetworkManager -> NetworkBondManager -> ConnectionManager
   ```

## Key Interfaces

### NetworkMonitorDelegate
```swift
public protocol NetworkMonitorDelegate: AnyObject {
    func networkMonitor(_ monitor: NetworkMonitor, 
                       didUpdateStatus status: NWPath.Status,
                       for type: ConnectionType)
}
```

### ConnectionManagerDelegate
```swift
public protocol ConnectionManagerDelegate: AnyObject {
    func connectionManager(_ manager: ConnectionManager,
                         didUpdateStatus status: NWPath.Status,
                         for type: ConnectionType)
}
```

### MPTCPConnectionManagerDelegate
```swift
public protocol MPTCPConnectionManagerDelegate: AnyObject {
    func mptcpManager(_ manager: MPTCPConnectionManager,
                     didUpdateStatus status: NWPath.Status)
    func mptcpManager(_ manager: MPTCPConnectionManager,
                     didUpdateMetrics metrics: MPTCPConnectionMetrics)
}
```

## Design Patterns

1. **Delegate Pattern**
   - Used for component communication
   - Enables loose coupling
   - Facilitates testing

2. **Observer Pattern**
   - Network status monitoring
   - UI updates
   - State change propagation

3. **Strategy Pattern**
   - Bonding mode implementation
   - Connection management
   - Interface selection

## Error Handling

1. **Connection Failures**
   - Exponential backoff
   - Automatic retry
   - Failover to backup interfaces

2. **MPTCP Degradation**
   - Fallback to single-path TCP
   - Automatic recovery attempts
   - User notification

## Testing Strategy

1. **Unit Tests**
   - Component isolation
   - Mock network interfaces
   - State transition testing

2. **Integration Tests**
   - Component interaction
   - Network state changes
   - UI responsiveness

3. **End-to-End Tests**
   - Full system functionality
   - Real network conditions
   - User interaction flows