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
    public var entries: [JourneyEntry]?
    public var profile: TrainingProfile?
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

public struct JourneyEntry: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var date = Date()
    public var category = "Milestone"
    public var text = ""
    public var source = "Manual entry"
    public var sourceID = UUID().uuidString
    public var originalText: String?
    public var originalTimestamp: Double?
    public var status = "unclear"
    public var approved = false
    public init() {}
}
public struct TrainingProfile: Codable, Equatable {
    public var minutes = 40
    public var equipment = "Gym"
    public var goal = "Build consistency"
    public var readiness = "Ready"
    public init() {}
}
public struct TrainingPlan {
    public var names: [String]
    public var explanation: String
    public init(state: FitnessState, now: Date = Date()) {
        let profile = state.profile ?? TrainingProfile()
        if profile.readiness == "Pain or unwell" {
            names = []; explanation = "Pause workout planning while you feel pain or unwell. Reassess when you feel ready; this app cannot assess symptoms."; return
        }
        let recent = state.history.filter { now.timeIntervalSince($0.startedAt) >= 0 && now.timeIntervalSince($0.startedAt) < 172800 }
        let trained = Set(recent.flatMap { $0.exercises.filter { $0.sets.contains { $0.completedAt != nil } }.map(\.name) })
        let catalog = profile.equipment == "Gym" ? ["Leg press", "Seated row", "Dumbbell bench press", "Leg curl", "Lat pulldown"] : profile.equipment == "Dumbbells" ? ["Goblet squat", "Dumbbell row", "Dumbbell floor press"] : ["Bodyweight squat", "Wall push-up", "Glute bridge"]
        let available = catalog.filter { !trained.contains($0) }
        let count = profile.minutes < 25 || profile.readiness == "Low energy" ? 2 : 3
        names = Array(available.prefix(count))
        explanation = "A starter session for \(profile.minutes) minutes with \(profile.equipment.lowercased()) equipment. Goal: \(profile.goal). Exercises logged in the last 48 hours are excluded. \(profile.readiness == "Low energy" ? "Reduced to two exercises for your energy today." : "Choose comfortable loads; no automatic weight increases.")"
        if names.isEmpty { explanation += " All matching exercises were trained recently. Consider a rest day or change equipment." }
    }
}
public enum ChatImport {
    public static func extract(_ data: Data) throws -> [JourneyEntry] {
        guard let conversations = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw CocoaError(.coderReadCorrupt) }
        let keywords = ["workout", "gym", "squat", "bench", "cycling", "bike", "weight", "deadlift", "reps", "sets", "leg press", "pulldown"]
        var result: [JourneyEntry] = []
        for conversation in conversations {
            let cid = conversation["id"] as? String ?? conversation["conversation_id"] as? String ?? ""
            guard !cid.isEmpty, let mapping = conversation["mapping"] as? [String: [String: Any]] else { continue }
            for (nodeID, node) in mapping {
                guard let message = node["message"] as? [String: Any], let content = message["content"] as? [String: Any], let parts = content["parts"] as? [Any] else { continue }
                let text = parts.compactMap { $0 as? String }.joined(separator: "\n")
                guard keywords.contains(where: { text.lowercased().contains($0) }) else { continue }
                var entry = JourneyEntry()
                let mid = message["id"] as? String ?? nodeID
                entry.sourceID = cid + ":" + mid
                entry.category = "Imported conversation"
                entry.text = text
                entry.originalText = text
                entry.originalTimestamp = message["create_time"] as? Double
                entry.date = Date(timeIntervalSince1970: entry.originalTimestamp ?? 0)
                let role = (message["author"] as? [String: Any])?["role"] as? String ?? "unknown"
                entry.status = role == "assistant" ? "advice" : "unclear"
                entry.source = "https://chatgpt.com/c/" + cid + " • Message " + mid + " • " + role + " • " + (conversation["title"] as? String ?? "Untitled")
                result.append(entry)
            }
        }
        return result.sorted { $0.date < $1.date }
    }
}
