import Foundation

public protocol EpisodeDetector {
    /// Returns an Episode if the window contains a detected bruxism episode, otherwise nil.
    func detect(window: [SensorSample], windowStart: Date) -> Episode?
}

public struct StubEpisodeDetector: EpisodeDetector {
    public init() {}
    public func detect(window: [SensorSample], windowStart: Date) -> Episode? {
        return nil
    }
}
