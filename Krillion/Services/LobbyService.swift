import Foundation
import MultipeerConnectivity
import Observation
import UIKit

/// Hosts or joins a multiplayer lobby over the local network (Wi-Fi / Bluetooth)
/// using MultipeerConnectivity, so no server or account is needed.
///
/// - The host advertises the lobby. Public lobbies accept anyone nearby; private
///   lobbies only accept players whose join request carries the right password.
/// - When the host starts a round, every member receives the same seed, plays the
///   same seven questions, and shares their score for a leaderboard.
@MainActor
@Observable
final class LobbyService: NSObject {
    /// Bonjour service type (max 15 chars). Must match NSBonjourServices in Info.plist.
    static let serviceType = "krillion-lobby"

    enum Role { case none, host, guest }

    enum JoinStatus: Equatable {
        case idle
        case connecting
        case joined
        case failed(String)
    }

    // MARK: Observable state

    private(set) var role: Role = .none
    private(set) var lobby: LobbyInfo?
    private(set) var nearbyLobbies: [LobbyInfo] = []
    /// Display names of everyone in the lobby, host first.
    private(set) var players: [String] = []
    private(set) var joinStatus: JoinStatus = .idle
    private(set) var scores: [LobbyScore] = []
    private(set) var playerName = ""
    /// Password of the lobby being hosted, shown to the host so they can share it.
    private(set) var hostPassword = ""
    /// Set when a round begins; the lobby screen presents DiveView for it.
    var activeRound: LobbyRound?

    // MARK: Multipeer plumbing

    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    /// Lobby id → the host peer advertising it.
    private var lobbyPeers: [String: MCPeerID] = [:]
    private var hostPeer: MCPeerID?

    /// Fallback pirate name when the player hasn't typed one.
    static var defaultPlayerName: String { UIDevice.current.name }

    override init() {
        super.init()
    }

    // MARK: Hosting

    /// Opens a lobby and starts advertising it to nearby devices.
    func host(lobbyName: String, isPrivate: Bool, password: String, playerName: String) {
        leave()
        let session = makeSession(playerName: playerName)
        let info = LobbyInfo(id: UUID().uuidString,
                             name: lobbyName,
                             hostName: self.playerName,
                             isPrivate: isPrivate)
        lobby = info
        role = .host
        hostPassword = isPrivate ? password : ""
        players = [self.playerName]

        // Discovery info is public, so the password is never put in here.
        let discovery = [
            "id": info.id,
            "name": info.name,
            "host": info.hostName,
            "private": isPrivate ? "1" : "0",
        ]
        let advertiser = MCNearbyServiceAdvertiser(peer: session.myPeerID,
                                                   discoveryInfo: discovery,
                                                   serviceType: Self.serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser
    }

    /// Host only: picks a seed and tells everyone to begin.
    func startRound(secondsPerQuestion: Int) {
        guard role == .host else { return }
        let round = LobbyRound(id: UUID(),
                               seed: UInt64.random(in: 0...UInt64.max),
                               secondsPerQuestion: secondsPerQuestion)
        scores = []
        send(.start(round))
        activeRound = round
    }

    // MARK: Joining

    /// Starts looking for lobbies advertised nearby.
    func startBrowsing(playerName: String) {
        leave()
        let session = makeSession(playerName: playerName)
        let browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: Self.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
    }

    /// Asks to join a lobby. For private lobbies the host checks `password`.
    func join(_ target: LobbyInfo, password: String = "") {
        guard joinStatus != .connecting else { return }
        guard let peer = lobbyPeers[target.id], let session, let browser else {
            joinStatus = .failed("That crew has already sailed away.")
            return
        }
        lobby = target
        hostPeer = peer
        joinStatus = .connecting
        let context = try? JSONEncoder().encode(JoinRequest(password: password))
        browser.invitePeer(peer, to: session, withContext: context, timeout: 15)
    }

    func clearJoinError() {
        if case .failed = joinStatus { joinStatus = .idle }
    }

    // MARK: Shared

    /// Called when this player finishes a round.
    func report(points: Int, emojis: String) {
        let score = LobbyScore(player: playerName, points: points, emojis: emojis)
        upsert(score)
        send(.score(score))
    }

    /// Disconnects from everything and resets to a blank state.
    func leave() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        role = .none
        lobby = nil
        nearbyLobbies = []
        players = []
        joinStatus = .idle
        scores = []
        activeRound = nil
        hostPassword = ""
        lobbyPeers = [:]
        hostPeer = nil
    }

