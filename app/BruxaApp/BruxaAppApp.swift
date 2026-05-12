import SwiftUI
import BruxaCore

@main
struct BruxaAppApp: App {
    private let storage: BruxaStorage = {
        do { return try BruxaStorage() }
        catch { fatalError("Storage init failed: \(error)") }
    }()

    private let receiver: LiveWCReceiver
    @AppStorage("bruxa.disclosure.accepted") private var hasAcceptedDisclosure: Bool = false

    init() {
        let coord = PhoneConnectivityCoordinator(storage: storage)
        self.receiver = LiveWCReceiver(coordinator: coord)
    }

    var body: some Scene {
        WindowGroup {
            if hasAcceptedDisclosure {
                RootView(storage: storage)
            } else {
                DisclosureView(hasAccepted: Binding(
                    get: { hasAcceptedDisclosure },
                    set: { hasAcceptedDisclosure = $0 }
                ))
            }
        }
    }
}
