import Foundation

public enum JawSoreness: String, Codable, CaseIterable, Sendable, Hashable {
    case yes
    case no
    case unsure
}

public struct SelfReport: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let date: Date
    public let jawSoreness: JawSoreness

    public init(id: UUID, date: Date, jawSoreness: JawSoreness) {
        self.id = id
        self.date = date
        self.jawSoreness = jawSoreness
    }
}
