import SwiftUI

@MainActor final class WorkoutStore: ObservableObject {
    @Published private(set) var state = FitnessState()
    @Published var error: String?
    @Published private(set) var loaded = false
    private let repository: StateRepository
    init() {
        let folder = URL.applicationSupportDirectory.appending(path: "DorianFitness")
        repository = StateRepository(url: folder.appending(path: "workouts.json"))
        reload()
    }
    func reload() {
        do { state = try repository.load(); loaded = true; error = nil }
        catch { loaded = false; self.error = "Your saved session could not be opened. It has been preserved. Retry opening it before making changes." }
    }
    func update(_ change: (inout FitnessState) -> Void) {
        guard loaded else { return }
        var next = state; change(&next)
        do { try repository.save(next); state = next; error = nil }
        catch { self.error = "This change could not be saved. Your last saved session is preserved. Please try again." }
    }
}
