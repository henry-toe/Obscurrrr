import SwiftUI

/// Multiplayer entry point: pick a pirate name, then create or join a crew lobby.
struct MultiplayerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("pirateName") private var pirateName = ""

    @State private var service = LobbyService()
    @State private var path: [Route] = []

    enum Route: Hashable {
        case create
        case join
        case room
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.parchmentGradient.ignoresSafeArea()

                VStack(spacing: 20) {
                    nameCard

                    Button { path.append(.create) } label: {
                        Label("Create Lobby", systemImage: "flag.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button { path.append(.join) } label: {
                        Label("Join Lobby", systemImage: "person.3.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.deepSea))

                    Text("Crews answer the same 7 riddles at the same time over nearby Wi-Fi or Bluetooth. No account needed.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.wood.opacity(0.7))

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Crew Dive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .create:
                    CreateLobbyView(service: service, playerName: effectiveName, path: $path)
                case .join:
                    JoinLobbyView(service: service, playerName: effectiveName, path: $path)
                case .room:
                    LobbyRoomView(service: service, path: $path)
                }
            }
        }
        .preferredColorScheme(.light)
        .onDisappear { service.leave() }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YER PIRATE NAME")
                .font(.caption.weight(.heavy))
                .tracking(2)
            TextField(LobbyService.defaultPlayerName, text: $pirateName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(12)
                .background(Theme.parchment, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.wood.opacity(0.5), lineWidth: 1.5)
                )
        }
        .foregroundStyle(Theme.wood)
        .parchmentCard()
    }

    private var effectiveName: String {
        let trimmed = pirateName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? LobbyService.defaultPlayerName : trimmed
    }
}

// MARK: - Create Lobby

/// Asks for a lobby name, public or private, and a password for private lobbies.
struct CreateLobbyView: View {
    let service: LobbyService
    let playerName: String
    @Binding var path: [MultiplayerView.Route]

    @State private var lobbyName = ""
    @State private var visibility: LobbyVisibility = .publicLobby
    @State private var password = ""

    var body: some View {
        Form {
            Section("Lobby") {
                TextField("Lobby name", text: $lobbyName)
                    .textInputAutocapitalization(.words)
            }

            Section {
                // GUI object: segmented picker for public vs. private
                Picker("Who can join?", selection: $visibility) {
                    ForEach(LobbyVisibility.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if visibility == .privateLobby {
                    TextField("Password (at least 4 characters)", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            } header: {
                Text("Visibility")
            } footer: {
                Text(visibility.footer)
            }

            Section {
                Button(action: open) {
                    Label("Open Lobby", systemImage: "flag.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canOpen)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.parchmentGradient.ignoresSafeArea())
        .navigationTitle("Create Lobby")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if lobbyName.isEmpty { lobbyName = "\(playerName)'s Crew" }
        }
    }

    private var trimmedName: String { lobbyName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedPassword: String { password.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canOpen: Bool {
        guard !trimmedName.isEmpty else { return false }
        return visibility == .publicLobby || trimmedPassword.count >= 4
    }

    private func open() {
        service.host(lobbyName: trimmedName,
                     isPrivate: visibility == .privateLobby,
                     password: trimmedPassword,
                     playerName: playerName)
        path.append(.room)
    }
}

// MARK: - Join Lobby

/// Lists lobbies advertised nearby. Private ones ask for the password first.
struct JoinLobbyView: View {
    let service: LobbyService
    let playerName: String
    @Binding var path: [MultiplayerView.Route]

    @State private var passwordTarget: LobbyInfo?
    @State private var askPassword = false
    @State private var password = ""
    @State private var showFailure = false
    @State private var failureMessage = ""

    var body: some View {
        ZStack {
            Theme.parchmentGradient.ignoresSafeArea()

            if service.nearbyLobbies.isEmpty {
                searching
            } else {
                lobbyList
            }
        }
        .navigationTitle("Join Lobby")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { service.startBrowsing(playerName: playerName) }
        .onDisappear {
            // Backing out of this screen stops browsing; moving on to the room keeps the session.
            if service.joinStatus != .joined { service.leave() }
        }
        .onChange(of: service.joinStatus) { _, status in
            switch status {
            case .joined:
                path.append(.room)
            case .failed(let reason):
                failureMessage = reason
                showFailure = true
            default:
                break
            }
        }
        .alert("Private crew", isPresented: $askPassword, presenting: passwordTarget) { target in
            TextField("Password", text: $password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Join") {
                service.join(target, password: password.trimmingCharacters(in: .whitespacesAndNewlines))
                password = ""
            }
            Button("Cancel", role: .cancel) { password = "" }
        } message: { target in
            Text("“\(target.name)” needs a password. Ask Captain \(target.hostName) for it.")
        }
        .alert("Couldn't join", isPresented: $showFailure) {
            Button("OK") { service.clearJoinError() }
        } message: {
            Text(failureMessage)
        }
    }

    private var searching: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Theme.wood)
            Text("Searching for crews nearby…")
                .font(.headline)
            Text("Make sure the captain has opened a lobby on the same Wi-Fi, or that Bluetooth is on.")
                .font(.footnote)
                .opacity(0.7)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Theme.wood)
        .padding(32)
    }

    private var lobbyList: some View {
        List(service.nearbyLobbies) { lobby in
            Button { tapped(lobby) } label: {
                HStack(spacing: 12) {
                    Image(systemName: lobby.isPrivate ? "lock.fill" : "globe")
                        .font(.title3)
                        .foregroundStyle(lobby.isPrivate ? Theme.treasureRed : Theme.deepSea)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lobby.name).font(.headline)
                        Text("Captain \(lobby.hostName) · \(lobby.isPrivate ? "Private" : "Public")")
                            .font(.caption)
                            .opacity(0.7)
                    }
                    Spacer()
                    if service.joinStatus == .connecting && service.lobby?.id == lobby.id {
                        ProgressView().tint(Theme.wood)
                    } else {
                        Image(systemName: "chevron.right").opacity(0.4)
                    }
                }
                .foregroundStyle(Theme.wood)
            }
            .listRowBackground(Theme.parchment)
        }
        .scrollContentBackground(.hidden)
    }

    private func tapped(_ lobby: LobbyInfo) {
        guard service.joinStatus != .connecting else { return }
        if lobby.isPrivate {
            passwordTarget = lobby
            askPassword = true
        } else {
            service.join(lobby)
        }
    }
}

// MARK: - Lobby Room

/// The waiting room: who's aboard, the password (host only), and the start button.
struct LobbyRoomView: View {
    @Bindable var service: LobbyService
    @Binding var path: [MultiplayerView.Route]
    @AppStorage("secondsPerQuestion") private var secondsPerQuestion = 25

    @State private var showClosed = false
    @State private var closedMessage = ""

    private var isHost: Bool { service.role == .host }

    var body: some View {
        ZStack {
            Theme.parchmentGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    lobbyCard
                    crewCard
                    if !service.scores.isEmpty { leaderboardCard }
                    actions
                }
                .padding(20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(service.lobby?.name ?? "Lobby")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Leave", action: leave)
            }
        }
        .fullScreenCover(item: $service.activeRound) { round in
            DiveView(round: round, lobby: service)
        }
        .onChange(of: service.joinStatus) { _, status in
            if case .failed(let reason) = status {
                closedMessage = reason
                showClosed = true
            }
        }
        .alert("Lobby closed", isPresented: $showClosed) {
            Button("OK", action: leave)
        } message: {
            Text(closedMessage)
        }
    }

    private var lobbyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(service.lobby?.isPrivate == true ? "Private crew" : "Public crew",
                      systemImage: service.lobby?.isPrivate == true ? "lock.fill" : "globe")
                    .font(.headline)
                    .foregroundStyle(service.lobby?.isPrivate == true ? Theme.treasureRed : Theme.deepSea)
                Spacer()
                Text(isHost ? "Ye be captain" : "Captain \(service.lobby?.hostName ?? "")")
                    .font(.caption.weight(.semibold))
                    .opacity(0.7)
            }

            if isHost, !service.hostPassword.isEmpty {
                Divider().overlay(Theme.wood.opacity(0.4))
                HStack {
                    Text("Password")
                        .font(.caption)
                        .opacity(0.7)
                    Spacer()
                    Text(service.hostPassword)
                        .font(.title3.monospaced().bold())
                        .textSelection(.enabled)
                }
                Text("Share this with yer crew so they can board.")
                    .font(.caption2)
                    .opacity(0.6)
            }
        }
        .foregroundStyle(Theme.wood)
        .parchmentCard()
    }

