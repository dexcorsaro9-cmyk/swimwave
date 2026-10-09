import SwiftUI
import SwimwaveCore

/// Ordine del primo avvio: 18+ -> scelta del coach e domande -> consenso all'IA -> (solo Spronami) spiegazione delle notifiche -> app.
struct RootView: View {
    @Environment(StatoApp.self) private var stato
    /// La spiegazione delle notifiche si mostra una volta sola.
    @AppStorage("swimwave.permessoNotificheMostrato") private var notificheMostrate = false
    /// Vero solo mentre la spiegazione è sullo schermo: si attiva subito dopo il consenso all'IA (o all'apertura, se
    /// l'app era stata chiusa proprio lì). Il passaggio a Spronami dal Profilo non passa di qui: ha il suo foglio.
    @State private var spiegaNotifiche = false

    var body: some View {
        Group {
            if !stato.maggiorenneConfermato {
                MaggiorenneView()
            } else if !stato.onboardingCompletato {
                OnboardingView()
            } else if stato.consensoIA == nil {
                ConsensoIAView()
            } else if spiegaNotifiche {
                PermessoNotificheView {
                    notificheMostrate = true
                    spiegaNotifiche = false
                    Task { await stato.riprogrammaPromemoria() }
                }
            } else {
                SchedaPrincipale()
            }
        }
        // Il profilo si modifica con i binding del Profilo: ogni cambio viene salvato.
        .onChange(of: stato.profilo) { _, _ in
            stato.salva()
        }
        .onChange(of: stato.consensoIA) { vecchio, nuovo in
            if vecchio == nil, nuovo != nil, stato.profilo.ritmo == .spronami, !notificheMostrate {
                spiegaNotifiche = true
            }
        }
        .onAppear {
            if stato.maggiorenneConfermato, stato.onboardingCompletato, stato.consensoIA != nil,
               stato.profilo.ritmo == .spronami, !notificheMostrate {
                spiegaNotifiche = true
            }
        }
        // "Cancella i miei dati" riporta tutto all'inizio: anche la spiegazione delle notifiche.
        .onChange(of: stato.maggiorenneConfermato) { _, confermato in
            if !confermato { notificheMostrate = false }
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
        // Barra in basso con i colori del tema (scuro: #0B2036).
        .toolbarBackground(Tema.barra, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
