import SwiftUI
import UniformTypeIdentifiers

struct JourneyView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var importer = false
    @State private var draft: JourneyEntry?
    @State private var importMessage: String?
    var body: some View {
        NavigationStack {
            List {
                Section("Your timeline") {
                    Button("Add weight, cardio, ride or milestone") { draft = JourneyEntry() }
                    Button("Import ChatGPT conversations.json") { importer = true }
                    Text("Imports stay pending until you review dates, units and whether activity was completed. Original message text is retained. Nothing is uploaded.").font(.caption)
                    ForEach((store.state.entries ?? []).sorted { $0.date > $1.date }) { entry in
                        Button { draft = entry } label: {
                            VStack(alignment: .leading) {
                                Text(entry.category).font(.headline)
                                Text(entry.date, style: .date)
                                Text(entry.text).lineLimit(3)
                                if entry.isCardio {
                                    Text("Duration: \(entry.durationMinutes.map { "\($0) min" } ?? "unknown") · Effort: \(entry.cardioEffort ?? "unknown")").font(.caption)
                                }
                                Text(entry.approved ? "Reviewed • \(entry.status)" : "Needs review • \(entry.status)").font(.caption)
                            }
                        }.foregroundStyle(.primary)
                    }
                }
                Section("Logged workouts") {
                    if store.state.history.isEmpty { Text("Finish a workout to start your lifting history.") }
                    ForEach(store.state.history.reversed()) { workout in
                        VStack(alignment: .leading) {
                            Text(workout.startedAt, style: .date).font(.headline)
                            let completed = workout.completedExercises()
                            if completed.isEmpty { Text("No completed sets logged.") }
                            ForEach(completed) { exercise in
                                Text("\(exercise.name): \(exercise.sets.count) completed sets")
                            }
                            DisclosureGroup("Saved plan • \(workout.exercises.count) movements") {
                                ForEach(workout.exercises) { exercise in
                                    Text("\(exercise.name): \(exercise.sets.count) planned sets • \(exercise.completedSets().count) completed\(exercise.remainingSetsSkipped == true ? " • remaining sets skipped" : "")")
                                }
                            }
                        }
                    }
                }
            }.navigationTitle("Journey")
            .fileImporter(isPresented: $importer, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let data = try Data(contentsOf: url)
                    guard data.count <= 50_000_000 else { importMessage = "Use an export under 50 MB for this version."; return }
                    let incoming = try ChatImport.extract(data)
                    var summary = ImportSummary()
                    store.update { state in summary = state.stageImportedEntries(incoming) }
                    if store.loaded && store.error == nil {
                        importMessage = incoming.isEmpty
                            ? "No matching fitness messages found. Choose conversations.json from your export."
                            : summary.message
                    }
                } catch { importMessage = "Could not read this export. Your existing history was preserved." }
            }
            .alert("Import", isPresented: Binding(get: { importMessage != nil }, set: { if !$0 { importMessage = nil } })) { Button("OK") { importMessage = nil } } message: { Text(importMessage ?? "") }
            .sheet(item: $draft) { entry in
                EntryEditor(entry: entry) { updated in
                    store.update { $0.saveJourneyEntry(updated) }
                    if store.error == nil { draft = nil }
                } remove: {
                    store.update { $0.entries?.removeAll { $0.id == entry.id } }
                    if store.error == nil { draft = nil }
                }
            }
        }
    }
}

