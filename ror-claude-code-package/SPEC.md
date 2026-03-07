# Rules of the Road - SwiftUI App Specification
## For Claude Code / Xcode Development

---

## PROJECT OVERVIEW

A native iOS study app for the SWOS Advanced Shiphandling Course Rules of the Road exam. Contains 1,272 questions, 87 embedded diagrams, spaced repetition, rule references, and quiz simulation. Target: App Store at $0.99.

**Bundle ID:** com.yourname.ror-study (replace with your actual bundle ID)
**Minimum iOS:** 17.0
**Orientation:** Portrait only
**Device:** iPhone (iPad compatible via scaling)

---

## DATA FILES (included in /data directory)

### questions.json
Array of 1,272 question objects:
```json
{
  "id": 1,
  "cat": "INLAND",           // "INLAND", "INTERNATIONAL", or "BOTH"
  "q": "INLAND ONLY You are navigating...",
  "a": "Answer choice A text",
  "b": "Answer choice B text",
  "c": "Answer choice C text",
  "d": "Answer choice D text",
  "ans": "A",                 // Correct answer: "A", "B", "C", or "D"
  "diag": "DIAGRAM 23",       // Diagram reference string, or empty ""
  "rule": "Rule 9"            // Mapped COLREGS/Inland rule, or empty ""
}
```

### rules.json
Dictionary of rule definitions:
```json
{
  "Rule 1": {
    "title": "Application",
    "part": "A - General",
    "summary": "These Rules apply to all vessels...",
    "keywords": ["application", "inland waters", ...]
  },
  ...
}
```

### diagrams/ (87 JPEG files)
Individual diagram images: `diagram_1.jpg` through `diagram_87.jpg`
Add all to asset catalog or app bundle.

### swsc_logo.jpg
Surface Warfare Schools Command logo (300x300). Use for app icon base and in-app branding.

---

## APP ARCHITECTURE

### SwiftUI Views

```
RoRApp (main entry)
  TabView (5 tabs)
    HomeView
      - Quick stats row (studied, accuracy, missed, bookmarked)
      - Question of the Day card
      - Quick action buttons (Study, Quiz, Drill Missed, Diagrams)
    StudyView
      - Filter pills (All, Both, Inland, Int'l, Bookmarked, Missed)
      - Rule reference toggle
      - QuestionCardView with spaced repetition
      - Navigation controls (prev/next with progress bar)
    QuizView
      - QuizSetupView (question count, category filter)
      - QuizQuestionView (question card, navigation, submit)
      - QuizResultsView (score, pass/fail, answer review)
    DiagramBrowserView
      - LazyVGrid of diagram thumbnails
      - Full-screen diagram viewer on tap (zoomable)
    StatsView
      - Overall stats cards
      - Spaced repetition box breakdown
      - Category accuracy breakdown
      - Missed questions list with drill button
      - Reset progress button
```

### Shared Components

```
QuestionCardView
  - Question number, category badge, bookmark button
  - Question text
  - DiagramView (if question references a diagram)
  - AnswerOptionsView (4 choices with tap-to-select)
  - RuleReferenceCard (expandable, shown after answering)

DiagramView
  - Show/hide toggle
  - Image display with tap-to-zoom
  - Full-screen modal with pinch zoom

RuleReferenceCard
  - Collapsible card showing rule number, title, part, summary
  - Green accent color to distinguish from question content
```

### Data Models

```swift
struct Question: Codable, Identifiable {
    let id: Int
    let cat: String        // "INLAND", "INTERNATIONAL", "BOTH"
    let q: String          // Question text
    let a: String          // Choice A
    let b: String          // Choice B
    let c: String          // Choice C
    let d: String          // Choice D
    let ans: String        // Correct answer letter
    let diag: String       // Diagram reference or ""
    let rule: String       // Rule reference or ""
}

struct RuleInfo: Codable {
    let title: String
    let part: String
    let summary: String
    let keywords: [String]
}

struct AnswerRecord: Codable {
    let yours: String      // User's answer letter
    let correct: String    // Correct answer letter
    let right: Bool        // Was it correct
}

struct SRState: Codable {
    var box: Int           // 0-4 (Leitner box)
    var lastSeen: Date
    var nextDue: Date
}

struct QuizSession: Codable {
    var questions: [Int]   // Question IDs
    var answers: [Int: String] // questionId -> answer letter
    var currentIndex: Int
    var isComplete: Bool
}
```

