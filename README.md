# Krillion — The Daily Dive (iOS)

A SwiftUI take on the web game [krillion.io](https://krillion.io): 7 prompts a day, 25 seconds each.
A correct answer scores points, and a rarer one scores more. Your depth is points × 10, so a perfect dive reaches 7,000 m.

## Open & run
1. Unzip, then double-click `Krillion.xcodeproj` (needs Xcode 16 or newer).
2. Choose the **iPhone 16 Pro Max** simulator and press **⌘R**.
3. To run on a real phone, go to Target → Signing & Capabilities and pick your Team.

The source files sit in the `Krillion/` folder, which Xcode syncs automatically. Any `.swift` file you add there is compiled with no extra setup.

## Project layout
```
Krillion/
├─ KrillionApp.swift        app entry, SwiftData container, TabView
├─ Theme/Theme.swift        colour palette, card + button styles
├─ Models/
│  ├─ Question.swift        Question + AnswerRecord structs
│  ├─ RarityTier.swift      6 rarity tiers (10–100 pts)
│  ├─ DiveResult.swift      @Model saved with SwiftData
│  └─ QuestionBank.swift    14 prompts, date-seeded daily pick
├─ Services/RarityService.swift   Datamuse Web API call
├─ ViewModels/DiveViewModel.swift game loop, timer, scoring
└─ Views/                   Home, Dive, Results, History (Logbook), Settings
```

## Rubric checklist
| Item | Where |
|---|---|
| 3 Screens | Home, Dive, Results, Logbook (+detail), Settings, Rules sheet |
| 3 Colors | `Theme`: abyss (navy), lagoon (teal), krill (coral), foam (text) |
| 3 Data Types | `String`, `Int`, `Double`, `Bool`, `Date`, `enum RarityTier`, `struct Question` |
| 3 GUI Objects | TextField, Button, ProgressView, Picker (segmented + menu), Toggle, List, ShareLink, Link |
| Web API | `RarityService` calls `api.datamuse.com` for word frequency, which sets the rarity tier |
| Persistent Storage | SwiftData `DiveResult` (dive history) + `@AppStorage` (settings) |
| User Experience | Countdown ring, instant feedback card, share-able emoji summary |
| Usefulness | Daily vocabulary/trivia practice with a history of your progress |

## Next steps / TODO
- Load questions from a remote JSON file instead of `QuestionBank.all`.
- Add more prompts, and add synonyms/aliases to the answer lists.
- Add a streak counter, haptics, sounds and an app icon.
- Add a depth "ocean" animation that changes colour as you go deeper.
