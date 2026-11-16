import XCTest
@testable import FitnessCore

final class JourneySaveTests: XCTestCase {
    func testCardioSavePreservesStrengthStateAndExplicitStatuses() throws {
        var state = FitnessState(); state.configureSplit(startingWith: "Lower")
        state.plannedExercises?.removeLast()
        state.active = Workout(exercises: [Exercise(name: "Seated row")])
        state.restUntil = Date(timeIntervalSince1970: 2_000_000_000)
        state.sessionFocus = "Upper"
        let before = state
        var entry = JourneyEntry(); entry.category = "Cycling"; entry.text = "Synthetic ride"
        XCTAssertTrue(entry.setCardioDetails(duration: "30", effort: "Unknown"))
        state.saveJourneyEntry(entry)
        XCTAssertEqual(state.entries, [entry])
        XCTAssertFalse(state.entries![0].approved)
        XCTAssertEqual(state.entries![0].status, "unclear")
        XCTAssertEqual(state.active, before.active)
        XCTAssertEqual(state.plannedExercises, before.plannedExercises)
        XCTAssertEqual(state.nextSplitFocus, before.nextSplitFocus)
        XCTAssertEqual(state.sessionFocus, before.sessionFocus)
        XCTAssertEqual(state.restUntil, before.restUntil)
        XCTAssertEqual(state.history, before.history)
        XCTAssertEqual(state.profile, before.profile)
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored, state)
    }
    func testRepeatedSaveUpdatesSameIdentityWithoutReplacingOtherEvidence() {
        var state = FitnessState()
        var existing = JourneyEntry(); existing.text = "Existing evidence"; existing.originalText = "Original"
        state.saveJourneyEntry(existing)
        var entry = JourneyEntry(); entry.category = "Cardio"; entry.text = "Synthetic activity"
        state.saveJourneyEntry(entry); state.saveJourneyEntry(entry)
        entry.approved = true; entry.status = "completed"
        XCTAssertTrue(entry.setCardioDetails(duration: "40", effort: "Easy"))
        state.saveJourneyEntry(entry)
        XCTAssertEqual(state.entries?.count, 2)
        XCTAssertEqual(state.entries?[0], existing)
        XCTAssertEqual(state.entries?[1], entry)
    }
}
