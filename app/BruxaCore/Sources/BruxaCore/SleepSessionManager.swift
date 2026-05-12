import Foundation

public final class SleepSessionManager {
    private let sleep: SleepStateProvider
    private let recorderFactory: () -> SensorRecorder
    private let detector: EpisodeDetector
    private let storage: BruxaStorage
    private let heartRateProvider: HeartRateSampleProvider?
    private let arousalDetector: ArousalDetector?

    private var recorder: SensorRecorder?
    private var lastSleepStart: Date?

    public init(
        sleep: SleepStateProvider,
        recorderFactory: @escaping () -> SensorRecorder,
        detector: EpisodeDetector,
        storage: BruxaStorage,
        heartRateProvider: HeartRateSampleProvider? = nil,
        arousalDetector: ArousalDetector? = nil
    ) {
        self.sleep = sleep
        self.recorderFactory = recorderFactory
        self.detector = detector
        self.storage = storage
        self.heartRateProvider = heartRateProvider
        self.arousalDetector = arousalDetector
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
        lastSleepStart = Date()
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
        if let start = lastSleepStart, let hr = heartRateProvider, let arousal = arousalDetector {
            let end = Date()
            lastSleepStart = nil
            Task { [storage] in
                guard let samples = try? await hr.samples(from: start, to: end), !samples.isEmpty else { return }
                let events = arousal.detect(samples: samples)
                if !events.isEmpty {
                    try? await storage.save(arousalEvents: events)
                }
            }
        } else {
            lastSleepStart = nil
        }
    }
}
