import Foundation
import Combine
import SwiftUI

// MARK: - App State (Central Observable)

@MainActor
final class AppState: ObservableObject {

    // MARK: - Data
    let dataManager: DataManager

    // MARK: - User Progress
    @Published var progress: UserProgress {
        didSet { scheduleSave() }
    }

    // MARK: - Study State
    @Published var studyFilter: StudyFilter = .all
    @Published var studyPool: [Question] = []
    @Published var studyIndex: Int = 0
    @Published var showingRuleRef: Bool = false

    // MARK: - Quiz State
    @Published var quizState: QuizState = .setup
    @Published var quizFilter: StudyFilter = .all
    @Published var quizSize: Int = 50
    @Published var quizQuestions: [Question] = []
    @Published var quizAnswers: [Int: String] = [:]
    @Published var quizResult: QuizResult?

    // MARK: - Diagrams
    @Published var selectedDiagram: Int? = nil

    // MARK: - QOTD
    @Published var qotdQuestion: Question?
    @Published var qotdAnswered: Bool = false

    private var saveTask: Task<Void, Never>?
    private let persistence = PersistenceManager.shared

    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.progress = persistence.loadProgress()

        // Observe data loading completion
        Task { @MainActor [weak self] in
            for await questions in dataManager.$questions.values where !questions.isEmpty {
                self?.onQuestionsLoaded()
                break  // Only need to react to first non-empty load
            }
        }
    }

    // MARK: - Data Loaded

    func onQuestionsLoaded() {
        guard !dataManager.questions.isEmpty else { return }
        buildStudyPool()
        loadQOTD()
    }

    // MARK: - Study

    func buildStudyPool() {
        let questions = dataManager.questions
        studyPool = SpacedRepetition.buildStudyPool(
            questions: questions,
            srStates: progress.srStates,
            filter: studyFilter,
            progress: progress
        )
        studyIndex = 0
    }

    var currentStudyQuestion: Question? {
        guard studyIndex < studyPool.count else { return nil }
        return studyPool[studyIndex]
    }

    var currentStudyAnswer: AnswerRecord? {
        guard let q = currentStudyQuestion else { return nil }
        return progress.latestAnswer(for: q.id)
    }

    var isCurrentStudyAnswered: Bool {
        currentStudyAnswer != nil
    }

    func answerStudy(choice: String) {
        guard let q = currentStudyQuestion,
              !isCurrentStudyAnswered else { return }

        progress.recordAnswer(questionId: q.id, yours: choice, correct: q.ans)

        // Update SR
        var srState = progress.srStates[q.id] ?? SRState.initial()
        srState = SpacedRepetition.updateState(srState, correct: choice == q.ans)
        progress.srStates[q.id] = srState
    }

    func nextStudyQuestion() {
        if studyIndex < studyPool.count - 1 {
            studyIndex += 1
            showingRuleRef = false
        } else {
            buildStudyPool()
        }
    }

    func prevStudyQuestion() {
        if studyIndex > 0 {
            studyIndex -= 1
            showingRuleRef = false
        }
    }

    func changeStudyFilter(_ filter: StudyFilter) {
        studyFilter = filter
        buildStudyPool()
    }

    // MARK: - Bookmarks

    func toggleBookmark(_ questionId: Int) {
        if progress.bookmarked.contains(questionId) {
            progress.bookmarked.remove(questionId)
        } else {
            progress.bookmarked.insert(questionId)
        }
    }

    func isBookmarked(_ questionId: Int) -> Bool {
        progress.bookmarked.contains(questionId)
    }

    // MARK: - Quiz

    func startQuiz() {
        let questions = dataManager.questions
        let filtered = SpacedRepetition.applyFilter(questions, filter: quizFilter, progress: progress)
        let size = min(quizSize, filtered.count)
        quizQuestions = Array(filtered.shuffled().prefix(size))
        quizAnswers = [:]
        quizResult = nil
        quizState = .active
    }

    func answerQuiz(questionId: Int, choice: String) {
        quizAnswers[questionId] = choice
    }

    func submitQuiz() {
        let result = QuizResult(
            questions: quizQuestions,
            answers: quizAnswers,
            date: Date()
        )
        quizResult = result
        quizState = .results

        // Update progress
        progress.quizCount += 1
        if result.passed { progress.quizPassed += 1 }

        // Record answers
        for q in quizQuestions {
            if let chosen = quizAnswers[q.id] {
                progress.recordAnswer(questionId: q.id, yours: chosen, correct: q.ans)
                var srState = progress.srStates[q.id] ?? SRState.initial()
                srState = SpacedRepetition.updateState(srState, correct: chosen == q.ans)
                progress.srStates[q.id] = srState
            }
        }
    }

    func resetQuiz() {
        quizState = .setup
        quizQuestions = []
        quizAnswers = [:]
        quizResult = nil
    }

    // MARK: - QOTD

    func loadQOTD() {
        let questions = dataManager.questions
        guard !questions.isEmpty else { return }
        qotdQuestion = SpacedRepetition.questionOfTheDay(from: questions, progress: progress)
        let dateKey = QOTD.dateKey()
        qotdAnswered = progress.qotdHistory[dateKey] != nil
    }

    func answerQOTD(choice: String) {
        guard let q = qotdQuestion else { return }
        let dateKey = QOTD.dateKey()
        progress.qotdHistory[dateKey] = q.id
        progress.recordAnswer(questionId: q.id, yours: choice, correct: q.ans)
        var srState = progress.srStates[q.id] ?? SRState.initial()
        srState = SpacedRepetition.updateState(srState, correct: choice == q.ans)
        progress.srStates[q.id] = srState
        qotdAnswered = true
    }

    // MARK: - Stats

    func resetAllProgress() {
        progress = UserProgress()
        buildStudyPool()
        loadQOTD()
    }

    var studiedCount: Int { progress.studiedCount }
    var missedCount: Int { progress.missedCount }
    var bookmarkedCount: Int { progress.bookmarked.count }
    var overallAccuracy: Double { progress.overallAccuracy }

    func missedQuestions() -> [Question] {
        dataManager.questions.filter { progress.isMissed($0.id) }
    }

    func categoryAccuracy(for category: QuestionCategory) -> Double {
        let ids = dataManager.questions
            .filter { $0.cat.uppercased() == category.rawValue }
            .map { $0.id }
        return progress.accuracy(for: ids)
    }

    func srBoxCounts() -> [Int: Int] {
        SpacedRepetition.boxCounts(
            questions: dataManager.questions,
            srStates: progress.srStates
        )
    }

    func drillMissed() {
        changeStudyFilter(.missed)
    }

    // MARK: - Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s debounce
            guard !Task.isCancelled else { return }
            persistence.saveProgress(self.progress)
        }
    }
}

// MARK: - Quiz State

enum QuizState {
    case setup
    case active
    case results
}
