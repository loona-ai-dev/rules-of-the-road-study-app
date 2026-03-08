import Foundation
import Combine

// MARK: - Data Manager

@MainActor
final class DataManager: ObservableObject {

    @Published var questions: [Question] = []
    @Published var rules: [String: RuleInfo] = [:]
    @Published var isLoading = true
    @Published var loadError: String?

    init() {
        Task {
            await loadData()
        }
    }

    func loadData() async {
        do {
            async let qs = loadQuestions()
            async let rs = loadRules()
            let (questions, rules) = try await (qs, rs)
            self.questions = questions
            self.rules = rules
            self.isLoading = false
        } catch {
            self.loadError = error.localizedDescription
            self.isLoading = false
        }
    }

    private func loadQuestions() async throws -> [Question] {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            throw DataError.fileNotFound("questions.json")
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([Question].self, from: data)
    }

    private func loadRules() async throws -> [String: RuleInfo] {
        guard let url = Bundle.main.url(forResource: "rules", withExtension: "json") else {
            throw DataError.fileNotFound("rules.json")
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([String: RuleInfo].self, from: data)
    }

    func ruleInfo(for ruleKey: String) -> RuleInfo? {
        // Normalize rule key - handle "Rule 9" or "Annex V" etc.
        return rules[ruleKey]
    }

    func question(by id: Int) -> Question? {
        questions.first { $0.id == id }
    }
}

enum DataError: LocalizedError {
    case fileNotFound(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name): return "Could not find \(name) in app bundle"
        case .decodingError(let msg): return "Failed to decode data: \(msg)"
        }
    }
}

// MARK: - Persistence Manager

final class PersistenceManager {

    static let shared = PersistenceManager()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let userProgress = "userProgress_v1"
        static let lastVersion = "dataVersion"
    }

    func saveProgress(_ progress: UserProgress) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(progress)
            defaults.set(data, forKey: Keys.userProgress)
        } catch {
            print("Failed to save progress: \(error)")
        }
    }

    func loadProgress() -> UserProgress {
        guard let data = defaults.data(forKey: Keys.userProgress) else {
            return UserProgress()
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(UserProgress.self, from: data)
        } catch {
            print("Failed to load progress: \(error)")
            return UserProgress()
        }
    }

    func clearProgress() {
        defaults.removeObject(forKey: Keys.userProgress)
    }
}
