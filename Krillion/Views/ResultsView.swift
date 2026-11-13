import SwiftUI

/// End-of-dive summary: final depth, every answer, and a share button.
struct ResultsView: View {
    let records: [AnswerRecord]
    let totalPoints: Int
    let shareText: String
    /// Crew scores for a multiplayer round; empty for solo dives.
    var leaderboard: [LobbyScore] = []
    var highlightPlayer: String = ""
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("You reached")
                        .foregroundStyle(Theme.foam.opacity(0.7))
                    Text("\(totalPoints * 10) m")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.foam)
                    Text("\(totalPoints) / 700 points")
                        .foregroundStyle(Theme.krill)
                }
                .padding(.top)

                Text(records.map { $0.tier?.emoji ?? "❌" }.joined())
                    .font(.largeTitle)

                if !leaderboard.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CREW LEADERBOARD")
                            .font(.caption.weight(.heavy))
                            .tracking(2)
                            .foregroundStyle(Theme.krill)
                        LeaderboardRows(scores: leaderboard, highlight: highlightPlayer)
                            .foregroundStyle(Theme.foam)
                        Text("Scores appear as each pirate finishes.")
                            .font(.caption2)
                            .foregroundStyle(Theme.foam.opacity(0.6))
                    }
                    .card()
                }

                AnswerList(records: records)

                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle(color: Theme.lagoon))

                Button("Back to Surface", action: onDone)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
    }
}

/// Reused by ResultsView and the logbook detail screen.
struct AnswerList: View {
    let records: [AnswerRecord]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(records) { record in
                HStack(alignment: .top) {
                    Text(record.tier?.emoji ?? "❌")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.prompt).font(.caption).foregroundStyle(Theme.foam.opacity(0.6))
                        Text(record.typedAnswer).font(.body.weight(.semibold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+\(record.points)").bold().foregroundStyle(record.tier?.color ?? .red)
                        Text(String(format: "%.1fs", record.secondsUsed))
                            .font(.caption2).foregroundStyle(Theme.foam.opacity(0.6))
                    }
                }
                .foregroundStyle(Theme.foam)
                .padding(.vertical, 10)
                if record.id != records.last?.id { Divider() }
            }
        }
        .card()
    }
}

#Preview {
    ZStack {
        Theme.oceanGradient.ignoresSafeArea()
        ResultsView(
            records: [
                AnswerRecord(prompt: "Name a farm animal", typedAnswer: "Llama", matchedAnswer: "Llama", tier: .shark, secondsUsed: 4.2),
                AnswerRecord(prompt: "Name a web browser", typedAnswer: "Chrome", matchedAnswer: "Chrome", tier: .plankton, secondsUsed: 2.0),
                AnswerRecord(prompt: "Name a fruit", typedAnswer: "—", matchedAnswer: nil, tier: nil, secondsUsed: 25),
            ],
            totalPoints: 70,
            shareText: "Krillion test",
            onDone: {}
        )
    }
    .preferredColorScheme(.dark)
}
