import XCTest
@testable import BruxaCore

final class BandPassJawActivityDetectorTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 0)

    private func window(rateHz: Double, durationSeconds: Double, gyro: (Int, Double) -> (Double, Double, Double)) -> [SensorSample] {
        let count = Int(rateHz * durationSeconds)
        return (0..<count).map { i in
            let (gx, gy, gz) = gyro(i, rateHz)
            return SensorSample(timestamp: base.addingTimeInterval(Double(i) / rateHz),
                                accelX: 0, accelY: 0, accelZ: 9.81,
                                gyroX: gx, gyroY: gy, gyroZ: gz)
        }
    }

    func test_emptyWindowReturnsNil() {
        let detector = BandPassJawActivityDetector()
        XCTAssertNil(detector.detect(window: [], windowStart: base))
    }

    func test_quietWindowReturnsNil() {
        let detector = BandPassJawActivityDetector()
        let samples = window(rateHz: 50, durationSeconds: 30) { _, _ in (0, 0, 0) }
        XCTAssertNil(detector.detect(window: samples, windowStart: base))
    }

    func test_pureLowFrequencyWindowReturnsNil() {
        // A 1 Hz oscillation on gyroX is in the low band but not the high band — should not fire alone.
        let detector = BandPassJawActivityDetector()
        let samples = window(rateHz: 50, durationSeconds: 30) { i, rate in
            let t = Double(i) / rate
            return (sin(2 * .pi * 1 * t) * 0.5, 0, 0)
        }
        XCTAssertNil(detector.detect(window: samples, windowStart: base))
    }

    func test_pureHighFrequencyWindowReturnsNil() {
        // 8 Hz alone, no RMMA envelope — typical of restless leg or REM micro-tremor.
        let detector = BandPassJawActivityDetector()
        let samples = window(rateHz: 50, durationSeconds: 30) { i, rate in
            let t = Double(i) / rate
            return (sin(2 * .pi * 8 * t) * 0.5, 0, 0)
        }
        XCTAssertNil(detector.detect(window: samples, windowStart: base))
    }

    func test_combinedRMMAEnvelopePlusGrindingMicroVibrationFires() {
        // 1 Hz envelope modulating an 8 Hz carrier — the signature the detector is tuned for.
        let detector = BandPassJawActivityDetector()
        let samples = window(rateHz: 50, durationSeconds: 30) { i, rate in
            let t = Double(i) / rate
            let envelope = max(0, sin(2 * .pi * 1 * t))
            let carrier = sin(2 * .pi * 8 * t)
            return (envelope * carrier * 1.5, 0, 0)
        }
        let episode = detector.detect(window: samples, windowStart: base)
        XCTAssertNotNil(episode)
        XCTAssertEqual(episode?.start, base)
        assertDate(episode?.end, equals: base.addingTimeInterval(30), accuracy: 0.001)
        XCTAssertGreaterThan(episode?.intensity ?? 0, 0)
        XCTAssertEqual(episode?.isCalibration, false)
    }
}

private extension XCTestCase {
    func assertDate(_ actual: Date?, equals expected: Date, accuracy: TimeInterval, file: StaticString = #file, line: UInt = #line) {
        guard let actual else {
            XCTFail("Expected \(expected) but got nil", file: file, line: line)
            return
        }
        let diff = abs(actual.timeIntervalSince1970 - expected.timeIntervalSince1970)
        XCTAssertLessThanOrEqual(diff, accuracy, "Date \(actual) not within \(accuracy)s of \(expected)", file: file, line: line)
    }
}
