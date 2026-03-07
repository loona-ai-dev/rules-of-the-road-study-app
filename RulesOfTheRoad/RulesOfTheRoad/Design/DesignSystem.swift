import SwiftUI

// MARK: - Color Palette

extension Color {
    // Navy Background System
    static let navyDeep       = Color(hex: "060d18")
    static let navyPrimary    = Color(hex: "0d1a2d")
    static let navyElevated   = Color(hex: "132040")
    static let navyCard       = Color(hex: "0d1a2d")

    // Accent Colors
    static let gold           = Color(hex: "c9a84c")
    static let goldDim        = Color(hex: "8a7333")
    static let goldBright     = Color(hex: "f0c060")
    static let seaGreen       = Color(hex: "2eaa7a")
    static let portRed        = Color(hex: "e05545")

    // Semantic
    static let correctGreen   = Color(hex: "2ecc71")
    static let incorrectRed   = Color(hex: "e74c3c")
    static let warningOrange  = Color(hex: "f39c12")

    // SR Box Colors
    static let srBox0 = Color(hex: "e74c3c")
    static let srBox1 = Color(hex: "e67e22")
    static let srBox2 = Color(hex: "f1c40f")
    static let srBox3 = Color(hex: "2ecc71")
    static let srBox4 = Color(hex: "1abc9c")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static func srBoxColor(for box: Int) -> Color {
        switch box {
        case 0: return .srBox0
        case 1: return .srBox1
        case 2: return .srBox2
        case 3: return .srBox3
        case 4: return .srBox4
        default: return .srBox0
        }
    }

    static func categoryColor(for category: String) -> Color {
        switch category.uppercased() {
        case "INLAND": return .seaGreen
        case "INTERNATIONAL": return .portRed
        default: return .gold
        }
    }
}

// MARK: - App Background

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "060d18"), location: 0.0),
                    .init(color: Color(hex: "0a1525"), location: 0.4),
                    .init(color: Color(hex: "0d1a2d"), location: 0.7),
                    .init(color: Color(hex: "132040"), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Subtle radial highlight
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.gold.opacity(0.04),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 0,
                endRadius: 600
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass Card

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16
    var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.05),
                                        Color.gold.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 4)
                    .shadow(color: Color.gold.opacity(0.05), radius: 20, x: 0, y: 0)
            )
            .opacity(opacity)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16, padding: CGFloat = 16, opacity: Double = 1.0) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, padding: padding, opacity: opacity))
    }
}

// MARK: - Glass Panel (lighter variant)

struct GlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
            )
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Typography

enum RORFont {
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Georgia", size: size).weight(weight)
    }

    static func display(_ size: CGFloat) -> Font {
        Font.custom("Georgia", size: size).weight(.bold)
    }

    static let questionText = Font.custom("Georgia", size: 16)
    static let headerLarge  = Font.custom("Georgia", size: 24).weight(.bold)
    static let headerMed    = Font.custom("Georgia", size: 18).weight(.semibold)
    static let label        = Font.system(size: 11, weight: .semibold, design: .monospaced)
    static let mono         = Font.system(size: 12, weight: .regular, design: .monospaced)
}

// MARK: - Animated Shimmer

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: Color.white.opacity(0.15), location: phase),
                        .init(color: .clear, location: phase + 0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

// MARK: - Gold Gradient Text

struct GoldTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [Color(hex: "f0c060"), Color(hex: "c9a84c"), Color(hex: "8a7333")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .mask(content)
    }
}

extension View {
    func goldText() -> some View {
        modifier(GoldTextModifier())
    }
}

// MARK: - SR Box Badge

struct SRBoxBadge: View {
    let box: Int
    let size: CGFloat

    static let boxNames = ["New", "Learning", "Familiar", "Confident", "Mastered"]

    init(box: Int, size: CGFloat = 28) {
        self.box = box
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.srBoxColor(for: box).opacity(0.2))
                .overlay(
                    Circle()
                        .strokeBorder(Color.srBoxColor(for: box), lineWidth: 1.5)
                )
            Text("\(box)")
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                .foregroundColor(Color.srBoxColor(for: box))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: String
    var small: Bool = false

    var displayText: String {
        switch category.uppercased() {
        case "INLAND": return "INLAND"
        case "INTERNATIONAL": return "INTL"
        default: return "BOTH"
        }
    }

    var body: some View {
        Text(displayText)
            .font(.system(size: small ? 9 : 10, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, small ? 6 : 8)
            .padding(.vertical, small ? 2 : 3)
            .background(
                Capsule()
                    .fill(Color.categoryColor(for: category).opacity(0.85))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.categoryColor(for: category), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color

    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color = .gold) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
                if let sub = subtitle {
                    Text(sub)
                        .font(RORFont.label)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            Text(value)
                .font(RORFont.display(28))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.55))
                .lineLimit(1)
        }
        .glassCard(cornerRadius: 14, padding: 14)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .navyDeep : .white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.gold : Color.white.opacity(0.08))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isSelected ? Color.clear : Color.white.opacity(0.15),
                                    lineWidth: 0.5
                                )
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Progress Bar

struct RORProgressBar: View {
    let value: Double  // 0.0 to 1.0
    var color: Color = .gold
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)), height: height)
                    .animation(.spring(response: 0.4), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Divider

struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 0.5)
    }
}
