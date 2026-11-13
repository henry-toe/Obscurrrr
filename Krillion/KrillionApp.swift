import SwiftUI
import SwiftData

@main
struct KrillionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Persistent Data Storage: SwiftData saves every finished dive on-device.
        .modelContainer(for: DiveResult.self)
    }
}

/// Root of the app. For now the app opens straight to the home screen; the
/// Captain's Log (history) and Settings open from buttons on it.
/// TODO: switch back to a TabView once the other screens are themed.
struct ContentView: View {
    var body: some View {
        HomeView()
            .tint(Theme.treasureRed)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DiveResult.self, inMemory: true)
}