struct EntryEditor: View {
    @EnvironmentObject var store: WorkoutStore
    @State var entry: JourneyEntry
    @State private var durationText: String
    @State private var effort: String
    @State private var liftingOccurrences: [LiftingOccurrence]
    init(entry: JourneyEntry, save: @escaping (JourneyEntry) -> Void, remove: @escaping () -> Void) {
        _entry = State(initialValue: entry)
        _durationText = State(initialValue: entry.durationMinutes.map(String.init) ?? "")
        _effort = State(initialValue: entry.cardioEffort ?? "Unknown")
        _liftingOccurrences = State(initialValue: entry.liftingOccurrences ?? [])
        self.save = save
        self.remove = remove
    }
    private var validatedEntry: JourneyEntry? {
        var copy = entry
        guard copy.setCardioDetails(duration: durationText, effort: effort),
              copy.setLiftingOccurrences(liftingOccurrences) else { return nil }
        return copy
    }
    let save: (JourneyEntry) -> Void
    let remove: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                if let error = store.error { Text(error).foregroundStyle(.red) }
                Picker("Type", selection: $entry.category) { ForEach(["Milestone", "Body weight", "Cycling", "Cardio", "Measurement", "Lifting", "Imported conversation"], id: \.self) { Text($0) } }
                DatePicker("Date", selection: $entry.date, displayedComponents: [.date, .hourAndMinute])
                if entry.isCardio {
                    Section("Cardio details • optional") {
                        TextField("Duration in minutes", text: $durationText).keyboardType(.numberPad)
                        Picker("Your effort", selection: $effort) {
                            ForEach(JourneyEntry.cardioEfforts, id: \.self) { Text($0) }
                        }
                        Text("Leave duration blank or effort Unknown if you do not know. These fields describe your record; they do not mark it completed or reviewed.").font(.caption)
                        if validatedEntry == nil {
                            Text("Enter whole minutes from 1 to 1440, or leave blank.").foregroundStyle(.orange)
                        }
                    }
                }
                Section("Record • include original units") { TextEditor(text: $entry.text).frame(minHeight: 140) }
                if ["Lifting", "Imported conversation"].contains(entry.category) || !liftingOccurrences.isEmpty {
                    LiftingOccurrenceReview(occurrences: $liftingOccurrences)
                }
                Section("Source") {
                    if let role = entry.originalRole {
                        Text("Original author: \(role)").font(.caption)
                        Text("The imported date is the message date, not a confirmed workout date. Review each workout day separately; prefer direct owner corrections over assistant recaps. Unknown sets, reps, load and duration remain unresolved; notes do not create completed lifting sets.").font(.caption)
                    }
                    if let parent = entry.originalParentSourceID {
                        Text("Reply to: \(parent)").font(.caption).textSelection(.enabled)
                    }
                    if let original = entry.originalText { DisclosureGroup("Original message") { Text(original).textSelection(.enabled) } }
                    Text(entry.source).font(.caption).textSelection(.enabled)
                    if entry.source != "Manual entry" && entry.originalTimestamp == nil { Text("Original date missing. Confirm the date before approval.").foregroundStyle(.orange) }
                }
                Picker("Activity status", selection: $entry.status) { ForEach(["unclear", "completed", "planned", "advice"], id: \.self) { Text($0) } }
                Toggle("I reviewed this record", isOn: $entry.approved)
                Text("Reviewed notes can be shown by Coach. Imported free text is not converted to lifting volume or used to choose loads.").font(.caption)
                Button("Delete record", role: .destructive, action: remove)
            }.navigationTitle("Review record")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { if let updated = validatedEntry { save(updated) } }.disabled(validatedEntry == nil || entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }
}

private struct LiftingOccurrenceReview: View {
    @Binding var occurrences: [LiftingOccurrence]
    var body: some View {
        Section("Lifting occurrences • manual review") {
            Text("Add only what the source supports, one movement and workout day per row. Use direct owner corrections, not assistant recaps. Leave an unknown day blank; the message date is not substituted.").font(.caption)
            ForEach($occurrences) { $occurrence in
                VStack(alignment: .leading) {
                    TextField("Workout day YYYY-MM-DD (optional)", text: $occurrence.day)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Movement from source", text: $occurrence.movement)
                    Picker("Occurrence status", selection: $occurrence.status) {
                        ForEach(LiftingOccurrence.statuses, id: \.self) { Text($0) }
                    }
                    Text("Sets, reps, load and duration: unresolved. Excluded from progression and workout recommendations.").font(.caption)
                    if !occurrence.isValid { Text("Enter a movement and a valid YYYY-MM-DD date, or leave the date blank.").foregroundStyle(.orange) }
                    Button("Remove occurrence", role: .destructive) { occurrences.removeAll { $0.id == occurrence.id } }
                }
            }
            Button("Add lifting occurrence") { occurrences.append(LiftingOccurrence()) }
            Text("Saving records your review notes only. It does not create completed sets or overwrite the original message. Review each day separately before marking the record reviewed.").font(.caption)
        }
    }
}
