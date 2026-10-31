import SwiftUI
import FitnessCore

struct JourneyView: View {
    @EnvironmentObject var store: WorkoutStore
    var body: some View {
        NavigationStack {
            List {
                Section("Logged workouts") {
                    if store.state.history.isEmpty { Text("Your first completed session will appear here.") }
                    ForEach(store.state.history.reversed()) { workout in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(workout.startedAt, style: .date).font(.headline)
                            ForEach(workout.exercises) { exercise in
                                Text("\(exercise.name): \(exercise.sets.filter { $0.completedAt != nil }.count) completed sets")
                            }
                        }
                    }
                }
                Section("Coming next") { Text("Cycling, body weight, measurements, progress photos, milestones, and reviewed chat imports.") }
            }.navigationTitle("Journey")
        }
    }
}
