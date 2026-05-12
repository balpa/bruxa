import Foundation

#if os(iOS)
import WatchConnectivity
#endif

public final class PhoneConnectivityCoordinator: Sendable {
    private let storage: BruxaStorage

    public init(storage: BruxaStorage) {
        self.storage = storage
    }

    public func handleIncoming(userInfo: [String: Any]) async throws {
        guard let data = userInfo["batch"] as? Data else {
            return
        }

        let batch = try NightDataBatch.decoded(from: data)
        try await storage.save(batch.episodes)
        try await storage.save(arousalEvents: batch.arousalEvents)
    }
}

#if os(iOS) && canImport(WatchConnectivity)
public final class LiveWCReceiver: NSObject, WCSessionDelegate {
    private let coordinator: PhoneConnectivityCoordinator

    public init(coordinator: PhoneConnectivityCoordinator) {
        self.coordinator = coordinator
        super.init()
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - WCSessionDelegate

    public func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        Task {
            try? await coordinator.handleIncoming(userInfo: userInfo)
        }
    }

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // No-op
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {
        // No-op
    }

    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
#endif
