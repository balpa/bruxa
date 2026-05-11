import Foundation

public final class SleepSessionManager {
    private let sleep: SleepStateProvider
    private let recorderFactory: () -> SensorRecorder
    private let detector: EpisodeDetector
    private let storage: BruxaStorage

    private var recorder: SensorRecorder?

    public init(
        sleep: SleepStateProvider,
        recorderFactory: @escaping () -> SensorRecorder,
        detector: EpisodeDetector,
        storage: BruxaStorage
    ) {
        self.sleep = sleep
        self.recorderFactory = recorderFactory
        self.detector = detector
        self.storage = storage
    }

    public func start() {
        sleep.start { [weak self] state in
            guard let self else { return }
            switch state {
            case .asleep: self.beginRecording()
            case .awake: self.endRecording()
            }
        }
    }

    public func stop() {
        sleep.stop()
        endRecording()
    }

    private func beginRecording() {
        guard recorder == nil else { return }
        let r = recorderFactory()
        r.start { [weak self] window in
            guard let self, let first = window.first else { return }
            if let episode = self.detector.detect(window: window, windowStart: first.timestamp) {
                Task { try? await self.storage.save([episode]) }
            }
        }
        recorder = r
    }

    private func endRecording() {
        recorder?.stop()
        recorder = nil
    }
}
