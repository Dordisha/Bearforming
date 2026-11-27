import XCTest
@testable import FitnessCore

final class ImportMergeTests: XCTestCase {
    private func note(_ key: String, text: String = "Seated row") -> JourneyEntry {
        var entry = JourneyEntry()
        entry.sourceID = key; entry.text = text; entry.originalText = text
        entry.originalTimestamp = 1000; entry.date = Date(timeIntervalSince1970: 1000)
        entry.category = "Imported conversation"
        return entry
    }
    func testRepeatedBatchAddsOnceAndReportsDuplicates() throws {
        var state = FitnessState()
        let entry = note("chat:message")
        let first = state.stageImportedEntries([entry, entry])
        XCTAssertEqual(first.added, 1); XCTAssertEqual(first.duplicates, 1)
        let saved = state
        let second = state.stageImportedEntries([entry])
        XCTAssertEqual(second.added, 0); XCTAssertEqual(second.duplicates, 1)
        XCTAssertEqual(state, saved)
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored, saved)
    }
    func testReviewAndOriginalEvidenceSurviveChangedExport() {
        var reviewed = note("chat:message")
        reviewed.text = "Owner corrected date and units"; reviewed.approved = true
        reviewed.status = "completed"; reviewed.category = "Cycling"
        var state = FitnessState(); state.entries = [reviewed]
        let summary = state.stageImportedEntries([note("chat:message", text: "Changed export")])
        XCTAssertEqual(summary.duplicates, 1)
        XCTAssertEqual(state.entries, [reviewed])
    }
    func testNewCandidatesRemainPendingWithoutChangingWorkoutOrPreview() {
        var state = FitnessState(); state.refreshPreview()
        state.active = Workout(exercises: [Exercise(name: "Leg press")])
        let before = state
        var incoming = note("chat:new"); incoming.approved = true
        let summary = state.stageImportedEntries([incoming])
        XCTAssertEqual(summary.added, 1)
        XCTAssertEqual(state.entries?.first?.approved, false)
        XCTAssertEqual(state.entries?.first?.originalText, incoming.originalText)
        XCTAssertEqual(state.entries?.first?.originalTimestamp, incoming.originalTimestamp)
        XCTAssertEqual(state.active, before.active)
        XCTAssertEqual(state.history, before.history)
        XCTAssertEqual(state.plannedExercises, before.plannedExercises)
    }
    func testEmptyAndInvalidBatchesDoNotAlterStateAndIdentityIncludesConversation() {
        var state = FitnessState()
        XCTAssertEqual(state.stageImportedEntries([]), ImportSummary())
        XCTAssertNil(state.entries)
        let invalid = state.stageImportedEntries([note(""), note("  ")])
        XCTAssertEqual(invalid.invalid, 2); XCTAssertNil(state.entries)
        let separate = state.stageImportedEntries([note("chat1:same"), note("chat2:same")])
        XCTAssertEqual(separate.added, 2); XCTAssertEqual(separate.duplicates, 0)
    }
}
