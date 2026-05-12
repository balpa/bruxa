import XCTest
@testable import BruxaCore

final class SelfReportTests: XCTestCase {
    func test_jawSorenessHasThreeCases() {
        XCTAssertEqual(Set(JawSoreness.allCases), [.yes, .no, .unsure])
    }

    func test_codableRoundtrip() throws {
        let report = SelfReport(id: UUID(), date: Date(timeIntervalSince1970: 1_700_000_000), jawSoreness: .yes)
        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(SelfReport.self, from: data)
        XCTAssertEqual(decoded, report)
    }

    func test_jawSorenessRawValuesAreStable() {
        // Persisted as strings in CoreData. Pin the contract so a future rename doesn't silently break old rows.
        XCTAssertEqual(JawSoreness.yes.rawValue, "yes")
        XCTAssertEqual(JawSoreness.no.rawValue, "no")
        XCTAssertEqual(JawSoreness.unsure.rawValue, "unsure")
    }
}
