import SwiftUI
import BruxaCore

struct SelfReportPromptView: View {
    let storage: BruxaStorage
    let onDone: () -> Void
    @State private var isSaving: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Wake with jaw soreness?")
                .font(.headline)
                .multilineTextAlignment(.center)
            Spacer()
            answerButton("Yes", value: .yes)
            answerButton("No", value: .no)
            answerButton("Unsure", value: .unsure)
        }
        .padding()
        .disabled(isSaving)
    }

    private func answerButton(_ label: String, value: JawSoreness) -> some View {
        Button(action: { save(value) }) {
            Text(label).frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private func save(_ value: JawSoreness) {
        isSaving = true
        let report = SelfReport(id: UUID(), date: Calendar.current.startOfDay(for: Date()), jawSoreness: value)
        Task {
            try? await storage.save(selfReports: [report])
            await MainActor.run { onDone() }
        }
    }
}
