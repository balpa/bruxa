import XCTest
@testable import BruxaCore

final class ConnectivityPayloadTests: XCTestCase {
    func test_encodesAndDecodesEpisodesBatch() throws {
        let episodes = [
            Episode(id: UUID(), start: .now, end: .now.addingTimeInterval(15), intensity: 0.4, isCalibration: false),
            Episode(id: UUID(), start: .now, end: .now.addingTimeInterval(20), intensity: 0.8, isCalibration: true)
        ]
        let payload = EpisodesBatch(deviceID: "watch-1", episodes: episodes)
        let data = try payload.encoded()
        let decoded = try EpisodesBatch.decoded(from: data)
        XCTAssertEqual(decoded, payload)
    }

    func test_emptyBatchRoundTrips() throws {
        let payload = EpisodesBatch(deviceID: "watch-1", episodes: [])
        let data = try payload.encoded()
        let decoded = try EpisodesBatch.decoded(from: data)
        XCTAssertEqual(decoded.episodes, [])
    }
}
