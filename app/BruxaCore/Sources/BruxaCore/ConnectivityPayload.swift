import Foundation

public struct EpisodesBatch: Codable, Equatable, Sendable {
    public let deviceID: String
    public let episodes: [Episode]

    public init(deviceID: String, episodes: [Episode]) {
        self.deviceID = deviceID
        self.episodes = episodes
    }

    public func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public static func decoded(from data: Data) throws -> EpisodesBatch {
        try JSONDecoder().decode(EpisodesBatch.self, from: data)
    }
}
