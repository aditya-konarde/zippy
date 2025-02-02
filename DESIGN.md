# Zippy Design Document

This document outlines the design and architecture of the Zippy channel bonding application for macOS and iOS.

## Overview

Zippy aims to provide a seamless and efficient way to combine multiple network interfaces (e.g., Ethernet and cellular) to improve internet speed and reliability. The application is designed with modularity, performance, and security in mind.

## Architecture

Zippy consists of three main components:

1. **NetworkManager:** This class is responsible for managing network connections, implementing channel bonding, handling failover, and monitoring connection quality. It uses the Network framework to establish and manage connections.

2. **MenuBarManager:** This class manages the macOS menu bar item, displaying network status and errors. It interacts with the NetworkManager to update the status and handle user interactions.

3. **Zippy Protocol:** Zippy uses a custom protocol optimized for efficient data transmission and minimal latency. This protocol utilizes multiple TCP sockets per connection to minimize the impact of packet loss and improve performance.

## Detailed Design

### NetworkManager

* **Connection Management:** The NetworkManager maintains a dictionary of active connections, keyed by connection type (Ethernet, Cellular). Each entry stores the NWPath and NWConnection objects.

* **Channel Bonding:** Data is split into packets and sent across all available connections using a round-robin approach. Sequence numbers are prepended to each packet to ensure correct reassembly.

* **Failover:** The NetworkManager monitors the status of each connection. If the active connection fails, it automatically switches to the next available connection.

* **Connection Quality Monitoring:** The NetworkManager periodically checks the round-trip time (RTT) of each connection to assess connection quality. This information can be used for adaptive channel bonding in the future.

* **Error Handling:** Robust error handling is implemented throughout the NetworkManager to gracefully handle connection failures, packet loss, and other network issues.

### MenuBarManager

* **Status Updates:** The MenuBarManager receives status updates from the NetworkManager and updates the menu bar item accordingly. Color coding is used to indicate connection status (green for connected, red for disconnected, yellow for connecting).

* **Error Display:** Errors are displayed in the menu bar for a short duration to inform the user of any issues.

* **User Interaction:** The MenuBarManager handles user interactions, such as toggling the network on/off.

### Zippy Protocol

* **Packet Format:** The Zippy protocol uses a simple packet format consisting of a sequence number followed by the data payload.

* **Multiple TCP Sockets:** Multiple TCP sockets are used per connection to improve throughput and resilience to packet loss.

## Security Considerations

* **Optional Encryption:** Zippy offers optional encryption to protect user data and privacy.

* **DNS Leak Protection:** Measures are taken to prevent DNS leaks when encryption is enabled.

* **Kill Switch:** A kill switch is implemented to block internet traffic if the VPN connection drops (when encryption is enabled).

## Future Enhancements

* **Adaptive Bonding:** Dynamically adjust the channel bonding algorithm based on connection quality.

* **Error Correction:** Implement forward error correction techniques to improve reliability.

* **Pair and Share:** Allow users to share their mobile connections with others.