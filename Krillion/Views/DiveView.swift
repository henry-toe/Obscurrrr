import SwiftUI
import SwiftData

/// Screen 2: the game itself. Shown full-screen over the tab bar.
struct DiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var vm: DiveViewModel
    @State private var saved = false
    @FocusState private var fieldFocused: Bool

    /// Present only for multiplayer rounds; used to share the score with the crew.
    private let lobby: LobbyService?

    init(practice: Bool, secondsPerQuestion: Int) {
        let questions = practice ? QuestionBank.practice() : QuestionBank.daily()
        lobby = nil
        _vm = State(initialValue: DiveViewModel(
            questions: questions,
            isPractice: practice,
            secondsPerQuestion: secondsPerQuestion
        ))
    }

    /// Multiplayer round: the seed comes from the host so everyone gets the same
    /// questions. Saved as a practice dive so it doesn't lock the Daily Dive.
    init(round: LobbyRound, lobby: LobbyService) {
        self.lobby = lobby
        _vm = State(initialValue: DiveViewModel(
            questions: QuestionBank.seeded(round.seed),
            isPractice: true,
            secondsPerQuestion: round.secondsPerQuestion
        ))
    }

    private var title: String {
        if lobby != nil { return "Crew Dive" }
        return vm.isPractice ? "Practice Dive" : "Daily Dive"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.oceanGradient.ignoresSafeArea()

                if vm.isFinished {
                    ResultsView(records: vm.records,
                                totalPoints: vm.totalPoints,
                                shareText: vm.shareText,
                                leaderboard: lobby?.scores ?? [],
                                highlightPlayer: lobby?.playerName ?? "") { dismiss() }
                } else {
                    questionScreen
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if !vm.isFinished {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Quit") {
                            vm.stop()
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            vm.start()
            fieldFocused = true
        }
        .onDisappear { vm.stop() }
    }

    // MARK: Question screen

    private var questionScreen: some View {
        VStack(spacing: 20) {
            // GUI object: progress bar for the whole dive
            ProgressView(value: vm.progress)
                .tint(Theme.krill)

            HStack {
                Text("Prompt \(vm.index + 1) of \(vm.questions.count)")
                Spacer()
                Label("\(vm.depth) m", systemImage: "arrow.down.to.line")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.foam.opacity(0.8))

            TimerRing(remaining: vm.timeRemaining, total: Double(vm.secondsPerQuestion))
                .frame(width: 90, height: 90)

            VStack(spacing: 8) {
                Text(vm.currentQuestion.category.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(Theme.krill)
                Text(vm.currentQuestion.prompt)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.foam)
            }

            Spacer(minLength: 0)

            switch vm.phase {
            case .answering:
                answerInput
            case .scoring:
                ProgressView("Measuring rarity…")
                    .tint(Theme.foam)
                    .foregroundStyle(Theme.foam)
                    .padding()
            case .feedback(let record):
                FeedbackCard(record: record, examples: Array(vm.currentQuestion.validAnswers.prefix(3)))
                Button(vm.isLastQuestion ? "See Results" : "Next Prompt") { advance() }
                    .buttonStyle(PrimaryButtonStyle())
            case .finished:
                EmptyView()
            }
        }
        .padding()
    }

    private var answerInput: some View {
        VStack(spacing: 12) {
            // GUI object: text field
            TextField("Type your answer…", text: $vm.input)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused($fieldFocused)
                .onSubmit { Task { await vm.submit() } }
                .padding()
                .background(Theme.foam.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(Theme.foam)

            // GUI object: button
            Button("Submit") { Task { await vm.submit() } }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func advance() {
        vm.next()
        if vm.isFinished {
            saveResult()
        } else {
            fieldFocused = true
        }
    }

    private func saveResult() {
        guard !saved else { return }
        saved = true
        context.insert(DiveResult(records: vm.records, isPractice: vm.isPractice))
        try? context.save()

        // Multiplayer: tell the rest of the crew how deep we got.
        if let lobby {
            let emojis = vm.records.map { $0.tier?.emoji ?? "❌" }.joined()
            lobby.report(points: vm.totalPoints, emojis: emojis)
        }
    }
}

/// Circular countdown for the per-question timer.
struct TimerRing: View {
    let remaining: Double
    let total: Double

    private var fraction: Double { max(0, min(1, remaining / total)) }

    var body: some View {
        ZStack {
            Circle().stroke(Theme.foam.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(fraction < 0.25 ? Color.red : Theme.lagoon,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: fraction)
            Text("\(Int(max(0, remaining).rounded(.up)))")
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(Theme.foam)
        }
    }
}

/// Shows how the last answer scored.
struct FeedbackCard: View {
    let record: AnswerRecord
    let examples: [String]

    var body: some View {
        VStack(spacing: 8) {
            if let tier = record.tier {
                Text(tier.emoji).font(.system(size: 48))
                Text(tier.name).font(.title2.bold()).foregroundStyle(tier.color)
                Text("“\(record.matchedAnswer ?? record.typedAnswer)” · +\(tier.points) pts")
                    .foregroundStyle(Theme.foam)
            } else {
                Text("🫧").font(.system(size: 48))
                Text(record.typedAnswer == "—" ? "Out of air!" : "Not on the list")
                    .font(.title2.bold())
                    .foregroundStyle(Theme.krill)
                Text("Some answers that work: \(examples.joined(separator: ", "))")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.foam.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .card()
    }
}

#Preview {
    DiveView(practice: true, secondsPerQuestion: 25)
        .modelContainer(for: DiveResult.self, inMemory: true)
        .preferredColorScheme(.dark)
}
