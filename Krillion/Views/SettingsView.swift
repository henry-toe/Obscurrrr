import SwiftUI
import SwiftData

/// Screen 4: preferences, saved with @AppStorage (UserDefaults).
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("secondsPerQuestion") private var secondsPerQuestion = 25
    @AppStorage("allowReplays") private var allowReplays = false

    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Gameplay") {
                    // GUI object: picker
                    Picker("Time per prompt", selection: $secondsPerQuestion) {
                        Text("15 s").tag(15)
                        Text("25 s").tag(25)
                        Text("40 s").tag(40)
                    }
                    // GUI object: toggle
                    Toggle("Allow replaying the Daily Dive", isOn: $allowReplays)
                }

                Section("Data") {
                    Button("Clear logbook", role: .destructive) { confirmClear = true }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Link("Play the original at krillion.io",
                         destination: URL(string: "https://krillion.io")!)
                    Link("Rarity data: Datamuse API",
                         destination: URL(string: "https://www.datamuse.com/api/")!)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.abyss)
            .navigationTitle("Settings")
            .confirmationDialog("Delete every saved dive?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    try? context.delete(model: DiveResult.self)
                    try? context.save()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: DiveResult.self, inMemory: true)
        .preferredColorScheme(.dark)
}
