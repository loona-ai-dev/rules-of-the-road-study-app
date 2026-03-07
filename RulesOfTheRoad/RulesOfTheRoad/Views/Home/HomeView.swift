import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @State private var showQOTD = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 20) {

                        // Header
                        headerSection

                        // Quick Stats Row
                        statsRow

                        // Question of the Day
                        if let qotd = appState.qotdQuestion {
                            qotdSection(qotd)
                        }

                        // Quick Actions
                        quickActionsSection

                        // Progress Overview
                        progressSection

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("swsc_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.gold.opacity(0.4), lineWidth: 1))

                        Text("Rules of the Road")
                            .font(RORFont.headerMed)
                            .foregroundColor(.gold)
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingText)
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)

            Text("SWOS Advanced Shiphandling")
                .font(RORFont.display(22))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("COLREGS Exam Preparation")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning, Navigator"
        case 12..<17: return "Good Afternoon, Navigator"
        case 17..<21: return "Good Evening, Navigator"
        default: return "Welcome Back, Navigator"
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 10) {
            MiniStatCard(
                value: "\(appState.studiedCount)",
                label: "Studied",
                icon: "book.fill",
                color: .seaGreen
            )
            MiniStatCard(
                value: appState.studiedCount > 0 ? "\(Int(appState.overallAccuracy))%" : "—",
                label: "Accuracy",
                icon: "target",
                color: .gold
            )
            MiniStatCard(
                value: "\(appState.missedCount)",
                label: "Missed",
                icon: "xmark.circle.fill",
                color: appState.missedCount > 0 ? .portRed : .white.opacity(0.4)
            )
            MiniStatCard(
                value: "\(appState.bookmarkedCount)",
                label: "Saved",
                icon: "bookmark.fill",
                color: .gold.opacity(0.8)
            )
        }
    }

    // MARK: - QOTD Section

    private func qotdSection(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Question of the Day", systemImage: "star.fill")
                    .font(RORFont.label)
                    .foregroundColor(.gold)
                Spacer()
                CategoryBadge(category: question.cat)
            }

            Text(question.q)
                .font(RORFont.questionText)
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if appState.qotdAnswered {
                if let answer = appState.progress.latestAnswer(for: question.id) {
                    HStack(spacing: 8) {
                        Image(systemName: answer.right ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(answer.right ? .correctGreen : .incorrectRed)
                        Text(answer.right ? "Correct!" : "Incorrect — \(question.ans) is right")
                            .font(RORFont.label)
                            .foregroundColor(answer.right ? .correctGreen : .incorrectRed)
                        Spacer()
                    }
                }
            } else {
                Button {
                    showQOTD = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                        Text("Answer Today's Question")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.navyDeep)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.gold)
                    )
                }
            }
        }
        .glassCard(cornerRadius: 16, padding: 16)
        .sheet(isPresented: $showQOTD) {
            QOTDSheet(question: question)
                .environmentObject(appState)
                .environmentObject(dataManager)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionCard(
                    title: "Continue Study",
                    subtitle: studySubtitle,
                    icon: "book.fill",
                    color: .seaGreen,
                    tab: .study
                )
                QuickActionCard(
                    title: "Take Quiz",
                    subtitle: "50 question exam",
                    icon: "checkmark.seal.fill",
                    color: .gold,
                    tab: .quiz
                )
                if appState.missedCount > 0 {
                    QuickActionCard(
                        title: "Drill Missed",
                        subtitle: "\(appState.missedCount) to review",
                        icon: "arrow.clockwise.circle.fill",
                        color: .portRed,
                        tab: .study
                    )
                }
                QuickActionCard(
                    title: "Browse Diagrams",
                    subtitle: "87 navigation charts",
                    icon: "photo.stack.fill",
                    color: Color(hex: "5b7dbf"),
                    tab: .diagrams
                )
            }
        }
    }

    private var studySubtitle: String {
        let total = dataManager.questions.count
        let studied = appState.studiedCount
        if studied == 0 {
            return "\(total) questions ready"
        }
        return "\(total - studied) remaining"
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Progress")
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)

            VStack(spacing: 10) {
                let total = Double(dataManager.questions.count)

                ForEach(0..<5) { box in
                    let count = appState.srBoxCounts()[box] ?? 0
                    let fraction = total > 0 ? Double(count) / total : 0

                    HStack(spacing: 10) {
                        SRBoxBadge(box: box, size: 24)

                        Text(SpacedRepetition.boxNames[box])
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 70, alignment: .leading)

                        RORProgressBar(value: fraction, color: Color.srBoxColor(for: box))

                        Text("\(count)")
                            .font(RORFont.mono)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
            .glassCard(cornerRadius: 14, padding: 14)
        }
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.45))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 12, padding: 0)
        .padding(.vertical, 12)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let tab: AppTab

    var body: some View {
        NavigationLink {
            // Navigate to appropriate tab view inline
            EmptyView()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(12)
            .glassCard(cornerRadius: 14, padding: 0)
            .padding(1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - QOTD Sheet

struct QOTDSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    let question: Question
    @State private var selectedAnswer: String?
    @State private var isAnswered = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Badge
                        HStack {
                            Label("Question of the Day", systemImage: "star.fill")
                                .font(RORFont.label)
                                .foregroundColor(.gold)
                            Spacer()
                            CategoryBadge(category: question.cat)
                        }
                        .glassCard(cornerRadius: 12, padding: 12)

                        // Question
                        QuestionCard(
                            question: question,
                            selectedAnswer: $selectedAnswer,
                            isAnswered: isAnswered,
                            correctAnswer: question.ans,
                            onAnswer: { choice in
                                selectedAnswer = choice
                                withAnimation(.spring(response: 0.4)) {
                                    isAnswered = true
                                }
                                appState.answerQOTD(choice: choice)
                            }
                        )

                        if isAnswered {
                            RuleReferenceCard(
                                ruleKey: question.rule,
                                rules: dataManager.rules
                            )

                            Button("Done") { dismiss() }
                                .foregroundColor(.navyDeep)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color.gold))
                                .font(.system(size: 15, weight: .semibold))
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}
