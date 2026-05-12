import Foundation

#if os(iOS) || os(watchOS)
import WatchConnectivity
#endif

public protocol WCTransport: Sendable {
    var isReachable: Bool { get }
    func transfer(_ data: Data)
}

public final class WatchConnectivityCoordinator: Sendable {
    private let session: WCTransport
    private let deviceID: String

    public init(session: WCTransport, deviceID: String) {
        self.session = session
        self.deviceID = deviceID
    }

    public func send(episodes: [Episode]) throws {
        guard !episodes.isEmpty else { return }

        let batch = EpisodesBatch(deviceID: deviceID, episodes: episodes)
        let data = try batch.encoded()
        session.transfer(data)
    }
}

#if os(iOS) || os(watchOS)
public final class LiveWCTransport: NSObject, WCTransport, WCSessionDelegate {
    private let wcSession = WCSession.default

    public var isReachable: Bool {
        wcSession.isReachable
    }

    public override init() {
        super.init()
        wcSession.delegate = self
        wcSession.activate()
    }

    public func transfer(_ data: Data) {
        wcSession.transferUserInfo(["batch": data])
    }

    // MARK: - WCSessionDelegate

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // No-op
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        // No-op
    }

    public func sessionDidDeactivate(_ session: WCSession) {
        wcSession.activate()
    }
    #endif
}
#endif
