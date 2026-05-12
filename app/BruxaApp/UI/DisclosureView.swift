import SwiftUI

struct DisclosureView: View {
    @Binding var hasAccepted: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome to Bruxa")
                    .font(.largeTitle.bold())
                Text("Bruxa is a sleep-wellness companion, not a medical device.")
                    .font(.title3)
                Group {
                    Text("What it tracks")
                        .font(.headline)
                    Text("• How restless your night was, based on wrist motion.")
                    Text("• When your heart rate spiked above your sleeping baseline.")
                    Text("• Wrist-motion windows that pattern-match jaw clenching.")
                }
                Group {
                    Text("Honest limits")
                        .font(.headline)
                    Text("Bruxism (sleep teeth-grinding) cannot be diagnosed from a wrist sensor alone — that requires a sleep clinic with EMG. Bruxa shows you patterns and helps you start a conversation with your dentist or doctor.")
                }
                Spacer(minLength: 24)
                Button(action: { hasAccepted = true }) {
                    Text("I understand")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
}
