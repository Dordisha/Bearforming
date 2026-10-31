import SwiftUI
import FitnessCore

struct TodayView: View {
    @EnvironmentObject var store: WorkoutStore
    @Binding var selectedTab: Int
    @State private var selected = "Full body"
    let templates = ["Full body": ["Leg press", "Dumbbell bench press", "Seated row"], "Upper body": ["Dumbbell bench press", "Lat pulldown", "Seated shoulder press"], "Lower body": ["Leg press", "Leg curl", "Leg extension"]]
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image("BearformingLogo").resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: 220).accessibilityLabel("Bearforming bear mascot")
                    Text("Your next session").font(.largeTitle.bold())
                    Text("Build consistency, one session at a time.")
                }
                Section("Choose a starter workout") {
                    Picker("Focus", selection: $selected) { ForEach(templates.keys.sorted(), id: \.self) { Text($0) } }
                    ForEach(templates[selected] ?? [], id: \.self) { Text($0) }
                    Text("Editable starter template. Personalized suggestions will arrive after your history is reviewed.").font(.footnote).foregroundStyle(.secondary)
                    Button(store.state.active == nil ? "Start workout" : "Resume workout") {
                        if store.state.active == nil {
                            store.update { $0.active = Workout(exercises: (templates[selected] ?? []).map { Exercise(name: $0) }) }
                        }
                        if store.error == nil { selectedTab = 1 }
                    }
                }
                Section("Your history") { Text("Chat export has not been imported. Recovered chat summaries are available for future review; they are not yet app training records.") }
            }.navigationTitle("Today, Dorian")
        }
    }
}
