import XCTest
@testable import BruxaCore

final class EpisodeDetectorTests: XCTestCase {
    func test_stubDetectorAlwaysReturnsNil() {
        let detector = StubEpisodeDetector()
        let window = [SensorSample](repeating: SensorSample(
            timestamp: .now, accelX: 0.1, accelY: 0.1, accelZ: 1.0,
            gyroX: 0.0, gyroY: 0.0, gyroZ: 0.0
        ), count: 1500)
        XCTAssertNil(detector.detect(window: window, windowStart: .now))
    }
}
