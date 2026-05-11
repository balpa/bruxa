#if DEBUG
import XCTest
@testable import BruxaCore

final class PilotCSVWriterTests: XCTestCase {
    func test_writesHeaderThenSamples() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("csv")
        let writer = try PilotCSVWriter(url: tmp)

        let sample = SensorSample(
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            accelX: 0.1, accelY: -0.2, accelZ: 0.98,
            gyroX: 0.01, gyroY: 0.02, gyroZ: -0.03
        )
        try writer.append(sample)
        try writer.append(sample)
        try writer.close()

        let content = try String(contentsOf: tmp, encoding: .utf8)
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(String(lines[0]), SensorSample.csvHeader)
        XCTAssertEqual(String(lines[1]), sample.csvRow)

        try FileManager.default.removeItem(at: tmp)
    }
}
#endif
