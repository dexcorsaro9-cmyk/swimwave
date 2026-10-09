import SwiftUI

struct RootView: View {
    @Environment(StatoApp.self) private var stato

    var body: some View {
        Group {
            if stato.onboardingCompletato {
                SchedaPrincipale()
            } else {
                OnboardingView()
            }
        }
        // Il profilo si modifica con i binding del Profilo: ogni cambio viene salvato.
        .onChange(of: stato.profilo) { _, _ in
            stato.salva()
        }
    }
}

struct SchedaPrincipale: View {
    var body: some View {
        TabView {
            OggiView()
                .tabItem { Label("tab.oggi", systemImage: "figure.pool.swim") }
            PercorsoView()
                .tabItem { Label("tab.percorso", systemImage: "flag.fill") }
            StoricoView()
                .tabItem { Label("tab.storico", systemImage: "clock.arrow.circlepath") }
            ProfiloView()
                .tabItem { Label("tab.profilo", systemImage: "person.crop.circle") }
        }
        .tint(Tema.corallo)
    }
}
