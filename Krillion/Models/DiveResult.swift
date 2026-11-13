import Foundation
import SwiftData

/// A finished dive, saved with SwiftData (rubric: Persistent Data Storage).
@Model
final class DiveResult {
    var date: Date            // Date
    var totalPoints: Int      // Int
    var isPractice: Bool      // Bool
    var averageSeconds: Double // Double
    /// The per-question records, JSON-encoded so the model stays simple.
    var answersData: Data

    init(date: Date = .now, records: [AnswerRecord], isPractice: Bool) {
        self.date = date
        self.totalPoints = records.reduce(0) { $0 + $1.points }
        self.isPractice = isPractice
        self.averageSeconds = records.isEmpty
            ? 0
            : records.map(\.secondsUsed).reduce(0, +) / Double(records.count)
        self.answersData = (try? JSONEncoder().encode(records)) ?? Data()
    }

    var answers: [AnswerRecord] {
        (try? JSONDecoder().decode([AnswerRecord].self, from: answersData)) ?? []
    }

    /// Depth in metres = points × 10 (max 7,000 m for a perfect 700-point dive).
    var depthMeters: Int { totalPoints * 10 }

    var correctCount: Int { answers.filter(\.isCorrect).count }
}
