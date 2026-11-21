import XCTest
@testable import FitnessCore

final class PreviousPerformanceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    private func set(_ offset: TimeInterval?, weight: Double = 50) -> LoggedSet {
        var result = LoggedSet()
        result.completedAt = offset.map { now.addingTimeInterval($0) }
        result.weight = weight
        return result
    }
    func testLastPerformanceUsesCompletionNotWorkoutOpeningOrder() {
        let recent = Exercise(name: "Seated row", sets: [set(-60, weight: 60)])
        let older = Exercise(name: "Seated row", sets: [set(-3600, weight: 40)])
        var earlyOpened = Workout(exercises: [recent]); earlyOpened.startedAt = now.addingTimeInterval(-86400)
        var lateOpened = Workout(exercises: [older]); lateOpened.startedAt = now.addingTimeInterval(-4000)
        var state = FitnessState(); state.history = [lateOpened, earlyOpened]
        XCTAssertEqual(state.previousPerformance(for: "Seated row", now: now), recent)
        state.history.reverse()
        XCTAssertEqual(state.previousPerformance(for: "Seated row", now: now), recent)
    }
    func testOnlyCompletedPastSetsAreReturnedWithoutMutatingHistory() {
        let valid = set(-60)
        let boundary = set(0)
        let exercise = Exercise(name: "Leg press", sets: [valid, set(nil), set(60), boundary])
        var state = FitnessState(); state.history = [Workout(exercises: [exercise])]
        let original = state
        let evidence = state.previousPerformance(for: "Leg press", now: now)
        XCTAssertEqual(evidence?.id, exercise.id)
        XCTAssertEqual(evidence?.sets, [valid, boundary])
        XCTAssertEqual(state, original)
    }
    func testNoEvidenceDoesNotInventPreviousPerformance() {
        var state = FitnessState()
        state.history = [Workout(exercises: [Exercise(name: "Leg curl", sets: [set(nil), set(60)])])]
        state.active = Workout(exercises: [Exercise(name: "Leg curl", sets: [set(-1)])])
        state.plannedExercises = [Exercise(name: "Leg curl", sets: [set(-1)])]
        XCTAssertNil(state.previousPerformance(for: "Leg curl", now: now))
        XCTAssertNil(state.previousPerformance(for: "Seated row", now: now))
    }
    func testFutureSetDoesNotPromoteOlderExerciseAndNamesStayExact() {
        let older = Exercise(name: "Seated row", sets: [set(-3600), set(3600)])
        let recent = Exercise(name: "Seated row", sets: [set(-60)])
        let different = Exercise(name: "Dumbbell row", sets: [set(-1)])
        var state = FitnessState()
        state.history = [Workout(exercises: [older, recent, different])]
        XCTAssertEqual(state.previousPerformance(for: "Seated row", now: now), recent)
        XCTAssertEqual(state.previousPerformance(for: "Dumbbell row", now: now), different)
    }
}
