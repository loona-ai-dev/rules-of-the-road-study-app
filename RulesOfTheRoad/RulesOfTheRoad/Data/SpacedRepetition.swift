import Foundation

// MARK: - Spaced Repetition Engine (Leitner System)

struct SpacedRepetition {

    static let boxCount = 5

    // Box intervals in seconds
    static let intervals: [TimeInterval] = [
        0,          // Box 0: immediately (new/reset)
        86400,      // Box 1: 1 day
        259200,     // Box 2: 3 days
        604800,     // Box 3: 7 days
        1209600     // Box 4: 14 days
    ]

    static let boxNames = ["New", "Learning", "Familiar", "Confident", "Mastered"]

    // MARK: - Update SR State After Answer

    static func updateState(_ state: SRState, correct: Bool) -> SRState {
        var newState = state
        newState.lastSeen = Date()

        if correct {
            let newBox = min(state.box + 1, boxCount - 1)
            newState.box = newBox
            newState.nextDue = Date().addingTimeInterval(intervals[newBox])
        } else {
            newState.box = 0
            newState.nextDue = Date()  // immediately available
        }

        return newState
    }

    // MARK: - Build Study Pool

    static func buildStudyPool(
        questions: [Question],
        srStates: [Int: SRState],
        filter: StudyFilter,
        progress: UserProgress,
        maxCount: Int = 50
    ) -> [Question] {
        let filtered = applyFilter(questions, filter: filter, progress: progress)

        // Split into due and not-due
        let due = filtered.filter { q in
            let state = srStates[q.id] ?? SRState.initial()
            return state.isDue
        }

        let notDue = filtered.filter { q in
            let state = srStates[q.id] ?? SRState.initial()
            return !state.isDue
        }

        // Sort due: lowest box first, then oldest lastSeen
        let sortedDue = due.sorted { a, b in
            let sa = srStates[a.id] ?? SRState.initial()
            let sb = srStates[b.id] ?? SRState.initial()
            if sa.box != sb.box { return sa.box < sb.box }
            return sa.lastSeen < sb.lastSeen
        }

        if sortedDue.count >= maxCount {
            return Array(sortedDue.prefix(maxCount))
        }

        // Pad with shuffled not-due if needed
        let remaining = maxCount - sortedDue.count
        let padding = Array(notDue.shuffled().prefix(remaining))

        return sortedDue + padding
    }

    // MARK: - Apply Filter

    static func applyFilter(
        _ questions: [Question],
        filter: StudyFilter,
        progress: UserProgress
    ) -> [Question] {
        switch filter {
        case .all:
            return questions
        case .both:
            return questions.filter { $0.cat.uppercased() == "BOTH" }
        case .inland:
            return questions.filter { $0.cat.uppercased() == "INLAND" }
        case .international:
            return questions.filter { $0.cat.uppercased() == "INTERNATIONAL" }
        case .bookmarked:
            return questions.filter { progress.bookmarked.contains($0.id) }
        case .missed:
            return questions.filter { progress.isMissed($0.id) }
        }
    }

    // MARK: - Box Statistics

    static func boxCounts(questions: [Question], srStates: [Int: SRState]) -> [Int: Int] {
        var counts: [Int: Int] = [0: 0, 1: 0, 2: 0, 3: 0, 4: 0]
        for q in questions {
            let box = srStates[q.id]?.box ?? 0
            counts[box, default: 0] += 1
        }
        return counts
    }

    // MARK: - Progress Percentage

    static func masteryPercentage(questions: [Question], srStates: [Int: SRState]) -> Double {
        guard !questions.isEmpty else { return 0 }
        let mastered = questions.filter { (srStates[$0.id]?.box ?? 0) >= 3 }.count
        return Double(mastered) / Double(questions.count) * 100
    }

    // MARK: - Question of the Day

    static func questionOfTheDay(from questions: [Question], progress: UserProgress) -> Question? {
        let dateKey = QOTD.dateKey()

        // If we've already picked a QOTD today, return that same question
        if let id = progress.qotdHistory[dateKey],
           let q = questions.first(where: { $0.id == id }) {
            return q
        }

        // Priority: missed → unseen → deterministic random
        let missed = questions.filter { progress.isMissed($0.id) }
        if !missed.isEmpty {
            let seed = QOTD.questionId(from: missed)
            return missed.first { $0.id == seed } ?? missed.first
        }

        let unseen = questions.filter { !progress.hasAnswered($0.id) }
        if !unseen.isEmpty {
            let seed = QOTD.questionId(from: unseen)
            return unseen.first { $0.id == seed } ?? unseen.first
        }

        let id = QOTD.questionId(from: questions)
        return questions.first { $0.id == id }
    }
}
