import Foundation

public struct ArousalDetector: Sendable {
    public let relativeThreshold: Double
    public let minDurationSeconds: TimeInterval
    public let baselineWindowSeconds: TimeInterval

    public init(relativeThreshold: Double = 0.25, minDurationSeconds: TimeInterval = 10, baselineWindowSeconds: TimeInterval = 1800) {
        self.relativeThreshold = relativeThreshold
        self.minDurationSeconds = minDurationSeconds
        self.baselineWindowSeconds = baselineWindowSeconds
    }

    public func detect(samples: [HeartRateSample]) -> [ArousalEvent] {
        guard let firstTime = samples.first?.timestamp else { return [] }
        let baselineCutoff = firstTime.addingTimeInterval(baselineWindowSeconds)
        let baselineSamples = samples.prefix { $0.timestamp <= baselineCutoff }
        guard !baselineSamples.isEmpty else { return [] }
        let baseline = median(baselineSamples.map(\.bpm))
        guard baseline > 0 else { return [] }
        let threshold = baseline * (1 + relativeThreshold)

        var events: [ArousalEvent] = []
        var runStart: Date?
        var runEnd: Date?
        var runPeak: Double = 0

        for sample in samples {
            if sample.bpm >= threshold {
                if runStart == nil {
                    runStart = sample.timestamp
                }
                runEnd = sample.timestamp
                runPeak = max(runPeak, sample.bpm)
            } else if let start = runStart, let end = runEnd {
                if end.timeIntervalSince(start) >= minDurationSeconds {
                    events.append(ArousalEvent(id: UUID(), start: start, end: end, peakBPM: runPeak, baselineBPM: baseline))
                }
                runStart = nil
                runEnd = nil
                runPeak = 0
            }
        }
        // Tail-run: if the recording ends while still elevated, only emit if it cleared the duration threshold.
        if let start = runStart, let end = runEnd {
            if end.timeIntervalSince(start) >= minDurationSeconds {
                events.append(ArousalEvent(id: UUID(), start: start, end: end, peakBPM: runPeak, baselineBPM: baseline))
            }
        }
        return events
    }

    private func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }
}
