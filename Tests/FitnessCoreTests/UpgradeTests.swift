import XCTest
@testable import FitnessCore

final class UpgradeTests: XCTestCase {
    func testOldStateStillLoads() throws {
        let old = Data(#"{"schemaVersion":1,"history":[]}"#.utf8)
        let state = try JSONDecoder().decode(FitnessState.self, from: old)
        XCTAssertNil(state.entries)
        XCTAssertNil(state.profile)
    }
    func testPendingImportsRetainEvidenceAndDoNotBecomeWorkouts() throws {
        let data = Data(#"[{"id":"chat1","mapping":{"node":{"message":{"id":"msg1","author":{"role":"assistant"},"create_time":1234,"content":{"parts":["Try squats 3 x 10 at 30 lb"]}}}}}]"#.utf8)
        let entries = try ChatImport.extract(data)
        XCTAssertEqual(entries.count, 1)
        XCTAssertFalse(entries[0].approved)
        XCTAssertEqual(entries[0].status, "advice")
        XCTAssertEqual(entries[0].sourceID, "chat1:msg1")
        XCTAssertEqual(entries[0].originalTimestamp, 1234)
        XCTAssertEqual(entries[0].originalText, entries[0].text)
    }
    func testPlannerExcludesRecentCompletedExerciseAndPausesOnFeedback() {
        var state = FitnessState()
        var set = LoggedSet(); set.completedAt = Date()
        state.history = [Workout(exercises: [Exercise(name: "Leg press", sets: [set])])]
        XCTAssertFalse(TrainingPlan(state: state).names.contains("Leg press"))
        var profile = TrainingProfile(); profile.readiness = "Pain or unwell"; state.profile = profile
        XCTAssertTrue(TrainingPlan(state: state).names.isEmpty)
    }
}
