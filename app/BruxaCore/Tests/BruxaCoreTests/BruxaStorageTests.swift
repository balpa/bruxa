import XCTest
@testable import BruxaCore

final class BruxaStorageTests: XCTestCase {
    func test_saveAndFetchReturnsSameEpisode() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let episode = Episode(
            id: UUID(),
            start: Date(timeIntervalSince1970: 1_000),
            end: Date(timeIntervalSince1970: 1_030),
            intensity: 0.4,
            isCalibration: false
        )
        try await storage.save([episode])
        let fetched = try await storage.fetchAll()
        XCTAssertEqual(fetched, [episode])
    }

    func test_saveIsIdempotentOnSameID() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let id = UUID()
        let first = Episode(id: id, start: .now, end: .now.addingTimeInterval(10), intensity: 0.3, isCalibration: false)
        let second = Episode(id: id, start: first.start, end: first.end, intensity: 0.9, isCalibration: false)
        try await storage.save([first])
        try await storage.save([second])
        let fetched = try await storage.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.intensity, 0.9)
    }

    func test_fetchByDateRangeReturnsOnlyMatching() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let inside = Episode(id: UUID(), start: Date(timeIntervalSince1970: 1_500), end: Date(timeIntervalSince1970: 1_530), intensity: 0.5, isCalibration: false)
        let outside = Episode(id: UUID(), start: Date(timeIntervalSince1970: 9_000), end: Date(timeIntervalSince1970: 9_030), intensity: 0.5, isCalibration: false)
        try await storage.save([inside, outside])
        let result = try await storage.fetch(
            from: Date(timeIntervalSince1970: 1_000),
            to: Date(timeIntervalSince1970: 2_000)
        )
        XCTAssertEqual(result, [inside])
    }
}

extension BruxaStorageTests {
    func test_saveAndFetchArousalEvents() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let event = ArousalEvent(id: UUID(), start: Date(timeIntervalSince1970: 100), end: Date(timeIntervalSince1970: 120), peakBPM: 95, baselineBPM: 60)
        try await storage.save(arousalEvents: [event])
        let fetched = try await storage.fetchArousalEvents(from: Date(timeIntervalSince1970: 50), to: Date(timeIntervalSince1970: 200))
        XCTAssertEqual(fetched, [event])
    }

    func test_arousalEventSaveIsIdempotentById() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let id = UUID()
        let first = ArousalEvent(id: id, start: Date(timeIntervalSince1970: 100), end: Date(timeIntervalSince1970: 110), peakBPM: 90, baselineBPM: 60)
        let updated = ArousalEvent(id: id, start: Date(timeIntervalSince1970: 100), end: Date(timeIntervalSince1970: 115), peakBPM: 99, baselineBPM: 60)
        try await storage.save(arousalEvents: [first])
        try await storage.save(arousalEvents: [updated])
        let all = try await storage.fetchArousalEvents(from: .distantPast, to: .distantFuture)
        XCTAssertEqual(all, [updated])
    }
}
