import SwiftUI
import BruxaCore

@main
struct BruxaAppApp: App {
    private let storage: BruxaStorage = {
        do { return try BruxaStorage() }
        catch { fatalError("Storage init failed: \(error)") }
    }()

    private let receiver: LiveWCReceiver

    init() {
        let coord = PhoneConnectivityCoordinator(storage: storage)
        self.receiver = LiveWCReceiver(coordinator: coord)
    }

    var body: some Scene {
        WindowGroup { RootView(storage: storage) }
    }
}
