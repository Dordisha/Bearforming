import XCTest
@testable import FitnessCore

final class PersistenceTests: XCTestCase {
    func location() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("state.json") }
    func testSessionRestoresAcrossRepositoryInstances() throws {
        let url = location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var state = FitnessState()
        state.active = Workout(exercises: [Exercise(name: "Leg press")])
        state.active?.exercises[0].sets[0].reps = 10
        state.active?.exercises[0].sets[0].weight = 200
        state.active?.exercises[0].sets[0].completedAt = Date()
        state.restUntil = Date().addingTimeInterval(90)
        try StateRepository(url: url).save(state)
        XCTAssertEqual(try StateRepository(url: url).load(), state)
    }
    func testUndoAndFinishSurviveReload() throws {
        let url = location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var state = FitnessState()
        var workout = Workout(exercises: [Exercise(name: "Seated row")])
        workout.exercises[0].sets[0].completedAt = Date()
        state.active = workout
        try StateRepository(url: url).save(state)
        state.active?.exercises[0].sets[0].completedAt = nil
        try StateRepository(url: url).save(state)
        XCTAssertNil(try StateRepository(url: url).load().active?.exercises[0].sets[0].completedAt)
        workout.finishedAt = Date()
        state.history.append(workout); state.active = nil
        try StateRepository(url: url).save(state)
        let restored = try StateRepository(url: url).load()
        XCTAssertNil(restored.active)
        XCTAssertEqual(restored.previousPerformance(for: "Seated row"), workout.exercises[0])
    }
    func testCorruptDataIsPreserved() throws {
        let url = location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let broken = Data("truncated".utf8)
        try broken.write(to: url)
        XCTAssertThrowsError(try StateRepository(url: url).load())
        XCTAssertEqual(try Data(contentsOf: url), broken)
    }
    func testSaveFailureDoesNotReplaceExistingSession() throws {
        let url = location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let repository = StateRepository(url: url)
        let original = FitnessState()
        try repository.save(original)
        // A file used as a parent directory forces a write error without touching the good file.
        let blocked = StateRepository(url: url.appendingPathComponent("child.json"))
        XCTAssertThrowsError(try blocked.save(FitnessState()))
        XCTAssertEqual(try repository.load(), original)
    }
}
