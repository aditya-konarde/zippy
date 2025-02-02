import Foundation

public class UnitDataRate: Dimension {
    public static let bytesPerSecond = UnitDataRate(symbol: "B/s", converter: UnitConverterLinear(coefficient: 1.0))
    public static let kiloBytesPerSecond = UnitDataRate(symbol: "KB/s", converter: UnitConverterLinear(coefficient: 1024.0))
    public static let megaBytesPerSecond = UnitDataRate(symbol: "MB/s", converter: UnitConverterLinear(coefficient: 1048576.0))
    
    public override class func baseUnit() -> Self {
        return bytesPerSecond as! Self
    }
}

@available(macOS 11.0, *)
public struct BondMetrics {
    public let throughput: Measurement<UnitDataRate>
    public let latency: Measurement<UnitDuration>
    public let errorRate: Double
    public let connectionCount: Int
    public let timestamp: Date
    
    public init(throughput: Measurement<UnitDataRate>,
                latency: Measurement<UnitDuration>,
                errorRate: Double,
                connectionCount: Int) {
        self.throughput = throughput
        self.latency = latency
        self.errorRate = errorRate
        self.connectionCount = connectionCount
        self.timestamp = Date()
    }
}

@available(macOS 11.0, *)
public class TelemetryManager {
    private var metrics: [BondMetrics] = []
    private let maxHistorySize = 1000
    
    public func recordMetrics(_ metrics: BondMetrics) {
        self.metrics.append(metrics)
        if self.metrics.count > maxHistorySize {
            self.metrics.removeFirst()
        }
    }
    
    public func getAverageThroughput(timeWindow: TimeInterval = 300) -> Measurement<UnitDataRate>? {
        let cutoff = Date().addingTimeInterval(-timeWindow)
        let recentMetrics = metrics.filter { $0.timestamp > cutoff }
        
        guard !recentMetrics.isEmpty else { return nil }
        
        let totalBytesPerSecond = recentMetrics.reduce(0.0) { $0 + $1.throughput.value }
        return Measurement(value: totalBytesPerSecond / Double(recentMetrics.count),
                         unit: UnitDataRate.bytesPerSecond)
    }
    
    public func getAverageLatency(timeWindow: TimeInterval = 300) -> Measurement<UnitDuration>? {
        let cutoff = Date().addingTimeInterval(-timeWindow)
        let recentMetrics = metrics.filter { $0.timestamp > cutoff }
        
        guard !recentMetrics.isEmpty else { return nil }
        
        let totalLatency = recentMetrics.reduce(0.0) { $0 + $1.latency.value }
        return Measurement(value: totalLatency / Double(recentMetrics.count),
                         unit: UnitDuration.milliseconds)
    }
    
    public func getErrorRate(timeWindow: TimeInterval = 300) -> Double? {
        let cutoff = Date().addingTimeInterval(-timeWindow)
        let recentMetrics = metrics.filter { $0.timestamp > cutoff }
        
        guard !recentMetrics.isEmpty else { return nil }
        
        let totalErrorRate = recentMetrics.reduce(0.0) { $0 + $1.errorRate }
        return totalErrorRate / Double(recentMetrics.count)
    }
}
