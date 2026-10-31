import Foundation

public struct LoggedSet: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var reps: Int = 8
    public var weight: Double = 0
    public var completedAt: Date?
    public init() {}
}
public struct Exercise: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var name: String
    public var sets: [LoggedSet]
    public init(name: String, sets: [LoggedSet] = [LoggedSet(), LoggedSet(), LoggedSet()]) {
        self.name = name; self.sets = sets
    }
}
public struct Workout: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var startedAt = Date()
    public var finishedAt: Date?
    public var exercises: [Exercise]
    public init(exercises: [Exercise]) { self.exercises = exercises }
}
public struct FitnessState: Codable, Equatable {
    public var schemaVersion = 1
    public var active: Workout?
    public var history: [Workout] = []
    public var restUntil: Date?
    public init() {}
    public func previousPerformance(for name: String) -> Exercise? {
        history.sorted { $0.startedAt > $1.startedAt }
            .lazy.flatMap(\.exercises).first { $0.name == name && $0.sets.contains { $0.completedAt != nil } }
    }
}

/// Writes occur synchronously before the UI reports success. Atomic replacement
/// preserves the preceding file when a write fails. Failed reads never create a blank file.
public struct StateRepository {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func load() throws -> FitnessState {
        guard FileManager.default.fileExists(atPath: url.path) else { return FitnessState() }
        let state = try JSONDecoder().decode(FitnessState.self, from: Data(contentsOf: url))
        guard state.schemaVersion == 1 else { throw CocoaError(.coderReadCorrupt) }
        return state
    }
    public func save(_ state: FitnessState) throws {
        let data = try JSONEncoder().encode(state)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
