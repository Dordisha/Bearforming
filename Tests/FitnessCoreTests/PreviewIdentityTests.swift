import XCTest
@testable import FitnessCore

final class PreviewIdentityTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    func testFirstRemoveAddressesDisplayedExerciseAndSurvivesReload() throws {
        var state = FitnessState()
        state.preparePreviewIfNeeded(now: now)
        let displayed = try XCTUnwrap(state.plannedExercises)
        XCTAssertEqual(displayed.count, 6)
        let removedID = displayed[0].id
        state.preparePreviewIfNeeded(now: now.addingTimeInterval(1))
        state.plannedExercises?.removeAll { $0.id == removedID }
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.plannedExercises, Array(displayed.dropFirst()))
    }
    func testFirstSubstitutionKeepsOtherRowsAndEditedDraftIsNotRegenerated() throws {
        var state = FitnessState(); state.preparePreviewIfNeeded(now: now)
        let displayed = try XCTUnwrap(state.plannedExercises)
        let target = displayed[0]
        state.preparePreviewIfNeeded(now: now.addingTimeInterval(1))
        let index = try XCTUnwrap(state.plannedExercises?.firstIndex { $0.id == target.id })
        state.plannedExercises?[index] = Exercise(name: "Leg extension", sets: target.sets)
        let edited = state.plannedExercises
        state.preparePreviewIfNeeded(now: now.addingTimeInterval(60))
        XCTAssertEqual(state.plannedExercises, edited)
        XCTAssertEqual(state.plannedExercises?.first?.name, "Leg extension")
        XCTAssertEqual(state.plannedExercises?.first?.sets, target.sets)
        XCTAssertEqual(Array(state.plannedExercises!.dropFirst()), Array(displayed.dropFirst()))
    }
    func testEmptyEditedPreviewIsPreservedUntilExplicitReset() {
        var state = FitnessState(); state.plannedExercises = []
        state.preparePreviewIfNeeded(now: now)
        XCTAssertEqual(state.plannedExercises, [])
        state.refreshPreview(now: now)
        XCTAssertEqual(state.plannedExercises?.count, 6)
    }
    func testPreferenceRefreshAndNextSessionRespectCurrentState() {
        var state = FitnessState(); state.preparePreviewIfNeeded(now: now)
        var profile = TrainingProfile(); profile.equipment = "Bodyweight"; profile.focus = "Lower"
        state.profile = profile; state.refreshPreview(now: now)
        XCTAssertTrue(state.plannedExercises!.allSatisfy { exercise in
            ExerciseCatalog.all.contains { $0.name == exercise.name && $0.equipment == "Bodyweight" && $0.group == "Lower" }
        })
        state.profile = nil; state.refreshPreview(now: now)
        state.startWorkout(exercises: state.plannedExercises!, now: now)
        state.active?.exercises[0].sets[0].completedAt = now
        let trainedName = state.active!.exercises[0].name
        state.finishWorkout(now: now.addingTimeInterval(60))
        state.preparePreviewIfNeeded(now: now.addingTimeInterval(120))
        XCTAssertFalse(state.plannedExercises!.contains { $0.name == trainedName })
    }
}
