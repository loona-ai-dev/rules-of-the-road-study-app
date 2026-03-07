import SwiftUI

struct QuizView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                switch appState.quizState {
                case .setup:
                    QuizSetupView()
                case .active:
                    QuizActiveView()
                case .results:
                    QuizResultsView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Quiz")
                        .font(RORFont.headerMed)
                        .foregroundColor(.gold)
                }

                if appState.quizState == .active {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Quit") {
                            withAnimation {
                                appState.resetQuiz()
                            }
                        }
                        .foregroundColor(.portRed.opacity(0.8))
                        .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
        }
    }
}

// MARK: - Quiz Setup

struct QuizSetupView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager

    var availableCount: Int {
        let filtered = SpacedRepetition.applyFilter(
            dataManager.questions,
            filter: appState.quizFilter,
            progress: appState.progress
        )
        return filtered.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.gold)

                    Text("Quiz Mode")
                        .font(RORFont.display(24))
                        .foregroundColor(.white)

                    Text("Test your knowledge with a simulated exam.\nPass threshold: 90%")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 24)
                .glassCard(cornerRadius: 20, padding: 20)

                // Question Count
                VStack(alignment: .leading, spacing: 12) {
                    Text("Number of Questions")
                        .font(RORFont.label)
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)

                    VStack(spacing: 8) {
                        HStack {
                            Text("\(appState.quizSize) Questions")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("of \(availableCount) available")
                                .font(RORFont.label)
                                .foregroundColor(.white.opacity(0.4))
                        }

                        Slider(
                            value: Binding(
                                get: { Double(appState.quizSize) },
                                set: { appState.quizSize = max(10, min(Int($0), availableCount)) }
                            ),
                            in: 10...Double(max(availableCount, 10)),
                            step: 10
                        )
                        .tint(.gold)

                        HStack {
                            Text("10")
                            Spacer()
                            Text("\(availableCount)")
                        }
                        .font(RORFont.mono)
                        .foregroundColor(.white.opacity(0.3))
                    }
                }
                .glassCard(cornerRadius: 16, padding: 16)

                // Category Filter
                VStack(alignment: .leading, spacing: 12) {
                    Text("Question Category")
                        .font(RORFont.label)
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)

                    VStack(spacing: 8) {
                        ForEach([StudyFilter.all, .both, .inland, .international], id: \.self) { filter in
                            QuizFilterRow(
                                filter: filter,
                                isSelected: appState.quizFilter == filter,
                                count: SpacedRepetition.applyFilter(
                                    dataManager.questions,
                                    filter: filter,
                                    progress: appState.progress
                                ).count
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    appState.quizFilter = filter
                                }
                            }
                        }
                    }
                }
                .glassCard(cornerRadius: 16, padding: 16)

                // Start Button
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        appState.startQuiz()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Start Quiz — \(appState.quizSize) Questions")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.navyDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.goldBright, Color.gold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.gold.opacity(0.4), radius: 12, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(availableCount < 10)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}

// MARK: - Quiz Filter Row

struct QuizFilterRow: View {
    let filter: StudyFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.gold : Color.white.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(Color.gold)
                            .frame(width: 10, height: 10)
                    }
                }

                Text(filter.displayName == "ALL" ? "All Questions" : filter.displayName)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))

                Spacer()

                Text("\(count)")
                    .font(RORFont.mono)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.gold.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - Quiz Active View

