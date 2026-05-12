import Foundation

public struct RestlessnessBucket: Codable, Equatable, Sendable {
    public let start: Date
    public let energy: Double

    public init(start: Date, energy: Double) {
        self.start = start
        self.energy = energy
    }
}

public struct RestlessnessAggregator: Sendable {
    private static let gravity: Double = 9.81

    public init() {}

    public func aggregate(samples: [SensorSample], bucketSeconds: TimeInterval = 300) -> [RestlessnessBucket] {
        guard !samples.isEmpty, bucketSeconds > 0 else { return [] }

        var bucketed: [Date: [Double]] = [:]
        for sample in samples {
            let magnitude = sqrt(sample.accelX * sample.accelX
                                 + sample.accelY * sample.accelY
                                 + sample.accelZ * sample.accelZ)
            let delta = magnitude - Self.gravity
            let key = Date(timeIntervalSince1970: floor(sample.timestamp.timeIntervalSince1970 / bucketSeconds) * bucketSeconds)
            bucketed[key, default: []].append(delta * delta)
        }
        return bucketed
            .map { start, squares in
                let rms = sqrt(squares.reduce(0, +) / Double(squares.count))
                return RestlessnessBucket(start: start, energy: rms)
            }
            .sorted { $0.start < $1.start }
    }
}
