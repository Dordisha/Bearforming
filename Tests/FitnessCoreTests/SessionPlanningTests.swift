import XCTest
@testable import FitnessCore

final class SessionPlanningTests: XCTestCase {
    func testStandardSessionHasSixAndFits() {
        let state = FitnessState()
        let plan = TrainingPlan(state: state)
        XCTAssertEqual(plan.exercises.count, 6)
        XCTAssertLessThanOrEqual(TrainingPlan.estimate(plan.exercises, profile: TrainingProfile()), 40)
    }
    func testShortAndReturnSessions() {
        var state = FitnessState()
        var profile = TrainingProfile(); profile.minutes = 20
        state.profile = profile
        let short = TrainingPlan(state: state)
        XCTAssertLessThanOrEqual(TrainingPlan.estimate(short.exercises, profile: profile), 20)
        profile.minutes = 60; profile.returning = true; state.profile = profile
        let reduced = TrainingPlan(state: state)
        XCTAssertLessThanOrEqual(reduced.exercises.count, 4)
        XCTAssertTrue(reduced.exercises.allSatisfy { $0.sets.count == 2 })
    }
    func testEquipmentAndFocus() {
        var state = FitnessState(); var profile = TrainingProfile()
        profile.equipment = "Bodyweight"; profile.focus = "Lower"; state.profile = profile
        let plan = TrainingPlan(state: state)
        XCTAssertFalse(plan.exercises.isEmpty)
        for name in plan.names {
            XCTAssertTrue(ExerciseCatalog.all.contains { $0.name == name && $0.equipment == "Bodyweight" && $0.group == "Lower" })
        }
    }
    func testPreviewRoundTripKeepsOrderAndIDs() throws {
        var state = FitnessState()
        state.plannedExercises = Array(TrainingPlan(state: state).exercises.reversed())
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.plannedExercises, state.plannedExercises)
    }
}
