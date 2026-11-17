import XCTest
@testable import FitnessCore

final class CardioTimerTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    func testStartRelaunchStopPreservesStrengthAndRequiresReview() throws {
        var state = FitnessState(); state.configureSplit(startingWith: "Lower", now: now)
        state.restUntil = now.addingTimeInterval(90)
        let before = state
        state.startCardio(category: "Cycling", now: now)
        let id = state.activeCardio!.id
        state = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        let entry = state.stopCardio(now: now.addingTimeInterval(1850))!
        XCTAssertEqual(entry.id, id); XCTAssertEqual(entry.durationMinutes, 30)
        XCTAssertFalse(entry.approved); XCTAssertEqual(entry.status, "unclear"); XCTAssertNil(entry.cardioEffort)
        XCTAssertNotNil(entry.originalText)
        XCTAssertEqual(state.plannedExercises, before.plannedExercises)
        XCTAssertEqual(state.nextSplitFocus, before.nextSplitFocus)
        XCTAssertEqual(state.restUntil, before.restUntil)
        XCTAssertEqual(state.history, before.history)
        XCTAssertNil(state.activeCardio)
        XCTAssertNil(state.stopCardio(now: now.addingTimeInterval(1900)))
        XCTAssertEqual(state.entries?.count, 1)
    }
    func testDuplicateStartAndConcurrentStrengthAreBlocked() {
        var state = FitnessState(); state.startCardio(category: "Cardio", now: now)
        let timer = state.activeCardio
        state.startCardio(category: "Cycling", now: now.addingTimeInterval(60))
        XCTAssertEqual(state.activeCardio, timer)
        state.startWorkout(exercises: [Exercise(name: "Leg press")], now: now)
        XCTAssertNil(state.active)
        state.discardCardio()
        state.startWorkout(exercises: [Exercise(name: "Leg press")], now: now)
        state.startCardio(category: "Cardio", now: now)
        XCTAssertNil(state.activeCardio)
    }
    func testPainAndUnsupportedCategoriesCannotStart() {
        var state = FitnessState(); state.profile = TrainingProfile(); state.profile?.readiness = "Pain or unwell"
        state.startCardio(category: "Cardio", now: now); XCTAssertNil(state.activeCardio)
        state.profile?.readiness = "Ready"
        state.startCardio(category: "Upper", now: now); XCTAssertNil(state.activeCardio)
    }
    func testClockAnomaliesShortAndLongTimersDoNotInventDuration() {
        var state = FitnessState(); state.startCardio(category: "Cardio", now: now)
        let before = state
        XCTAssertNil(state.stopCardio(now: now.addingTimeInterval(-1)))
        XCTAssertEqual(state, before)
        XCTAssertNil(state.stopCardio(now: now.addingTimeInterval(30))?.durationMinutes)
        state.startCardio(category: "Cardio", now: now)
        XCTAssertNil(state.stopCardio(now: now.addingTimeInterval(90000))?.durationMinutes)
        XCTAssertTrue(state.entries!.allSatisfy { !$0.approved && $0.status == "unclear" })
    }
    func testDiscardAndLegacyDoNotCreateActivity() throws {
        var state = try JSONDecoder().decode(FitnessState.self, from: Data(#"{"schemaVersion":1,"history":[]}"#.utf8))
        XCTAssertNil(state.activeCardio)
        let before = state
        state.startCardio(category: "Cycling", now: now); state.discardCardio()
        XCTAssertEqual(state, before)
    }
}
