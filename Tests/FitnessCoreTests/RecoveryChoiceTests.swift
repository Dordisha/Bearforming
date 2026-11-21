import XCTest
@testable import FitnessCore

final class RecoveryChoiceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testRecoveryPreservesEditedDraftSequenceAndEvidenceAcrossDiskRelaunch() throws {
        var state = FitnessState(); state.configureSplit(startingWith: "Lower", now: now)
        state.sessionFocus = "Push"
        state.plannedExercises = [Exercise(name: "Edited workout", sets: [LoggedSet()])]
        state.restUntil = now.addingTimeInterval(90)
        state.history = [Workout(exercises: [Exercise(name: "Leg press")])]
        var entry = JourneyEntry(); entry.category = "Cycling"; entry.text = "Pending review"
        state.saveJourneyEntry(entry)
        let before = state
        state.chooseRecovery(now: now)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let repository = StateRepository(url: folder.appendingPathComponent("state.json"))
        try repository.save(state); state = try repository.load()
        XCTAssertEqual(state.recoverySelectedAt, now)
        state.chooseRecovery(now: now.addingTimeInterval(86400))
        XCTAssertEqual(state.recoverySelectedAt, now)
        state.returnToTraining()
        XCTAssertEqual(state, before)
    }

    func testBothStartsRequireExplicitReturnAndReturnDoesNotStartWorkout() {
        var state = FitnessState(); state.preparePreviewIfNeeded(now: now)
        let draft = state.plannedExercises!
        state.chooseRecovery(now: now); let resting = state
        state.startWorkout(exercises: draft, now: now)
        state.startCardio(category: "Cycling", now: now)
        XCTAssertEqual(state, resting)
        state.returnToTraining(); XCTAssertNil(state.active); XCTAssertNil(state.activeCardio)
        XCTAssertEqual(state.plannedExercises, draft)
        state.startWorkout(exercises: draft, now: now)
        XCTAssertEqual(state.active?.exercises, draft)
    }

    func testRecoveryCannotInterruptStrengthOrRunningOrPausedCardio() {
        var state = FitnessState()
        state.startWorkout(exercises: [Exercise(name: "Leg press")], now: now)
        var before = state; state.chooseRecovery(now: now); XCTAssertEqual(state, before)
        state = FitnessState(); state.startCardio(category: "Cardio", now: now)
        before = state; state.chooseRecovery(now: now); XCTAssertEqual(state, before)
        state.pauseCardio(now: now.addingTimeInterval(60))
        before = state; state.chooseRecovery(now: now); XCTAssertEqual(state, before)
    }

    func testManualActivityAndPainReadinessRemainIndependentOfRecoveryChoice() {
        var state = FitnessState(); state.profile = TrainingProfile()
        state.profile?.readiness = "Pain or unwell"
        state.chooseRecovery(now: now); XCTAssertEqual(state.recoverySelectedAt, now)
        var entry = JourneyEntry(); entry.category = "Cycling"; entry.text = "Actual activity to review"
        state.saveJourneyEntry(entry)
        XCTAssertEqual(state.recoverySelectedAt, now); XCTAssertEqual(state.entries, [entry])
        state.returnToTraining()
        state.startWorkout(exercises: [Exercise(name: "Leg press")], now: now)
        state.startCardio(category: "Cardio", now: now)
        XCTAssertNil(state.active); XCTAssertNil(state.activeCardio)
        XCTAssertEqual(state.profile?.readiness, "Pain or unwell")
    }

    func testLegacyAndInvalidDateDoNotSelectRecoveryOrCreateRecords() throws {
        var state = try JSONDecoder().decode(FitnessState.self, from: Data(#"{"schemaVersion":1,"history":[]}"#.utf8))
        XCTAssertNil(state.recoverySelectedAt); let before = state
        state.chooseRecovery(now: Date(timeIntervalSince1970: .infinity))
        XCTAssertEqual(state, before)
        state.chooseRecovery(now: now); state.returnToTraining(); state.returnToTraining()
        XCTAssertEqual(state, before)
    }
}