### State Management

```swift
@Observable
class StudyStore {
    var answered: [Int: AnswerRecord] = [:]
    var bookmarked: Set<Int> = []
    var srState: [Int: SRState] = [:]
    var showRuleRef: Bool = true
    var theme: AppTheme = .dark
    
    // Persistence via UserDefaults or @AppStorage
    // Later: Supabase sync
    
    func answerQuestion(id: Int, yours: String, correct: String) {
        let right = yours == correct
        answered[id] = AnswerRecord(yours: yours, correct: correct, right: right)
        updateSR(id: id, correct: right)
        save()
    }
    
    func updateSR(id: Int, correct: Bool) {
        var sr = srState[id] ?? SRState(box: 0, lastSeen: .now, nextDue: .now)
        sr.box = correct ? min(sr.box + 1, 4) : 0
        let intervals: [TimeInterval] = [0, 86400, 259200, 604800, 1209600]
        sr.lastSeen = .now
        sr.nextDue = .now.addingTimeInterval(intervals[sr.box])
        srState[id] = sr
    }
    
    func studyPool(from questions: [Question]) -> [Question] {
        let now = Date()
        let due = questions.filter { q in
            let sr = srState[q.id] ?? SRState(box: 0, lastSeen: .distantPast, nextDue: .distantPast)
            return sr.nextDue <= now || sr.box == 0
        }.sorted { a, b in
            let sa = srState[a.id]?.box ?? 0
            let sb = srState[b.id]?.box ?? 0
            return sa < sb
        }
        return due.isEmpty ? questions.shuffled() : due
    }
}
```

---

## DESIGN SYSTEM

### Color Palette (support light/dark themes)

```swift
extension Color {
    // Dark theme
    static let navyPrimary = Color(hex: "#060d18")
    static let navyCard = Color(hex: "#0d1a2d")
    static let navyElevated = Color(hex: "#132040")
    
    // Accent colors (same in both themes)
    static let gold = Color(hex: "#c9a84c")
    static let goldDim = Color(hex: "#8a7333")
    static let seaGreen = Color(hex: "#2eaa7a")
    static let portRed = Color(hex: "#e05545")
    
    // Semantic
    static let correctGreen = Color(hex: "#2ecc71")
    static let incorrectRed = Color(hex: "#e74c3c")
}
```

### Typography
- Headers: Georgia or New York (serif, system)
- Body/Questions: System serif
- Mono/Labels: SF Mono or system monospaced
- UI: System default (SF Pro)

### Category Badge Colors
- INLAND: Sea green background, green text
- INTERNATIONAL: Red background, red text
- BOTH: Gold background, gold text

### Spaced Repetition Box Colors
- Box 0 (New/Reset): Red tint
- Box 1 (Learning): Orange tint
- Box 2 (Familiar): Yellow tint
- Box 3 (Confident): Green tint
- Box 4 (Mastered): Teal tint

---

## FEATURE DETAILS

### Question of the Day
- Deterministic: seed Random with year*10000 + month*100 + day
- Same question for all users on a given day
- Prioritize: missed questions first, then unseen, then random
- Track whether today's QOTD has been answered

### Spaced Repetition (Leitner System)
- 5 boxes: 0 through 4
- New questions start at Box 0
- Correct answer moves up one box
- Wrong answer resets to Box 0
- Intervals: Box 0 = immediate, Box 1 = 1 day, Box 2 = 3 days, Box 3 = 7 days, Box 4 = 14 days
- Study queue prioritizes: lowest box first, then oldest lastSeen
- If no questions are due, serve a shuffled sample

