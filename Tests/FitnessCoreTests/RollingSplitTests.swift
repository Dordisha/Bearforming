import XCTest
@testable import FitnessCore

final class RollingSplitTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    private func started() -> FitnessState {
        var state = FitnessState(); state.configureSplit(startingWith: "Upper", now: now)
        state.startWorkout(exercises: state.plannedExercises!, now: now)
        return state
    }
    private func complete(_ state: inout FitnessState) {
        for i in state.active!.exercises.indices {
            for j in state.active!.exercises[i].sets.indices {
                state.active!.exercises[i].sets[j].completedAt = now.addingTimeInterval(60)
            }
        }
    }
    func testCompleteMatchingSessionAdvancesOnceAndKeepsSixExerciseDefault() {
        var state = started()
        XCTAssertEqual(state.active?.exercises.count, 6)
        XCTAssertEqual(state.active?.splitSlot, "Upper")
        complete(&state); state.finishWorkout(now: now.addingTimeInterval(120))
        XCTAssertEqual(state.nextSplitFocus, "Lower")
        state.finishWorkout(now: now.addingTimeInterval(130))
        XCTAssertEqual(state.history.count, 1)
        state.preparePreviewIfNeeded(now: now.addingTimeInterval(180))
        XCTAssertEqual(state.plannedExercises?.count, 6)
        XCTAssertEqual(state.planningProfile.focus, "Lower")
    }
    func testPartialEmptyAndInvalidDatesDoNotAdvance() {
        for mode in 0...4 {
            var state = started(); complete(&state)
            if mode == 0 { state.active!.exercises[0].sets[0].completedAt = nil }
            if mode == 1 { state.active!.exercises[0].sets = [] }
            if mode == 2 { state.active!.exercises = [] }
            if mode == 3 { state.active!.exercises[0].sets[0].completedAt = now.addingTimeInterval(-1) }
            if mode == 4 { state.active!.exercises[0].sets[0].completedAt = now.addingTimeInterval(1000) }
            state.finishWorkout(now: now.addingTimeInterval(120))
            XCTAssertEqual(state.nextSplitFocus, "Upper")
        }
    }
    func testDifferentFocusDoesNotConsumeSlot() {
        var state = FitnessState(); state.configureSplit(startingWith: "Upper", now: now)
        state.changeSessionFocus("Lower", now: now)
        state.startWorkout(exercises: state.plannedExercises!, now: now)
        XCTAssertNil(state.active?.splitSlot)
        complete(&state); state.finishWorkout(now: now.addingTimeInterval(120))
        XCTAssertEqual(state.nextSplitFocus, "Upper")
    }
    func testUnknownOppositeAndCoreOnlyEditsCannotAdvance() {
        for name in ["Custom movement", "Leg press", "Dead bug"] {
            var state = started()
            state.active!.exercises = [Exercise(name: name)]
            complete(&state); state.finishWorkout(now: now.addingTimeInterval(120))
            XCTAssertEqual(state.nextSplitFocus, "Upper")
        }
    }
    func testRelaunchAndMissedDaysPreserveSlotAndEditedPreview() throws {
        var state = FitnessState(); state.configureSplit(startingWith: "Lower", now: now)
        state.plannedExercises?.removeLast()
        let before = state
        state = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        state.preparePreviewIfNeeded(now: now.addingTimeInterval(864000))
        XCTAssertEqual(state, before)
        state.startWorkout(exercises: state.plannedExercises!, now: now)
        state = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        complete(&state); state.finishWorkout(now: now.addingTimeInterval(120))
        XCTAssertEqual(state.nextSplitFocus, "Upper")
    }
    func testConfigurationGuardDisableAndLegacyCompatibility() throws {
        var state = started(); let before = state
        state.configureSplit(startingWith: nil, now: now)
        XCTAssertEqual(state, before)
        state.finishWorkout(now: now)
        state.profile = TrainingProfile(); state.profile?.focus = "Pull"
        state.configureSplit(startingWith: nil, now: now)
        XCTAssertNil(state.nextSplitFocus)
        XCTAssertEqual(state.planningProfile.focus, "Pull")
        let disabled = state; state.configureSplit(startingWith: "Cardio", now: now)
        XCTAssertEqual(state, disabled)
        let legacy = try JSONDecoder().decode(FitnessState.self, from: Data(#"{"schemaVersion":1,"history":[]}"#.utf8))
        XCTAssertNil(legacy.nextSplitFocus)
    }
}
