# Rules of the Road – iOS SwiftUI App

A native iOS app for SWOS Advanced Shiphandling Course Rules of the Road exam preparation. Built with SwiftUI and glass morphism design.

## Design

- **Theme:** Dark navy glass morphism with gold accents
- **Minimum iOS:** 17.0
- **Orientation:** Portrait only
- **Architecture:** MVVM with `AppState` as central observable

---

## Project Setup (Xcode)

### 1. Create a New Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Settings:
   - Product Name: `RulesOfTheRoad`
   - Bundle Identifier: `com.swsc.rulesoftheroad`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployments: **iOS 17.0**
4. Save in any location

---

### 2. Add Source Files

Copy all `.swift` files from this folder into the Xcode project. Maintain the same folder structure:

```
RulesOfTheRoad/
├── App/
│   ├── RulesOfTheRoadApp.swift   ← Replace the default App entry
│   └── ContentView.swift          ← Replace the default ContentView
├── Design/
│   └── DesignSystem.swift
├── Models/
│   ├── Models.swift
│   └── AppState.swift
├── Data/
│   ├── DataManager.swift
│   └── SpacedRepetition.swift
└── Views/
    ├── Home/HomeView.swift
    ├── Study/StudyView.swift
    ├── Quiz/QuizView.swift
    ├── Diagrams/DiagramsView.swift
    ├── Stats/StatsView.swift
    └── Components/QuestionCard.swift
```

In Xcode: Right-click the project → **Add Files to "RulesOfTheRoad"** → select the folder, check "Create groups"

---

### 3. Add Data Files (JSON)

From `ror-claude-code-package/data/`:

1. `questions.json` → Add to project, ensure **"Add to target"** is checked
2. `rules.json` → Add to project, ensure **"Add to target"** is checked

These will be bundled as app resources and loaded at startup.

---

### 4. Add Diagram Images

From `ror-claude-code-package/data/diagrams/`:

**Option A (Recommended): Asset Catalog**
1. Open `Assets.xcassets` in Xcode
2. Create a new folder: Right-click → New Folder → name it `diagrams`
3. Drag all 87 JPEG files (`diagram_1.jpg` through `diagram_87.jpg`) into the folder
4. For each image, ensure the name in the catalog matches `diagram_1`, `diagram_2`, etc. (no extension)

**Option B: Direct Bundle**
1. Right-click project → Add Files
2. Select the entire `diagrams/` folder
3. Check "Create folder references" (yellow folder icon)
4. Update `DiagramsView.swift` to load from bundle path instead of `UIImage(named:)`

---

### 5. Add SWSC Logo

From `ror-claude-code-package/data/`:
1. Open `Assets.xcassets`
2. Drag `swsc_logo.jpg` in
3. Rename to `swsc_logo` in the catalog

---

### 6. Configure App Icons & Info.plist

In `Info.plist`, add/verify:
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
```

For App Store: Add privacy descriptions if needed (this app uses no camera/location/contacts).

---

### 7. Build & Run

- Select **iPhone 16** or any iPhone simulator (iOS 17+)
- ⌘R to build and run
- First launch loads `questions.json` (462KB) — takes ~1 second

---

## File Architecture

### Data Flow
```
DataManager (loads JSON)
    → AppState (central state, ObservableObject)
        → Views (observe via @EnvironmentObject)
```

### Persistence
- `UserDefaults` via `PersistenceManager`
- Auto-saves with 0.5s debounce after any progress change
- Key: `userProgress_v1`

### Spaced Repetition
- Leitner 5-box system
- Intervals: 0, 1, 3, 7, 14 days
- Correct → box+1; Wrong → box 0
- Study pool: lowest-box-first, oldest-seen-first

---

## App Store Submission Checklist

- [ ] Set Bundle ID to your own (e.g., `com.yourname.rulesoftheroad`)
- [ ] Add App Icons (1024×1024 for App Store)
- [ ] Create Privacy Policy URL
- [ ] Set category: Education
- [ ] Price: $0.99 (as specified)
- [ ] Add screenshots (6.7" and 6.1" required minimum)
- [ ] Age rating: 4+
- [ ] Add keywords: COLREGS, maritime, navigation, rules of the road, USCG, study

---

## Color Palette

| Token         | Hex       | Usage                    |
|---------------|-----------|--------------------------|
| `navyDeep`    | `#060d18` | Background base          |
| `navyPrimary` | `#0d1a2d` | Card backgrounds         |
| `navyElevated`| `#132040` | Elevated surfaces        |
| `gold`        | `#c9a84c` | Primary accent           |
| `seaGreen`    | `#2eaa7a` | Correct / Inland badge   |
| `portRed`     | `#e05545` | Incorrect / Intl badge   |
| `correctGreen`| `#2ecc71` | Answer correct state     |
| `incorrectRed`| `#e74c3c` | Answer wrong state       |

---

## Known Limitations / Future Work

- **Cloud Sync:** Phase 2 — Supabase integration with user accounts
- **Study Streaks:** Not yet implemented
- **Timed Quiz:** Not yet implemented
- **iPad Layout:** Works but not optimized (portrait-only enforced)
