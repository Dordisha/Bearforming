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
    public var plannedExercises: [Exercise]?
    public var entries: [JourneyEntry]?
    public var profile: TrainingProfile?
    public var schemaVersion = 1
    public var active: Workout?
    public var history: [Workout] = []
    public var restUntil: Date?
    public init() {}
    /// Persist one draft so UI actions address the same exercise IDs that
    /// were displayed. Never replace an edited draft merely by reopening Today.
    public mutating func preparePreviewIfNeeded(now: Date = Date()) {
        guard plannedExercises == nil else { return }
        refreshPreview(now: now)
    }
    public mutating func refreshPreview(now: Date = Date()) {
        plannedExercises = TrainingPlan(state: self, now: now).exercises
    }
    /// The preview is a one-session draft. Consume it in the same saved state
    /// as the new workout so a later session gets a fresh recovery-aware plan.
    public mutating func startWorkout(exercises: [Exercise], now: Date = Date()) {
        guard active == nil, !exercises.isEmpty,
              profile?.readiness != "Pain or unwell" else { return }
        var workout = Workout(exercises: exercises)
        workout.startedAt = now
        active = workout
        plannedExercises = nil
        restUntil = nil
    }
    public mutating func finishWorkout(now: Date = Date()) {
        guard var workout = active else { return }
        workout.finishedAt = now
        history.append(workout)
        active = nil
        // Also retire previews left by versions predating startWorkout.
        plannedExercises = nil
        restUntil = nil
    }
    public func previousPerformance(for name: String, now: Date = Date()) -> Exercise? {
        var latest: Exercise?
        var latestCompletion: Date?
        for exercise in history.flatMap(\.exercises) where exercise.name == name {
            let completed = exercise.sets.filter { set in
                guard let date = set.completedAt else { return false }
                return date <= now
            }
            guard let date = completed.compactMap(\.completedAt).max() else { continue }
            if latestCompletion == nil || date > latestCompletion! {
                var evidence = exercise
                evidence.sets = completed
                latest = evidence
                latestCompletion = date
            }
        }
        return latest
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
    public var focus: String?
    public var targetCount: Int?
    public var warmedUp: Bool?
    public var returning: Bool?
    public var minutes = 40
    public var equipment = "Gym"
    public var goal = "Build consistency"
    public var readiness = "Ready"
    public init() {}
}
public struct ExerciseOption: Identifiable {
    public var id: String { name }
    public let name: String
    public let group: String
    public let equipment: String
}
public enum ExerciseCatalog {
    public static let all: [ExerciseOption] = [
        .init(name: "Leg press", group: "Lower", equipment: "Gym"),
        .init(name: "Dumbbell bench press", group: "Push", equipment: "Dumbbells"),
        .init(name: "Seated row", group: "Pull", equipment: "Gym"),
        .init(name: "Leg curl", group: "Lower", equipment: "Gym"),
        .init(name: "Lateral raise", group: "Push", equipment: "Dumbbells"),
        .init(name: "Dumbbell curl", group: "Pull", equipment: "Dumbbells"),
        .init(name: "Dead bug", group: "Core", equipment: "Bodyweight"),
        .init(name: "Lat pulldown", group: "Pull", equipment: "Gym"),
        .init(name: "Rope triceps pushdown", group: "Push", equipment: "Gym"),
        .init(name: "Leg extension", group: "Lower", equipment: "Gym"),
        .init(name: "Dumbbell shoulder press", group: "Push", equipment: "Dumbbells"),
        .init(name: "Goblet squat", group: "Lower", equipment: "Dumbbells"),
        .init(name: "Dumbbell row", group: "Pull", equipment: "Dumbbells"),
        .init(name: "Dumbbell floor press", group: "Push", equipment: "Dumbbells"),
        .init(name: "Glute bridge", group: "Lower", equipment: "Bodyweight"),
        .init(name: "Bodyweight squat", group: "Lower", equipment: "Bodyweight"),
        .init(name: "Wall push-up", group: "Push", equipment: "Bodyweight"),
        .init(name: "Bird dog", group: "Core", equipment: "Bodyweight"),
        .init(name: "Standing calf raise", group: "Lower", equipment: "Bodyweight")
    ]
    public static func choices(_ profile: TrainingProfile) -> [ExerciseOption] {
        all.filter { item in
            let equipment = profile.equipment == "Gym" || item.equipment == "Bodyweight" || item.equipment == profile.equipment
            let focus = profile.focus ?? "Full body"
            let matches = focus == "Full body" || item.group == focus || (focus == "Upper" && ["Push", "Pull", "Core"].contains(item.group))
            return equipment && matches
        }
    }
}
public struct TrainingPlan {
    public var exercises: [Exercise]
    public var names: [String] { exercises.map(\.name) }
    public var explanation: String
    public static func estimate(_ exercises: [Exercise], profile: TrainingProfile) -> Int {
        let seconds = exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { $0 + Double(max(1, $1.reps)) * 4 }
                + Double(max(0, exercise.sets.count - 1)) * 90 + 60
        }
        return Int(ceil(seconds / 60)) + (profile.warmedUp == true ? 0 : 5)
    }
    public init(state: FitnessState, now: Date = Date()) {
        let profile = state.profile ?? TrainingProfile()
        exercises = []
        if profile.readiness == "Pain or unwell" {
            explanation = "Pause planning while you feel pain or unwell. This app cannot assess symptoms."; return
        }
        // Set completion is the activity evidence; a session may have been opened
        // days earlier. Include saved active sets, but never planned or future sets.
        let logged = state.history + (state.active.map { [$0] } ?? [])
        let completed = logged.flatMap(\.exercises).filter { exercise in
            exercise.sets.contains { set in set.completedAt.map { $0 <= now } ?? false }
        }
        let familiar = Set(completed.map(\.name))
        let trained = Set(completed.filter { exercise in
            exercise.sets.contains { set in
                guard let date = set.completedAt else { return false }
                let age = now.timeIntervalSince(date)
                return age >= 0 && age < 172800
            }
        }.map(\.name))
        let eligible = ExerciseCatalog.choices(profile).filter { !trained.contains($0.name) }
        // Keep the catalog's movement-group sequence; prefer familiar exercises
        // within each group instead of allowing one group's history to dominate.
        var pools: [String: [ExerciseOption]] = [:]
        for group in Set(eligible.map(\.group)) {
            let items = eligible.filter { $0.group == group }
            pools[group] = items.filter { familiar.contains($0.name) }
                + items.filter { !familiar.contains($0.name) }
        }
        let options = eligible.map { item -> ExerciseOption in
            pools[item.group]!.removeFirst()
        }
        let recentCycling = (state.entries ?? []).contains { entry in
            let age = now.timeIntervalSince(entry.date)
            return entry.category == "Cycling" && entry.approved && entry.status == "completed"
                && age >= 0 && age < 172800
        }
        let reduced = profile.readiness == "Low energy" || profile.returning == true
        let target = min(reduced ? 4 : 7, max(1, profile.targetCount ?? (profile.minutes < 35 ? 4 : 6)))
        for option in options {
            let exercise = Exercise(name: option.name, sets: Array(repeating: 0, count: reduced || profile.minutes < 35 ? 2 : 3).map { _ in LoggedSet() })
            if exercises.count < target && Self.estimate(exercises + [exercise], profile: profile) <= profile.minutes {
                exercises.append(exercise)
            }
        }
        explanation = "\(exercises.count) exercises within your \(profile.minutes)-minute budget. Estimates allow 4 seconds per rep, 90-second rests and transitions; actual time varies. Warmup is \(profile.warmedUp == true ? "already completed" : "5 minutes, counted separately")."
        if reduced { explanation += " Reduced sets and accessories for today's feedback." }
        if exercises.contains(where: { familiar.contains($0.name) }) {
            explanation += " Familiar exercises are prioritized within each movement group using completed sets in your log; past weights are not prescribed." }
        if recentCycling {
            explanation += " Your reviewed Journey records include completed cycling within 48 hours. Check today's energy and leg fatigue; ride intensity is unknown, so sets and warmup are not automatically changed." }
        if !trained.isEmpty { explanation += " Recently logged exercises are excluded; related muscles may still overlap." }
        if exercises.count < target { explanation += " Fewer options fit the equipment, focus, recent log and time budget." }
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
