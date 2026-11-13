import Foundation
import Observation

/// Runs one dive: the question order, the countdown timer, scoring and results.
@MainActor
@Observable
final class DiveViewModel {
    enum Phase {
        case answering
        case scoring
        case feedback(AnswerRecord)
        case finished
    }

    let questions: [Question]
    let isPractice: Bool
    let secondsPerQuestion: Int

    var index = 0
    var input = ""
    var timeRemaining: Double
    var records: [AnswerRecord] = []
    var phase: Phase = .answering

    private var timerTask: Task<Void, Never>?
    private let rarity = RarityService()

    init(questions: [Question], isPractice: Bool, secondsPerQuestion: Int) {
        self.questions = questions
        self.isPractice = isPractice
        self.secondsPerQuestion = secondsPerQuestion
        self.timeRemaining = Double(secondsPerQuestion)
    }

    // MARK: Derived values

    var currentQuestion: Question { questions[index] }
    var isLastQuestion: Bool { index == questions.count - 1 }
    var totalPoints: Int { records.reduce(0) { $0 + $1.points } }
    var depth: Int { totalPoints * 10 }
    var progress: Double { Double(records.count) / Double(questions.count) }
    var isFinished: Bool { if case .finished = phase { true } else { false } }

    // MARK: Flow

    func start() {
        guard records.isEmpty, case .answering = phase else { return }
        startTimer()
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
    }

    func submit() async {
        guard case .answering = phase else { return }
        stop()

        let question = currentQuestion
        let typed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let used = Double(secondsPerQuestion) - max(timeRemaining, 0)

        var tier: RarityTier?
        let matched = question.match(typed)
        if let matched {
            phase = .scoring
            tier = await rarity.tier(for: matched)
        }

        let record = AnswerRecord(
            prompt: question.prompt,
            typedAnswer: typed.isEmpty ? "—" : typed,
            matchedAnswer: matched,
            tier: tier,
            secondsUsed: used
        )
        records.append(record)
        phase = .feedback(record)
    }

    func next() {
        if isLastQuestion {
            phase = .finished
        } else {
            index += 1
            input = ""
            phase = .answering
            startTimer()
        }
    }

    /// Emoji summary for the share sheet, e.g. "🦐🦑❌🐋✨🦠🦈".
    var shareText: String {
        let row = records.map { $0.tier?.emoji ?? "❌" }.joined()
        let date = Date.now.formatted(date: .abbreviated, time: .omitted)
        return "Krillion Daily Dive — \(date)\n\(row)\nReached \(depth) m (\(totalPoints) pts)"
    }

    // MARK: Timer

    private func startTimer() {
        timerTask?.cancel()
        timeRemaining = Double(secondsPerQuestion)
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, !Task.isCancelled else { return }
                self.timeRemaining -= 0.1
                if self.timeRemaining <= 0 {
                    // Time's up: score whatever was typed. Run it in a fresh Task
                    // because submit() cancels this timer task (which would also
                    // cancel the network request).
                    Task { await self.submit() }
                    return
                }
            }
        }
    }
}
