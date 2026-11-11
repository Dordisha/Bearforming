import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: WorkoutStore
    @Binding var selectedTab: Int
    private var profile: TrainingProfile { store.state.profile ?? TrainingProfile() }
    private var preview: [Exercise] { store.state.plannedExercises ?? [] }
    private func editPreview(_ change: (inout [Exercise]) -> Void) {
        var items = preview
        change(&items)
        store.update { $0.plannedExercises = items }
    }
    private func optionalSetting<T>(_ key: WritableKeyPath<TrainingProfile, T?>, fallback: T) -> Binding<T> {
        Binding(get: { profile[keyPath: key] ?? fallback }, set: { value in
            store.update { state in
                var updated = state.profile ?? TrainingProfile()
                updated[keyPath: key] = value
                state.profile = updated
                state.refreshPreview()
            }
        })
    }
    private var summary: SessionPreviewSummary { SessionPreviewSummary(state: store.state) }
    private func setting<T>(_ key: WritableKeyPath<TrainingProfile, T>, fallback: T) -> Binding<T> {
        Binding(get: { (store.state.profile ?? TrainingProfile())[keyPath: key] }, set: { value in
            store.update { state in var profile = state.profile ?? TrainingProfile(); profile[keyPath: key] = value; state.profile = profile; state.refreshPreview() }
        })
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image("BearformingLogo").resizable().scaledToFit().frame(height: 180).frame(maxWidth: .infinity)
                    Text("Build your next chapter").font(.title.bold())
                }
                Section(store.state.active == nil ? "Your saved workout" : "Workout in progress") {
                    if store.state.active == nil {
                        Text("\(summary.exerciseCount) exercises · \(summary.setCount) planned sets · about \(summary.minutes) minutes")
                            .font(.headline)
                        Text(summary.explanation).font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("Resume your active workout to continue logging.")
                    }
                    Button(store.state.active == nil ? "Start workout" : "Resume workout") {
                        if store.state.active == nil { store.update { $0.startWorkout(exercises: preview) } }
                        if store.error == nil { selectedTab = 1 }
                    }.disabled(store.state.active == nil && (preview.isEmpty || profile.readiness == "Pain or unwell"))
                }
                Section("Today's check-in") {
                    Picker("Goal", selection: setting(\.goal, fallback: "Build consistency")) { ForEach(["Build consistency", "Build strength", "Maintain muscle"], id: \.self) { Text($0) } }
                    Stepper("Time: \(store.state.profile?.minutes ?? 40) minutes", value: setting(\.minutes, fallback: 40), in: 15...90, step: 5)
                    Picker("Equipment", selection: setting(\.equipment, fallback: "Gym")) { ForEach(["Gym", "Dumbbells", "Bodyweight"], id: \.self) { Text($0) } }
                    Picker("Feeling", selection: setting(\.readiness, fallback: "Ready")) { ForEach(["Ready", "Low energy", "Pain or unwell"], id: \.self) { Text($0) } }
                }
                Section("Session preferences") {
                    Picker("Focus", selection: optionalSetting(\.focus, fallback: "Full body")) {
                        ForEach(["Full body", "Upper", "Lower", "Push", "Pull"], id: \.self) { Text($0) }
                    }
                    Stepper("Target: \(profile.targetCount ?? (profile.minutes < 35 ? 4 : 6)) exercises",
                            value: optionalSetting(\.targetCount, fallback: profile.minutes < 35 ? 4 : 6), in: 3...7)
                    Toggle("Strength warmup already done", isOn: optionalSetting(\.warmedUp, fallback: false))
                    Toggle("Returning after a break", isOn: optionalSetting(\.returning, fallback: false))
                }
                Section("Session preview") {
                    ForEach(preview) { exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.name).font(.headline)
                            Text("\(exercise.sets.count) sets").font(.caption)
                            HStack {
                                Menu("Substitute") {
                                    ForEach(ExerciseCatalog.choices(profile).filter { option in !preview.contains { $0.name == option.name } }) { option in
                                        Button(option.name) {
                                            editPreview { items in
                                                if let index = items.firstIndex(where: { $0.id == exercise.id }) {
                                                    items[index] = Exercise(name: option.name, sets: exercise.sets)
                                                }
                                            }
                                        }
                                    }
                                }
                                Button("Remove", role: .destructive) { editPreview { $0.removeAll { $0.id == exercise.id } } }
                            }.buttonStyle(.borderless)
                        }
                    }.onMove { source, destination in editPreview { $0.move(fromOffsets: source, toOffset: destination) } }
                    Menu("Add exercise") {
                        ForEach(ExerciseCatalog.choices(profile).filter { option in !preview.contains { $0.name == option.name } }) { option in
                            Button(option.name) { editPreview { $0.append(Exercise(name: option.name)) } }
                        }
                    }
                    Text("Estimated total: \(TrainingPlan.estimate(preview, profile: profile)) minutes • \(profile.warmedUp == true ? 0 : 5) minutes warmup")
                    if TrainingPlan.estimate(preview, profile: profile) > profile.minutes {
                        Text("Your edits exceed the available time. Remove exercises or increase your time budget.").foregroundStyle(.orange)
                    }
                    Button("Reset suggestion") { store.update { $0.refreshPreview() } }
                    Text("Adjust exercises and sets in Workout. Goal is recorded for context; this starter planner does not yet prescribe goal-specific progression.").font(.caption)

                }
            }.navigationTitle("Today").toolbar { EditButton() }
            .onAppear {
                if store.state.plannedExercises == nil {
                    store.update { $0.preparePreviewIfNeeded() }
                }
            }
        }
    }
}
