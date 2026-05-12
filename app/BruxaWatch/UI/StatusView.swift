import SwiftUI
import BruxaCore

struct StatusView: View {
    @State private var todayCount: Int = 0
    @State private var isRecording: Bool = false
    private let storage: BruxaStorage

    init(storage: BruxaStorage) { self.storage = storage }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isRecording ? "Recording" : "Idle")
                .font(.headline)
                .foregroundStyle(isRecording ? .green : .secondary)
            Text("Episodes tonight: \(todayCount)")
                .font(.subheadline)
            Spacer()
            Text("Open the iPhone app for reports.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .task { await refresh() }
    }

    private func refresh() async {
        let cal = Calendar.current
        let now = Date()
        let start = cal.startOfDay(for: now.addingTimeInterval(-12 * 3600))
        let end = now
        do {
            let eps = try await storage.fetch(from: start, to: end)
            todayCount = eps.count
        } catch {
            todayCount = 0
        }
    }
}
