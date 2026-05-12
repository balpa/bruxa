import SwiftUI
import BruxaCore
#if canImport(Charts)
import Charts
#endif

struct RootView: View {
    @State private var selectedMorning: Date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(8 * 3600)
    @State private var report: MorningReport?
    @State private var lastError: String?
    private let storage: BruxaStorage
    private let builder: MorningReportBuilder

    init(storage: BruxaStorage) {
        self.storage = storage
        self.builder = MorningReportBuilder(storage: storage)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Morning of", selection: $selectedMorning, displayedComponents: .date)
                        .onChange(of: selectedMorning) { _, _ in Task { await refresh() } }
                }
                if let report {
                    Section("Last night") {
                        metricRow(title: "Restless minutes", value: "—", note: "available in v1.1")
                        metricRow(title: "Arousal events", value: "\(report.arousalEventCount)", note: "HR spikes ≥25% above baseline")
                        metricRow(title: "Jaw activity indicator", value: "\(report.jawActivityIndicatorCount)", note: "candidate windows, not a clinical diagnosis")
                    }
                    if !report.jawActivityIndicators.isEmpty {
                        Section("Timeline") { TimelineView(report: report) }
                    }
                    Section("Your self-report") {
                        if let sr = report.selfReport {
                            Text("Jaw soreness this morning: \(sr.jawSoreness.rawValue.capitalized)")
                        } else {
                            Text("No self-report recorded. Open Bruxa on your Watch to log it.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Onboarding") {
                    Button("Grant sleep + heart rate access") { Task { await requestAccess() } }
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

    private func metricRow(title: String, value: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            LabeledContent(title, value: value)
            Text(note).font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func refresh() async {
        do { report = try await builder.build(forMorningOf: selectedMorning) }
        catch { lastError = "Failed to build report: \(error.localizedDescription)" }
    }

    private func requestAccess() async {
        let coord = SleepAuthorizationCoordinator(authorizer: LiveHealthAuthorizer())
        do { try await coord.requestSleepAndHeartRateReadAccess() }
        catch { lastError = "Authorization failed: \(error.localizedDescription)" }
    }
}

private struct TimelineView: View {
    let report: MorningReport

    var body: some View {
        #if canImport(Charts)
        Chart {
            ForEach(report.jawActivityIndicators) { ep in
                BarMark(
                    xStart: .value("Start", ep.start),
                    xEnd: .value("End", ep.end),
                    y: .value("Track", "Jaw")
                )
            }
            ForEach(report.arousalEvents) { ev in
                BarMark(
                    xStart: .value("Start", ev.start),
                    xEnd: .value("End", ev.end),
                    y: .value("Track", "HR")
                )
                .foregroundStyle(.orange)
            }
        }
        .frame(height: 120)
        #else
        Text("Timeline view requires iOS 16+.")
        #endif
    }
}
