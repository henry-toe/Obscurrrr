import SwiftUI

/// Pirate colour palette (rubric: 3 Colors). Everything visual pulls from here,
/// so the look can be changed in one place. The colours match the app icon.
enum Theme {
    // MARK: Pirate palette
    /// Old treasure-map paper. Main light background.
    static let parchment = Color(red: 0.96, green: 0.89, blue: 0.73)
    /// Darker, "burnt" paper edge.
    static let parchmentDark = Color(red: 0.85, green: 0.69, blue: 0.47)
    /// The red X that marks the spot. Main buttons and highlights.
    static let treasureRed = Color(red: 0.75, green: 0.15, blue: 0.18)
    /// Steel-blue sea, like the shovel. Secondary buttons and the game background.
    static let deepSea = Color(red: 0.18, green: 0.33, blue: 0.40)
    /// Shovel-handle wood brown. Borders and ink-style text.
    static let wood = Color(red: 0.42, green: 0.20, blue: 0.10)

    // MARK: Older names kept so the other screens still compile
    static let abyss = Color(red: 0.08, green: 0.16, blue: 0.21)
    static let lagoon = deepSea
    static let krill = treasureRed
    static let foam = parchment

    /// Dark sea gradient used behind the game screens.
    static let oceanGradient = LinearGradient(
        colors: [deepSea, abyss],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Warm paper gradient used behind the home screen.
    static let parchmentGradient = LinearGradient(
        colors: [parchment, parchmentDark],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Font used for pirate headings.
    static func pirateFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }
}

/// Reusable rounded "glass" card used on the dark game screens.
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

/// Paper card with a wooden border, used on the home screen.
struct ParchmentCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.parchment, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.wood.opacity(0.6), lineWidth: 2)
            )
            .shadow(color: Theme.wood.opacity(0.25), radius: 6, y: 3)
    }
}

/// Big pill-shaped button style for the main actions.
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.treasureRed
    var textColor: Color = Theme.parchment

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.wood.opacity(0.5), lineWidth: 2))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }
    func parchmentCard() -> some View { modifier(ParchmentCardModifier()) }
}
