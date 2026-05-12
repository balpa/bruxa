import XCTest
@testable import BruxaCore

final class ArousalDetectorTests: XCTestCase {
    private let baseTime = Date(timeIntervalSince1970: 0)

    private func samples(_ bpms: [Double], spacingSeconds: TimeInterval = 1) -> [HeartRateSample] {
        bpms.enumerated().map { i, bpm in
            HeartRateSample(timestamp: baseTime.addingTimeInterval(Double(i) * spacingSeconds), bpm: bpm)
        }
    }

    func test_noSpikesProducesNoEvents() {
        let baseline: [Double] = Array(repeating: 60, count: 60)
        let events = ArousalDetector().detect(samples: samples(baseline))
        XCTAssertTrue(events.isEmpty)
    }

    func test_singleSustainedSpikeAboveThresholdProducesOneEvent() {
        // First 30 min calm at 60 bpm, then 15 s of 80 bpm (>=25% above baseline)
        var bpms: [Double] = Array(repeating: 60, count: 1800)
        bpms.append(contentsOf: Array(repeating: 80, count: 15))
        bpms.append(contentsOf: Array(repeating: 60, count: 60))
        let events = ArousalDetector().detect(samples: samples(bpms))
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].peakBPM, 80)
        XCTAssertEqual(events[0].baselineBPM, 60)
        XCTAssertEqual(events[0].duration, 14, accuracy: 0.001)
    }

    func test_shortSpikeIsIgnored() {
        var bpms: [Double] = Array(repeating: 60, count: 1800)
        bpms.append(contentsOf: Array(repeating: 80, count: 5))  // only 4 s of contiguous samples
        bpms.append(contentsOf: Array(repeating: 60, count: 60))
        let events = ArousalDetector().detect(samples: samples(bpms))
        XCTAssertTrue(events.isEmpty)
    }

    func test_belowThresholdElevationIsIgnored() {
        var bpms: [Double] = Array(repeating: 60, count: 1800)
        bpms.append(contentsOf: Array(repeating: 70, count: 30))  // only 17% above baseline
        let events = ArousalDetector().detect(samples: samples(bpms))
        XCTAssertTrue(events.isEmpty)
    }

    func test_emptyInputProducesNoEvents() {
        XCTAssertTrue(ArousalDetector().detect(samples: []).isEmpty)
    }
}
