import Foundation

public struct NightDataBatch: Codable, Equatable, Sendable {
    public let deviceID: String
    public let episodes: [Episode]
    public let arousalEvents: [ArousalEvent]

    public init(deviceID: String, episodes: [Episode], arousalEvents: [ArousalEvent] = []) {
        self.deviceID = deviceID
        self.episodes = episodes
        self.arousalEvents = arousalEvents
    }

    public func encoded() throws -> Data { try JSONEncoder().encode(self) }

    public static func decoded(from data: Data) throws -> NightDataBatch {
        try JSONDecoder().decode(NightDataBatch.self, from: data)
    }
}
