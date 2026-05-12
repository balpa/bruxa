import Foundation

public struct HeartRateSample: Codable, Equatable, Sendable {
    public let timestamp: Date
    public let bpm: Double

    public init(timestamp: Date, bpm: Double) {
        self.timestamp = timestamp
        self.bpm = bpm
    }
}

public protocol HeartRateSampleProvider: Sendable {
    func samples(from: Date, to: Date) async throws -> [HeartRateSample]
}

public final class ScriptedHeartRateSampleProvider: HeartRateSampleProvider, @unchecked Sendable {
    private let stored: [HeartRateSample]

    public init(samples: [HeartRateSample]) {
        self.stored = samples
    }

    public func samples(from: Date, to: Date) async throws -> [HeartRateSample] {
        stored.filter { $0.timestamp >= from && $0.timestamp < to }
    }
}
