import Foundation

public struct SensorSample: Equatable, Sendable {
    public let timestamp: Date
    public let accelX: Double
    public let accelY: Double
    public let accelZ: Double
    public let gyroX: Double
    public let gyroY: Double
    public let gyroZ: Double

    public init(
        timestamp: Date,
        accelX: Double, accelY: Double, accelZ: Double,
        gyroX: Double, gyroY: Double, gyroZ: Double
    ) {
        self.timestamp = timestamp
        self.accelX = accelX
        self.accelY = accelY
        self.accelZ = accelZ
        self.gyroX = gyroX
        self.gyroY = gyroY
        self.gyroZ = gyroZ
    }

    public static let csvHeader =
        "timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z"

    public var csvRow: String {
        let ts = String(format: "%.3f", timestamp.timeIntervalSince1970)
        let f: (Double) -> String = { String(format: "%.6f", $0) }
        return [ts, f(accelX), f(accelY), f(accelZ), f(gyroX), f(gyroY), f(gyroZ)].joined(separator: ",")
    }
}
