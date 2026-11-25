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
    /// The most recent wrong guess on the current question, shown as a
    /// "try again" hint. Cleared when the next question starts.
    var rejectedAnswer: String?
    /// How many wrong guesses were made on the current question.
    var wrongAttempts = 0

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

    /// Checks the typed answer.
    ///
    /// - A correct answer is scored right away and the question ends.
    /// - A wrong answer does **not** end the question: the player gets a hint and
    ///   can keep guessing while the timer runs.
    /// - When the timer hits zero it calls this with `timedOut: true`, which
    ///   records a miss and moves on.
    func submit(timedOut: Bool = false) async {
        guard case .answering = phase else { return }

        let question = currentQuestion
        let typed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let matched = question.match(typed)

        // Wrong (or empty) guess with time still on the clock: stay on this question.
        if matched == nil && !timedOut {
            guard !typed.isEmpty else { return }
            wrongAttempts += 1
            rejectedAnswer = typed
            input = ""
            return
        }

        stop()
        let used = Double(secondsPerQuestion) - max(timeRemaining, 0)

        var tier: RarityTier?
        if let matched {
            phase = .scoring
            tier = await rarity.tier(for: matched)
        }

        // On a timeout, show the last wrong guess rather than a blank.
        let shown = typed.isEmpty ? (rejectedAnswer ?? "—") : typed

        let record = AnswerRecord(
            prompt: question.prompt,
            typedAnswer: shown,
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
            rejectedAnswer = nil
            wrongAttempts = 0
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
                    // Time's up: score whatever was typed and move on. Run it in a
                    // fresh Task because submit() cancels this timer task (which
                    // would also cancel the network request).
                    Task { await self.submit(timedOut: true) }
                    return
                }
            }
        }
    }
}
