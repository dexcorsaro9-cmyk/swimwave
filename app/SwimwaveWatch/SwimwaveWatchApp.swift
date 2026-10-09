import SwiftUI

@main
struct SwimwaveWatchApp: App {
    @StateObject private var manager = WorkoutManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
    }
}
