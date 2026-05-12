import XCTest
@testable import BruxaCore

final class HeartRateSampleProviderTests: XCTestCase {
    func test_scriptedProviderReturnsConfiguredSamples() async throws {
        let provider = ScriptedHeartRateSampleProvider(samples: [
            HeartRateSample(timestamp: Date(timeIntervalSince1970: 0), bpm: 58),
            HeartRateSample(timestamp: Date(timeIntervalSince1970: 30), bpm: 95)
        ])
        let result = try await provider.samples(from: .distantPast, to: .distantFuture)
        XCTAssertEqual(result.map(\.bpm), [58, 95])
    }

    func test_scriptedProviderFiltersByTimeRange() async throws {
        let provider = ScriptedHeartRateSampleProvider(samples: [
            HeartRateSample(timestamp: Date(timeIntervalSince1970: 0), bpm: 58),
            HeartRateSample(timestamp: Date(timeIntervalSince1970: 100), bpm: 95)
        ])
        let result = try await provider.samples(from: Date(timeIntervalSince1970: 50), to: Date(timeIntervalSince1970: 200))
        XCTAssertEqual(result.map(\.bpm), [95])
    }
}
