import Foundation
#if os(iOS) || os(watchOS) || os(visionOS)
import CoreMotion

public final class CoreMotionProvider: MotionProvider {
    private let manager = CMMotionManager()
    private let sampleRateHz: Double

    public init(sampleRateHz: Double = 50) {
        self.sampleRateHz = sampleRateHz
        manager.deviceMotionUpdateInterval = 1.0 / sampleRateHz
    }

    public func start(handler: @escaping (SensorSample) -> Void) {
        guard manager.isDeviceMotionAvailable else { return }
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let sample = SensorSample(
                timestamp: Date(),
                accelX: motion.userAcceleration.x,
                accelY: motion.userAcceleration.y,
                accelZ: motion.userAcceleration.z,
                gyroX: motion.rotationRate.x,
                gyroY: motion.rotationRate.y,
                gyroZ: motion.rotationRate.z
            )
            handler(sample)
        }
    }

    public func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
#endif
