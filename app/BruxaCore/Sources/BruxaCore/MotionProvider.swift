import Foundation

public protocol MotionProvider {
    func start(handler: @escaping (SensorSample) -> Void)
    func stop()
}

public final class ScriptedMotionProvider: MotionProvider {
    private let samples: [SensorSample]
    private var handler: ((SensorSample) -> Void)?
    private var index = 0

    public init(samples: [SensorSample]) {
        self.samples = samples
    }

    public func start(handler: @escaping (SensorSample) -> Void) {
        self.handler = handler
    }

    public func stop() {
        self.handler = nil
    }

    public func runUntilEmpty() async {
        while index < samples.count {
            handler?(samples[index])
            index += 1
            await Task.yield()
        }
    }
}