    // MARK: Private helpers

    private func makeSession(playerName: String) -> MCSession {
        let trimmed = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.playerName = trimmed.isEmpty ? Self.defaultPlayerName : trimmed
        let peer = MCPeerID(displayName: self.playerName)
        let session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session
        return session
    }

    private func send(_ message: LobbyMessage) {
        guard let session, !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(message) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    private func upsert(_ score: LobbyScore) {
        scores.removeAll { $0.player == score.player }
        scores.append(score)
    }

    private func refreshRoster() {
        guard role == .host, let session else { return }
        players = [playerName] + session.connectedPeers.map(\.displayName)
        send(.roster(players))
    }

    private func handle(_ message: LobbyMessage) {
        switch message {
        case .roster(let names):
            if role == .guest { players = names }
        case .start(let round):
            if role == .guest {
                scores = []
                activeRound = round
            }
        case .score(let score):
            upsert(score)
            // The host relays scores so every guest sees the full leaderboard.
            if role == .host { send(.score(score)) }
        }
    }

    private func peerChanged(_ peer: MCPeerID, state: MCSessionState) {
        if role == .host {
            refreshRoster()
            return
        }

        // Guest (or still browsing): only the host connection matters.
        guard peer == hostPeer else { return }
        switch state {
        case .connected:
            role = .guest
            joinStatus = .joined
            browser?.stopBrowsingForPeers()
            nearbyLobbies = []
        case .notConnected:
            if joinStatus == .connecting {
                let reason = lobby?.isPrivate == true
                    ? "Wrong password, or the captain turned ye away."
                    : "Couldn't reach that crew. Try again."
                joinStatus = .failed(reason)
            } else if joinStatus == .joined {
                joinStatus = .failed("The captain closed the lobby.")
            }
            lobby = nil
            hostPeer = nil
            role = .none
            players = []
            activeRound = nil
        case .connecting:
            break
        @unknown default:
            break
        }
    }
}

/// Sent as the invitation context when asking to join a lobby.
private struct JoinRequest: Codable {
    let password: String
}

// MARK: - MCNearbyServiceAdvertiserDelegate (host side)

extension LobbyService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let request = context.flatMap { try? JSONDecoder().decode(JoinRequest.self, from: $0) }
        Task { @MainActor in
            let isPrivate = self.lobby?.isPrivate ?? false
            let passwordOK = !isPrivate || request?.password == self.hostPassword
            // Don't let anyone board mid-round.
            let accept = passwordOK && self.activeRound == nil && self.session != nil
            invitationHandler(accept, accept ? self.session : nil)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (guest side)

extension LobbyService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {
        guard let info, let id = info["id"], let name = info["name"] else { return }
        let found = LobbyInfo(id: id,
                              name: name,
                              hostName: info["host"] ?? peerID.displayName,
                              isPrivate: info["private"] == "1")
        Task { @MainActor in
            self.lobbyPeers[id] = peerID
            if !self.nearbyLobbies.contains(where: { $0.id == id }) {
                self.nearbyLobbies.append(found)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            let ids = self.lobbyPeers.filter { $0.value == peerID }.map(\.key)
            for id in ids { self.lobbyPeers[id] = nil }
            self.nearbyLobbies.removeAll { ids.contains($0.id) }
        }
    }
}

// MARK: - MCSessionDelegate (both sides)

extension LobbyService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in self.peerChanged(peerID, state: state) }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(LobbyMessage.self, from: data) else { return }
        Task { @MainActor in self.handle(message) }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream,
                             withName streamName: String, fromPeer peerID: MCPeerID) {}

    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, with progress: Progress) {}

    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