struct QuizActiveView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @State private var currentIndex = 0
    @State private var showSubmitAlert = false
    @State private var selectedAnswer: String?

    var currentQuestion: Question? {
        guard currentIndex < appState.quizQuestions.count else { return nil }
        return appState.quizQuestions[currentIndex]
    }

    var answeredCount: Int {
        appState.quizAnswers.count
    }

    var unansweredCount: Int {
        appState.quizQuestions.count - answeredCount
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header progress
            quizHeader

            ScrollView {
                VStack(spacing: 16) {
                    if let question = currentQuestion {
                        QuizQuestionCard(
                            question: question,
                            questionNumber: currentIndex + 1,
                            totalQuestions: appState.quizQuestions.count,
                            selectedAnswer: Binding(
                                get: { appState.quizAnswers[question.id] },
                                set: { if let ans = $0 { appState.answerQuiz(questionId: question.id, choice: ans) } }
                            )
                        )
                        .id(question.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .animation(.spring(response: 0.35), value: currentIndex)
            }

            // Navigation
            quizNavigation
                .background(.ultraThinMaterial)
        }
        .alert("Submit Quiz?", isPresented: $showSubmitAlert) {
            Button("Submit", role: .destructive) {
                withAnimation {
                    appState.submitQuiz()
                }
            }
            Button("Keep Answering", role: .cancel) {}
        } message: {
            if unansweredCount > 0 {
                Text("You have \(unansweredCount) unanswered question\(unansweredCount == 1 ? "" : "s"). Submit anyway?")
            } else {
                Text("Submit all \(appState.quizQuestions.count) answers?")
            }
        }
    }

    // MARK: - Quiz Header

    private var quizHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Question \(currentIndex + 1) of \(appState.quizQuestions.count)")
                    .font(RORFont.label)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("\(answeredCount) answered")
                    .font(RORFont.label)
                    .foregroundColor(answeredCount == appState.quizQuestions.count ? .correctGreen : .gold)
            }
            .padding(.horizontal, 16)

            RORProgressBar(
                value: Double(answeredCount) / Double(max(appState.quizQuestions.count, 1)),
                color: .seaGreen
            )
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.navyDeep.opacity(0.3))
    }

    // MARK: - Quiz Navigation

    private var quizNavigation: some View {
        HStack(spacing: 12) {
            // Previous
            Button {
                withAnimation(.spring(response: 0.3)) {
                    if currentIndex > 0 { currentIndex -= 1 }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(currentIndex > 0 ? .white : .white.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(currentIndex > 0 ? 0.08 : 0.03))
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)))
            }
            .disabled(currentIndex == 0)

            // Question Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<appState.quizQuestions.count, id: \.self) { idx in
                        let q = appState.quizQuestions[idx]
                        let answered = appState.quizAnswers[q.id] != nil

                        Circle()
                            .fill(idx == currentIndex ? Color.gold :
                                answered ? Color.seaGreen : Color.white.opacity(0.15))
                            .frame(width: idx == currentIndex ? 10 : 7, height: idx == currentIndex ? 10 : 7)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) { currentIndex = idx }
                            }
                            .animation(.spring(response: 0.25), value: answered)
                    }
                }
                .padding(.horizontal, 4)
            }

            // Next / Submit
            if currentIndex < appState.quizQuestions.count - 1 {
                Button {
                    withAnimation(.spring(response: 0.3)) { currentIndex += 1 }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.08))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)))
                }
            } else {
                Button {
                    showSubmitAlert = true
                } label: {
                    Text("Submit")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.navyDeep)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(answeredCount == appState.quizQuestions.count ? Color.gold : Color.white.opacity(0.3))
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Quiz Question Card

struct QuizQuestionCard: View {
    let question: Question
    let questionNumber: Int
    let totalQuestions: Int
    @Binding var selectedAnswer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Q\(questionNumber)")
                    .font(RORFont.label)
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                CategoryBadge(category: question.cat)
                if !question.rule.isEmpty {
                    Text(question.rule)
                        .font(RORFont.label)
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Question
            Text(question.q)
                .font(RORFont.questionText)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)

            // Diagram ref
            if question.hasDiagram {
                DiagramReferenceRow(diagramNumbers: question.diagramNumbers)
            }

            GlassDivider()

            // Answers (no reveal in quiz mode)
            VStack(spacing: 8) {
                ForEach(question.answersOrdered, id: \.key) { key, value in
                    QuizAnswerButton(
                        label: key,
                        text: value,
                        isSelected: selectedAnswer == key,
                        onTap: {
                            withAnimation(.spring(response: 0.2)) {
                                selectedAnswer = key
                            }
                        }
                    )
                }
            }
        }
        .glassCard(cornerRadius: 18, padding: 20)
    }
}

// MARK: - Quiz Answer Button (no reveal)

struct QuizAnswerButton: View {
    let label: String
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? Color.gold.opacity(0.25) : Color.white.opacity(0.06))
                        .frame(width: 32, height: 32)
                    Text(label)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .gold : .white.opacity(0.7))
                }

                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(isSelected ? 1.0 : 0.8))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gold)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.gold.opacity(0.12) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isSelected ? Color.gold.opacity(0.5) : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.2), value: isSelected)
    }
}

// MARK: - Quiz Results View

