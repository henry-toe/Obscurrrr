import SwiftUI
import SwiftData

/// Screen 3: the logbook of every saved dive (read from SwiftData).
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DiveResult.date, order: .reverse) private var results: [DiveResult]

    // GUI object: segmented picker to filter the list
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", daily = "Daily", practice = "Practice"
        var id: Self { self }
    }

    private var filtered: [DiveResult] {
        switch filter {
        case .all: results
        case .daily: results.filter { !$0.isPractice }
        case .practice: results.filter(\.isPractice)
        }
    }

    private var averageDepth: Int {
        guard !filtered.isEmpty else { return 0 }
        return filtered.map(\.depthMeters).reduce(0, +) / filtered.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        StatBlock(title: "Average depth", value: "\(averageDepth) m")
                        Spacer()
                        StatBlock(title: "Deepest", value: "\(filtered.map(\.depthMeters).max() ?? 0) m")
                    }
                }

                Section("Dives") {
                    if filtered.isEmpty {
                        ContentUnavailableView("No dives yet",
                                               systemImage: "water.waves",
                                               description: Text("Finish a dive and it will show up here."))
                    }
                    ForEach(filtered) { result in
                        NavigationLink {
                            DiveDetailView(result: result)
                        } label: {
                            DiveRow(result: result)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.abyss)
            .navigationTitle("Logbook")
        }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(filtered[i]) }
        try? context.save()
    }
}

struct DiveRow: View {
    let result: DiveResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                Text(result.answers.map { $0.tier?.emoji ?? "❌" }.joined())
                    .font(.caption)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(result.depthMeters) m").bold().foregroundStyle(Theme.lagoon)
                if result.isPractice {
                    Text("Practice").font(.caption2).foregroundStyle(Theme.krill)
                }
            }
        }
    }
}

struct DiveDetailView: View {
    let result: DiveResult

    var body: some View {
        ZStack {
            Theme.oceanGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("\(result.depthMeters) m")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.foam)
                    Text("\(result.correctCount)/\(result.answers.count) correct · avg \(String(format: "%.1f", result.averageSeconds))s per answer")
                        .foregroundStyle(Theme.foam.opacity(0.7))
                    AnswerList(records: result.answers)
                }
                .padding()
            }
        }
        .navigationTitle(result.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: DiveResult.self, inMemory: true)
        .preferredColorScheme(.dark)
}
