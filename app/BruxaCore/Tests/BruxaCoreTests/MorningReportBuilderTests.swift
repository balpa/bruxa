import XCTest
@testable import BruxaCore

final class MorningReportBuilderTests: XCTestCase {
    func test_buildAggregatesEpisodesArousalAndSelfReport() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 5, day: 12))!
        let sleepStart = date.addingTimeInterval(-6 * 3600)
        let sleepEnd = date

        try await storage.save([
            Episode(id: UUID(), start: sleepStart.addingTimeInterval(3600), end: sleepStart.addingTimeInterval(3630), intensity: 0.4, isCalibration: false),
            Episode(id: UUID(), start: sleepStart.addingTimeInterval(7200), end: sleepStart.addingTimeInterval(7230), intensity: 0.6, isCalibration: false),
        ])
        try await storage.save(arousalEvents: [
            ArousalEvent(id: UUID(), start: sleepStart.addingTimeInterval(7100), end: sleepStart.addingTimeInterval(7120), peakBPM: 92, baselineBPM: 60)
        ])
        try await storage.save(selfReports: [
            SelfReport(id: UUID(), date: date, jawSoreness: .yes)
        ])

        let report = try await MorningReportBuilder(storage: storage).build(forMorningOf: date)

        XCTAssertEqual(report.jawActivityIndicatorCount, 2)
        XCTAssertEqual(report.arousalEventCount, 1)
        XCTAssertEqual(report.selfReport?.jawSoreness, .yes)
        XCTAssertEqual(report.windowStart, sleepStart)
        XCTAssertEqual(report.windowEnd, sleepEnd)
    }

    func test_buildReturnsEmptyReportWhenNothingRecorded() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let report = try await MorningReportBuilder(storage: storage).build(forMorningOf: date)
        XCTAssertEqual(report.jawActivityIndicatorCount, 0)
        XCTAssertEqual(report.arousalEventCount, 0)
        XCTAssertNil(report.selfReport)
    }
}
