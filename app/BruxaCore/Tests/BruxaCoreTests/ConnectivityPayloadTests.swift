import XCTest
@testable import BruxaCore

final class ConnectivityPayloadTests: XCTestCase {
    func test_encodesAndDecodesNightDataBatch() throws {
        let episodes = [
            Episode(id: UUID(), start: .now, end: .now.addingTimeInterval(15), intensity: 0.4, isCalibration: false),
            Episode(id: UUID(), start: .now, end: .now.addingTimeInterval(20), intensity: 0.8, isCalibration: true)
        ]
        let payload = NightDataBatch(deviceID: "watch-1", episodes: episodes)
        let data = try payload.encoded()
        let decoded = try NightDataBatch.decoded(from: data)
        XCTAssertEqual(decoded, payload)
    }

    func test_emptyBatchRoundTrips() throws {
        let payload = NightDataBatch(deviceID: "watch-1", episodes: [])
        let data = try payload.encoded()
        let decoded = try NightDataBatch.decoded(from: data)
        XCTAssertEqual(decoded.episodes, [])
    }

    func test_roundTripsEpisodesAndArousalEvents() throws {
        let episode = Episode(
            id: UUID(),
            start: .now,
            end: .now.addingTimeInterval(15),
            intensity: 0.5,
            isCalibration: false
        )
        let arousal = ArousalEvent(
            id: UUID(),
            start: .now,
            end: .now.addingTimeInterval(30),
            peakBPM: 95.0,
            baselineBPM: 60.0
        )
        let payload = NightDataBatch(deviceID: "watch-1", episodes: [episode], arousalEvents: [arousal])
        let data = try payload.encoded()
        let decoded = try NightDataBatch.decoded(from: data)
        XCTAssertEqual(decoded, payload)
        XCTAssertEqual(decoded.episodes.count, 1)
        XCTAssertEqual(decoded.arousalEvents.count, 1)
        XCTAssertEqual(decoded.arousalEvents[0], arousal)
    }
}
