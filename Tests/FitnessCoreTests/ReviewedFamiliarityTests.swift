import XCTest
@testable import FitnessCore

final class ReviewedFamiliarityTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    func entry(enabled: Bool = true) -> JourneyEntry {
        var row = LiftingOccurrence(); row.day = "2030-04-11"; row.movement = "Synthetic pulldown"; row.status = "completed"
        row.matchCatalogExercise("Lat pulldown")
        var set = LiftingSetReview(); set.repsText = "10"; set.loadText = "12.5"; set.unit = "kg"
        row.reviewedSets = [set]; XCTAssertTrue(row.confirmQuantities(now: now))
        if enabled { XCTAssertTrue(row.setFamiliarityUse(true, now: now)) }
        var entry = JourneyEntry(); entry.category = "Lifting"; entry.status = "completed"; entry.approved = true
        entry.originalRole = "user"; entry.originalText = "Synthetic source"; entry.liftingOccurrences = [row]
        return entry
    }
    func testExplicitReviewedHistoryChangesOnlyFamiliarityAndPreservesDraft() throws {
        var state = FitnessState(); state.preparePreviewIfNeeded(now: now); let before = state
        state.entries = [entry()]
        let plan = TrainingPlan(state: state, now: now)
        XCTAssertEqual(plan.names[2], "Lat pulldown"); XCTAssertEqual(plan.exercises.count, 6)
        XCTAssertTrue(plan.exercises.flatMap(\.sets).allSatisfy { $0.weight == 0 && $0.completedAt == nil })
        XCTAssertEqual(state.plannedExercises, before.plannedExercises); XCTAssertEqual(state.history, before.history)
        XCTAssertNil(state.previousPerformance(for: "Lat pulldown", now: now))
        XCTAssertEqual(NextFocusSuggestion(state: state, now: now).focus, NextFocusSuggestion(state: before, now: now).focus)
        let saved = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(saved.reviewedFamiliarExerciseNames(now: now), ["Lat pulldown"])
        XCTAssertEqual(saved.entries![0].originalText, "Synthetic source")
        state.refreshPreview(now: now)
        XCTAssertTrue(SessionPreviewSummary(state: state, now: now).explanation.contains("familiarity only"))
    }
    func testPendingAdviceUnknownFutureAndRevokedEvidenceNeverQualifies() {
        let edits: [(inout JourneyEntry) -> Void] = [
            { $0.approved = false }, { $0.status = "planned" }, { $0.originalRole = "assistant" },
            { $0.category = "Cycling" }, { $0.liftingOccurrences![0].day = "2099-01-01" },
            { $0.liftingOccurrences![0].reviewedSets![0].loadText = nil },
            { $0.liftingOccurrences![0].clearQuantityConfirmation() },
            { $0.liftingOccurrences![0].matchCatalogExercise(nil) },
            { $0.liftingOccurrences![0].setFamiliarityUse(false) }
        ]
        for edit in edits {
            var record = entry(); edit(&record); var state = FitnessState(); state.entries = [record]
            XCTAssertTrue(state.reviewedFamiliarExerciseNames(now: now).isEmpty)
            XCTAssertEqual(TrainingPlan(state: state, now: now).names[2], "Seated row")
        }
        var state = FitnessState(); state.entries = [entry(enabled: false)]
        XCTAssertTrue(state.reviewedFamiliarExerciseNames(now: now).isEmpty)
    }
    func testCorrectionsRequireFreshOptInAndDuplicatesDoNotMultiplyInfluence() {
        var record = entry(); let original = record
        record.liftingOccurrences![0].reviewedSets![0].repsText = "11"
        XCTAssertNil(record.liftingOccurrences![0].useForFamiliarity)
        XCTAssertTrue(record.liftingOccurrences![0].confirmQuantities(now: now))
        XCTAssertNil(record.liftingOccurrences![0].useForFamiliarity)
        var state = FitnessState(); state.entries = [record]
        XCTAssertTrue(state.reviewedFamiliarExerciseNames(now: now).isEmpty)
        XCTAssertTrue(record.liftingOccurrences![0].setFamiliarityUse(true, now: now))
        state.entries = [record, original, original]
        XCTAssertEqual(state.reviewedFamiliarExerciseNames(now: now).count, 1)
        let names = TrainingPlan(state: state, now: now).names
        state.entries = [original]
        XCTAssertEqual(TrainingPlan(state: state, now: now).names, names)
        state.entries = []; XCTAssertTrue(state.reviewedFamiliarExerciseNames(now: now).isEmpty)
        var unknown = LiftingOccurrence(); XCTAssertFalse(unknown.setFamiliarityUse(true, now: now))
    }
}
