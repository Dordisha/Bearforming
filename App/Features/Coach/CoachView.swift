import SwiftUI
import FitnessCore

struct CoachView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Your coach is coming", systemImage: "bubble.left.and.bubble.right", description: Text("This first build focuses on dependable workout logging. Conversations and recommendations will use confirmed training history once implemented."))
                .navigationTitle("Coach")
        }
    }
}
