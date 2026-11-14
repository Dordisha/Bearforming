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
    public var splitSlot: String?
    public var exercises: [Exercise]
    public init(exercises: [Exercise]) { self.exercises = exercises }
}
public struct FitnessState: Codable, Equatable {
    public var plannedExercises: [Exercise]?
    /// Applies to the next draft only; nil preserves the usual profile focus.
    public var sessionFocus: String?
    /// nil disables the opt-in rolling sequence. Time passing never advances it.
    public var nextSplitFocus: String?
    public mutating func configureSplit(startingWith focus: String?, now: Date = Date()) {
        guard active == nil, focus == nil || ["Upper", "Lower"].contains(focus!) else { return }
        nextSplitFocus = focus
        sessionFocus = nil
        refreshPreview(now: now)
    }
    public var planningProfile: TrainingProfile {
        var value = profile ?? TrainingProfile()
        if let next = nextSplitFocus, ["Upper", "Lower"].contains(next) { value.focus = next }
        if let focus = sessionFocus, TrainingProfile.strengthFocuses.contains(focus) {
            value.focus = focus
        }
        return value
    }
    /// Explicit replacement operation. UI confirms before invoking this on an edited draft.
    public mutating func changeSessionFocus(_ focus: String?, now: Date = Date()) {
        guard active == nil, focus == nil || TrainingProfile.strengthFocuses.contains(focus!) else { return }
        sessionFocus = focus
        refreshPreview(now: now)
    }
    public var entries: [JourneyEntry]?
    public var profile: TrainingProfile?
    public var schemaVersion = 1
    public var active: Workout?
    public var history: [Workout] = []
    public var restUntil: Date?
    public init() {}
    /// Merge review candidates without replacing the owner's edits or approval.
    @discardableResult
    public mutating func stageImportedEntries(_ incoming: [JourneyEntry]) -> ImportSummary {
        var saved = entries ?? []
        var known = Set(saved.map(\.sourceID))
        var summary = ImportSummary()
        for var entry in incoming {
            guard !entry.sourceID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                summary.invalid += 1; continue
            }
            guard known.insert(entry.sourceID).inserted else {
                summary.duplicates += 1; continue
            }
            entry.approved = false
            saved.append(entry)
            summary.added += 1
        }
        if summary.added > 0 { entries = saved }
        return summary
    }
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
        if let next = nextSplitFocus, ["Upper", "Lower"].contains(next), planningProfile.focus == next {
            workout.splitSlot = next
        }
        active = workout
        plannedExercises = nil
        sessionFocus = nil
        restUntil = nil
    }
    public mutating func finishWorkout(now: Date = Date()) {
        guard var workout = active else { return }
        workout.finishedAt = now
        if let slot = workout.splitSlot, nextSplitFocus == slot,
           Self.completesSplit(workout, slot: slot, now: now) {
            nextSplitFocus = slot == "Upper" ? "Lower" : "Upper"
        }
        history.append(workout)
        active = nil
        // Also retire previews left by versions predating startWorkout.
        plannedExercises = nil
        sessionFocus = nil
        restUntil = nil
    }
    /// Only fully logged, matching strength work advances the sequence.
    /// Unknown/opposite movements, empty sets and invalid dates do not qualify.
    private static func completesSplit(_ workout: Workout, slot: String, now: Date) -> Bool {
        guard ["Upper", "Lower"].contains(slot), !workout.exercises.isEmpty else { return false }
        var hasPrimary = false
        for exercise in workout.exercises {
            guard let option = ExerciseCatalog.all.first(where: { $0.name == exercise.name }),
                  !exercise.sets.isEmpty,
                  exercise.sets.allSatisfy({ set in
                      guard let date = set.completedAt else { return false }
                      return date >= workout.startedAt && date <= now
                  }) else { return false }
            if option.group == "Core" { continue }
            let group = option.group == "Lower" ? "Lower" : "Upper"
            guard group == slot else { return false }
            hasPrimary = true
        }
        return hasPrimary
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

public struct ImportSummary: Equatable {
    public var added = 0
    public var duplicates = 0
    public var invalid = 0
    public init() {}
    public var message: String {
        "Added \(added) notes for review. Skipped \(duplicates) duplicates and \(invalid) records without message identity. Existing records were preserved."
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
    public static let strengthFocuses = ["Full body", "Upper", "Lower", "Push", "Pull"]
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
/// Advisory only: does not advance a program or rewrite a saved draft.
/// Classify actual sets from the most recently finished session, not its title.
public struct NextFocusSuggestion {
    public let focus: String?
    public let explanation: String
    public init(state: FitnessState, now: Date = Date()) {
        focus = Self.suggestedFocus(state: state, now: now)
        if state.active != nil {
            explanation = "Finish or resume your active workout before choosing the next focus."
        } else if state.profile?.readiness == "Pain or unwell" {
            explanation = "Pause planning while you feel pain or unwell."
        } else if let focus = focus {
            let previous = focus == "Lower" ? "upper-body" : "lower-body"
            explanation = "Your most recently finished session includes logged \(previous) work within 48 hours. Consider \(focus.lowercased()) body next if you feel ready. This is a focus suggestion, not a recovery measurement; your saved workout has not changed."
        } else {
            explanation = "No clear recent upper/lower pattern in your finished workout log. Choose a focus based on how you feel; your saved workout has not changed."
        }
    }
    private static func suggestedFocus(state: FitnessState, now: Date) -> String? {
        guard state.active == nil, state.profile?.readiness != "Pain or unwell" else { return nil }
        let finished = state.history.filter {
            guard let end = $0.finishedAt else { return false }
            return end <= now && end >= $0.startedAt
        }.max { $0.finishedAt! < $1.finishedAt! }
        guard let workout = finished, let end = workout.finishedAt else { return nil }
        var groups = Set<String>()
        for exercise in workout.exercises {
            let logged = exercise.sets.contains { set in
                guard let date = set.completedAt else { return false }
                return date >= workout.startedAt && date <= end
                    && now.timeIntervalSince(date) >= 0 && now.timeIntervalSince(date) < 172800
            }
            guard logged else { continue }
            // Unknown completed movements prevent a confident classification.
            guard let option = ExerciseCatalog.all.first(where: { $0.name == exercise.name }) else { return nil }
            if option.group == "Lower" { groups.insert("Lower") }
            else if ["Push", "Pull"].contains(option.group) { groups.insert("Upper") }
            // Core is neutral and never establishes an upper/lower pattern alone.
        }
        if groups == ["Upper"] { return "Lower" }
        if groups == ["Lower"] { return "Upper" }
        return nil
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
        let profile = state.planningProfile
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
/// A read-only description of the saved draft, never of a newly generated plan.
/// Legacy drafts have no generation metadata, so do not infer their focus or rationale.
public struct SessionPreviewSummary {
    public let exerciseCount: Int
    public let setCount: Int
    public let minutes: Int
    public let explanation: String
    public init(state: FitnessState, now: Date = Date()) {
        let exercises = state.plannedExercises ?? []
        let profile = state.planningProfile
        exerciseCount = exercises.count
        setCount = exercises.reduce(0) { $0 + $1.sets.count }
        minutes = exercises.isEmpty ? 0 : TrainingPlan.estimate(exercises, profile: profile)
        var text = exercises.isEmpty
            ? "No exercises in your saved draft. Add an exercise or reset the suggestion."
            : "This is your saved draft, including any edits. Time is an estimate including warmup; actual time varies. Reset suggestion to rebuild from current preferences and logged activity."
        if profile.readiness == "Pain or unwell" {
            text += " Pause planning while you feel pain or unwell. This app cannot assess symptoms."
        }
        let names = Set(exercises.map(\.name))
        let logged = state.history + (state.active.map { [$0] } ?? [])
        let overlap = logged.flatMap(\.exercises).contains { exercise in
            names.contains(exercise.name) && exercise.sets.contains { set in
                guard let date = set.completedAt else { return false }
                let age = now.timeIntervalSince(date)
                return age >= 0 && age < 172800
            }
        }
        if overlap {
            text += " This draft includes exercises with completed sets logged within 48 hours. Review before starting; your draft has not been changed."
        }
        if (state.entries ?? []).contains(where: { entry in
            let age = now.timeIntervalSince(entry.date)
            return entry.category == "Cycling" && entry.approved && entry.status == "completed"
                && age >= 0 && age < 172800
        }) {
            text += " Your reviewed records include completed cycling within 48 hours. Check your energy and leg fatigue; ride intensity is unknown. Cycling has not automatically changed this draft or marked warmup complete."
        }
        explanation = text
    }
}

public enum ChatImport {
    private static func normalized(_ text: String) -> String {
        text.lowercased().split { !$0.isLetter && !$0.isNumber }.joined(separator: " ")
    }
    private static func matchesFitnessText(_ text: String) -> Bool {
        let keywords = ["workout", "gym", "squat", "bench", "cycling", "bike", "weight", "deadlift", "reps", "sets", "leg press", "pulldown"]
        // Recognition only: these names do not establish completion, dates,
        // units, or a safe training load. Keep the original message unchanged.
        let variants = ["incline dumbbell press", "incline db press", "shoulder press", "supine press", "lat pull down"]
        let candidate = normalized(text)
        return (keywords + ExerciseCatalog.all.map(\.name) + variants)
            .contains { candidate.contains(normalized($0)) }
    }
    public static func extract(_ data: Data) throws -> [JourneyEntry] {
        guard let conversations = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw CocoaError(.coderReadCorrupt) }
        var result: [JourneyEntry] = []
        for conversation in conversations {
            let cid = conversation["id"] as? String ?? conversation["conversation_id"] as? String ?? ""
            guard !cid.isEmpty, let mapping = conversation["mapping"] as? [String: [String: Any]] else { continue }
            for (nodeID, node) in mapping {
                guard let message = node["message"] as? [String: Any], let content = message["content"] as? [String: Any], let parts = content["parts"] as? [Any] else { continue }
                let text = parts.compactMap { $0 as? String }.joined(separator: "\n")
                guard matchesFitnessText(text) else { continue }
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

/// Validate an edit before replacing durable set values. No grouping or exponent notation.
public enum SetInput {
    public static func parse(_ text: String, maximum: Double, integerOnly: Bool,
                             decimalSeparator: String = ".") -> Double? {
        let normalized = text.replacingOccurrences(of: decimalSeparator, with: ".")
        guard !normalized.isEmpty,
              normalized.allSatisfy({ "0123456789.".contains($0) }),
              normalized.filter({ $0 == "." }).count <= 1,
              let number = Double(normalized), number.isFinite,
              number >= 0, number <= maximum,
              !integerOnly || number.rounded() == number else { return nil }
        return number
    }
}
