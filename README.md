# Zippy: Channel Bonding for macOS and iOS

## Table of Contents
- [Disclaimer](#disclaimer)
- [What is Zippy?](#what-is-zippy)
- [How Zippy Works](#how-zippy-works)
- [Features](#features)
- [Design and Implementation](#design-and-implementation)
- [Security Considerations](#security-considerations)
- [Future Enhancements](#future-enhancements)
- [Building and Running](#building-and-running)

## Disclaimer
I was bored and my internet wasn't quite working well. I thought it would be fun to build a channel bonding solution for macOS and iOS, inspired by paid solutions like Speedify. 

This is entirely AI generated, and I'm not sure how well it works. I'm not sure if it's a good idea or not. I'm just doing it for fun. Use it at your own risk.

## What is Zippy?
Zippy is a channel bonding solution for macOS and iOS, designed to enhance internet speed and/or reliability by combining multiple network interfaces, such as Ethernet and an iPhone's 5G connection via USB tethering.

## How Zippy Works
Zippy utilizes channel bonding to aggregate bandwidth from multiple connections. Data packets are split and transmitted concurrently across all available connections, effectively creating a "One Big Pipe" where the combined bandwidth is accessible for every data flow. This method provides a significant advantage over traditional load balancing, which limits each traffic flow to the speed of a single connection.

Zippy also implements automatic failover. If the primary connection (e.g., Ethernet) drops, Zippy seamlessly switches to the secondary connection (e.g., 5G), ensuring uninterrupted online access.

### Key Components
1. **NetworkManager:** Manages network connections, implements channel bonding, and handles failover.
2. **MenuBarManager:** Manages the macOS menu bar item, displaying network status and errors.
3. **Zippy Protocol:** A proprietary protocol optimized for efficient data transmission and minimal latency.

## Features
### Core Features
- **Connection Aggregation:** Combines Ethernet and tethered 5G connections.
- **Channel Bonding:** Splits data packets and transmits them across multiple connections for increased throughput.
- **Automatic Failover:** Seamlessly switches to a secondary connection if the primary connection fails.
- **Load Balancing:** Distributes network traffic across available connections.

### Advanced Features
- **Packet Prioritization:** Prioritizes time-sensitive traffic (e.g., video calls, online games).
- **Optional Encryption:** Encrypts internet traffic for enhanced security and privacy.
- **DNS Leak Protection:** Prevents DNS leaks to protect user privacy.
- **Kill Switch:** Blocks internet access if the VPN connection drops (when encryption is enabled).
- **Real-time Statistics:** Displays connection speed, latency, and data usage.
- **Customizable Settings:** Allows users to adjust bonding settings and connection preferences.

## Security Considerations
Zippy offers optional encryption to protect user data and privacy. When encryption is enabled, a kill switch is activated to block internet access if the VPN connection drops. DNS leak protection is also implemented to prevent DNS leaks.

## Future Enhancements
- **Pair and Share:** Allow users to share their mobile connections with others.
- **Adaptive Bonding:** Dynamically adjust the bonding algorithm based on connection quality.
- **Error Correction:** Implement forward error correction techniques to improve reliability.
- **Improved Statistics Dashboard:** Add visual graphs and historical data tracking.
- **Enhanced Configuration Options:** Include advanced settings for network optimization.

## Building and Running
To build and run Zippy using Swift Package Manager:

1. Clone the repository.
2. Open a terminal and navigate to the repository's root directory.
3. Execute the following commands:

```bash
swift build
swift run Zippy
```
