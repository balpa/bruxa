import Foundation

public final class SensorRecorder {
    private let motion: MotionProvider
    private let samplesPerWindow: Int
    private var buffer: [SensorSample] = []
    private var onWindow: (([SensorSample]) -> Void)?
    private var onStopFlush: (([SensorSample]) -> Void)?

    public init(motion: MotionProvider, sampleRateHz: Double = 50, windowSeconds: Double = 30) {
        self.motion = motion
        self.samplesPerWindow = Int(sampleRateHz * windowSeconds)
    }

    public func start(onWindow: @escaping ([SensorSample]) -> Void, onStopFlush: (([SensorSample]) -> Void)? = nil) {
        self.onWindow = onWindow
        self.onStopFlush = onStopFlush
        motion.start { [weak self] sample in
            guard let self else { return }
            self.buffer.append(sample)
            if self.buffer.count >= self.samplesPerWindow {
                let window = Array(self.buffer.prefix(self.samplesPerWindow))
                self.buffer.removeFirst(self.samplesPerWindow)
                self.onWindow?(window)
            }
        }
    }

    public func stop() {
        motion.stop()
        if !buffer.isEmpty {
            onStopFlush?(buffer)
            buffer.removeAll()
        }
        onWindow = nil
        onStopFlush = nil
    }
}
