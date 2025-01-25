# Failure Recovery

## Common Failure Scenarios

### Network Interface Failures

#### Wi-Fi Connection Loss
1. Application automatically detects connection loss via `NetworkMonitor`
2. Triggers failover to Ethernet if in Active Backup mode
3. Updates UI to show disconnected state
4. Implements retry logic with exponential backoff
5. Logs error and notifies user via menu bar icon

#### Ethernet Connection Loss
1. System detects physical connection loss
2. Switches to Wi-Fi if available in Active Backup mode
3. Updates bond status and metrics
4. Attempts to re-establish connection periodically
5. Provides visual feedback in menu bar

### MPTCP Connection Issues

#### Connection Setup Failure
1. Log detailed error information
2. Fall back to single-path TCP
3. Retry MPTCP setup after delay
4. Update UI to show degraded service
5. Monitor for conditions to re-enable MPTCP

#### Subflow Loss
1. Detect subflow failure via metrics
2. Attempt to establish new subflow
3. Update bonding status
4. Adjust traffic distribution
5. Log event for debugging

## Recovery Procedures

### Interface Recovery
```swift
// Implement retry with exponential backoff
func handleConnectionFailure(type: ConnectionType) {
    guard retryCount < maxRetries else {
        notifyUserOfPermanentFailure()
        return
    }
    
    let delay = calculateBackoffDelay(retryCount)
    scheduleRetry(after: delay)
}
```

### MPTCP Recovery
```swift
// Handle MPTCP degradation
func handleMPTCPFailure() {
    // Fall back to single-path
    disableMPTCP()
    
    // Setup monitoring for re-enabling
    startMPTCPRecoveryMonitor()
    
    // Notify user
    updateStatusMenu()
}
```

## Prevention Strategies

### Connection Monitoring
- Regular health checks
- Proactive interface monitoring
- Quality metrics collection
- Early warning system

### Failover Configuration
- Prioritized interface list
- Automatic mode switching
- Connection quality thresholds
- Backup connection maintenance

## Debugging

### Logs to Collect
- Network interface status
- MPTCP metrics
- Connection events
- Error messages
- User actions

### Analysis Tools
- Network.framework debugging
- System logs
- Interface statistics
- Connection metrics
- Performance data