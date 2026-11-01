import SwiftUI

@main struct BearformingApp: App {
    @StateObject private var store = WorkoutStore()
    var body: some Scene { WindowGroup { RootView().environmentObject(store) } }
}
