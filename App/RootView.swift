import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var selectedTab = 0
    var body: some View {
        Group {
            if store.loaded {
                TabView(selection: $selectedTab) {
                    TodayView(selectedTab: $selectedTab).tabItem { Label("Today", systemImage: "sun.max") }.tag(0)
                    WorkoutView().tabItem { Label("Workout", systemImage: "dumbbell") }.tag(1)
                    JourneyView().tabItem { Label("Journey", systemImage: "chart.xyaxis.line") }.tag(2)
                    CoachView().tabItem { Label("Coach", systemImage: "bubble.left") }.tag(3)
                }.tint(.teal)
            } else {
                ContentUnavailableView {
                    Label("Saved data needs attention", systemImage: "externaldrive.badge.exclamationmark")
                } description: { Text(store.error ?? "Unable to open saved data.") }
                actions: { Button("Retry") { store.reload() } }
            }
        }
        .alert("Saving needs attention", isPresented: Binding(get: { store.loaded && store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
    }
}
