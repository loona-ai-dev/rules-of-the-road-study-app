import SwiftUI

// MARK: - Question Card (Full)

struct QuestionCard: View {
    let question: Question
    @Binding var selectedAnswer: String?
    let isAnswered: Bool
    let correctAnswer: String
    let onAnswer: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Question text
            Text(question.q)
                .font(RORFont.questionText)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)

            // Diagram reference
            if question.hasDiagram {
                DiagramReferenceRow(diagramNumbers: question.diagramNumbers)
            }

            GlassDivider()

            // Answer options
            VStack(spacing: 8) {
                ForEach(question.answersOrdered, id: \.key) { key, value in
                    AnswerButton(
                        label: key,
                        text: value,
                        state: answerState(for: key),
                        onTap: {
                            guard !isAnswered else { return }
                            onAnswer(key)
                        }
                    )
                }
            }
        }
        .glassCard(cornerRadius: 18, padding: 20)
    }

    private func answerState(for key: String) -> AnswerButtonState {
        guard isAnswered else {
            return selectedAnswer == key ? .selected : .idle
        }
        if key == correctAnswer {
            return .correct
        }
        if key == selectedAnswer && selectedAnswer != correctAnswer {
            return .incorrect
        }
        return .locked
    }
}

// MARK: - Answer Button State

enum AnswerButtonState {
    case idle
    case selected
    case correct
    case incorrect
    case locked
}

// MARK: - Answer Button

struct AnswerButton: View {
    let label: String
    let text: String
    let state: AnswerButtonState
    let onTap: () -> Void

    @State private var isPressed = false

    var backgroundColor: Color {
        switch state {
        case .idle:     return Color.white.opacity(0.05)
        case .selected: return Color.gold.opacity(0.15)
        case .correct:  return Color.correctGreen.opacity(0.2)
        case .incorrect: return Color.incorrectRed.opacity(0.2)
        case .locked:   return Color.white.opacity(0.03)
        }
    }

    var borderColor: Color {
        switch state {
        case .idle:     return Color.white.opacity(0.1)
        case .selected: return Color.gold.opacity(0.5)
        case .correct:  return Color.correctGreen.opacity(0.7)
        case .incorrect: return Color.incorrectRed.opacity(0.7)
        case .locked:   return Color.white.opacity(0.05)
        }
    }

    var labelBackground: Color {
        switch state {
        case .idle:     return Color.white.opacity(0.08)
        case .selected: return Color.gold.opacity(0.3)
        case .correct:  return Color.correctGreen.opacity(0.3)
        case .incorrect: return Color.incorrectRed.opacity(0.3)
        case .locked:   return Color.white.opacity(0.04)
        }
    }

    var textColor: Color {
        switch state {
        case .locked:   return Color.white.opacity(0.35)
        default:        return Color.white.opacity(0.9)
        }
    }

    var trailingIcon: String? {
        switch state {
        case .correct:  return "checkmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        default: return nil
        }
    }

    var trailingIconColor: Color {
        state == .correct ? .correctGreen : .incorrectRed
    }

    var body: some View {
        Button(action: {
            guard state == .idle || state == .selected else { return }
            withAnimation(.spring(response: 0.2)) {
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                // Letter badge
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(labelBackground)
                        .frame(width: 32, height: 32)
                    Text(label)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(state == .locked ? .white.opacity(0.3) : .white)
                }

                // Answer text
                Text(text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Result icon
                if let icon = trailingIcon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(trailingIconColor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2), value: state)
        .disabled(state == .correct || state == .incorrect || state == .locked)
    }
}

// MARK: - Diagram Reference Row

struct DiagramReferenceRow: View {
    let diagramNumbers: [Int]
    @State private var showingDiagram = false
    @State private var selectedDiagramNum: Int = 1

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "photo.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "5b7dbf"))

            Text("References: \(diagramNumbers.map { "Diagram \($0)" }.joined(separator: ", "))")
                .font(RORFont.label)
                .foregroundColor(Color(hex: "5b7dbf"))

            Spacer()

            ForEach(diagramNumbers, id: \.self) { num in
                Button {
                    selectedDiagramNum = num
                    showingDiagram = true
                } label: {
                    Text("View \(num)")
                        .font(RORFont.label)
                        .foregroundColor(.navyDeep)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: "5b7dbf").opacity(0.85))
                        )
                }
            }
        }
        .padding(10)
        .glassPanel(cornerRadius: 8)
        .sheet(isPresented: $showingDiagram) {
            DiagramDetailView(diagramNumber: selectedDiagramNum)
        }
    }
}

// MARK: - Rule Reference Card

struct RuleReferenceCard: View {
    let ruleKey: String
    let rules: [String: RuleInfo]
    @State private var isExpanded = false

    var ruleInfo: RuleInfo? { rules[ruleKey] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.seaGreen)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(ruleKey)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.seaGreen)

                        if let info = ruleInfo {
                            Text(info.title)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.seaGreen.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded, let info = ruleInfo {
                GlassDivider()
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 8) {
                    Text(info.part)
                        .font(RORFont.label)
                        .foregroundColor(.seaGreen.opacity(0.7))
                        .textCase(.uppercase)

                    Text(info.summary)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)

                    if !info.keywords.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(info.keywords.prefix(6), id: \.self) { keyword in
                                    Text(keyword)
                                        .font(RORFont.label)
                                        .foregroundColor(.seaGreen.opacity(0.8))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(Color.seaGreen.opacity(0.1))
                                                .overlay(
                                                    Capsule()
                                                        .strokeBorder(Color.seaGreen.opacity(0.25), lineWidth: 0.5)
                                                )
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.seaGreen.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.seaGreen.opacity(0.35), Color.seaGreen.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.seaGreen.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}
