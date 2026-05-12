import SwiftUI
import BruxaCore

@main
struct BruxaWatchApp: App {
    private let storage: BruxaStorage = {
        do { return try BruxaStorage() }
        catch { fatalError("Storage init failed: \(error)") }
    }()

    private let manager: SleepSessionManager
    private let connectivity: WatchConnectivityCoordinator

    init() {
        let transport = LiveWCTransport()
        self.connectivity = WatchConnectivityCoordinator(session: transport, deviceID: "watch-default")
        let storageRef = self.storage
        let connectivityRef = self.connectivity
        let motionFactory = { SensorRecorder(motion: CoreMotionProvider(sampleRateHz: 50), windowSeconds: 30) }
        self.manager = SleepSessionManager(
            sleep: HealthKitSleepStateProvider(),
            recorderFactory: motionFactory,
            detector: BandPassJawActivityDetector(),
            storage: storageRef,
            heartRateProvider: HealthKitHeartRateSampleProvider(),
            arousalDetector: ArousalDetector()
        )
        manager.start()
        Task {
            let from = Date().addingTimeInterval(-36 * 3600)
            let to = Date()
            if let episodes = try? await storageRef.fetch(from: from, to: to) {
                try? connectivityRef.send(episodes: episodes)
            }
        }
    }

    var body: some Scene {
        WindowGroup { StatusView(storage: storage) }
    }
}
