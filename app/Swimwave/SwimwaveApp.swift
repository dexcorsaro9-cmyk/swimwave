import SwiftUI

@main
struct SwimwaveApp: App {
    @State private var stato = ModalitaDemo.creaStato()
    // In modalità demo (test dell'interfaccia) la schermata di apertura si salta, salvo richiesta.
    @State private var mostraSplash = !ModalitaDemo.attiva || ModalitaDemo.mostraSplash

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
