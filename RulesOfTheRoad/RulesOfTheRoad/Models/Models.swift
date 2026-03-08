import Foundation

// MARK: - Question

struct Question: Codable, Identifiable, Hashable {
    let id: Int
    let cat: String       // "INLAND", "INTERNATIONAL", "BOTH"
    let q: String         // Question text
    let a: String
    let b: String
    let c: String
    let d: String
    let ans: String       // "A", "B", "C", "D"
    let diag: String      // "DIAGRAM 23" or "" or "DIAGRAM 47 AND 48"
    let rule: String      // "Rule 9", "Rule 34", "Annex V", etc.

    var answers: [String: String] {
        ["A": a, "B": b, "C": c, "D": d]
    }

    var answersOrdered: [(key: String, value: String)] {
        [("A", a), ("B", b), ("C", c), ("D", d)]
    }

    var diagramNumbers: [Int] {
        guard !diag.isEmpty else { return [] }
        // Parse "DIAGRAM 23" or "DIAGRAM 47 AND 48" or "DIAGRAM 47 AND DIAGRAM 48"
        let numbers = diag.components(separatedBy: .whitespaces)
            .compactMap { Int($0) }
        return numbers
    }

    var hasDiagram: Bool { !diag.isEmpty }

    func category() -> QuestionCategory {
        QuestionCategory(rawValue: cat.uppercased()) ?? .both
    }
}

// MARK: - Question Category

enum QuestionCategory: String, CaseIterable {
    case inland       = "INLAND"
    case international = "INTERNATIONAL"
    case both         = "BOTH"

    var displayName: String {
        switch self {
        case .inland: return "Inland"
        case .international: return "International"
        case .both: return "Both"
        }
    }
}

// MARK: - Study Filter

enum StudyFilter: String, CaseIterable {
    case all          = "ALL"
    case both         = "BOTH"
    case inland       = "INLAND"
    case international = "INTERNATIONAL"
    case bookmarked   = "BOOKMARKED"
    case missed       = "MISSED"

    var displayName: String {
        switch self {
        case .all: return "All"
        case .both: return "Both"
        case .inland: return "Inland"
        case .international: return "Intl"
        case .bookmarked: return "Bookmarked"
        case .missed: return "Missed"
        }
    }
}

// MARK: - Rule Info

struct RuleInfo: Codable {
    let title: String
    let part: String
    let summary: String
    let keywords: [String]
}

// MARK: - Answer Record

struct AnswerRecord: Codable {
    let yours: String     // User's chosen letter
    let correct: String   // Correct answer letter
    let right: Bool       // Was user correct
    let timestamp: Date

    init(yours: String, correct: String) {
        self.yours = yours
        self.correct = correct
        self.right = yours == correct
        self.timestamp = Date()
    }
}

// MARK: - Spaced Repetition State

struct SRState: Codable {
    var box: Int          // 0-4 (Leitner box)
    var lastSeen: Date
    var nextDue: Date

    static let intervals: [TimeInterval] = [
        0,                    // Box 0: immediately
        86400,                // Box 1: 1 day
        259200,               // Box 2: 3 days
        604800,               // Box 3: 7 days
        1209600               // Box 4: 14 days
    ]

    var isDue: Bool {
        Date() >= nextDue
    }

    static func initial() -> SRState {
        SRState(box: 0, lastSeen: .distantPast, nextDue: Date())
    }
}

// MARK: - Quiz Result

struct QuizResult: Identifiable {
    let id = UUID()
    let questions: [Question]
    let answers: [Int: String]      // questionId -> chosen letter
    let date: Date

    var score: Int {
        questions.filter { q in answers[q.id] == q.ans }.count
    }

    var total: Int { questions.count }
    var percentage: Double { total > 0 ? Double(score) / Double(total) * 100 : 0 }
    var passed: Bool { percentage >= 90 }

    func result(for question: Question) -> QuizAnswerResult {
        let chosen = answers[question.id]
        return QuizAnswerResult(
            question: question,
            chosen: chosen,
            correct: question.ans,
            isCorrect: chosen == question.ans
        )
    }
}

struct QuizAnswerResult {
    let question: Question
    let chosen: String?
    let correct: String
    let isCorrect: Bool
    var isUnanswered: Bool { chosen == nil }
}

// MARK: - User Progress

struct UserProgress: Codable {
    // Answer history: questionId -> [AnswerRecord]
    var answered: [Int: [AnswerRecord]] = [:]

    // Bookmarks
    var bookmarked: Set<Int> = []

    // Spaced repetition state
    var srStates: [Int: SRState] = [:]

    // Question of the Day tracking
    var qotdHistory: [String: Int] = [:]   // "YYYY-MM-DD" -> questionId

    // Session stats
    var totalStudied: Int = 0
    var quizCount: Int = 0
    var quizPassed: Int = 0
    var studyStreak: Int = 0
    var lastStudyDate: Date?

    mutating func recordAnswer(questionId: Int, yours: String, correct: String) {
        let record = AnswerRecord(yours: yours, correct: correct)
        if answered[questionId] == nil {
            answered[questionId] = []
        }
        answered[questionId]?.append(record)
        totalStudied += 1
    }

    func latestAnswer(for questionId: Int) -> AnswerRecord? {
        answered[questionId]?.last
    }

    func hasAnswered(_ questionId: Int) -> Bool {
        !(answered[questionId]?.isEmpty ?? true)
    }

    func isMissed(_ questionId: Int) -> Bool {
        guard let records = answered[questionId], !records.isEmpty else { return false }
        return records.last?.right == false
    }

    func accuracy(for questionIds: [Int]) -> Double {
        let answered = questionIds.compactMap { self.answered[$0]?.last }
        guard !answered.isEmpty else { return 0 }
        let correct = answered.filter { $0.right }.count
        return Double(correct) / Double(answered.count) * 100
    }

    var overallAccuracy: Double {
        let allAnswers = answered.values.compactMap { $0.last }
        guard !allAnswers.isEmpty else { return 0 }
        let correct = allAnswers.filter { $0.right }.count
        return Double(correct) / Double(allAnswers.count) * 100
    }

    var missedCount: Int {
        answered.values.filter { ($0.last?.right == false) }.count
    }

    var studiedCount: Int {
        answered.count
    }
}

// MARK: - QOTD

struct QOTD {
    static func questionId(from questions: [Question], for date: Date = Date()) -> Int {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month, .day], from: date)
        let seed = (components.year ?? 2025) * 10000 + (components.month ?? 1) * 100 + (components.day ?? 1)
        let index = seed % questions.count
        return questions[index].id
    }

    static func dateKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
