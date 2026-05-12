import SwiftUI
import BruxaCore

struct StatusView: View {
    @State private var todayCount: Int = 0
    @State private var showingPrompt: Bool = false
    @State private var lastReport: SelfReport?
    private let storage: BruxaStorage

    init(storage: BruxaStorage) { self.storage = storage }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bruxa")
                .font(.headline)
            Text("Jaw indicators tonight: \(todayCount)")
                .font(.subheadline)
            Spacer()
            Button(action: { showingPrompt = true }) {
                Text(lastReport == nil ? "Log this morning" : "Update report")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            Text("Open the iPhone app for the full report.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .task { await refresh() }
        .sheet(isPresented: $showingPrompt) {
            SelfReportPromptView(storage: storage, onDone: {
                showingPrompt = false
                Task { await refresh() }
            })
        }
    }

    private func refresh() async {
        let cal = Calendar.current
        let now = Date()
        let start = cal.startOfDay(for: now.addingTimeInterval(-12 * 3600))
        let end = now
        do {
            let eps = try await storage.fetch(from: start, to: end)
            todayCount = eps.count
            let reports = try await storage.fetchSelfReports(from: cal.startOfDay(for: now), to: now)
            lastReport = reports.last
        } catch {
            todayCount = 0
            lastReport = nil
        }
    }
}
