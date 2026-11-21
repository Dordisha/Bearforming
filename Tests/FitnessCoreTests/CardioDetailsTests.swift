import XCTest
@testable import FitnessCore

final class CardioDetailsTests: XCTestCase {
    func testExplicitDetailsDoNotInventCompletionOrApproval() {
        var entry = JourneyEntry(); entry.category = "Cycling"; entry.text = "ride"
        XCTAssertTrue(entry.setCardioDetails(duration: " 45 ", effort: "Moderate"))
        XCTAssertEqual(entry.durationMinutes, 45)
        XCTAssertEqual(entry.cardioEffort, "Moderate")
        XCTAssertFalse(entry.approved)
        XCTAssertEqual(entry.status, "unclear")
    }
    func testBlankAndUnknownStayUnknown() {
        var entry = JourneyEntry(); entry.category = "Cardio"
        XCTAssertTrue(entry.setCardioDetails(duration: "15", effort: "Easy"))
        XCTAssertTrue(entry.setCardioDetails(duration: " ", effort: "Unknown"))
        XCTAssertNil(entry.durationMinutes); XCTAssertNil(entry.cardioEffort)
    }
    func testInvalidInputPreservesSavedDetails() {
        var entry = JourneyEntry(); entry.category = "Cycling"
        XCTAssertTrue(entry.setCardioDetails(duration: "30", effort: "Hard"))
        let before = entry
        for value in ["0", "-1", "1.5", "abc", "1441", "999999999999999999999", "1e2", "+2"] {
            XCTAssertFalse(entry.setCardioDetails(duration: value, effort: "Easy"))
            XCTAssertEqual(entry, before)
        }
        XCTAssertFalse(entry.setCardioDetails(duration: "30", effort: "guessed"))
        XCTAssertEqual(entry, before)
    }
    func testDetailsPersistAndDoNotAlterStrengthState() throws {
        var state = FitnessState(); state.configureSplit(startingWith: "Lower")
        let before = state
        var entry = JourneyEntry(); entry.category = "Cardio"
        XCTAssertTrue(entry.setCardioDetails(duration: "60", effort: "Moderate"))
        state.entries = [entry]
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored, state)
        XCTAssertEqual(restored.plannedExercises, before.plannedExercises)
        XCTAssertEqual(restored.nextSplitFocus, before.nextSplitFocus)
        XCTAssertEqual(restored.history, before.history)
    }
    func testLegacyEntryDecodesWithoutDetailsAndCategoryChangeClearsThem() throws {
        let entry = JourneyEntry()
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as! [String: Any]
        json.removeValue(forKey: "durationMinutes"); json.removeValue(forKey: "cardioEffort")
        var legacy = try JSONDecoder().decode(JourneyEntry.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(legacy.durationMinutes); XCTAssertNil(legacy.cardioEffort)
        legacy.category = "Cycling"
        XCTAssertTrue(legacy.setCardioDetails(duration: "1", effort: "Easy"))
        legacy.category = "Milestone"
        XCTAssertTrue(legacy.setCardioDetails(duration: "1", effort: "Easy"))
        XCTAssertNil(legacy.durationMinutes); XCTAssertNil(legacy.cardioEffort)
    }
}
