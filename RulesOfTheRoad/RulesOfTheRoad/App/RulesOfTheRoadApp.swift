import SwiftUI

@main
struct RulesOfTheRoadApp: App {
    @StateObject private var dataManager: DataManager
    @StateObject private var appState: AppState

    init() {
        let dm = DataManager()
        let state = AppState(dataManager: dm)
        _dataManager = StateObject(wrappedValue: dm)
        _appState = StateObject(wrappedValue: state)

        // Configure tab bar appearance
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(dataManager)
                .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        // Glass morphism tab bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.navyDeep.opacity(0.8))
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)

        // Tab item colors
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(Color.white.opacity(0.45))
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.white.opacity(0.45)),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        itemAppearance.selected.iconColor = UIColor(Color.gold)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.gold),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        tabBarAppearance.inlineLayoutAppearance = itemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(Color.gold)

        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = UIColor(Color.navyDeep.opacity(0.85))
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.gold),
            .font: UIFont(name: "Georgia-Bold", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .bold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.gold),
            .font: UIFont(name: "Georgia-Bold", size: 32) ?? UIFont.systemFont(ofSize: 32, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
}
