import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @State private var showResetAlert = false
    @State private var showMissedDrillConfirm = false

    var boxCounts: [Int: Int] { appState.srBoxCounts() }
    var totalQuestions: Int { dataManager.questions.count }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Overview Stats
                        overviewSection

                        // Category Accuracy
                        categorySection

                        // SR Box Breakdown
                        srSection

                        // Missed Questions
                        if appState.missedCount > 0 {
                            missedSection
                        }

                        // Reset
                        resetSection

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Statistics")
                        .font(RORFont.headerMed)
                        .foregroundColor(.gold)
                }
            }
            .alert("Reset All Progress?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    withAnimation {
                        appState.resetAllProgress()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all answered questions, bookmarks, spaced repetition data, and quiz history. This cannot be undone.")
            }
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Questions Studied",
                    value: "\(appState.studiedCount)",
                    subtitle: "of \(totalQuestions)",
                    icon: "book.fill",
                    color: .seaGreen
                )
                StatCard(
                    title: "Overall Accuracy",
                    value: appState.studiedCount > 0 ? "\(Int(appState.overallAccuracy))%" : "—",
                    subtitle: appState.studiedCount > 0 ? "correct rate" : "no data yet",
                    icon: "target",
                    color: .gold
                )
                StatCard(
                    title: "Missed Questions",
                    value: "\(appState.missedCount)",
                    subtitle: "need review",
                    icon: "xmark.circle.fill",
                    color: appState.missedCount > 0 ? .portRed : .seaGreen
                )
                StatCard(
                    title: "Bookmarked",
                    value: "\(appState.bookmarkedCount)",
                    subtitle: "saved for later",
                    icon: "bookmark.fill",
                    color: .gold.opacity(0.8)
                )
            }

            // Mastery progress bar
            if appState.studiedCount > 0 {
                let mastered = (boxCounts[3] ?? 0) + (boxCounts[4] ?? 0)
                let pct = totalQuestions > 0 ? Double(mastered) / Double(totalQuestions) : 0

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Mastery Progress")
                            .font(RORFont.label)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("\(mastered) / \(totalQuestions)")
                            .font(RORFont.mono)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    RORProgressBar(value: pct, color: .seaGreen, height: 8)
                        .clipShape(Capsule())
                }
                .glassCard(cornerRadius: 12, padding: 14)
            }
        }
    }

    // MARK: - Category Accuracy

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Accuracy")
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)

            VStack(spacing: 10) {
                ForEach(QuestionCategory.allCases, id: \.self) { category in
                    let accuracy = appState.categoryAccuracy(for: category)
                    let count = dataManager.questions.filter { $0.cat.uppercased() == category.rawValue }.count

                    HStack(spacing: 12) {
                        CategoryBadge(category: category.rawValue)
                            .frame(width: 48)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(category.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(appState.progress.accuracy(for:
                                    dataManager.questions.filter { $0.cat.uppercased() == category.rawValue }.map { $0.id }
                                ) > 0 ? "\(Int(accuracy))%" : "—")
                                    .font(RORFont.mono)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            RORProgressBar(
                                value: accuracy / 100,
                                color: Color.categoryColor(for: category.rawValue),
                                height: 4
                            )
                        }

                        Text("\(count)")
                            .font(RORFont.mono)
                            .foregroundColor(.white.opacity(0.3))
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }
            .glassCard(cornerRadius: 14, padding: 16)
        }
    }

    // MARK: - SR Box Section

    private var srSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spaced Repetition")
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)

            VStack(spacing: 10) {
                ForEach(0..<5) { box in
                    let count = boxCounts[box] ?? 0
                    let fraction = totalQuestions > 0 ? Double(count) / Double(totalQuestions) : 0
                    let interval = SpacedRepetition.intervals[box]
                    let intervalText = box == 0 ? "Immediate" :
                        box == 1 ? "1 day" :
                        box == 2 ? "3 days" :
                        box == 3 ? "7 days" : "14 days"

                    VStack(spacing: 6) {
                        HStack(spacing: 10) {
                            SRBoxBadge(box: box, size: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(SpacedRepetition.boxNames[box])
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                                Text(intervalText)
                                    .font(RORFont.label)
                                    .foregroundColor(Color.srBoxColor(for: box).opacity(0.7))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(count)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text("\(Int(fraction * 100))%")
                                    .font(RORFont.mono)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }

                        RORProgressBar(value: fraction, color: Color.srBoxColor(for: box))
                    }
                    .padding(.vertical, 4)

                    if box < 4 { GlassDivider() }
                }
            }
            .glassCard(cornerRadius: 14, padding: 16)
        }
    }

    // MARK: - Missed Questions

    private var missedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Missed Questions")
                    .font(RORFont.label)
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)

                Spacer()

                Text("\(appState.missedCount) total")
                    .font(RORFont.mono)
                    .foregroundColor(.portRed.opacity(0.7))
            }

            // Drill button
            Button {
                appState.drillMissed()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 16))
                    Text("Drill All Missed Questions")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("\(appState.missedCount)")
                        .font(RORFont.mono)
                        .foregroundColor(.portRed)
                }
                .foregroundColor(.white)
                .glassCard(cornerRadius: 12, padding: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.portRed.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Top missed (up to 10)
            let missed = appState.missedQuestions().prefix(10)
            if !missed.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(missed.enumerated()), id: \.element.id) { idx, q in
                        MissedQuestionRow(question: q, index: idx)
                        if idx < missed.count - 1 { GlassDivider().padding(.horizontal, 12) }
                    }
                }
                .glassCard(cornerRadius: 14, padding: 0)
                .padding(0)
            }
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        VStack(spacing: 12) {
            Button {
                showResetAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                    Text("Reset All Progress")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.portRed.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.portRed.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.portRed.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())

            Text("Resets all answers, bookmarks, and spaced repetition data")
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Missed Question Row

struct MissedQuestionRow: View {
    let question: Question
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(RORFont.mono)
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 20)

            Text(question.q)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            CategoryBadge(category: question.cat, small: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
