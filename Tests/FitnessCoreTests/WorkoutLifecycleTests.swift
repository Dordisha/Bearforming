import XCTest
@testable import FitnessCore

final class WorkoutLifecycleTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testStartConsumesDraftPreservingOrderIDsAndSetsAcrossReload() throws {
        var state = FitnessState()
        let draft = Array(TrainingPlan(state: state, now: now).exercises.reversed())
        state.plannedExercises = draft
        state.restUntil = now.addingTimeInterval(90)
        state.startWorkout(exercises: draft, now: now)
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.active?.exercises, draft)
        XCTAssertEqual(restored.active?.startedAt, now)
        XCTAssertNil(restored.plannedExercises)
        XCTAssertNil(restored.restUntil)
    }
    func testResumeDoesNotReplaceActiveSessionOrDraft() {
        var state = FitnessState()
        state.startWorkout(exercises: [Exercise(name: "Seated row")], now: now)
        state.plannedExercises = [Exercise(name: "Leg press")]
        state.restUntil = now.addingTimeInterval(90)
        let before = state
        state.startWorkout(exercises: [Exercise(name: "Lat pulldown")], now: now.addingTimeInterval(60))
        XCTAssertEqual(state, before)
    }
    func testEmptyAndPainBlockedStartsPreserveDraft() {
        var state = FitnessState()
        let draft = [Exercise(name: "Leg press")]
        state.plannedExercises = draft
        state.startWorkout(exercises: [], now: now)
        XCTAssertNil(state.active)
        XCTAssertEqual(state.plannedExercises, draft)
        var profile = TrainingProfile(); profile.readiness = "Pain or unwell"
        state.profile = profile
        state.startWorkout(exercises: draft, now: now)
        XCTAssertNil(state.active)
        XCTAssertEqual(state.plannedExercises, draft)
    }
    func testFinishIsIdempotentAndNextPlanUsesCompletedHistory() throws {
        var state = FitnessState()
        state.startWorkout(exercises: [Exercise(name: "Leg press")], now: now)
        state.active?.exercises[0].sets[0].completedAt = now
        state.plannedExercises = [Exercise(name: "Leg press")] // legacy saved draft
        let expected = state.active?.exercises
        state.finishWorkout(now: now.addingTimeInterval(60))
        state.finishWorkout(now: now.addingTimeInterval(120))
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.history.count, 1)
        XCTAssertEqual(restored.history.first?.exercises, expected)
        XCTAssertEqual(restored.history.first?.finishedAt, now.addingTimeInterval(60))
        XCTAssertNil(restored.active)
        XCTAssertNil(restored.plannedExercises)
        XCTAssertNil(restored.restUntil)
        XCTAssertFalse(TrainingPlan(state: restored, now: now.addingTimeInterval(120)).names.contains("Leg press"))
    }
    func testFailedCandidateSaveLeavesDurablePreviewIntact() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("state.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var original = FitnessState()
        original.plannedExercises = [Exercise(name: "Seated row")]
        let repository = StateRepository(url: url)
        try repository.save(original)
        var candidate = original
        candidate.startWorkout(exercises: original.plannedExercises!, now: now)
        XCTAssertThrowsError(try StateRepository(url: url.appendingPathComponent("blocked.json")).save(candidate))
        XCTAssertEqual(try repository.load(), original)
    }
}