### Quiz Mode
- Configurable: 10-100 questions, category filter
- 90% passing threshold (matches SWOS standard)
- Progress tracking during quiz
- Submit with unanswered warning
- Results: pass/fail, percentage, per-question review with rule citations
- Quiz answers also update SR state and answered records

### Rule Reference Cards
- Shown after answering in Study mode and QOTD
- Toggle on/off globally
- Expandable/collapsible per question
- Shows: Rule number, title, part, and summary text
- Styled with green accent to distinguish from question content
- Also shown in quiz results review

### Diagram Display
- Inline with questions that reference them
- Show/hide toggle per question
- Tap to open full-screen zoomable viewer
- Dedicated Diagrams tab with grid browser
- Parse diagram number from question's diag field (e.g., "DIAGRAM 23" -> 23)

### Persistence
- Phase 1 (this weekend): UserDefaults / @AppStorage
- Phase 2: Supabase integration for cloud sync and user accounts

---

## SUPABASE SCHEMA (Phase 2)

```sql
-- Users table (handled by Supabase Auth)

-- User progress
CREATE TABLE user_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  question_id INT NOT NULL,
  yours TEXT NOT NULL,
  correct TEXT NOT NULL,
  is_right BOOLEAN NOT NULL,
  sr_box INT DEFAULT 0,
  sr_last_seen TIMESTAMPTZ,
  sr_next_due TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, question_id)
);

-- Bookmarks
CREATE TABLE bookmarks (
  user_id UUID REFERENCES auth.users NOT NULL,
  question_id INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, question_id)
);

-- Quiz history
CREATE TABLE quiz_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  score_pct INT NOT NULL,
  correct_count INT NOT NULL,
  total_count INT NOT NULL,
  passed BOOLEAN NOT NULL,
  category_filter TEXT,
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS policies
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own progress" ON user_progress
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own bookmarks" ON bookmarks
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own quiz history" ON quiz_history
  FOR ALL USING (auth.uid() = user_id);
```

---

## BUILD CHECKLIST

### This Weekend (v1.0 - TestFlight)
- [ ] Create Xcode project with SwiftUI
- [ ] Import question data (questions.json)
- [ ] Import diagram images (87 JPEGs into asset catalog)
- [ ] Import rules data (rules.json)
- [ ] Build all 5 tab views
- [ ] Implement QuestionCardView with answer selection
- [ ] Implement diagram inline display and zoom viewer
- [ ] Implement spaced repetition logic
- [ ] Implement rule reference cards with toggle
- [ ] Implement Question of the Day
- [ ] Implement quiz mode with results
- [ ] Implement stats view
- [ ] Light/dark theme support
- [ ] UserDefaults persistence
- [ ] App icon from SWSC logo
- [ ] TestFlight build and submit

### Post-Launch (v1.1+)
- [ ] Supabase auth integration
- [ ] Cloud sync for progress
- [ ] Add 10 Raynor-unique questions
- [ ] Improve rule mapping accuracy
- [ ] Timed quiz mode
- [ ] Study streak tracking
- [ ] App Store submission at $0.99

---

## NOTES FOR CLAUDE CODE

1. All data files are in the /data directory. Load questions.json and rules.json at app startup using Bundle.main.
2. Diagram images should go in the asset catalog or be loaded from the bundle by filename pattern: "diagram_\(number)".
3. The question text includes a category prefix like "BOTH INTERNATIONAL & INLAND " that is redundant with the `cat` field. Keep it in the display text since the user wants it for reinforcement.
4. The `diag` field contains strings like "DIAGRAM 23" or "DIAGRAM 47 AND DIAGRAM 48". Parse out the numbers to load the correct images.
5. The `rule` field contains strings like "Rule 9" or "Rule 34" or "Annex V". Use this as a key into rules.json.
6. For the navy/gold aesthetic, reference the color palette above. The app should feel professional and military, not generic.
7. Prioritize getting all features working over visual polish. Polish can happen in v1.1.
