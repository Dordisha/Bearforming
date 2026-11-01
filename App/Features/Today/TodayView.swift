import SwiftUI
import FitnessCore

struct TodayView: View {
    @EnvironmentObject var store: WorkoutStore
    @Binding var selectedTab: Int
    private var plan: TrainingPlan { TrainingPlan(state: store.state) }
    private func setting<T>(_ key: WritableKeyPath<TrainingProfile, T>, fallback: T) -> Binding<T> {
        Binding(get: { (store.state.profile ?? TrainingProfile())[keyPath: key] }, set: { value in
            store.update { state in var profile = state.profile ?? TrainingProfile(); profile[keyPath: key] = value; state.profile = profile }
        })
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image("BearformingLogo").resizable().scaledToFit().frame(height: 180).frame(maxWidth: .infinity)
                    Text("Build your next chapter").font(.title.bold())
                }
                Section("Today's check-in") {
                    Picker("Goal", selection: setting(\.goal, fallback: "Build consistency")) { ForEach(["Build consistency", "Build strength", "Maintain muscle"], id: \.self) { Text($0) } }
                    Stepper("Time: \(store.state.profile?.minutes ?? 40) minutes", value: setting(\.minutes, fallback: 40), in: 15...90, step: 5)
                    Picker("Equipment", selection: setting(\.equipment, fallback: "Gym")) { ForEach(["Gym", "Dumbbells", "Bodyweight"], id: \.self) { Text($0) } }
                    Picker("Feeling", selection: setting(\.readiness, fallback: "Ready")) { ForEach(["Ready", "Low energy", "Pain or unwell"], id: \.self) { Text($0) } }
                }
                Section("Suggested session") {
                    ForEach(plan.names, id: \.self) { Text($0) }
                    Text(plan.explanation).font(.footnote).foregroundStyle(.secondary)
                    Text("Adjust exercises and sets in Workout. Goal is recorded for context; this starter planner does not yet prescribe goal-specific progression.").font(.caption)
                    Button(store.state.active == nil ? "Start workout" : "Resume workout") {
                        if store.state.active == nil { store.update { $0.active = Workout(exercises: plan.names.map { Exercise(name: $0) }) } }
                        if store.error == nil { selectedTab = 1 }
                    }.disabled(store.state.active == nil && plan.names.isEmpty)
                }
            }.navigationTitle("Today")
        }
    }
}
