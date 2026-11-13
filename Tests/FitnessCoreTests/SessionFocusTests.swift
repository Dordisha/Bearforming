import XCTest
@testable import FitnessCore

final class SessionFocusTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    func testOverrideGeneratesSixLowerExercisesWithoutChangingUsualFocus() {
        var state = FitnessState(); state.profile = TrainingProfile(); state.profile?.focus = "Upper"
        let original = state.profile
        state.changeSessionFocus("Lower", now: now)
        XCTAssertEqual(state.profile, original)
        XCTAssertEqual(state.plannedExercises?.count, 6)
        XCTAssertTrue(state.plannedExercises!.allSatisfy { ex in ExerciseCatalog.all.first { $0.name == ex.name }?.group == "Lower" })
        XCTAssertEqual(state.plannedExercises!.map { $0.sets.count }, [3, 3, 3, 3, 3, 3])
    }
    func testOverrideAndEditedDraftSurviveRoundTripAndReopen() throws {
        var state = FitnessState(); state.changeSessionFocus("Lower", now: now)
        state.plannedExercises?.removeLast()
        let original = state
        state = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        state.preparePreviewIfNeeded(now: now.addingTimeInterval(86400))
        XCTAssertEqual(state, original)
        XCTAssertEqual(state.planningProfile.focus, "Lower")
    }
    func testStartConsumesOverrideAndFinishReturnsToUsualFocus() {
        var state = FitnessState(); state.profile = TrainingProfile(); state.profile?.focus = "Upper"
        state.changeSessionFocus("Lower", now: now)
        let draft = state.plannedExercises!
        state.startWorkout(exercises: draft, now: now)
        XCTAssertNil(state.sessionFocus)
        XCTAssertEqual(state.active?.exercises, draft)
        let activeState = state
        state.changeSessionFocus("Push", now: now)
        XCTAssertEqual(state, activeState)
        state.finishWorkout(now: now)
        state.preparePreviewIfNeeded(now: now)
        XCTAssertNil(state.sessionFocus)
        XCTAssertEqual(state.planningProfile.focus, "Upper")
    }
    func testResetUsesOverrideAndExplicitReturnUsesUsualFocus() {
        var state = FitnessState(); state.profile = TrainingProfile(); state.profile?.focus = "Upper"
        state.changeSessionFocus("Lower", now: now)
        state.profile?.minutes = 30; state.refreshPreview(now: now)
        XCTAssertEqual(state.planningProfile.focus, "Lower")
        XCTAssertTrue(state.plannedExercises!.allSatisfy { $0.sets.count == 2 })
        state.changeSessionFocus(nil, now: now)
        XCTAssertNil(state.sessionFocus)
        XCTAssertEqual(state.planningProfile.focus, "Upper")
    }
    func testLegacyDecodeAndInvalidFocusPreserveState() throws {
        var state = try JSONDecoder().decode(FitnessState.self, from: Data(#"{"schemaVersion":1,"history":[]}"#.utf8))
        XCTAssertNil(state.sessionFocus)
        state.preparePreviewIfNeeded(now: now)
        let original = state
        state.changeSessionFocus("Cardio", now: now)
        XCTAssertEqual(state, original)
    }
    func testPainAndEquipmentGatesStillApply() {
        var state = FitnessState(); state.profile = TrainingProfile()
        state.profile?.equipment = "Bodyweight"
        state.changeSessionFocus("Lower", now: now)
        XCTAssertTrue(state.plannedExercises!.allSatisfy { ex in ExerciseCatalog.all.first { $0.name == ex.name }?.equipment == "Bodyweight" })
        state.profile?.readiness = "Pain or unwell"
        state.changeSessionFocus("Upper", now: now)
        XCTAssertTrue(state.plannedExercises!.isEmpty)
        state.startWorkout(exercises: [Exercise(name: "Seated row")], now: now)
        XCTAssertNil(state.active)
        XCTAssertEqual(state.sessionFocus, "Upper")
    }
}
