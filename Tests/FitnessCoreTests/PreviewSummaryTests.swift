import XCTest
@testable import FitnessCore

final class PreviewSummaryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    func testSummaryUsesEditedDraftAndDoesNotMutateIt() throws {
        var state = FitnessState()
        state.preparePreviewIfNeeded(now: now)
        state.plannedExercises!.removeLast()
        state.plannedExercises![0].sets.removeLast()
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        let summary = SessionPreviewSummary(state: restored, now: now)
        XCTAssertEqual(summary.exerciseCount, 5)
        XCTAssertEqual(summary.setCount, 14)
        XCTAssertEqual(summary.minutes, TrainingPlan.estimate(state.plannedExercises!, profile: TrainingProfile()))
        XCTAssertEqual(restored, state)
        XCTAssertFalse(summary.explanation.contains("within your"))
    }
    func testEmptyAndMissingDraftDoNotDescribeGeneratedWorkout() {
        for draft in [nil, []] as [[Exercise]?] {
            var state = FitnessState(); state.plannedExercises = draft
            let summary = SessionPreviewSummary(state: state, now: now)
            XCTAssertEqual(summary.exerciseCount, 0)
            XCTAssertEqual(summary.setCount, 0)
            XCTAssertEqual(summary.minutes, 0)
        }
    }
    func testOverlapRequiresRecentCompletedSetsAndMatchingDraft() {
        for age: TimeInterval? in [nil, -1, 0, 172799, 172800] {
            var set = LoggedSet(); set.completedAt = age.map { now.addingTimeInterval(-$0) }
            var state = FitnessState()
            state.plannedExercises = [Exercise(name: "Leg press")]
            state.history = [Workout(exercises: [Exercise(name: "Leg press", sets: [set])])]
            XCTAssertEqual(SessionPreviewSummary(state: state, now: now).explanation.contains("Review before starting"), age == 0 || age == 172799)
            state.active = state.history.first; state.history = []
            XCTAssertEqual(SessionPreviewSummary(state: state, now: now).explanation.contains("Review before starting"), age == 0 || age == 172799)
            state.plannedExercises = [Exercise(name: "Seated row")]
            XCTAssertFalse(SessionPreviewSummary(state: state, now: now).explanation.contains("Review before starting"))
        }
    }
    func testCyclingRequiresReviewedCompletedRecentEvidence() {
        var entry = JourneyEntry(); entry.category = "Cycling"; entry.approved = true
        entry.status = "completed"; entry.date = now.addingTimeInterval(-60)
        var state = FitnessState(); state.entries = [entry]
        state.preparePreviewIfNeeded(now: now)
        let original = state
        XCTAssertTrue(SessionPreviewSummary(state: state, now: now).explanation.contains("ride intensity is unknown"))
        XCTAssertEqual(state, original)
        for kind in 0..<5 {
            var invalid = entry
            switch kind {
            case 0: invalid.approved = false
            case 1: invalid.status = "planned"
            case 2: invalid.category = "Imported conversation"
            case 3: invalid.date = now.addingTimeInterval(1)
            default: invalid.date = now.addingTimeInterval(-172800)
            }
            state.entries = [invalid]
            XCTAssertFalse(SessionPreviewSummary(state: state, now: now).explanation.contains("ride intensity"))
        }
    }
    func testPainWarningSurvivesSavedDraftAndBudgetOverrun() {
        var state = FitnessState(); state.preparePreviewIfNeeded(now: now)
        var profile = TrainingProfile(); profile.minutes = 15; profile.readiness = "Pain or unwell"
        state.profile = profile
        let summary = SessionPreviewSummary(state: state, now: now)
        XCTAssertEqual(summary.exerciseCount, 6)
        XCTAssertEqual(summary.setCount, 18)
        XCTAssertGreaterThan(summary.minutes, 15)
        XCTAssertTrue(summary.explanation.contains("Pause planning"))
        state.startWorkout(exercises: state.plannedExercises!, now: now)
        XCTAssertNil(state.active)
    }
}
