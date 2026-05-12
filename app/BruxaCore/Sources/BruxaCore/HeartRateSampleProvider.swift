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

#if (os(iOS) || os(watchOS)) && canImport(HealthKit)
import HealthKit

public final class HealthKitHeartRateSampleProvider: HeartRateSampleProvider, @unchecked Sendable {
    private let store = HKHealthStore()

    public init() {}

    public func samples(from: Date, to: Date) async throws -> [HeartRateSample] {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return []
        }
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let bpmUnit = HKUnit.count().unitDivided(by: .minute())
                let mapped = (samples as? [HKQuantitySample] ?? []).map {
                    HeartRateSample(timestamp: $0.startDate, bpm: $0.quantity.doubleValue(for: bpmUnit))
                }
                continuation.resume(returning: mapped)
            }
            store.execute(query)
        }
    }
}
#endif
