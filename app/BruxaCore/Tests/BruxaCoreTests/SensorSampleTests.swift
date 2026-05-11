import XCTest
@testable import BruxaCore

final class SensorSampleTests: XCTestCase {
    func test_csvRowEncodesAllAxes() {
        let sample = SensorSample(
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            accelX: 0.10, accelY: -0.20, accelZ: 0.98,
            gyroX: 0.01, gyroY: 0.02, gyroZ: -0.03
        )
        XCTAssertEqual(
            sample.csvRow,
            "1700000000.000,0.100000,-0.200000,0.980000,0.010000,0.020000,-0.030000"
        )
    }

    func test_csvHeaderListsExpectedColumns() {
        XCTAssertEqual(
            SensorSample.csvHeader,
            "timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z"
        )
    }
}
