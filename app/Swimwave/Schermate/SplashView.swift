import SwiftUI
import SwimwaveCore

/// Schermata di apertura: il logo di Swimwave al centro e, sotto, i personaggi acquatici che nuotano.
/// Si chiude da sola dopo pochi secondi (o con un tocco). Con "Riduci movimento" i personaggi stanno fermi.
/// Lo sfondo del lancio statico (UILaunchScreen) ha lo stesso blu, così dal lancio a questa schermata non c'è stacco.
struct SplashView: View {
    /// Chiamata quando la schermata va chiusa (tempo scaduto o tocco).
    var fine: () -> Void

    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @State private var visibile = false

    static let durata: Double = 2.6

    private let colonne = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Tema.navy, Tema.navyChiaro], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)
                logo
                Spacer(minLength: 16)
                acqua
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: fine)
        .task {
            withAnimation(.easeOut(duration: 0.6)) { visibile = true }
            try? await Task.sleep(nanoseconds: UInt64(Self.durata * 1_000_000_000))
            fine()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Swimwave"))
        .accessibilityAddTraits(.isButton)
    }

    private var logo: some View {
        VStack(spacing: 14) {
            Image("logo-swimwave")
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: Color.black.opacity(0.35), radius: 18, y: 8)
                .scaleEffect(visibile ? 1 : 0.85)
            Text(verbatim: "Swimwave")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("splash.slogan")
                .font(Tema.corpo)
                .foregroundStyle(Color.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .opacity(visibile ? 1 : 0)
    }

    /// Una fascia d'acqua con i personaggi (lo squalo e gli altri), in due file da tre.
    private var acqua: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: Tipologia.a2.acqua, startPoint: .top, endPoint: .bottom)
            OndaSuperficie(fase: 0.6)
                .fill(Color.white.opacity(0.22))
                .frame(height: 14)
            TimelineView(.animation(minimumInterval: 1.0 / 15.0, paused: riduciMovimento)) { linea in
                let t = riduciMovimento ? 0 : linea.date.timeIntervalSinceReferenceDate
                LazyVGrid(columns: colonne, spacing: 4) {
                    ForEach(Array(Personaggio.tutti.enumerated()), id: \.element.id) { i, p in
                        PersonaggioSplash(personaggio: p, t: t + Double(i) * 0.37, ferma: riduciMovimento)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 28)
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
        .opacity(visibile ? 1 : 0)
        .ignoresSafeArea(edges: .bottom)
        .accessibilityHidden(true)
    }
}

/// Un personaggio nella cella: nuota sul posto (fotogrammi del suo foglio) con un leggero dondolio.
private struct PersonaggioSplash: View {
    let personaggio: Personaggio
    let t: Double
    let ferma: Bool

    var body: some View {
        let foglio = personaggio.nuota
        Canvas { contesto, dimensione in
            let immagine = contesto.resolve(Image(foglio.nome))
            let i = ferma ? 0 : Int(t * 12) % foglio.totale
            let col = i % FoglioPersonaggio.colonne, riga = i / FoglioPersonaggio.colonne
            // Il fotogramma sta nella cella senza deformarsi, centrato, un po' in basso per lasciare spazio al dondolio.
            var w = dimensione.width
            var h = w * foglio.proporzione
            if h > dimensione.height { h = dimensione.height; w = h / foglio.proporzione }
            let dy: CGFloat = ferma ? 0 : CGFloat(sin(t * 1.6)) * 3
            let ox = (dimensione.width - w) / 2
            let oy = (dimensione.height - h) / 2 + dy
            let tutta = CGRect(x: ox - CGFloat(col) * w, y: oy - CGFloat(riga) * h,
                               width: w * CGFloat(FoglioPersonaggio.colonne), height: h * CGFloat(foglio.righe))
            contesto.clip(to: Path(CGRect(x: ox, y: oy, width: w, height: h)))
            contesto.draw(immagine, in: tutta)
        }
        .frame(height: 84)
    }
}
