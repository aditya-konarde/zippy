import Network
import Foundation
import os.log

@available(macOS 11.0, *)
public enum TrafficPriority: Int {
    case voice = 4      // Real-time voice traffic
    case video = 3      // Video streaming
    case interactive = 2 // Interactive data
    case background = 1  // Background transfers
    case bestEffort = 0 // Default priority
    
    var qos: DispatchQoS {
        switch self {
        case .voice: return .userInteractive
        case .video: return .userInitiated
        case .interactive: return .userInitiated
        case .background: return .background
        case .bestEffort: return .default
        }
    }
}

@available(macOS 11.0, *)
public class TrafficManager {
    private let logger = OSLog(subsystem: "com.zippy.network", category: "TrafficManager")
    private let connectionPool: ConnectionPoolManager
    private var priorityQueues: [TrafficPriority: DispatchQueue] = [:]
    
    public init(connectionPool: ConnectionPoolManager) {
        self.connectionPool = connectionPool
        setupPriorityQueues()
    }
    
    private func setupPriorityQueues() {
        for priority in [TrafficPriority.voice, .video, .interactive, .background, .bestEffort] {
            let queue = DispatchQueue(label: "com.zippy.network.priority.\(priority)",
                                    qos: priority.qos,
                                    attributes: .concurrent)
            priorityQueues[priority] = queue
        }
    }
    
    public func send(data: Data, priority: TrafficPriority = .bestEffort) {
        guard let connection = selectBestConnection(for: priority) else {
            os_log("No suitable connection available for priority %{public}d", log: logger, type: .error, priority.rawValue)
            return
        }
        
        priorityQueues[priority]?.async { [weak self] in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    os_log("Send error for priority %{public}d: %{public}@",
                          log: self?.logger ?? .default,
                          type: .error,
                          priority.rawValue,
                          error.localizedDescription)
                }
            })
        }
    }
    
    private func selectBestConnection(for priority: TrafficPriority) -> NWConnection? {
        let activeConnections = connectionPool.getActiveConnections()
        guard !activeConnections.isEmpty else { return nil }
        
        // For high-priority traffic, use the connection with the best metrics
        if priority == .voice || priority == .video {
            return activeConnections.first // In a real implementation, select based on connection quality
        }
        
        // For other traffic, use round-robin or random selection
        return activeConnections.randomElement()
    }
}
