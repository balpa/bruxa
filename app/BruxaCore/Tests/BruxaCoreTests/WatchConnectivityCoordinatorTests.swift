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

        let decodedBatch = try NightDataBatch.decoded(from: fakeSession.transferredData[0])
        XCTAssertEqual(decodedBatch.deviceID, "watch-1")
        XCTAssertEqual(decodedBatch.episodes.count, 1)
        XCTAssertEqual(decodedBatch.episodes[0], episodes[0])
    }

    func test_emptyBatchIsNotTransferred() throws {
        let fakeSession = FakeWCSession()
        let coordinator = WatchConnectivityCoordinator(session: fakeSession, deviceID: "watch-1")

        try coordinator.send(episodes: [], arousalEvents: [])

        XCTAssertEqual(fakeSession.transferredData.count, 0)
    }

    func test_sendsArousalsOnlyBatch() throws {
        let fakeSession = FakeWCSession()
        let coordinator = WatchConnectivityCoordinator(session: fakeSession, deviceID: "watch-1")

        let arousal = ArousalEvent(
            id: UUID(),
            start: .now,
            end: .now.addingTimeInterval(30),
            peakBPM: 95.0,
            baselineBPM: 60.0
        )

        try coordinator.send(episodes: [], arousalEvents: [arousal])

        XCTAssertEqual(fakeSession.transferredData.count, 1)

        let decodedBatch = try NightDataBatch.decoded(from: fakeSession.transferredData[0])
        XCTAssertEqual(decodedBatch.episodes.count, 0)
        XCTAssertEqual(decodedBatch.arousalEvents.count, 1)
        XCTAssertEqual(decodedBatch.arousalEvents[0], arousal)
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
