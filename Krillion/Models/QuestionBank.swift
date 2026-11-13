import Foundation

/// Local question bank. The Daily Dive picks 7 questions using the date as a seed,
/// so every player gets the same set on the same day.
/// TODO: replace/extend with questions loaded from a remote JSON file.
enum QuestionBank {
    static let questionsPerDive = 7

    static func daily(for date: Date = .now) -> [Question] {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        var rng = SeededGenerator(seed: UInt64(day))
        return Array(all.shuffled(using: &rng).prefix(questionsPerDive))
    }

    static func practice() -> [Question] {
        Array(all.shuffled().prefix(questionsPerDive))
    }

    /// Picks a set from an explicit seed. Multiplayer rounds share one seed so
    /// every player in the lobby gets the same questions in the same order.
    static func seeded(_ seed: UInt64) -> [Question] {
        var rng = SeededGenerator(seed: seed)
        return Array(all.shuffled(using: &rng).prefix(questionsPerDive))
    }

    static let all: [Question] = [
        Question(id: 1, category: "Animals", prompt: "Name a farm animal",
                 validAnswers: ["Cow", "Pig", "Chicken", "Sheep", "Goat", "Horse", "Duck", "Turkey",
                                "Donkey", "Llama", "Alpaca", "Rabbit", "Goose", "Mule", "Ox", "Yak",
                                "Water buffalo", "Guinea fowl", "Emu", "Ostrich", "Bee"]),
        Question(id: 2, category: "Tech", prompt: "Name a web browser",
                 validAnswers: ["Chrome", "Safari", "Firefox", "Edge", "Opera", "Brave", "Vivaldi",
                                "Internet Explorer", "Arc", "Tor", "Lynx", "Netscape", "Mosaic",
                                "Konqueror", "Midori", "WorldWideWeb", "Chromium", "DuckDuckGo"]),
        Question(id: 3, category: "Geography", prompt: "Name a country in Africa",
                 validAnswers: ["Egypt", "Nigeria", "Kenya", "South Africa", "Ethiopia", "Morocco",
                                "Ghana", "Algeria", "Tanzania", "Uganda", "Senegal", "Madagascar",
                                "Rwanda", "Namibia", "Botswana", "Zimbabwe", "Zambia", "Mali",
                                "Chad", "Niger", "Sudan", "Libya", "Tunisia", "Angola", "Cameroon",
                                "Eritrea", "Djibouti", "Lesotho", "Eswatini", "Comoros", "Gabon",
                                "Benin", "Togo", "Malawi", "Mozambique", "Somalia", "Burundi",
                                "Liberia", "Sierra Leone", "Gambia", "Guinea", "Mauritania",
                                "Cape Verde", "Seychelles", "Mauritius"]),
        Question(id: 4, category: "Tech", prompt: "Name a programming language",
                 validAnswers: ["Python", "Java", "JavaScript", "Swift", "C", "C++", "C#", "Go",
                                "Rust", "Kotlin", "Ruby", "PHP", "TypeScript", "Haskell", "Lisp",
                                "Scala", "Perl", "Fortran", "COBOL", "Pascal", "Erlang", "Elixir",
                                "Clojure", "Lua", "Julia", "Dart", "Prolog", "Ada", "Zig", "OCaml"]),
        Question(id: 5, category: "Food", prompt: "Name a type of pasta",
                 validAnswers: ["Spaghetti", "Penne", "Macaroni", "Fettuccine", "Linguine",
                                "Lasagna", "Ravioli", "Rigatoni", "Fusilli", "Farfalle", "Tortellini",
                                "Orzo", "Gnocchi", "Ziti", "Rotini", "Orecchiette", "Bucatini",
                                "Pappardelle", "Tagliatelle", "Cavatappi", "Ditalini", "Conchiglie"]),
        Question(id: 6, category: "Animals", prompt: "Name a dog breed",
                 validAnswers: ["Labrador", "Poodle", "Bulldog", "Beagle", "Chihuahua", "Pug",
                                "Husky", "Dachshund", "Rottweiler", "Boxer", "Corgi", "Shih Tzu",
                                "Golden Retriever", "German Shepherd", "Dalmatian", "Greyhound",
                                "Pomeranian", "Akita", "Basenji", "Vizsla", "Weimaraner",
                                "Saluki", "Komondor", "Puli", "Borzoi", "Whippet", "Samoyed"]),
        Question(id: 7, category: "Music", prompt: "Name a musical instrument",
                 validAnswers: ["Piano", "Guitar", "Drums", "Violin", "Flute", "Trumpet",
                                "Saxophone", "Cello", "Clarinet", "Harp", "Ukulele", "Banjo",
                                "Trombone", "Tuba", "Oboe", "Bassoon", "Harmonica", "Accordion",
                                "Sitar", "Theremin", "Didgeridoo", "Bagpipes", "Xylophone",
                                "Marimba", "Erhu", "Koto", "Oud", "Hurdy-gurdy", "Glockenspiel"]),
        Question(id: 8, category: "Food", prompt: "Name a fruit",
                 validAnswers: ["Apple", "Banana", "Orange", "Grape", "Strawberry", "Mango",
                                "Pineapple", "Watermelon", "Peach", "Pear", "Cherry", "Kiwi",
                                "Lemon", "Lime", "Plum", "Papaya", "Guava", "Lychee", "Durian",
                                "Rambutan", "Persimmon", "Jackfruit", "Pomegranate", "Quince",
                                "Kumquat", "Mangosteen", "Starfruit", "Dragon fruit", "Feijoa"]),
        Question(id: 9, category: "Geography", prompt: "Name a U.S. state",
                 validAnswers: ["California", "Texas", "Florida", "New York", "Alabama", "Alaska",
                                "Arizona", "Arkansas", "Colorado", "Connecticut", "Delaware",
                                "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa",
                                "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland",
                                "Massachusetts", "Michigan", "Minnesota", "Mississippi",
                                "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
                                "New Jersey", "New Mexico", "North Carolina", "North Dakota",
                                "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
                                "South Carolina", "South Dakota", "Tennessee", "Utah", "Vermont",
                                "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"]),
        Question(id: 10, category: "Ocean", prompt: "Name a sea creature",
                 validAnswers: ["Shark", "Whale", "Dolphin", "Octopus", "Squid", "Jellyfish",
                                "Starfish", "Crab", "Lobster", "Shrimp", "Krill", "Seahorse",
                                "Clam", "Oyster", "Eel", "Stingray", "Manatee", "Walrus", "Seal",
                                "Narwhal", "Nudibranch", "Anglerfish", "Cuttlefish", "Sea urchin",
                                "Sea cucumber", "Barnacle", "Coral", "Anemone", "Lamprey",
                                "Hagfish", "Dugong", "Orca", "Swordfish", "Marlin"]),
        Question(id: 11, category: "Science", prompt: "Name a chemical element",
                 validAnswers: ["Hydrogen", "Helium", "Oxygen", "Carbon", "Nitrogen", "Gold",
                                "Silver", "Iron", "Copper", "Sodium", "Calcium", "Neon", "Lead",
                                "Uranium", "Zinc", "Mercury", "Aluminum", "Silicon", "Lithium",
                                "Potassium", "Platinum", "Tungsten", "Titanium", "Argon",
                                "Bismuth", "Gallium", "Osmium", "Yttrium", "Hafnium", "Tellurium",
                                "Ruthenium", "Rhodium", "Krypton", "Xenon", "Radon"]),
        Question(id: 12, category: "Games", prompt: "Name a board game",
                 validAnswers: ["Monopoly", "Chess", "Checkers", "Scrabble", "Clue", "Risk",
                                "Catan", "Sorry", "Trouble", "Battleship", "Backgammon", "Go",
                                "Mahjong", "Pandemic", "Ticket to Ride", "Carcassonne",
                                "Stratego", "Othello", "Mancala", "Parcheesi", "Twister",
                                "Candy Land", "Operation", "Azul", "Wingspan", "Gloomhaven"]),
        Question(id: 13, category: "Colors", prompt: "Name a shade of blue",
                 validAnswers: ["Navy", "Sky blue", "Royal blue", "Baby blue", "Teal", "Turquoise",
                                "Cyan", "Azure", "Cobalt", "Sapphire", "Indigo", "Cerulean",
                                "Ultramarine", "Periwinkle", "Aquamarine", "Denim", "Steel blue",
                                "Prussian blue", "Powder blue", "Cornflower"]),
        Question(id: 14, category: "Space", prompt: "Name something in our solar system",
                 validAnswers: ["Sun", "Moon", "Mercury", "Venus", "Earth", "Mars", "Jupiter",
                                "Saturn", "Uranus", "Neptune", "Pluto", "Ceres", "Eris",
                                "Haumea", "Makemake", "Titan", "Europa", "Io", "Ganymede",
                                "Callisto", "Enceladus", "Triton", "Phobos", "Deimos", "Charon",
                                "Vesta", "Oort cloud", "Kuiper belt", "Asteroid belt"]),
    ]
}

/// Tiny deterministic random generator (SplitMix64) so the daily set is stable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
