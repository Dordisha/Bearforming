import XCTest
@testable import FitnessCore

final class LiftingOccurrenceTests: XCTestCase {
    private func occurrence(_ day: String, _ movement: String, _ status: String) -> LiftingOccurrence {
        var value = LiftingOccurrence(); value.day = day; value.movement = movement; value.status = status
        return value
    }
    func testAdjacentDayManualCorrectionPreservesOtherDayAndOriginalEvidence() throws {
        var entry = JourneyEntry(); entry.category = "Imported conversation"
        entry.originalText = "Synthetic original: two days planned; later owner correction narrows day two."
        entry.text = entry.originalText!; entry.originalRole = "user"; entry.originalTimestamp = 1000
        entry.originalParentSourceID = "synthetic:parent"
        let first = occurrence("2030-04-10", "Seated row", "planned")
        let second = occurrence("2030-04-11", "Leg curl", "planned")
        let omitted = occurrence("2030-04-11", "Leg press", "planned")
        XCTAssertTrue(entry.setLiftingOccurrences([first, second, omitted]))
        let original = entry
        var corrected = second; corrected.status = "completed"
        XCTAssertTrue(entry.setLiftingOccurrences([first, corrected]))
        XCTAssertEqual(entry.liftingOccurrences?.first, first)
        XCTAssertEqual(entry.liftingOccurrences?.last?.id, second.id)
        XCTAssertEqual(entry.originalText, original.originalText); XCTAssertEqual(entry.originalTimestamp, 1000)
        XCTAssertEqual(entry.originalParentSourceID, "synthetic:parent")
        XCTAssertFalse(entry.approved)
        let restored = try JSONDecoder().decode(JourneyEntry.self, from: JSONEncoder().encode(entry))
        XCTAssertEqual(restored, entry)
    }
    func testInvalidDateStatusMovementAndDuplicateIdentityRejectWholeEdit() {
        var entry = JourneyEntry(); let valid = occurrence("2028-02-29", "Seated row", "completed")
        XCTAssertTrue(entry.setLiftingOccurrences([valid])); let before = entry
        for day in ["2027-02-29", "2030-04-31", "04/11/2030", "2030-4-11", "2030-04-11 extra"] {
            XCTAssertFalse(entry.setLiftingOccurrences([occurrence(day, "Leg curl", "completed")]), day)
            XCTAssertEqual(entry, before)
        }
        XCTAssertFalse(entry.setLiftingOccurrences([occurrence("", " ", "completed")]))
        XCTAssertFalse(entry.setLiftingOccurrences([occurrence("", "Leg curl", "inferred")]))
        XCTAssertFalse(entry.setLiftingOccurrences([valid, valid])); XCTAssertEqual(entry, before)
    }
    func testReviewedUnquantifiedOccurrenceCannotChangePlansOrProgression() throws {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        var state = FitnessState(); state.preparePreviewIfNeeded(now: now)
        let before = state
        var entry = JourneyEntry(); entry.category = "Lifting"; entry.status = "completed"; entry.approved = true
        entry.originalText = "Synthetic: completed, amounts unknown; 20 fortnights is unresolved."
        XCTAssertTrue(entry.setLiftingOccurrences([occurrence("", "Leg curl", "completed")]))
        XCTAssertEqual(entry.liftingOccurrences?.first?.day, "")
        XCTAssertNil(entry.durationMinutes)
        state.saveJourneyEntry(entry)
        XCTAssertEqual(state.history, before.history); XCTAssertEqual(state.plannedExercises, before.plannedExercises)
        XCTAssertNil(state.previousPerformance(for: "Leg curl", now: now))
        XCTAssertEqual(TrainingPlan(state: state, now: now).names, TrainingPlan(state: before, now: now).names)
        XCTAssertEqual(SessionPreviewSummary(state: state, now: now).explanation, SessionPreviewSummary(state: before, now: now).explanation)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let repository = StateRepository(url: folder.appendingPathComponent("state.json"))
        try repository.save(state); XCTAssertEqual(try repository.load(), state)
        var incoming = entry; incoming.liftingOccurrences = nil
        XCTAssertEqual(state.stageImportedEntries([incoming]).duplicates, 1)
        XCTAssertEqual(state.entries?.first, entry)
    }
    func testLegacyAndRemovingOccurrencesPreserveOriginalRecord() throws {
        var entry = JourneyEntry(); entry.text = "Existing note"
        entry = try JSONDecoder().decode(JourneyEntry.self, from: JSONEncoder().encode(entry))
        XCTAssertNil(entry.liftingOccurrences); let before = entry
        XCTAssertTrue(entry.setLiftingOccurrences([occurrence("", "Unclassified movement", "unclear")]))
        XCTAssertTrue(entry.setLiftingOccurrences([])); XCTAssertEqual(entry, before)
    }
}
