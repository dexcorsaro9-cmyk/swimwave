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
            TimelineView(.animation(minimumInterval: 0.066, paused: !animato)) { linea in
                let t = linea.date.timeIntervalSinceReferenceDate
                let onda = animato ? sin(t * (nuota ? 3.5 : 1.4)) * (nuota ? 1 : 2) : 0
                OndaSqualo(fase: animato ? t * (nuota ? 8 : 2.2) : 0, ampiezza: animato ? (nuota ? 0.085 : 0.03) : 0)
                    .frame(width: larghezza, height: altezza)
                    .rotationEffect(.degrees(6))   // l'immagine ha il muso leggermente in su: +6° lo mette in piano
                    .offset(x: max(0, geo.size.width - larghezza) * min(1, max(0, progresso)), y: onda)
                    .opacity(inPausa ? 0.5 : 1)
            }
            .animation(.easeInOut(duration: 0.5), value: progresso)
        }
        .frame(height: altezza + 6)
        .accessibilityHidden(true)
    }
}

/// L'immagine dello squalo tagliata in fettine verticali che ondeggiano una dopo l'altra, più forte verso la coda
/// (a sinistra): l'effetto di un pesce che nuota, partendo da una sola immagine.
struct OndaSqualo: View {
    var fase: Double
    /// Spostamento massimo della coda, in frazione dell'altezza dell'immagine.
    var ampiezza: CGFloat

    private let fettine = 24

    var body: some View {
        Canvas { contesto, dimensione in
            let immagine = contesto.resolve(Image("squalo-nuota"))
            let larghezzaFettina = dimensione.width / CGFloat(fettine)
            for i in 0..<fettine {
                let x = CGFloat(i) * larghezzaFettina
                let posizione = Double(i) / Double(fettine - 1)         // 0 = coda, 1 = muso
                let peso = CGFloat(pow(1 - posizione, 1.6))               // la coda si muove di più, il muso quasi niente
                let spostamento = sin(fase - posizione * 4.2) * Double(ampiezza * peso * dimensione.height)
                contesto.drawLayer { strato in
                    strato.clip(to: Path(CGRect(x: x - 0.4, y: -dimensione.height, width: larghezzaFettina + 0.8, height: dimensione.height * 3)))
                    strato.translateBy(x: 0, y: CGFloat(spostamento))
                    strato.draw(immagine, in: CGRect(origin: .zero, size: dimensione))
                }
            }
        }
    }
}
