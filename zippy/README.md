# Zippy Network Manager

Zippy is a macOS menu bar application that provides advanced network management capabilities, including MPTCP (Multipath TCP) support and intelligent network bonding.

## Features

- **Network Interface Management**
  - Wi-Fi and Ethernet connection control
  - Real-time connection status monitoring
  - Automatic failover between interfaces
  - Visual status indicators in menu bar

- **MPTCP Support**
  - Multipath TCP connection management
  - Subflow monitoring and optimization
  - Automatic fallback to single-path TCP
  - Performance metrics tracking

- **Network Bonding**
  - Multiple bonding modes:
    - Active Backup: Automatic failover to backup interface
    - Load Balance: Distribute traffic across interfaces
    - Broadcast: Send traffic over all interfaces
  - Dynamic mode switching based on network conditions
  - Real-time bond status monitoring

## Requirements

- macOS 13.0 or later
- Network.framework support
- Administrative privileges for network interface control

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/zippy.git
cd zippy
```

2. Build the project:
```bash
swift build
```

3. Run the application:
```bash
.build/debug/zippy
```

## Usage

1. Click the network icon in the menu bar to access network controls
2. Toggle Wi-Fi and Ethernet connections as needed
3. Select a bonding mode based on your requirements:
   - Active Backup: For reliability
   - Load Balance: For maximum throughput
   - Broadcast: For specialized use cases
4. Monitor connection status and performance through the menu bar interface

## Development

### Project Structure

```
zippy/
├── Sources/
│   ├── Networking/          # Core networking functionality
│   ├── MenuManagement/      # Menu bar UI components
│   └── main.swift           # Application entry point
├── Tests/                   # Test suite
├── Documentation/           # Project documentation
└── Package.swift           # Swift package manifest
```

### Key Components

- **NetworkManager**: Coordinates network operations and state
- **ConnectionManager**: Handles individual interface connections
- **MPTCPConnectionManager**: Manages MPTCP functionality
- **NetworkBondManager**: Implements network bonding logic
- **MenuBarManager**: Manages the menu bar UI

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Apple's Network.framework documentation
- MPTCP implementation guidelines
- Community feedback and contributions