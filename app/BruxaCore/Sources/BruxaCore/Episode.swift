import Foundation

public struct Episode: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let start: Date
    public let end: Date
    public let intensity: Double
    public let isCalibration: Bool

    public init(id: UUID, start: Date, end: Date, intensity: Double, isCalibration: Bool) {
        self.id = id
        self.start = start
        self.end = end
        self.intensity = max(0, min(1, intensity))
        self.isCalibration = isCalibration
    }

    public var duration: TimeInterval { end.timeIntervalSince(start) }
}
