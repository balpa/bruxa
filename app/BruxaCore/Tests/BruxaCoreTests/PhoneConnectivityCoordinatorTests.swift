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
        let batch = EpisodesBatch(deviceID: "watch-1", episodes: [episode])
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
}
