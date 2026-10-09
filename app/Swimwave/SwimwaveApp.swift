import SwiftUI

@main
struct SwimwaveApp: App {
    @State private var stato = StatoApp()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(stato)
        }
    }
}
