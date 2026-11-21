import XCTest
@testable import FitnessCore

final class PartialHistoryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    // Synthetic fixture only; not an owner's workout record.
    private var plan: [Exercise] {
        ["Dumbbell bench press", "Seated row", "Lat pulldown", "Dumbbell shoulder press", "Leg press", "Leg curl"].map { Exercise(name: $0) }
    }

    func testSixMovementPartialFinishReopensWithCompletedOnlyEvidenceAndIntactPlan() throws {
        var state = FitnessState(); state.configureSplit(startingWith: "Upper", now: now)
        state.plannedExercises = plan
        let authored = state.plannedExercises!
        state.startWorkout(exercises: authored, now: now)
        for index in 0..<4 { state.active?.exercises[index].sets[0].completedAt = now.addingTimeInterval(60) }
        state.setRemainingSetsSkipped(exerciseID: authored[5].id, skipped: true)
        let savedPlan = state.active!.exercises
        state.finishWorkout(now: now.addingTimeInterval(600))
        state.finishWorkout(now: now.addingTimeInterval(601))
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let repository = StateRepository(url: folder.appendingPathComponent("state.json"))
        try repository.save(state); state = try repository.load()
        let workout = try XCTUnwrap(state.history.first)
        XCTAssertEqual(state.history.count, 1); XCTAssertEqual(workout.exercises, savedPlan)
        XCTAssertEqual(workout.exercises.map(\.id), authored.map(\.id))
        XCTAssertEqual(workout.exercises.count, 6)
        XCTAssertEqual(workout.completedExercises(now: now.addingTimeInterval(700)).map(\.name), Array(authored.prefix(4)).map(\.name))
        XCTAssertEqual(workout.completedExercises(now: now.addingTimeInterval(700)).flatMap(\.sets).count, 4)
        XCTAssertEqual(state.nextSplitFocus, "Upper") // Partial work does not advance.
        XCTAssertEqual(NextFocusSuggestion(state: state, now: now.addingTimeInterval(700)).focus, "Lower")
        state.plannedExercises = [authored[4], authored[5]]
        XCTAssertFalse(SessionPreviewSummary(state: state, now: now.addingTimeInterval(700)).explanation.contains("completed sets logged within 48 hours"))
        state.plannedExercises = [authored[0]]
        XCTAssertTrue(SessionPreviewSummary(state: state, now: now.addingTimeInterval(700)).explanation.contains("completed sets logged within 48 hours"))
    }

    func testPendingImportedCandidateCannotInfluenceExplanationBeforeReviewAndCompletion() {
        var state = FitnessState(); state.plannedExercises = plan
        let original = SessionPreviewSummary(state: state, now: now).explanation
        var candidate = JourneyEntry(); candidate.category = "Cycling"; candidate.date = now
        candidate.sourceID = "synthetic:pending-ride"; candidate.status = "completed"
        candidate.approved = true
        state.stageImportedEntries([candidate])
        XCTAssertFalse(state.entries![0].approved)
        XCTAssertEqual(SessionPreviewSummary(state: state, now: now).explanation, original)
        state.entries![0].approved = true; state.entries![0].status = "planned"
        XCTAssertEqual(SessionPreviewSummary(state: state, now: now).explanation, original)
        state.entries![0].status = "completed"
        XCTAssertTrue(SessionPreviewSummary(state: state, now: now).explanation.contains("completed cycling within 48 hours"))
        XCTAssertEqual(state.plannedExercises?.count, 6); XCTAssertTrue(state.history.isEmpty)
    }

    func testSkipRestoreRetainsCompletedSetsAndAllAuthoredValues() {
        var state = FitnessState(); let authored = plan
        state.startWorkout(exercises: authored, now: now)
        state.active?.exercises[0].sets[0].completedAt = now
        let before = state
        state.setRemainingSetsSkipped(exerciseID: authored[0].id, skipped: true)
        XCTAssertEqual(state.active?.exercises[0].completedSets(now: now).count, 1)
        XCTAssertEqual(state.active?.exercises[0].sets, before.active?.exercises[0].sets)
        state.setRemainingSetsSkipped(exerciseID: authored[0].id, skipped: false)
        XCTAssertEqual(state, before)
        state.setRemainingSetsSkipped(exerciseID: UUID(), skipped: true)
        XCTAssertEqual(state, before)
    }

    func testLegacyPlannedAndFutureSetsNeverBecomeCompletedDisplayEvidence() throws {
        var workout = Workout(exercises: plan)
        workout.exercises[0].sets[0].completedAt = now.addingTimeInterval(100)
        workout.exercises[1].remainingSetsSkipped = true
        workout = try JSONDecoder().decode(Workout.self, from: JSONEncoder().encode(workout))
        XCTAssertNil(workout.exercises[0].remainingSetsSkipped)
        XCTAssertTrue(workout.completedExercises(now: now).isEmpty)
        XCTAssertEqual(workout.exercises.count, 6)
    }
}
