import XCTest
@testable import BruxaCore

final class WatchConnectivityCoordinatorTests: XCTestCase {
    func test_sendsEpisodesAsEncodedBatch() throws {
        let fakeSession = FakeWCSession()
        let coordinator = WatchConnectivityCoordinator(session: fakeSession, deviceID: "watch-1")

        let episodes = [
            Episode(id: UUID(), start: .now, end: .now.addingTimeInterval(15), intensity: 0.4, isCalibration: false)
        ]

        try coordinator.send(episodes: episodes)

        XCTAssertEqual(fakeSession.transferredData.count, 1)

        let decodedBatch = try EpisodesBatch.decoded(from: fakeSession.transferredData[0])
        XCTAssertEqual(decodedBatch.deviceID, "watch-1")
        XCTAssertEqual(decodedBatch.episodes.count, 1)
        XCTAssertEqual(decodedBatch.episodes[0], episodes[0])
    }

    func test_emptyBatchIsNotTransferred() throws {
        let fakeSession = FakeWCSession()
        let coordinator = WatchConnectivityCoordinator(session: fakeSession, deviceID: "watch-1")

        try coordinator.send(episodes: [])

        XCTAssertEqual(fakeSession.transferredData.count, 0)
    }
}

// MARK: - Fake Implementation

private final class FakeWCSession: WCTransport {
    var transferredData: [Data] = []

    var isReachable: Bool = true

    func transfer(_ data: Data) {
        transferredData.append(data)
    }
}