    private var crewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CREW ABOARD · \(service.players.count)")
                .font(.caption.weight(.heavy))
                .tracking(2)

            ForEach(Array(service.players.enumerated()), id: \.offset) { index, name in
                HStack {
                    Image(systemName: index == 0 ? "crown.fill" : "person.fill")
                        .foregroundStyle(index == 0 ? Theme.treasureRed : Theme.deepSea)
                        .frame(width: 24)
                    Text(name)
                    if name == service.playerName {
                        Text("(you)").opacity(0.6)
                    }
                    Spacer()
                }
            }
        }
        .foregroundStyle(Theme.wood)
        .parchmentCard()
    }

    private var leaderboardCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LAST ROUND")
                .font(.caption.weight(.heavy))
                .tracking(2)
            LeaderboardRows(scores: service.scores, highlight: service.playerName)
        }
        .foregroundStyle(Theme.wood)
        .parchmentCard()
    }

    @ViewBuilder
    private var actions: some View {
        if isHost {
            Button {
                service.startRound(secondsPerQuestion: secondsPerQuestion)
            } label: {
                Label("Set Sail", systemImage: "sailboat.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Text(service.players.count < 2
                 ? "Waiting for crew to board… ye can also set sail alone."
                 : "Everyone aboard gets the same 7 riddles, \(secondsPerQuestion) seconds each.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.wood.opacity(0.7))
        } else {
            HStack(spacing: 10) {
                ProgressView().tint(Theme.wood)
                Text("Waiting for the captain to set sail…")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.wood)
            .padding(.top, 4)
        }
    }

    private func leave() {
        service.leave()
        path.removeAll()
    }
}

/// Ranked list of lobby scores, shared by the room and the results screen.
struct LeaderboardRows: View {
    let scores: [LobbyScore]
    let highlight: String

    private var ranked: [LobbyScore] { scores.sorted { $0.points > $1.points } }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(ranked.enumerated()), id: \.element.id) { index, score in
                HStack(spacing: 10) {
                    Text("\(index + 1).")
                        .font(.subheadline.monospacedDigit().bold())
                        .frame(width: 26, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(score.player)
                            .font(.body.weight(score.player == highlight ? .bold : .regular))
                        Text(score.emojis).font(.caption)
                    }
                    Spacer()
                    Text("\(score.depthMeters) m")
                        .font(.headline.monospacedDigit())
                }
                .padding(.vertical, 8)
                if score.id != ranked.last?.id { Divider() }
            }
        }
    }
}

#Preview {
    MultiplayerView()
}
