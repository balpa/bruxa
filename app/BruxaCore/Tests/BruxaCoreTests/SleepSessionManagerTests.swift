import XCTest
@testable import BruxaCore

final class SleepSessionManagerTests: XCTestCase {
    func test_recordingStartsOnAsleepAndStopsOnAwake() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let motion = ScriptedMotionProvider(samples: makeFakeSamples(count: 1500))
        let sleep = ScriptedSleepStateProvider()
        let manager = SleepSessionManager(
            sleep: sleep,
            recorderFactory: { SensorRecorder(motion: motion, windowSeconds: 30) },
            detector: AlwaysHitDetector(),
            storage: storage
        )

        manager.start()
        sleep.emit(.asleep)
        await motion.runUntilEmpty()
        sleep.emit(.awake)
        // Allow background save to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        let episodes = try await storage.fetchAll()
        XCTAssertEqual(episodes.count, 1)
    }

    private func makeFakeSamples(count: Int) -> [SensorSample] {
        let base = Date(timeIntervalSince1970: 1_000)
        return (0..<count).map { i in
            SensorSample(
                timestamp: base.addingTimeInterval(Double(i) * 0.02),
                accelX: 0, accelY: 0, accelZ: 1, gyroX: 0, gyroY: 0, gyroZ: 0
            )
        }
    }
}

private struct AlwaysHitDetector: EpisodeDetector {
    func detect(window: [SensorSample], windowStart: Date) -> Episode? {
        Episode(
            id: UUID(),
            start: windowStart,
            end: windowStart.addingTimeInterval(30),
            intensity: 0.8,
            isCalibration: false
        )
    }
}
