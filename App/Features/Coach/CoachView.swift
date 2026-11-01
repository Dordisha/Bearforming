import SwiftUI
import FitnessCore

struct CoachView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var question = ""
    @State private var messages: [String] = []
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Your training companion").font(.title2.bold())
                    Text("Offline coach • guided responses from your saved workouts and reviewed notes. No AI service connected.").font(.caption).foregroundStyle(.secondary)
                    ForEach(["What should I train today?", "Show my progress", "Show reviewed history"], id: \.self) { prompt in Button(prompt) { respond(prompt) } }
                }
                ForEach(Array(messages.enumerated()), id: \.offset) { _, message in Text(message).textSelection(.enabled) }
                Section {
                    TextField("Ask about today, progress or history", text: $question)
                    Button("Ask coach") { let prompt = question; question = ""; respond(prompt) }.disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }.navigationTitle("Coach")
        }
    }
    private func respond(_ prompt: String) {
        messages.append("You: " + prompt)
        let text = prompt.lowercased()
        if text.contains("today") || text.contains("train") {
            let plan = TrainingPlan(state: store.state)
            messages.append("Coach: " + plan.names.joined(separator: ", ") + "\n" + plan.explanation + "\nUpdate your time, equipment and feedback in Today.")
        } else if text.contains("progress") {
            let workouts = store.state.history
            let count = workouts.flatMap(\.exercises).flatMap(\.sets).filter { $0.completedAt != nil }.count
            messages.append("Coach: Your saved workout log contains \(workouts.count) finished sessions and \(count) completed sets. This alone does not establish body composition or weight-loss changes.")
        } else if text.contains("history") || text.contains("record") {
            let reviewed = (store.state.entries ?? []).filter { $0.approved && $0.status == "completed" }.sorted { $0.date > $1.date }
            messages.append(reviewed.isEmpty ? "Coach: No reviewed completed records yet. Open Journey to review or add entries." : "Coach: Latest reviewed completed records:\n" + reviewed.prefix(3).map { "\($0.date.formatted(date: .abbreviated, time: .omitted)): \($0.text)\nSource: \($0.source)" }.joined(separator: "\n\n"))
        } else {
            messages.append("Coach: I can currently explain today's starter session, summarize logged progress, and show reviewed history. Open-ended coaching is not connected yet.")
        }
    }
}
