import XCTest
@testable import FitnessCore

final class LiftingQuantityTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    private func occurrence() -> LiftingOccurrence {
        var value = LiftingOccurrence(); value.day = "2030-04-11"; value.movement = "Synthetic movement"; value.status = "completed"
        var set = LiftingSetReview(); set.repsText = "10"; set.loadText = "12,5"; set.unit = "kg"
        value.reviewedSets = [set]; return value
    }
    func testExplicitQuantitiesUnitsAndConfirmationSurvivePersistenceWithoutHistoryEffects() throws {
        var value = occurrence()
        XCTAssertEqual(value.reviewedSets?.first?.load, 12.5)
        XCTAssertTrue(value.confirmQuantities(now: now)); XCTAssertTrue(value.quantitiesAreConfirmed)
        var entry = JourneyEntry(); entry.category = "Lifting"; entry.approved = true; entry.status = "completed"
        entry.originalText = "Synthetic original evidence"; XCTAssertTrue(entry.setLiftingOccurrences([value]))
        var state = FitnessState(); state.preparePreviewIfNeeded(now: now); let before = state
        state.saveJourneyEntry(entry)
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertTrue(restored.entries![0].liftingOccurrences![0].quantitiesAreConfirmed)
        XCTAssertEqual(restored.entries![0].originalText, entry.originalText)
        XCTAssertEqual(restored.history, before.history); XCTAssertEqual(restored.plannedExercises, before.plannedExercises)
        XCTAssertNil(restored.previousPerformance(for: value.movement, now: now))
        XCTAssertEqual(SessionPreviewSummary(state: restored, now: now).explanation, SessionPreviewSummary(state: before, now: now).explanation)
    }
    func testEveryMaterialEditInvalidatesConfirmationAndOtherDaysStayIntact() {
        var original = occurrence(); XCTAssertTrue(original.confirmQuantities(now: now))
        let edits: [(inout LiftingOccurrence) -> Void] = [
            { $0.day = "2030-04-10" }, { $0.movement = "Another movement" }, { $0.status = "planned" },
            { $0.reviewedSets![0].repsText = "11" }, { $0.reviewedSets![0].loadText = "13" },
            { $0.reviewedSets![0].unit = "lb" }, { $0.reviewedSets?.append(LiftingSetReview()) },
            { $0.reviewedSets = nil }
        ]
        for edit in edits {
            var changed = original; edit(&changed)
            XCTAssertFalse(changed.quantitiesAreConfirmed)
            XCTAssertTrue(original.quantitiesAreConfirmed)
        }
        original.clearQuantityConfirmation(); XCTAssertFalse(original.quantitiesAreConfirmed)
    }
    func testEditThenRevertRequiresExplicitReconfirmationAfterPersistence() throws {
        var original = occurrence(); XCTAssertTrue(original.confirmQuantities(now: now))
        let edits: [(inout LiftingOccurrence) -> Void] = [
            { $0.id = UUID() }, { $0.day = "2030-04-10" },
            { $0.movement = "Corrected movement" }, { $0.status = "skipped" },
            { $0.reviewedSets![0].id = UUID() }, { $0.reviewedSets![0].repsText = "11" },
            { $0.reviewedSets![0].loadText = "13" }, { $0.reviewedSets![0].unit = "lb" },
            { $0.reviewedSets?.append(LiftingSetReview()) }, { $0.reviewedSets = nil }
        ]
        for edit in edits {
            var changed = original; edit(&changed)
            // Persist the edited review before restoring the original field values.
            changed = try JSONDecoder().decode(LiftingOccurrence.self, from: JSONEncoder().encode(changed))
            changed.id = original.id; changed.day = original.day; changed.movement = original.movement
            changed.status = original.status; changed.reviewedSets = original.reviewedSets
            XCTAssertFalse(changed.quantitiesAreConfirmed)
            changed = try JSONDecoder().decode(LiftingOccurrence.self, from: JSONEncoder().encode(changed))
            XCTAssertFalse(changed.quantitiesAreConfirmed)
            XCTAssertTrue(changed.confirmQuantities(now: now))
            XCTAssertTrue(original.quantitiesAreConfirmed)
        }
    }
    func testUnchangedBindingWritesPreserveConfirmation() throws {
        var value = occurrence(); XCTAssertTrue(value.confirmQuantities(now: now))
        let same = value
        value.id = same.id; value.day = same.day; value.movement = same.movement
        value.status = same.status; value.reviewedSets = same.reviewedSets
        value.reviewedSets![0].repsText = same.reviewedSets![0].repsText
        XCTAssertTrue(value.quantitiesAreConfirmed)
        value = try JSONDecoder().decode(LiftingOccurrence.self, from: JSONEncoder().encode(value))
        XCTAssertTrue(value.quantitiesAreConfirmed)
    }
    func testUnknownAndInvalidValuesNeverBecomeConfirmedDefaults() {
        var value = occurrence()
        for sets in [nil, [], [LiftingSetReview()]] as [[LiftingSetReview]?] {
            value.reviewedSets = sets; XCTAssertTrue(value.isValid)
            XCTAssertFalse(value.confirmQuantities(now: now))
        }
        for raw in ["-1", "0", "1000", "ten", "1.5", "1e2"] {
            value = occurrence(); value.reviewedSets![0].repsText = raw
            XCTAssertFalse(value.isValid); XCTAssertFalse(value.confirmQuantities(now: now))
        }
        for raw in ["-1", "10000", "20 fortnights", "NaN", "1e3"] {
            value = occurrence(); value.reviewedSets![0].loadText = raw
            XCTAssertFalse(value.isValid); XCTAssertFalse(value.confirmQuantities(now: now))
        }
        value = occurrence(); value.reviewedSets![0].loadText = nil
        XCTAssertTrue(value.isValid); XCTAssertNil(value.reviewedSets![0].load); XCTAssertFalse(value.confirmQuantities(now: now))
        value.reviewedSets![0].loadText = "0"; value.reviewedSets![0].unit = nil
        XCTAssertFalse(value.confirmQuantities(now: now))
        value.reviewedSets![0].unit = "lb"; XCTAssertTrue(value.confirmQuantities(now: now))
    }
    func testDateStatusDuplicateAndLegacyGates() throws {
        for day in ["", "2099-01-01", "2030-02-30"] {
            var value = occurrence(); value.day = day; XCTAssertFalse(value.confirmQuantities(now: now))
        }
        for status in ["unclear", "planned", "skipped"] {
            var value = occurrence(); value.status = status; XCTAssertFalse(value.confirmQuantities(now: now))
        }
        var value = occurrence(); value.reviewedSets!.append(value.reviewedSets![0])
        XCTAssertFalse(value.isValid); XCTAssertFalse(value.confirmQuantities(now: now))
        var legacy = LiftingOccurrence(); legacy.movement = "Old note"
        legacy = try JSONDecoder().decode(LiftingOccurrence.self, from: JSONEncoder().encode(legacy))
        XCTAssertNil(legacy.reviewedSets); XCTAssertFalse(legacy.quantitiesAreConfirmed)
    }
}
