import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var exerciseName = ""
    @State private var finishConfirmation = false
    @FocusState private var keyboardFocused: Bool
    var body: some View {
        NavigationStack {
            Group {
                if let workout = store.state.active {
                    List {
                        Section {
                            Label("Changes save automatically", systemImage: "checkmark.shield")
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                let remaining = max(0, Int((store.state.restUntil ?? context.date).timeIntervalSince(context.date).rounded(.up)))
                                if remaining > 0 {
                                    HStack { Text("Rest: \(remaining)s").monospacedDigit(); Spacer(); Button("Skip") { store.update { $0.restUntil = nil } } }
                                }
                            }
                        }
                        ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { ei, exercise in
                            Section {
                                if let previous = store.state.previousPerformance(for: exercise.name) {
                                    Text("Last: " + previous.sets.filter { $0.completedAt != nil }.map { "\($0.reps) × \($0.weight.formatted()) lb" }.joined(separator: ", "))
                                        .font(.footnote).foregroundStyle(.secondary)
                                } else { Text("No previous logged performance").font(.footnote).foregroundStyle(.secondary) }
                                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { si, set in
                                    HStack {
                                        Text("\(si + 1)").foregroundStyle(.secondary)
                                        LiveSetField(title: "Reps", value: Double(set.reps), maximum: 999, integerOnly: true) { value in
                                            store.update { $0.active?.exercises[ei].sets[si].reps = Int(value) }
                                        }.focused($keyboardFocused)
                                        Text("×")
                                        LiveSetField(title: "Weight in pounds", value: set.weight, maximum: 9999, integerOnly: false) { value in
                                            store.update { $0.active?.exercises[ei].sets[si].weight = value }
                                        }.focused($keyboardFocused)
                                        Text("lb").font(.caption)
                                        Button {
                                            store.update { state in
                                                if set.completedAt == nil {
                                                    state.active?.exercises[ei].sets[si].completedAt = Date()
                                                    state.restUntil = Date().addingTimeInterval(90)
                                                } else {
                                                    state.active?.exercises[ei].sets[si].completedAt = nil
                                                    state.restUntil = nil
                                                }
                                            }
                                        } label: { Image(systemName: set.completedAt == nil ? "circle" : "checkmark.circle.fill").font(.title2) }
                                        .disabled(set.completedAt == nil && set.reps < 1)
                                        .accessibilityLabel(set.completedAt == nil ? "Complete set" : "Undo set")
                                    }.buttonStyle(.borderless)
                                }
                                Button("Add set") { store.update { $0.active?.exercises[ei].sets.append(LoggedSet()) } }
                                Menu("Substitute exercise") {
                                    ForEach(["Leg press", "Goblet squat", "Dumbbell bench press", "Seated row", "Lat pulldown", "Leg curl", "Leg extension"].filter { $0 != exercise.name }, id: \.self) { name in
                                        Button(name) { store.update { $0.active?.exercises[ei] = Exercise(name: name) } }
                                    }
                                }.disabled(exercise.sets.contains { $0.completedAt != nil })
                                Text("Substitution is available before completing sets for this exercise.").font(.caption).foregroundStyle(.secondary)
                            } header: { Text(exercise.name) }
                        }
                        Section("Add an exercise") {
                            TextField("Exercise name", text: $exerciseName)
                            Button("Add exercise") {
                                let name = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                                store.update { $0.active?.exercises.append(Exercise(name: name)) }
                                if store.error == nil { exerciseName = "" }
                            }.disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        Button("Finish workout") { finishConfirmation = true }
                    }.scrollDismissesKeyboard(.interactively)
                } else { ContentUnavailableView("Ready when you are", systemImage: "dumbbell", description: Text("Start a session from Today.")) }
            }.navigationTitle("Workout")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { keyboardFocused = false }
                }
            }
            .confirmationDialog("Save this workout to Journey?", isPresented: $finishConfirmation, titleVisibility: .visible) {
                Button("Finish and save") { store.update { state in
                    guard var finished = state.active else { return }
                    finished.finishedAt = Date(); state.history.append(finished); state.active = nil; state.restUntil = nil
                } }
                Button("Keep training", role: .cancel) {}
            }
        }
    }
}

// String-backed input persists each valid edit without waiting for focus to leave.
private struct LiveSetField: View {
    let title: String
    let value: Double
    let maximum: Double
    let integerOnly: Bool
    let save: (Double) -> Void
    @State private var draft = ""
    @State private var invalid = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField(title, text: $draft)
                .keyboardType(integerOnly ? .numberPad : .decimalPad)
                .accessibilityLabel(title)
                .onAppear { draft = display(value) }
                .onChange(of: draft) { _, text in
                    let separator = Locale.current.decimalSeparator ?? "."
                    let normalized = text.replacingOccurrences(of: separator, with: ".")
                    let parsed = text.isEmpty ? 0 : Double(normalized)
                    guard let number = parsed, number.isFinite, number >= 0,
                          number <= maximum, !integerOnly || number.rounded() == number else {
                        invalid = true
                        return
                    }
                    invalid = false
                    if number != value { save(number) }
                }
                .onChange(of: value) { _, newValue in
                    // Preserve partial decimal input such as "60." during typing.
                    let normalized = draft.replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
                    if (draft.isEmpty ? Optional(0.0) : Double(normalized)) != Optional(newValue) {
                        draft = display(newValue)
                    }
                }
            if invalid {
                Text("Enter 0–\(Int(maximum))\(integerOnly ? " whole reps" : " lb"). Not saved.")
                    .font(.caption2).foregroundStyle(.red)
            }
        }
    }

    private func display(_ number: Double) -> String {
        number == 0 ? "" : (number.rounded() == number ? String(Int(number)) : String(number))
            .replacingOccurrences(of: ".", with: Locale.current.decimalSeparator ?? ".")
    }
}
