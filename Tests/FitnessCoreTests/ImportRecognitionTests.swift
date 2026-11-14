import XCTest
@testable import FitnessCore

final class ImportRecognitionTests: XCTestCase {
    private func export(_ text: String, role: String = "user") throws -> Data {
        try JSONSerialization.data(withJSONObject: [[
            "id": "fixture-chat", "title": "Synthetic training notes",
            "mapping": ["node": ["message": [
                "id": "fixture-message", "create_time": 1000,
                "author": ["role": role], "content": ["parts": [text]]
            ]]]
        ]])
    }
    func testCatalogMovementsAreRecognizedWithoutGenericKeywords() throws {
        for name in ExerciseCatalog.all.map(\.name) {
            let entries = try ChatImport.extract(export(name))
            XCTAssertEqual(entries.count, 1, name)
            XCTAssertFalse(try XCTUnwrap(entries.first).approved, name)
        }
    }
    func testVariantsAndFormattingPreserveOriginalEvidence() throws {
        for text in ["SEATED   ROW 10", "Lateral raises 12", "Incline DB press", "lat pull-down", "Shoulder press", "Supine press"] {
            let entry = try XCTUnwrap(ChatImport.extract(export(text)).first)
            XCTAssertEqual(entry.originalText, text)
            XCTAssertEqual(entry.text, text)
            XCTAssertEqual(entry.sourceID, "fixture-chat:fixture-message")
            XCTAssertEqual(entry.originalTimestamp, 1000)
            XCTAssertEqual(entry.status, "unclear")
        }
    }
    func testAdviceAndPlansStayPendingAndDoNotChangeTraining() throws {
        let advice = try ChatImport.extract(export("Try seated row tomorrow", role: "assistant"))
        let planned = try ChatImport.extract(export("Shoulder press next week"))
        XCTAssertEqual(advice.first?.status, "advice")
        XCTAssertEqual(planned.first?.status, "unclear")
        XCTAssertTrue((advice + planned).allSatisfy { !$0.approved })
        var state = FitnessState(); state.entries = advice + planned
        XCTAssertTrue(state.history.isEmpty)
        XCTAssertNil(state.previousPerformance(for: "Seated row"))
        XCTAssertEqual(TrainingPlan(state: state).names, TrainingPlan(state: FitnessState()).names)
        XCTAssertTrue(TrainingPlan(state: state).exercises.flatMap(\.sets).allSatisfy { $0.weight == 0 && $0.completedAt == nil })
    }
    func testUnrelatedNotesExcludedAndRepeatIdentityStable() throws {
        XCTAssertTrue(try ChatImport.extract(export("Book a table for dinner")).isEmpty)
        let data = try export("Leg curl")
        let first = try ChatImport.extract(data)
        let second = try ChatImport.extract(data)
        XCTAssertEqual(first.map(\.sourceID), second.map(\.sourceID))
        XCTAssertEqual(first.first?.originalText, second.first?.originalText)
    }
}
