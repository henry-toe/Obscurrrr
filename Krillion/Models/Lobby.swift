import Foundation

/// Whether anyone nearby can join a lobby, or only people with the password.
enum LobbyVisibility: String, CaseIterable, Identifiable {
    case publicLobby
    case privateLobby

    var id: String { rawValue }

    var title: String {
        switch self {
        case .publicLobby: "Public"
        case .privateLobby: "Private"
        }
    }

    var footer: String {
        switch self {
        case .publicLobby:
            "Any pirate nearby can see and join this lobby."
        case .privateLobby:
            "The lobby still shows up nearby, but only crew who know the password can board."
        }
    }
}

/// A lobby a host is advertising on the local network.
struct LobbyInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let hostName: String
    let isPrivate: Bool
}

/// One round started by the host. Everyone uses the same seed so they get
/// identical questions.
struct LobbyRound: Identifiable, Codable, Hashable {
    let id: UUID
    let seed: UInt64
    let secondsPerQuestion: Int
}

/// A player's finished score for the current round.
struct LobbyScore: Identifiable, Codable, Hashable {
    var id: String { player }
    let player: String
    let points: Int
    /// Emoji row like "🦐🦑❌🐋✨🦠🦈".
    let emojis: String

    var depthMeters: Int { points * 10 }
}

/// Messages exchanged between lobby members.
enum LobbyMessage: Codable {
    /// Host → guests: the current list of players (host first).
    case roster([String])
    /// Host → guests: a new round is starting.
    case start(LobbyRound)
    /// Anyone → everyone: a finished score.
    case score(LobbyScore)
}
