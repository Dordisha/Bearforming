import XCTest
@testable import FitnessCore

final class ImportCorrectionTests: XCTestCase {
    private func node(_ id: String, _ text: String, role: String = "user", parent: String? = nil, time: Double = 1000) -> [String: Any] {
        var value: [String: Any] = ["message": ["id": id, "create_time": time,
            "author": ["role": role], "content": ["parts": [text]]]]
        if let parent = parent { value["parent"] = parent }
        return value
    }
    private func extract(_ mapping: [String: [String: Any]]) throws -> [JourneyEntry] {
        try ChatImport.extract(JSONSerialization.data(withJSONObject: [["id": "synthetic-correction", "mapping": mapping]]))
    }
    // Invented text only, unrelated to any owner's training history.
    func testAdjacentDayCorrectionAndUnquantifiedOccurrenceRetainExactEvidence() throws {
        let first = "2030-04-10: planned seated row and leg press. 2030-04-11: planned leg curl and dumbbell bench press."
        let recap = "You completed both workouts, three sets of ten each."
        let correction = "Correction: on 2030-04-11 I completed only the first movement. Amounts unknown. The other day is unchanged."
        let duration = "I did it for 20 fortnights; that duration unit needs checking."
        let entries = try extract([
            "a": node("plan", first),
            "b": node("recap", recap, role: "assistant", parent: "a", time: 1100),
            "c": node("correction", correction, parent: "b", time: 1200),
            "d": node("duration", duration, parent: "c", time: 1300)
        ])
        XCTAssertEqual(entries.count, 4)
        XCTAssertEqual(entries.map(\.originalText), [first, recap, correction, duration])
        XCTAssertEqual(entries[2].originalRole, "user")
        XCTAssertEqual(entries[2].originalParentSourceID, "synthetic-correction:recap")
        XCTAssertEqual(entries[3].originalParentSourceID, "synthetic-correction:correction")
        XCTAssertEqual(entries[2].date, Date(timeIntervalSince1970: 1200)) // Message date only.
        XCTAssertEqual(entries[1].status, "advice")
        XCTAssertTrue(entries.allSatisfy { !$0.approved && $0.durationMinutes == nil })
        var state = FitnessState(); state.preparePreviewIfNeeded()
        let before = state
        state.stageImportedEntries(entries)
        XCTAssertEqual(state.history, before.history); XCTAssertEqual(state.plannedExercises, before.plannedExercises)
        XCTAssertEqual(SessionPreviewSummary(state: state).explanation, SessionPreviewSummary(state: before).explanation)
        XCTAssertNil(state.previousPerformance(for: "Leg curl"))
        // Even explicit note review does not manufacture quantified lifting sets.
        state.entries![2].approved = true; state.entries![2].status = "completed"; state.entries![2].category = "Lifting"
        XCTAssertNil(state.previousPerformance(for: "Leg curl")); XCTAssertTrue(state.history.isEmpty)
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored, state)
        XCTAssertEqual(state.stageImportedEntries(entries).duplicates, 4)
        XCTAssertEqual(state.entries?.count, 4)
    }

    func testUnrelatedBranchesAndAssistantOnlyFollowupsAreNotAdded() throws {
        let entries = try extract([
            "a": node("fitness", "Seated row"),
            "b": node("dinner", "Dinner reservation"),
            "c": node("unrelated", "Correction: only two people", parent: "b"),
            "d": node("assistant", "Actually all of it was completed", role: "assistant", parent: "a"),
            "e": node("orphan", "I completed only one", parent: "missing")
        ])
        XCTAssertEqual(entries.map(\.sourceID), ["synthetic-correction:fitness"])
    }

    func testParentCycleTerminatesAndMissingMessageIDsUseNodeIdentity() throws {
        XCTAssertTrue(try extract([
            "a": node("a", "Correction: first only", parent: "b"),
            "b": node("b", "Actually no", parent: "a")
        ]).isEmpty)
        var parent = node("remove", "Leg press")
        var message = parent["message"] as! [String: Any]; message.removeValue(forKey: "id"); parent["message"] = message
        let entries = try extract(["parent-node": parent, "child": node("child", "Only the first one", parent: "parent-node", time: 1100)])
        XCTAssertEqual(entries.last?.originalParentSourceID, "synthetic-correction:parent-node")
    }

    func testLegacyEntryWithoutProvenanceStillDecodes() throws {
        var legacy = JourneyEntry(); legacy.text = "Existing reviewed note"; legacy.approved = true
        let decoded = try JSONDecoder().decode(JourneyEntry.self, from: JSONEncoder().encode(legacy))
        XCTAssertNil(decoded.originalRole); XCTAssertNil(decoded.originalParentSourceID)
        XCTAssertEqual(decoded, legacy)
    }
}
