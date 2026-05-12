import Foundation

public struct MorningReport: Equatable, Sendable {
    public let windowStart: Date
    public let windowEnd: Date
    public let jawActivityIndicators: [Episode]
    public let arousalEvents: [ArousalEvent]
    public let selfReport: SelfReport?

    public var jawActivityIndicatorCount: Int { jawActivityIndicators.count }
    public var arousalEventCount: Int { arousalEvents.count }

    public init(windowStart: Date, windowEnd: Date, jawActivityIndicators: [Episode], arousalEvents: [ArousalEvent], selfReport: SelfReport?) {
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.jawActivityIndicators = jawActivityIndicators
        self.arousalEvents = arousalEvents
        self.selfReport = selfReport
    }
}

public struct MorningReportBuilder: @unchecked Sendable {
    private let storage: BruxaStorage
    private let nightWindowHours: TimeInterval

    public init(storage: BruxaStorage, nightWindowHours: TimeInterval = 12) {
        self.storage = storage
        self.nightWindowHours = nightWindowHours
    }

    public func build(forMorningOf date: Date) async throws -> MorningReport {
        let windowEnd = date
        let windowStart = date.addingTimeInterval(-nightWindowHours * 3600)
        async let episodesTask = storage.fetch(from: windowStart, to: windowEnd)
        async let arousalsTask = storage.fetchArousalEvents(from: windowStart, to: windowEnd)
        async let reportsTask = storage.fetchSelfReports(from: windowStart, to: windowEnd.addingTimeInterval(3600 * 6))
        let episodes = try await episodesTask
        let arousals = try await arousalsTask
        let selfReport = try await reportsTask.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        return MorningReport(
            windowStart: windowStart,
            windowEnd: windowEnd,
            jawActivityIndicators: episodes,
            arousalEvents: arousals,
            selfReport: selfReport
        )
    }
}
