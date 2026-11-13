import Foundation

/// One prompt in a dive, e.g. "Name a farm animal".
struct Question: Identifiable, Codable, Hashable {
    let id: Int
    let category: String
    let prompt: String
    /// Every answer we accept as correct. Rarity is decided later.
    let validAnswers: [String]

    /// Returns the canonical answer if the user's input is valid, otherwise nil.
    func match(_ input: String) -> String? {
        let key = Question.normalize(input)
        guard !key.isEmpty else { return nil }
        return validAnswers.first { Question.normalize($0) == key }
    }

    /// Lower-cases, drops a leading "the", and strips spaces/punctuation so
    /// "The Netherlands", "netherlands" and "Nether-lands" all match.
    static func normalize(_ s: String) -> String {
        var t = s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("the ") { t.removeFirst(4) }
        return t.filter { $0.isLetter || $0.isNumber || "+#".contains($0) }
    }
}

/// What happened on a single question. Stored inside a DiveResult.
struct AnswerRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    let prompt: String
    let typedAnswer: String
    let matchedAnswer: String?
    let tier: RarityTier?
    let secondsUsed: Double

    var isCorrect: Bool { tier != nil }
    var points: Int { tier?.points ?? 0 }
}
