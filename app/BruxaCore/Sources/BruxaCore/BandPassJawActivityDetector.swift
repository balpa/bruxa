import Foundation

public struct BandPassJawActivityDetector: EpisodeDetector, Sendable {
    public let sampleRateHz: Double
    public let lowBand: ClosedRange<Double>
    public let highBand: ClosedRange<Double>
    public let lowBandThreshold: Double
    public let highBandThreshold: Double

    public init(
        sampleRateHz: Double = 50,
        lowBand: ClosedRange<Double> = 0.5...3,
        highBand: ClosedRange<Double> = 4...12,
        lowBandThreshold: Double = 0.05,
        highBandThreshold: Double = 0.1
    ) {
        self.sampleRateHz = sampleRateHz
        self.lowBand = lowBand
        self.highBand = highBand
        self.lowBandThreshold = lowBandThreshold
        self.highBandThreshold = highBandThreshold
    }

    public func detect(window: [SensorSample], windowStart: Date) -> Episode? {
        guard window.count >= Int(sampleRateHz) else { return nil }
        let magnitude = window.map { sqrt($0.gyroX * $0.gyroX + $0.gyroY * $0.gyroY + $0.gyroZ * $0.gyroZ) }
        let lowEnergy = rms(bandPass(magnitude, band: lowBand))
        let highEnergy = rms(bandPass(magnitude, band: highBand))
        guard lowEnergy >= lowBandThreshold, highEnergy >= highBandThreshold else { return nil }
        let intensity = min(1.0, (lowEnergy * highEnergy) / (lowBandThreshold * highBandThreshold * 4))
        let durationSeconds = Double(window.count) / sampleRateHz
        return Episode(
            id: UUID(),
            start: windowStart,
            end: windowStart.addingTimeInterval(durationSeconds),
            intensity: intensity,
            isCalibration: false
        )
    }

    // Single-pole biquad band-pass approximation via cascaded high-pass + low-pass first-order filters.
    private func bandPass(_ signal: [Double], band: ClosedRange<Double>) -> [Double] {
        let highPassed = highPass(signal, cutoffHz: band.lowerBound)
        return lowPass(highPassed, cutoffHz: band.upperBound)
    }

    private func lowPass(_ signal: [Double], cutoffHz: Double) -> [Double] {
        let rc = 1.0 / (2.0 * .pi * cutoffHz)
        let dt = 1.0 / sampleRateHz
        let alpha = dt / (rc + dt)
        var output: [Double] = []
        output.reserveCapacity(signal.count)
        var prev: Double = 0
        for v in signal {
            let y = prev + alpha * (v - prev)
            output.append(y)
            prev = y
        }
        return output
    }

    private func highPass(_ signal: [Double], cutoffHz: Double) -> [Double] {
        let rc = 1.0 / (2.0 * .pi * cutoffHz)
        let dt = 1.0 / sampleRateHz
        let alpha = rc / (rc + dt)
        var output: [Double] = []
        output.reserveCapacity(signal.count)
        var prevIn: Double = signal.first ?? 0
        var prevOut: Double = 0
        for v in signal {
            let y = alpha * (prevOut + v - prevIn)
            output.append(y)
            prevIn = v
            prevOut = y
        }
        return output
    }

    private func rms(_ signal: [Double]) -> Double {
        guard !signal.isEmpty else { return 0 }
        let sumSquares = signal.reduce(0) { $0 + $1 * $1 }
        return sqrt(sumSquares / Double(signal.count))
    }
}
