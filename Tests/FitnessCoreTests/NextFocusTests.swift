import XCTest
@testable import FitnessCore

final class NextFocusTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    private func session(_ names: [String], age: TimeInterval = 3600) -> Workout {
        var set = LoggedSet(); set.completedAt = now.addingTimeInterval(-age)
        var workout = Workout(exercises: names.map { Exercise(name: $0, sets: [set]) })
        workout.startedAt = now.addingTimeInterval(-age - 600)
        workout.finishedAt = now.addingTimeInterval(-age + 60)
        return workout
    }
    func testUpperAndLowerEvidenceSuggestOppositeWithoutMutatingDraft() {
        for (names, expected) in [(["Seated row", "Dumbbell bench press", "Dead bug"], "Lower"), (["Leg press", "Leg curl"], "Upper")] {
            var state = FitnessState(); state.history = [session(names)]
            state.preparePreviewIfNeeded(now: now)
            let before = state
            XCTAssertEqual(NextFocusSuggestion(state: state, now: now).focus, expected)
            XCTAssertEqual(state, before)
        }
    }
    func testMixedUnknownCoreAndEmptyHistoryDoNotGuess() {
        for names in [["Leg press", "Seated row"], ["Seated row", "Custom movement"], ["Dead bug"], []] {
            var state = FitnessState(); state.history = [session(names)]
            XCTAssertNil(NextFocusSuggestion(state: state, now: now).focus)
        }
        XCTAssertNil(NextFocusSuggestion(state: FitnessState(), now: now).focus)
    }
    func testMostRecentFinishedSessionWinsRegardlessOfArrayOrder() {
        let older = session(["Leg press"], age: 7200)
        let newer = session(["Seated row"])
        for history in [[older, newer], [newer, older]] {
            var state = FitnessState(); state.history = history
            XCTAssertEqual(NextFocusSuggestion(state: state, now: now).focus, "Lower")
        }
    }
    func testInvalidUncompletedFutureAndBoundaryEvidenceIgnored() {
        var valid = session(["Seated row"])
        var cases: [Workout] = [session(["Seated row"], age: 172800), session(["Seated row"], age: -100)]
        valid.exercises[0].sets[0].completedAt = nil; cases.append(valid)
        valid = session(["Seated row"]); valid.finishedAt = nil; cases.append(valid)
        valid = session(["Seated row"]); valid.exercises[0].sets[0].completedAt = now; cases.append(valid)
        valid = session(["Seated row"]); valid.startedAt = now; cases.append(valid)
        for workout in cases {
            var state = FitnessState(); state.history = [workout]
            XCTAssertNil(NextFocusSuggestion(state: state, now: now).focus)
        }
    }
    func testActivePainAndJourneyNotesCannotEstablishNextFocus() {
        var state = FitnessState(); state.history = [session(["Seated row"])]
        state.active = session(["Leg press"])
        XCTAssertNil(NextFocusSuggestion(state: state, now: now).focus)
        state.active = nil; state.profile = TrainingProfile(); state.profile?.readiness = "Pain or unwell"
        XCTAssertNil(NextFocusSuggestion(state: state, now: now).focus)
        state = FitnessState()
        var entry = JourneyEntry(); entry.category = "Cycling"; entry.approved = true; entry.status = "completed"; entry.date = now
        state.entries = [entry]
        XCTAssertNil(NextFocusSuggestion(state: state, now: now).focus)
    }
}
