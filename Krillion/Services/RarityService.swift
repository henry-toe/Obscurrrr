import Foundation

/// Web API implementation: asks the free Datamuse API (https://www.datamuse.com/api/)
/// how common a word is in English. Common words = low tier, obscure words = high tier.
///
/// Example request:
///   https://api.datamuse.com/words?sp=llama&md=f&max=1
/// Example response:
///   [{"word":"llama","score":...,"tags":["f:1.92"]}]   ← f = uses per million words
struct RarityService {
    private struct DatamuseWord: Decodable {
        let word: String
        let tags: [String]?
    }

    enum RarityError: Error { case badURL, badResponse }

    /// Frequency per million words, or nil if Datamuse doesn't know the word.
    func frequency(of answer: String) async throws -> Double? {
        var components = URLComponents(string: "https://api.datamuse.com/words")
        components?.queryItems = [
            URLQueryItem(name: "sp", value: answer.lowercased()),
            URLQueryItem(name: "md", value: "f"),
            URLQueryItem(name: "max", value: "1"),
        ]
        guard let url = components?.url else { throw RarityError.badURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw RarityError.badResponse
        }

        let words = try JSONDecoder().decode([DatamuseWord].self, from: data)
        guard let first = words.first,
              first.word.lowercased() == answer.lowercased() else { return nil }

        return first.tags?
            .first { $0.hasPrefix("f:") }
            .flatMap { Double($0.dropFirst(2)) }
    }

    /// Never fails: falls back to a middle tier when offline.
    func tier(for answer: String) async -> RarityTier {
        do {
            if let f = try await frequency(of: answer) {
                return RarityTier.from(frequencyPerMillion: f)
            }
            return .whale // valid answer the dictionary barely knows = very rare
        } catch {
            return .squid // network problem: give a fair middle score
        }
    }
}
