import SwiftUI

struct StudyView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedAnswer: String?
    @State private var showDiagram = false
    @State private var showRuleRef = false
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if dataManager.questions.isEmpty {
                    loadingPlaceholder
                } else if appState.studyPool.isEmpty {
                    emptyState
                } else {
                    mainContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .onChange(of: appState.studyIndex) {
            selectedAnswer = nil
            showRuleRef = false
        }
        .onChange(of: appState.studyFilter) {
            selectedAnswer = nil
            showRuleRef = false
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Filter pills
            filterBar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            // Progress bar
            progressSection
                .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 16) {
                    if let question = appState.currentStudyQuestion {
                        // Question Card
                        QuestionCard(
                            question: question,
                            selectedAnswer: $selectedAnswer,
                            isAnswered: appState.isCurrentStudyAnswered,
                            correctAnswer: question.ans,
                            onAnswer: { choice in
                                withAnimation(.spring(response: 0.4)) {
                                    selectedAnswer = choice
                                    appState.answerStudy(choice: choice)
                                }
                            }
                        )
                        .id(question.id)  // Force refresh on question change
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                        // Post-answer content
                        if appState.isCurrentStudyAnswered {
                            // SR Status
                            if let srState = appState.progress.srStates[question.id] {
                                srStatusRow(box: srState.box, nextDue: srState.nextDue)
                            }

                            // Rule Reference
                            if !question.rule.isEmpty {
                                RuleReferenceCard(
                                    ruleKey: question.rule,
                                    rules: dataManager.rules
                                )
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .animation(.spring(response: 0.4), value: appState.studyIndex)
            }

            // Navigation controls
            navigationControls
                .background(.ultraThinMaterial)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StudyFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.displayName,
                        isSelected: appState.studyFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            appState.changeStudyFilter(filter)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        HStack(spacing: 10) {
            RORProgressBar(
                value: appState.studyPool.isEmpty ? 0 :
                    Double(appState.studyIndex + 1) / Double(appState.studyPool.count)
            )

            Text("\(appState.studyIndex + 1) / \(appState.studyPool.count)")
                .font(RORFont.mono)
                .foregroundColor(.white.opacity(0.5))
                .frame(minWidth: 55, alignment: .trailing)
        }
        .padding(.bottom, 6)
    }

    // MARK: - SR Status Row

    private func srStatusRow(box: Int, nextDue: Date) -> some View {
        HStack(spacing: 10) {
            SRBoxBadge(box: box, size: 26)

            Text("Box \(box) • \(SpacedRepetition.boxNames[box])")
                .font(RORFont.label)
                .foregroundColor(Color.srBoxColor(for: box))

            Spacer()

            if box > 0 {
                Text("Next: \(nextDue, format: .relative(presentation: .named))")
                    .font(RORFont.label)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassPanel(cornerRadius: 10)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        HStack(spacing: 16) {
            // Prev
            Button {
                withAnimation(.spring(response: 0.3)) {
                    appState.prevStudyQuestion()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(appState.studyIndex > 0 ? .white : .white.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(appState.studyIndex > 0 ? 0.08 : 0.03))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5))
                    )
            }
            .disabled(appState.studyIndex == 0)

            // Bookmark
            if let q = appState.currentStudyQuestion {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        appState.toggleBookmark(q.id)
                    }
                } label: {
                    Image(systemName: appState.isBookmarked(q.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(appState.isBookmarked(q.id) ? .gold : .white.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
                        )
                }
            }

            Spacer()

            // Next / Skip
            Button {
                withAnimation(.spring(response: 0.3)) {
                    appState.nextStudyQuestion()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(appState.isCurrentStudyAnswered ? "Next" : "Skip")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(appState.isCurrentStudyAnswered ? .navyDeep : .white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(appState.isCurrentStudyAnswered ? Color.gold : Color.white.opacity(0.1))
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Study")
                .font(RORFont.headerMed)
                .foregroundColor(.gold)
        }

        ToolbarItem(placement: .topBarTrailing) {
            if let q = appState.currentStudyQuestion {
                HStack(spacing: 6) {
                    CategoryBadge(category: q.cat, small: true)
                    if q.hasDiagram {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "5b7dbf"))
                    }
                }
            }
        }
    }

    // MARK: - Empty / Loading States

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.2))

            Text("No Questions")
                .font(RORFont.headerMed)
                .foregroundColor(.white.opacity(0.6))

            Text("No questions match the selected filter.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)

            Button {
                appState.changeStudyFilter(.all)
            } label: {
                Text("Show All Questions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.navyDeep)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.gold))
            }
        }
        .padding(40)
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.gold)
            Text("Loading questions...")
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
