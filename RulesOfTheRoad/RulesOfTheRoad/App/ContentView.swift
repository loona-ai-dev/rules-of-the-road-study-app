import SwiftUI

// MARK: - Tab Selection

enum AppTab: Int {
    case home      = 0
    case study     = 1
    case quiz      = 2
    case diagrams  = 3
    case stats     = 4
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            AppBackground()

            if dataManager.isLoading {
                LoadingView()
            } else if let error = dataManager.loadError {
                ErrorView(message: error)
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            StudyView()
                .tabItem {
                    Label("Study", systemImage: "book.fill")
                }
                .tag(AppTab.study)

            QuizView()
                .tabItem {
                    Label("Quiz", systemImage: "checkmark.seal.fill")
                }
                .tag(AppTab.quiz)

            DiagramsView()
                .tabItem {
                    Label("Diagrams", systemImage: "photo.stack.fill")
                }
                .tag(AppTab.diagrams)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.stats)
        }
        .tint(.gold)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.gold.opacity(0.2), Color.gold],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }

                Image(systemName: "helm")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.gold.opacity(0.8))
            }

            VStack(spacing: 8) {
                Text("Rules of the Road")
                    .font(RORFont.headerMed)
                    .foregroundColor(.white)

                Text("Loading questions...")
                    .font(RORFont.label)
                    .foregroundColor(.white.opacity(0.45))
            }
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.portRed)

            Text("Failed to Load")
                .font(RORFont.headerMed)
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
