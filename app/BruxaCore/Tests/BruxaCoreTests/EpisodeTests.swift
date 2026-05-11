import XCTest
@testable import BruxaCore

final class EpisodeTests: XCTestCase {
    func test_durationIsEndMinusStart() {
        let start = Date(timeIntervalSince1970: 1_000)
        let end = Date(timeIntervalSince1970: 1_045)
        let episode = Episode(
            id: UUID(),
            start: start,
            end: end,
            intensity: 0.7,
            isCalibration: false
        )
        XCTAssertEqual(episode.duration, 45)
    }

    func test_episodeIsCodable() throws {
        let original = Episode(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            start: Date(timeIntervalSince1970: 1_000),
            end: Date(timeIntervalSince1970: 1_030),
            intensity: 0.5,
            isCalibration: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Episode.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_intensityIsClampedToZeroOneRange() {
        let tooLow = Episode(id: UUID(), start: .now, end: .now, intensity: -0.5, isCalibration: false)
        let tooHigh = Episode(id: UUID(), start: .now, end: .now, intensity: 1.5, isCalibration: false)
        XCTAssertEqual(tooLow.intensity, 0)
        XCTAssertEqual(tooHigh.intensity, 1)
    }
}
