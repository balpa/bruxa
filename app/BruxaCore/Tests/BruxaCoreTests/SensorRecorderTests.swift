import XCTest
@testable import BruxaCore

final class SensorRecorderTests: XCTestCase {
    func test_emitsWindowEvery30SecondsOfSamples() async {
        let baseTime = Date(timeIntervalSince1970: 1_000)
        // 50Hz × 30s = 1500 samples per window; send 1501 to complete one window
        var samples: [SensorSample] = []
        for i in 0..<1501 {
            samples.append(makeSample(at: baseTime.addingTimeInterval(Double(i) * 0.02)))
        }
        let provider = ScriptedMotionProvider(samples: samples)
        let recorder = SensorRecorder(motion: provider, windowSeconds: 30)

        var windows: [[SensorSample]] = []
        recorder.start(onWindow: { window in windows.append(window) })
        await provider.runUntilEmpty()
        recorder.stop()

        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows.first?.count, 1500)
    }

    func test_stopFlushesPartialWindow() async {
        let baseTime = Date(timeIntervalSince1970: 1_000)
        let samples = (0..<10).map { makeSample(at: baseTime.addingTimeInterval(Double($0) * 0.02)) }
        let provider = ScriptedMotionProvider(samples: samples)
        let recorder = SensorRecorder(motion: provider, windowSeconds: 30)

        var partials: [[SensorSample]] = []
        recorder.start(onWindow: { _ in }, onStopFlush: { partials.append($0) })
        await provider.runUntilEmpty()
        recorder.stop()

        XCTAssertEqual(partials.first?.count, 10)
    }

    private func makeSample(at date: Date) -> SensorSample {
        SensorSample(timestamp: date, accelX: 0, accelY: 0, accelZ: 1, gyroX: 0, gyroY: 0, gyroZ: 0)
    }
}
