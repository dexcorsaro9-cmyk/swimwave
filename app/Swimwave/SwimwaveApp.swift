import SwiftUI

@main
struct SwimwaveApp: App {
    @State private var stato = StatoApp()
    @State private var mostraSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // La schermata principale nasce dopo la splash: così nessun foglio o richiesta compare sopra il logo.
                if !mostraSplash {
                    RootView()
                        .transition(.opacity)
                }
                if mostraSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.5)) { mostraSplash = false }
                    }
                    .transition(.opacity)
                }
            }
            .environment(stato)
        }
    }
}
