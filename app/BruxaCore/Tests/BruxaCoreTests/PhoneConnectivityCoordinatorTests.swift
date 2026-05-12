import XCTest
@testable import BruxaCore

final class PhoneConnectivityCoordinatorTests: XCTestCase {
    func test_receivedBatchIsPersistedToStorage() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let coordinator = PhoneConnectivityCoordinator(storage: storage)

        let episode = Episode(
            id: UUID(),
            start: .now,
            end: .now.addingTimeInterval(15),
            intensity: 0.4,
            isCalibration: false
        )
        let batch = NightDataBatch(deviceID: "watch-1", episodes: [episode])
        let encodedBatch = try batch.encoded()

        try await coordinator.handleIncoming(userInfo: ["batch": encodedBatch])

        let fetchedEpisodes = try await storage.fetchAll()
        XCTAssertEqual(fetchedEpisodes.count, 1)
        XCTAssertEqual(fetchedEpisodes[0], episode)
    }

    func test_malformedPayloadIsIgnored() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let coordinator = PhoneConnectivityCoordinator(storage: storage)

        // Should not throw with malformed payload
        try await coordinator.handleIncoming(userInfo: ["wrong": Data()])

        let fetchedEpisodes = try await storage.fetchAll()
        XCTAssertEqual(fetchedEpisodes.count, 0)
    }

    func test_receivedBatchPersistsBothEpisodesAndArousalEvents() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let coordinator = PhoneConnectivityCoordinator(storage: storage)

        let episode = Episode(
            id: UUID(),
            start: .now,
            end: .now.addingTimeInterval(15),
            intensity: 0.4,
            isCalibration: false
        )
        let arousal = ArousalEvent(
            id: UUID(),
            start: .now,
            end: .now.addingTimeInterval(30),
            peakBPM: 95.0,
            baselineBPM: 60.0
        )
        let batch = NightDataBatch(deviceID: "watch-1", episodes: [episode], arousalEvents: [arousal])
        let encodedBatch = try batch.encoded()

        try await coordinator.handleIncoming(userInfo: ["batch": encodedBatch])

        let fetchedEpisodes = try await storage.fetchAll()
        XCTAssertEqual(fetchedEpisodes.count, 1)
        XCTAssertEqual(fetchedEpisodes[0], episode)

        let now = Date()
        let fetchedArousals = try await storage.fetchArousalEvents(
            from: now.addingTimeInterval(-3600),
            to: now.addingTimeInterval(3600)
        )
        XCTAssertEqual(fetchedArousals.count, 1)
        XCTAssertEqual(fetchedArousals[0].id, arousal.id)
        XCTAssertEqual(fetchedArousals[0].peakBPM, arousal.peakBPM)
    }
}