struct QuizResultsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @State private var showReview = false
    @State private var selectedResultFilter: ResultFilter = .all

    enum ResultFilter: String, CaseIterable {
        case all = "All"
        case correct = "Correct"
        case incorrect = "Incorrect"
        case missed = "Missed"
    }

    var result: QuizResult? { appState.quizResult }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let result = result {
                    // Score Card
                    scoreCard(result)

                    // Stats breakdown
                    statsBreakdown(result)

                    // Review toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showReview.toggle()
                            }
                        } label: {
                            HStack {
                                Text(showReview ? "Hide Review" : "Review Answers")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: showReview ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        if showReview {
                            // Filter pills
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ResultFilter.allCases, id: \.self) { f in
                                        FilterPill(title: f.rawValue, isSelected: selectedResultFilter == f) {
                                            selectedResultFilter = f
                                        }
                                    }
                                }
                            }

                            let filtered = filteredResults(result)
                            ForEach(filtered, id: \.question.id) { r in
                                ReviewRow(result: r, rules: dataManager.rules)
                            }
                        }
                    }
                    .glassCard(cornerRadius: 16, padding: 16)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            withAnimation {
                                appState.resetQuiz()
                                appState.startQuiz()
                            }
                        } label: {
                            Label("Take New Quiz", systemImage: "arrow.clockwise")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.navyDeep)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.gold))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button {
                            withAnimation {
                                appState.resetQuiz()
                            }
                        } label: {
                            Label("Back to Setup", systemImage: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.07))
                                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Spacer(minLength: 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    private func scoreCard(_ result: QuizResult) -> some View {
        VStack(spacing: 16) {
            // Pass/fail badge
            ZStack {
                Circle()
                    .fill(result.passed ? Color.correctGreen.opacity(0.15) : Color.incorrectRed.opacity(0.15))
                    .overlay(
                        Circle()
                            .strokeBorder(result.passed ? Color.correctGreen.opacity(0.5) : Color.incorrectRed.opacity(0.5), lineWidth: 2)
                    )
                    .frame(width: 80, height: 80)

                VStack(spacing: 0) {
                    Text("\(Int(result.percentage))%")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(result.passed ? .correctGreen : .incorrectRed)
                    Text(result.passed ? "PASS" : "FAIL")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(result.passed ? .correctGreen.opacity(0.7) : .incorrectRed.opacity(0.7))
                }
            }

            VStack(spacing: 6) {
                Text(result.passed ? "Congratulations!" : "Keep Studying")
                    .font(RORFont.display(22))
                    .foregroundColor(.white)

                Text(result.passed
                    ? "You passed the SWOS exam simulation"
                    : "You need 90% to pass. Keep practicing!")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            RORProgressBar(
                value: result.percentage / 100,
                color: result.passed ? .correctGreen : .incorrectRed,
                height: 6
            )
        }
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 20, padding: 20)
    }

    private func statsBreakdown(_ result: QuizResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MiniStatCard(value: "\(result.score)", label: "Correct", icon: "checkmark.circle.fill", color: .correctGreen)
            MiniStatCard(value: "\(result.total - result.score)", label: "Wrong", icon: "xmark.circle.fill", color: .incorrectRed)
            MiniStatCard(value: "\(result.total - result.answers.count)", label: "Skipped", icon: "minus.circle.fill", color: .white.opacity(0.4))
        }
    }

    private func filteredResults(_ result: QuizResult) -> [QuizAnswerResult] {
        let all = result.questions.map { result.result(for: $0) }
        switch selectedResultFilter {
        case .all: return all
        case .correct: return all.filter { $0.isCorrect }
        case .incorrect: return all.filter { !$0.isCorrect && !$0.isUnanswered }
        case .missed: return all.filter { $0.isUnanswered }
        }
    }
}

// MARK: - Review Row

struct ReviewRow: View {
    let result: QuizAnswerResult
    let rules: [String: RuleInfo]
    @State private var isExpanded = false

    var borderColor: Color {
        if result.isUnanswered { return Color.white.opacity(0.1) }
        return result.isCorrect ? Color.correctGreen.opacity(0.4) : Color.incorrectRed.opacity(0.4)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: result.isUnanswered ? "minus.circle.fill" :
                        result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(result.isUnanswered ? .white.opacity(0.3) :
                            result.isCorrect ? .correctGreen : .incorrectRed)

                    Text(result.question.q)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                GlassDivider().padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(result.question.answersOrdered, id: \.key) { key, value in
                        HStack(spacing: 8) {
                            Text(key)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(
                                    key == result.correct ? .correctGreen :
                                    key == result.chosen ? .incorrectRed : .white.opacity(0.4)
                                )
                                .frame(width: 20)

                            Text(value)
                                .font(.system(size: 12))
                                .foregroundColor(
                                    key == result.correct ? .correctGreen :
                                    key == result.chosen ? .incorrectRed : .white.opacity(0.4)
                                )
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            if key == result.correct {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.correctGreen)
                            } else if key == result.chosen {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.incorrectRed)
                            }
                        }
                    }

                    if !result.question.rule.isEmpty {
                        RuleReferenceCard(ruleKey: result.question.rule, rules: rules)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 0.5)
                )
        )
    }
}
