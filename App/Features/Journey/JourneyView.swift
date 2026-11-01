import SwiftUI
import UniformTypeIdentifiers
import FitnessCore

struct JourneyView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var importer = false
    @State private var draft: JourneyEntry?
    @State private var importError: String?
    var body: some View {
        NavigationStack {
            List {
                Section("Your timeline") {
                    Button("Add weight, ride, measurement or milestone") { draft = JourneyEntry() }
                    Button("Import ChatGPT conversations.json") { importer = true }
                    Text("Imports stay pending until you review dates, units and whether activity was completed. Original message text is retained. Nothing is uploaded.").font(.caption)
                    ForEach((store.state.entries ?? []).sorted { $0.date > $1.date }) { entry in
                        Button { draft = entry } label: {
                            VStack(alignment: .leading) {
                                Text(entry.category).font(.headline)
                                Text(entry.date, style: .date)
                                Text(entry.text).lineLimit(3)
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
                            ForEach(workout.exercises) { exercise in
                                Text("\(exercise.name): \(exercise.sets.filter { $0.completedAt != nil }.count) completed sets")
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
                    guard data.count <= 50_000_000 else { importError = "Use an export under 50 MB for this version."; return }
                    let incoming = try ChatImport.extract(data)
                    store.update { state in
                        var entries = state.entries ?? []
                        var known = Set(entries.map(\.sourceID))
                        for entry in incoming where known.insert(entry.sourceID).inserted { entries.append(entry) }
                        state.entries = entries
                    }
                    if incoming.isEmpty { importError = "No matching fitness messages found. Choose conversations.json from your export." }
                } catch { importError = "Could not read this export. Your existing history was preserved." }
            }
            .alert("Import", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) { Button("OK") { importError = nil } } message: { Text(importError ?? "") }
            .sheet(item: $draft) { entry in
                EntryEditor(entry: entry) { updated in
                    store.update { state in
                        var entries = state.entries ?? []
                        if let i = entries.firstIndex(where: { $0.id == updated.id }) { entries[i] = updated } else { entries.append(updated) }
                        state.entries = entries
                    }
                    if store.error == nil { draft = nil }
                } remove: {
                    store.update { $0.entries?.removeAll { $0.id == entry.id } }
                    if store.error == nil { draft = nil }
                }
            }
        }
    }
}

private struct EntryEditor: View {
    @State var entry: JourneyEntry
    let save: (JourneyEntry) -> Void
    let remove: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $entry.category) { ForEach(["Milestone", "Body weight", "Cycling", "Measurement", "Lifting", "Imported conversation"], id: \.self) { Text($0) } }
                DatePicker("Date", selection: $entry.date, displayedComponents: [.date, .hourAndMinute])
                Section("Record • include original units") { TextEditor(text: $entry.text).frame(minHeight: 140) }
                Section("Source") {
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
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save(entry) }.disabled(entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }
}
