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

extension SleepSessionManagerTests {
    func test_arousalDetectionRunsOnSleepEndAndPersists() async throws {
        let scriptedSleep = ScriptedSleepStateProvider()
        let storage = try BruxaStorage(inMemory: true)
        let onset = Date()
        // 17 samples spanning ~0.8 s: first 5 at 60 bpm (baseline), next 12 at 80 bpm (elevated).
        let hrSamples = (0..<17).map { i in
            HeartRateSample(timestamp: onset.addingTimeInterval(Double(i) * 0.05), bpm: i < 5 ? 60 : 80)
        }
        let hrProvider = ScriptedHeartRateSampleProvider(samples: hrSamples)
        let detector = ArousalDetector(relativeThreshold: 0.25, minDurationSeconds: 0.3, baselineWindowSeconds: 0.3)
        let manager = SleepSessionManager(
            sleep: scriptedSleep,
            recorderFactory: { SensorRecorder(motion: ScriptedMotionProvider(samples: []), sampleRateHz: 50, windowSeconds: 30) },
            detector: StubEpisodeDetector(),
            storage: storage,
            heartRateProvider: hrProvider,
            arousalDetector: detector
        )
        manager.start()
        scriptedSleep.emit(.asleep)
        // Real elapsed time so the HR window [lastSleepStart, Date()] actually contains the synthetic samples.
        try await Task.sleep(nanoseconds: 1_200_000_000)
        scriptedSleep.emit(.awake)
        // Allow the awake handler's async work to drain.
        try await Task.sleep(nanoseconds: 300_000_000)
        let arousals = try await storage.fetchArousalEvents(from: .distantPast, to: .distantFuture)
        XCTAssertEqual(arousals.count, 1)
    }
}
