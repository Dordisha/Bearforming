import XCTest
@testable import FitnessCore

final class HistoryPlanningTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    private func workout(_ name: String, completed: Date?, started: Date) -> Workout {
        var set = LoggedSet(); set.completedAt = completed
        var workout = Workout(exercises: [Exercise(name: name, sets: [set])])
        workout.startedAt = started
        return workout
    }
    func testFamiliarExercisesKeepMovementBalanceAndBudget() {
        var state = FitnessState()
        state.history = [workout("Lat pulldown", completed: now.addingTimeInterval(-200000), started: now.addingTimeInterval(-200100))]
        let plan = TrainingPlan(state: state, now: now)
        XCTAssertEqual(plan.names[2], "Lat pulldown")
        XCTAssertEqual(plan.exercises.count, 6)
        XCTAssertLessThanOrEqual(TrainingPlan.estimate(plan.exercises, profile: TrainingProfile()), 40)
        XCTAssertTrue(plan.exercises.flatMap(\.sets).allSatisfy { $0.weight == 0 && $0.completedAt == nil })
        let groups = plan.names.map { name in ExerciseCatalog.all.first { $0.name == name }!.group }
        XCTAssertEqual(groups, ["Lower", "Push", "Pull", "Lower", "Push", "Pull"])
    }
    func testRecoveryUsesSetTimeAndIncludesActiveWorkout() {
        var state = FitnessState()
        state.active = workout("Leg press", completed: now.addingTimeInterval(-60), started: now.addingTimeInterval(-300000))
        XCTAssertFalse(TrainingPlan(state: state, now: now).names.contains("Leg press"))
        state.history = [state.active!]; state.active = nil
        XCTAssertFalse(TrainingPlan(state: state, now: now).names.contains("Leg press"))
    }
    func testRecoveryBoundaryAndFutureOrUncompletedSets() {
        for offset: TimeInterval? in [-172800, 60, nil] {
            var state = FitnessState()
            state.history = [workout("Leg press", completed: offset.map { now.addingTimeInterval($0) }, started: now)]
            XCTAssertTrue(TrainingPlan(state: state, now: now).names.contains("Leg press"))
        }
        var state = FitnessState()
        state.history = [workout("Leg press", completed: now.addingTimeInterval(-172799), started: now)]
        XCTAssertFalse(TrainingPlan(state: state, now: now).names.contains("Leg press"))
    }
    func testFutureAndPlannedSetsDoNotPersonalize() {
        for completion in [nil, now.addingTimeInterval(60)] as [Date?] {
            var state = FitnessState()
            state.history = [workout("Lat pulldown", completed: completion, started: now)]
            XCTAssertEqual(TrainingPlan(state: state, now: now).names[2], "Seated row")
        }
    }
    func testCyclingRequiresReviewCompletionCategoryAndRecentDate() {
        var entry = JourneyEntry()
        entry.category = "Cycling"; entry.status = "completed"; entry.approved = true
        entry.date = now.addingTimeInterval(-3600)
        var state = FitnessState(); state.entries = [entry]
        let plan = TrainingPlan(state: state, now: now)
        XCTAssertTrue(plan.explanation.contains("completed cycling within 48 hours"))
        XCTAssertEqual(plan.names, TrainingPlan(state: FitnessState(), now: now).names)
        XCTAssertEqual(plan.exercises.map { $0.sets.count }, [3, 3, 3, 3, 3, 3])
        XCTAssertTrue(plan.explanation.contains("5 minutes, counted separately"))
        var invalid: [JourneyEntry] = []
        var copy = entry; copy.approved = false; invalid.append(copy)
        for status in ["planned", "advice", "unclear"] { copy = entry; copy.status = status; invalid.append(copy) }
        copy = entry; copy.category = "Imported conversation"; invalid.append(copy)
        for age: TimeInterval in [-1, 172800] { copy = entry; copy.date = now.addingTimeInterval(-age); invalid.append(copy) }
        for item in invalid {
            state.entries = [item]
            XCTAssertFalse(TrainingPlan(state: state, now: now).explanation.contains("completed cycling within 48 hours"))
        }
    }
    func testHistoryCannotOverrideEquipmentFocusOrReadiness() {
        var state = FitnessState()
        state.history = [workout("Lat pulldown", completed: now.addingTimeInterval(-200000), started: now)]
        var profile = TrainingProfile(); profile.equipment = "Bodyweight"; profile.focus = "Lower"
        state.profile = profile
        XCTAssertFalse(TrainingPlan(state: state, now: now).names.contains("Lat pulldown"))
        profile.readiness = "Low energy"; state.profile = profile
        XCTAssertTrue(TrainingPlan(state: state, now: now).exercises.allSatisfy { $0.sets.count == 2 })
        profile.readiness = "Pain or unwell"; state.profile = profile
        XCTAssertTrue(TrainingPlan(state: state, now: now).exercises.isEmpty)
    }
}
