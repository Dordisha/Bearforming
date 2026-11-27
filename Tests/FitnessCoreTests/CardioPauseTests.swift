import XCTest
@testable import FitnessCore

final class CardioPauseTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 2_000_000_000)
    private func at(_ seconds: Double) -> Date { start.addingTimeInterval(seconds) }

    func testMultiplePausesExcludeOnlyExplicitBreaksAndPreserveStrength() throws {
        var state = FitnessState(); state.configureSplit(startingWith: "Lower", now: start)
        state.sessionFocus = "Push"; state.restUntil = at(90)
        let before = state
        state.startCardio(category: "Cycling", now: start)
        state.pauseCardio(now: at(120)); state.resumeCardio(now: at(300))
        state.pauseCardio(now: at(360)); state.resumeCardio(now: at(420))
        let entry = try XCTUnwrap(state.stopCardio(now: at(600)))
        XCTAssertEqual(entry.durationMinutes, 6)
        XCTAssertTrue(entry.originalText!.contains("elapsed seconds: 600.0; paused seconds: 240.0; unpaused seconds: 360.0"))
        XCTAssertFalse(entry.approved); XCTAssertEqual(entry.status, "unclear"); XCTAssertNil(entry.cardioEffort)
        XCTAssertEqual(state.plannedExercises, before.plannedExercises)
        XCTAssertEqual(state.sessionFocus, before.sessionFocus)
        XCTAssertEqual(state.nextSplitFocus, before.nextSplitFocus)
        XCTAssertEqual(state.restUntil, before.restUntil); XCTAssertEqual(state.history, before.history)
        XCTAssertNil(state.stopCardio(now: at(601))); XCTAssertEqual(state.entries?.count, 1)
    }

    func testPausedTimerSurvivesDiskRelaunchAndCanStopWithoutResume() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let repository = StateRepository(url: folder.appendingPathComponent("state.json"))
        var state = FitnessState(); state.startCardio(category: "Cardio", now: start)
        state.pauseCardio(now: at(125))
        let timer = state.activeCardio
        try repository.save(state)
        state = try repository.load()
        XCTAssertEqual(state.activeCardio, timer)
        XCTAssertEqual(state.activeCardio?.unpausedSeconds(now: at(90000)), 125)
        let entry = try XCTUnwrap(state.stopCardio(now: at(90000)))
        XCTAssertEqual(entry.durationMinutes, 2)
        XCTAssertTrue(entry.originalText!.contains("paused seconds: 89875.0"))
        try repository.save(state)
        XCTAssertEqual(try repository.load(), state)
    }

    func testDuplicateTransitionsDoNotResetOrDoubleCount() throws {
        var state = FitnessState(); state.startCardio(category: "Cardio", now: start)
        let running = state
        state.resumeCardio(now: at(60)); XCTAssertEqual(state, running)
        state.pauseCardio(now: at(120)); let paused = state
        state.pauseCardio(now: at(180)); XCTAssertEqual(state, paused)
        state.resumeCardio(now: at(300)); let resumed = state
        state.resumeCardio(now: at(360)); XCTAssertEqual(state, resumed)
        state = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(state.activeCardio?.unpausedSeconds(now: at(420)), 240)
        XCTAssertEqual(state.stopCardio(now: at(420))?.durationMinutes, 4)
    }

    func testClockRollbackAndNonfiniteTransitionsPreserveTimer() {
        var state = FitnessState(); state.startCardio(category: "Cardio", now: start)
        var before = state
        state.pauseCardio(now: at(-1)); XCTAssertEqual(state, before)
        state.pauseCardio(now: at(.infinity)); XCTAssertEqual(state, before)
        state.pauseCardio(now: at(120)); before = state
        state.resumeCardio(now: at(119)); XCTAssertEqual(state, before)
        state.resumeCardio(now: at(.infinity)); XCTAssertEqual(state, before)
        XCTAssertNil(state.stopCardio(now: at(119))); XCTAssertEqual(state, before)
        state.resumeCardio(now: at(300)); before = state
        state.pauseCardio(now: at(299)); XCTAssertEqual(state, before)
        XCTAssertNil(state.stopCardio(now: at(299))); XCTAssertEqual(state, before)
        XCTAssertNil(state.stopCardio(now: at(.nan))); XCTAssertEqual(state, before)
        XCTAssertEqual(state.stopCardio(now: at(360))?.durationMinutes, 3)
        state.startCardio(category: "Cardio", now: at(.infinity)); XCTAssertNil(state.activeCardio)
    }

    func testLegacyRunningTimerDecodesAndCanPauseWithoutLosingIdentity() throws {
        var state = FitnessState(); state.startCardio(category: "Cycling", now: start)
        let id = state.activeCardio?.id
        let data = try JSONEncoder().encode(state)
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("pausedSeconds"))
        state = try JSONDecoder().decode(FitnessState.self, from: data)
        XCTAssertNil(state.activeCardio?.pausedAt); XCTAssertNil(state.activeCardio?.resumedAt)
        XCTAssertEqual(state.activeCardio?.unpausedSeconds(now: at(120)), 120)
        state.pauseCardio(now: at(120)); state.resumeCardio(now: at(180))
        XCTAssertEqual(state.activeCardio?.id, id)
        XCTAssertEqual(state.stopCardio(now: at(240))?.durationMinutes, 3)
    }

    func testPausedTimerStillBlocksConcurrentWorkAndDiscardCreatesNoActivity() {
        var state = FitnessState(); state.startCardio(category: "Cycling", now: start)
        state.pauseCardio(now: at(30)); let paused = state
        state.startCardio(category: "Cardio", now: at(60))
        state.startWorkout(exercises: [Exercise(name: "Leg press")], now: at(60))
        XCTAssertEqual(state, paused)
        XCTAssertNil(state.stopCardio(now: at(600))?.durationMinutes)
        XCTAssertEqual(state.entries?.count, 1)
        state.startCardio(category: "Cardio", now: at(700)); state.pauseCardio(now: at(730))
        state.discardCardio(); XCTAssertNil(state.activeCardio); XCTAssertEqual(state.entries?.count, 1)
        let before = state
        state.pauseCardio(now: at(800)); state.resumeCardio(now: at(900))
        XCTAssertEqual(state, before)
    }
}
