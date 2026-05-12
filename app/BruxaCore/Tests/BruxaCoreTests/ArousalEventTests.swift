import XCTest
@testable import BruxaCore

final class ArousalEventTests: XCTestCase {
    func test_durationIsEndMinusStart() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 30)
        let event = ArousalEvent(id: UUID(), start: start, end: end, peakBPM: 92, baselineBPM: 60)
        XCTAssertEqual(event.duration, 30, accuracy: 0.001)
    }

    func test_relativeIncreaseIsPeakOverBaselineMinusOne() {
        let event = ArousalEvent(id: UUID(), start: .now, end: .now.addingTimeInterval(10), peakBPM: 80, baselineBPM: 50)
        XCTAssertEqual(event.relativeIncrease, 0.6, accuracy: 0.001)
    }

    func test_codableRoundtrip() throws {
        let original = ArousalEvent(id: UUID(), start: .now, end: .now.addingTimeInterval(15), peakBPM: 95, baselineBPM: 58)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ArousalEvent.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
