import SwiftUI
import SwiftData

/// Screen 1: the pirate-themed home screen. Shows today's status and starts a dive.
struct HomeView: View {
    @Query(sort: \DiveResult.date, order: .reverse) private var results: [DiveResult]
    @AppStorage("allowReplays") private var allowReplays = false
    @AppStorage("secondsPerQuestion") private var secondsPerQuestion = 25

    @State private var activeDive: DiveConfig?
    @State private var showRules = false
    @State private var showLog = false
    @State private var showSettings = false
    @State private var showMultiplayer = false

    struct DiveConfig: Identifiable {
        let id = UUID()
        let practice: Bool
    }

    // MARK: Data from SwiftData

    private var todaysDive: DiveResult? {
        results.first { !$0.isPractice && Calendar.current.isDateInToday($0.date) }
    }

    private var bestDepth: Int {
        results.filter { !$0.isPractice }.map(\.depthMeters).max() ?? 0
    }

    private var dailyLocked: Bool { todaysDive != nil && !allowReplays }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.parchmentGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        header
                        statusCard
                        actionButtons
                        bottomRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showRules = true } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.wood)
                    }
                    .accessibilityLabel("How to play")
                }
            }
            .sheet(isPresented: $showRules) { RulesSheet() }
            .sheet(isPresented: $showLog) { HistoryView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showMultiplayer) { MultiplayerView() }
            .fullScreenCover(item: $activeDive) { config in
                DiveView(practice: config.practice, secondsPerQuestion: secondsPerQuestion)
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: 4) {
            Image("TreasureMap")
                .interpolation(.none)   // keep pixel-art edges sharp
                .resizable()
                .scaledToFit()
                .frame(height: 190)
                .accessibilityHidden(true)

            Text("Krillion")
                .font(Theme.pirateFont(46))
                .foregroundStyle(Theme.wood)

            HStack(spacing: 8) {
                Rectangle().fill(Theme.treasureRed).frame(width: 28, height: 2)
                Text("THE DAILY DIVE")
                    .font(.caption.weight(.heavy))
                    .tracking(4)
                    .foregroundStyle(Theme.treasureRed)
                Rectangle().fill(Theme.treasureRed).frame(width: 28, height: 2)
            }

            Text(Date.now.formatted(date: .complete, time: .omitted))
                .font(.subheadline.italic())
                .foregroundStyle(Theme.wood.opacity(0.75))
                .padding(.top, 2)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let todaysDive {
                Label("Treasure found today!", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.deepSea)
                Text("Ye reached **\(todaysDive.depthMeters) m** with \(todaysDive.totalPoints) doubloons.")
            } else {
                Label("Today's map be ready", systemImage: "map.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.treasureRed)
                Text("7 riddles · \(secondsPerQuestion) seconds each. The rarer yer answer, the deeper the treasure.")
            }

            Divider().overlay(Theme.wood.opacity(0.4))

            HStack {
                StatBlock(title: "Deepest dive", value: "\(bestDepth) m")
                Spacer()
                StatBlock(title: "Voyages", value: "\(results.count)")
                Spacer()
                StatBlock(title: "Doubloons", value: "\(results.reduce(0) { $0 + $1.totalPoints })")
            }
        }
        .foregroundStyle(Theme.wood)
        .parchmentCard()
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                activeDive = DiveConfig(practice: false)
            } label: {
                Label(dailyLocked ? "Come back tomorrow, matey" : "Set Sail: Daily Dive",
                      systemImage: dailyLocked ? "lock.fill" : "sailboat.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(dailyLocked)
            .opacity(dailyLocked ? 0.5 : 1)

            Button {
                activeDive = DiveConfig(practice: true)
            } label: {
                Label("Practice Voyage", systemImage: "scope")
            }
            .buttonStyle(PrimaryButtonStyle(color: Theme.deepSea))

            Button {
                showMultiplayer = true
            } label: {
                Label("Crew Dive: Multiplayer", systemImage: "person.3.fill")
            }
            .buttonStyle(PrimaryButtonStyle(color: Theme.wood))
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 12) {
            Button { showLog = true } label: {
                Label("Captain's Log", systemImage: "book.closed.fill")
            }
            Button { showSettings = true } label: {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .buttonStyle(PrimaryButtonStyle(color: Theme.parchmentDark, textColor: Theme.wood))
    }
}

/// Small title/value pair used in the stat rows.
struct StatBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).opacity(0.7)
            Text(value).font(.title3.bold())
        }
    }
}

/// How-to-play sheet with the scoring table.
struct RulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("How to play") {
                    Text("Answer each riddle with something that fits. Right answers earn doubloons, and **rarer** right answers earn more.")
                    Text("Yer depth is doubloons × 10. A perfect dive reaches 7,000 m.")
                }
                Section("Rarity tiers") {
                    ForEach(RarityTier.allCases.reversed(), id: \.self) { tier in
                        HStack {
                            Text(tier.emoji)
                            Text(tier.name)
                            Spacer()
                            Text("\(tier.points) pts").foregroundStyle(tier.color).bold()
                        }
                    }
                }
            }
            .navigationTitle("Pirate's Code")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: DiveResult.self, inMemory: true)
}
