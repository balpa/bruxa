import SwiftUI
import BruxaCore

struct RootView: View {
    @State private var episodeCount: Int = 0
    @State private var lastError: String?
    private let storage: BruxaStorage

    init(storage: BruxaStorage) { self.storage = storage }

    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    LabeledContent("Recorded episodes", value: "\(episodeCount)")
                }
                Section("Onboarding") {
                    Button("Grant sleep access") { Task { await requestAccess() } }
                    Text("Open the Bruxa app on your Apple Watch and wear it overnight.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let lastError {
                    Section { Text(lastError).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Bruxa")
            .task { await refresh() }
            .refreshable { await refresh() }
        }
    }

    private func refresh() async {
        do { episodeCount = try await storage.fetchAll().count }
        catch { lastError = "Failed to fetch: \(error.localizedDescription)" }
    }

    private func requestAccess() async {
        let coord = SleepAuthorizationCoordinator(authorizer: LiveHealthAuthorizer())
        do { try await coord.requestSleepReadAccess() }
        catch { lastError = "Authorization failed: \(error.localizedDescription)" }
    }
}
