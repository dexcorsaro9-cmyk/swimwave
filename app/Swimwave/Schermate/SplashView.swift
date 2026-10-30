import SwiftUI

/// Schermata di apertura: un'unica immagine (assets/splash/splash.jpg) con il logo di Swimwave e i sei personaggi.
/// Si chiude da sola dopo pochi secondi o con un tocco. Lo sfondo del lancio statico (UILaunchScreen) è dello stesso blu
/// dell'alto dell'immagine, così dal lancio alla splash non c'è stacco.
struct SplashView: View {
    /// Chiamata quando la schermata va chiusa (tempo scaduto o tocco).
    var fine: () -> Void

    @State private var visibile = false

    static let durata: Double = 2.6

    var body: some View {
        ZStack {
            Tema.navy.ignoresSafeArea()
            // Riempie lo schermo: sui telefoni con schermo meno alto si tagliano un po' i bordi, mai il centro.
            Image("splash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(visibile ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: fine)
        .task {
            withAnimation(.easeOut(duration: 0.5)) { visibile = true }
            try? await Task.sleep(nanoseconds: UInt64(Self.durata * 1_000_000_000))
            fine()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Swimwave"))
        .accessibilityAddTraits(.isButton)
    }
}
