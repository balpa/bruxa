import Foundation

public struct ArousalEvent: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let start: Date
    public let end: Date
    public let peakBPM: Double
    public let baselineBPM: Double

    public init(id: UUID, start: Date, end: Date, peakBPM: Double, baselineBPM: Double) {
        self.id = id
        self.start = start
        self.end = end
        self.peakBPM = peakBPM
        self.baselineBPM = baselineBPM
    }

    public var duration: TimeInterval { end.timeIntervalSince(start) }
    public var relativeIncrease: Double { (peakBPM - baselineBPM) / baselineBPM }
}
