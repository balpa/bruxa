import XCTest
@testable import BruxaCore

final class MotionProviderTests: XCTestCase {
    func test_scriptedProviderEmitsScheduledSamples() async {
        let s1 = SensorSample(timestamp: Date(timeIntervalSince1970: 1), accelX: 0.1, accelY: 0, accelZ: 1, gyroX: 0, gyroY: 0, gyroZ: 0)
        let s2 = SensorSample(timestamp: Date(timeIntervalSince1970: 2), accelX: 0.2, accelY: 0, accelZ: 1, gyroX: 0, gyroY: 0, gyroZ: 0)
        let provider = ScriptedMotionProvider(samples: [s1, s2])

        var received: [SensorSample] = []
        provider.start { sample in received.append(sample) }
        await provider.runUntilEmpty()
        provider.stop()

        XCTAssertEqual(received, [s1, s2])
    }

    func test_stopPreventsFurtherEmissions() async {
        let s1 = SensorSample(timestamp: Date(timeIntervalSince1970: 1), accelX: 0.1, accelY: 0, accelZ: 1, gyroX: 0, gyroY: 0, gyroZ: 0)
        let provider = ScriptedMotionProvider(samples: [s1])

        var received: [SensorSample] = []
        provider.start { sample in received.append(sample) }
        provider.stop()
        await provider.runUntilEmpty()

        XCTAssertEqual(received, [])
    }
}
