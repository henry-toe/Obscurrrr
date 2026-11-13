import SwiftUI

/// How rare a correct answer is. Rarer answers score more points and dive deeper.
/// The scale runs from 10 (very common) to 100 (one in a krillion), like the web game.
enum RarityTier: Int, CaseIterable, Codable, Comparable {
    case plankton = 10
    case shrimp = 25
    case squid = 40
    case shark = 60
    case whale = 80
    case oneInAKrillion = 100

    var points: Int { rawValue }

    var name: String {
        switch self {
        case .plankton: "Plankton"
        case .shrimp: "Shrimp"
        case .squid: "Squid"
        case .shark: "Shark"
        case .whale: "Whale"
        case .oneInAKrillion: "One in a Krillion"
        }
    }

    var emoji: String {
        switch self {
        case .plankton: "🦠"
        case .shrimp: "🦐"
        case .squid: "🦑"
        case .shark: "🦈"
        case .whale: "🐋"
        case .oneInAKrillion: "✨"
        }
    }

    var color: Color {
        switch self {
        case .plankton: .gray
        case .shrimp: .mint
        case .squid: Theme.lagoon
        case .shark: .indigo
        case .whale: .purple
        case .oneInAKrillion: .yellow
        }
    }

    /// Maps an English word frequency (occurrences per million words, from the
    /// Datamuse API) to a rarity tier. Common words → low tiers.
    static func from(frequencyPerMillion f: Double) -> RarityTier {
        switch f {
        case 100...: .plankton
        case 20..<100: .shrimp
        case 5..<20: .squid
        case 1..<5: .shark
        case 0.2..<1: .whale
        default: .oneInAKrillion
        }
    }

    static func < (lhs: RarityTier, rhs: RarityTier) -> Bool { lhs.rawValue < rhs.rawValue }
}
