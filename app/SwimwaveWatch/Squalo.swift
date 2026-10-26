import SwiftUI

/// Lo squalo di Swimwave (immagine in Assets.xcassets/squalo-nuota, sorgente in assets/squalo/), che nuota lungo una corsia:
/// la posizione è l'avanzamento della ripetizione (0...1).
/// - `nuota`: ondeggia e si schiaccia a ritmo di bracciata. Nel recupero galleggia piano; in pausa sta fermo e si attenua.
/// - Con il Watch in risparmio energetico (schermo attenuato) l'animazione si ferma: in acqua conta la batteria.
/// Una sola informazione dominante per schermata (docs/GRAFICA.md): lo squalo è piccolo e non copre mai i numeri.
struct CorsiaSqualo: View {
    var progresso: Double
    var nuota: Bool
    var inPausa: Bool

    @Environment(\.isLuminanceReduced) private var schermoAttenuato

    private let larghezza: CGFloat = 40
    private let altezza: CGFloat = 20

    var body: some View {
        let animato = !inPausa && !schermoAttenuato
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 0.1, paused: !animato)) { linea in
                let t = linea.date.timeIntervalSinceReferenceDate
                // L'immagine ha il muso leggermente in su: +6° lo mette in piano. Poi un'ondulazione da nuotata.
                let ondulazione = animato ? sin(t * (nuota ? 7 : 2)) * (nuota ? 4 : 1.5) : 0
                let respiro = animato ? sin(t * (nuota ? 7 : 2)) * (nuota ? 0.05 : 0.02) : 0
                let onda = animato ? sin(t * (nuota ? 3.5 : 1.4)) * (nuota ? 1 : 2) : 0
                Image("squalo-nuota")
                    .resizable()
                    .scaledToFit()
                    .frame(width: larghezza, height: altezza)
                    .rotationEffect(.degrees(6 + ondulazione))
                    .scaleEffect(x: 1 + respiro, y: 1 - respiro)
                    .offset(x: max(0, geo.size.width - larghezza) * min(1, max(0, progresso)), y: onda)
                    .opacity(inPausa ? 0.5 : 1)
            }
            .animation(.easeInOut(duration: 0.5), value: progresso)
        }
        .frame(height: altezza + 4)
        .accessibilityHidden(true)
    }
}
