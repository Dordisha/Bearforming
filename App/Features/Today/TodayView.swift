import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: WorkoutStore
    @Binding var selectedTab: Int
    @State private var pendingFocus = "Full body"
    @State private var confirmFocus = false
    @State private var pendingSplit: String?
    @State private var confirmSplit = false
    private var profile: TrainingProfile { store.state.planningProfile }
    private func requestFocus(_ focus: String) {
        pendingFocus = focus
        confirmFocus = true
    }
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
                if store.state.active == nil && store.state.nextSplitFocus == nil {
                    Section("Next focus suggestion") {
                        let suggestion = NextFocusSuggestion(state: store.state)
                        if let focus = suggestion.focus {
                            Text("Consider \(focus.lowercased()) body").font(.headline)
                        }
                        Text(suggestion.explanation).font(.footnote).foregroundStyle(.secondary)
                        if let focus = suggestion.focus {
                            Button("Use \(focus.lowercased()) for this workout") { requestFocus(focus) }
                        }
                        Text("Choose a focus for this workout below. Your usual focus stays unchanged.")
                            .font(.caption)
                    }
                }
                Section("Today's check-in") {
                    Picker("Goal", selection: setting(\.goal, fallback: "Build consistency")) { ForEach(["Build consistency", "Build strength", "Maintain muscle"], id: \.self) { Text($0) } }
                    Stepper("Time: \(store.state.profile?.minutes ?? 40) minutes", value: setting(\.minutes, fallback: 40), in: 15...90, step: 5)
                    Picker("Equipment", selection: setting(\.equipment, fallback: "Gym")) { ForEach(["Gym", "Dumbbells", "Bodyweight"], id: \.self) { Text($0) } }
                    Picker("Feeling", selection: setting(\.readiness, fallback: "Ready")) { ForEach(["Ready", "Low energy", "Pain or unwell"], id: \.self) { Text($0) } }
                }
                if store.state.active == nil {
                    Section("Focus for this workout") {
                        Text("Planning focus: \(profile.focus ?? "Full body")")
                        Menu("Change this workout") {
                            ForEach(TrainingProfile.strengthFocuses, id: \.self) { focus in
                                Button(focus) { requestFocus(focus) }
                            }
                            Button("Use sequence or usual focus") { requestFocus("Use usual focus") }
                        }
                        Text("Applies to the next workout, including after reopening the app. Starting it clears the override. Replacing the preview requires confirmation.").font(.caption)
                    }
                }
                if store.state.active == nil {
                    Section("Rolling Upper / Lower") {
                        Text(store.state.nextSplitFocus.map { "Next in sequence: \($0)" } ?? "Sequence off")
                        Menu("Set sequence") {
                            ForEach(["Upper", "Lower"], id: \.self) { focus in
                                Button("Start with \(focus)") { pendingSplit = focus; confirmSplit = true }
                            }
                            Button("Turn off sequence") { pendingSplit = nil; confirmSplit = true }
                        }
                        Text("Alternates after you finish a matching workout with every remaining set logged. Partial sessions, a different focus and missed days keep the same next slot. This is a schedule, not a recovery assessment.").font(.caption)
                    }
                }
                Section("Session preferences") {
                    Picker("Usual focus", selection: Binding(get: { store.state.profile?.focus ?? "Full body" }, set: { focus in
                        store.update { state in
                            var saved = state.profile ?? TrainingProfile(); saved.focus = focus; state.profile = saved
                            state.refreshPreview()
                        }
                    })) {
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
            .confirmationDialog("Replace preview and update sequence?", isPresented: $confirmSplit, titleVisibility: .visible) {
                Button("Update sequence") { store.update { $0.configureSplit(startingWith: pendingSplit) } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This replaces preview edits and clears the next-workout override. Your usual focus and logged workouts stay unchanged.")
            }
            .confirmationDialog("Replace saved workout preview?", isPresented: $confirmFocus, titleVisibility: .visible) {
                Button("Replace preview") {
                    store.update { $0.changeSessionFocus(pendingFocus == "Use usual focus" ? nil : pendingFocus) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This replaces your preview edits using \(pendingFocus == "Use usual focus" ? (store.state.nextSplitFocus ?? store.state.profile?.focus ?? "Full body") : pendingFocus). Your usual focus and logged workouts stay unchanged.")
            }
            .onAppear {
                if store.state.plannedExercises == nil {
                    store.update { $0.preparePreviewIfNeeded() }
                }
            }
        }
    }
}
