import SwiftUI

/// Lo squalo di Swimwave, disegnato con la grafica di SwiftUI (nessuna immagine). Guarda verso destra.
/// Coordinate nello spazio 180 x 100, ridimensionate alla dimensione della vista (bozza: docs/mockup/squalo-watch.html).
struct SqualoDisegno: View {
    /// Oscillazione della coda in gradi (0 = ferma).
    var angoloCoda: Double = 0
    var angoloPinna: Double = 0

    private static let dorso = Color(red: 31.0 / 255.0, green: 181.0 / 255.0, blue: 201.0 / 255.0)
    private static let pinne = Color(red: 21.0 / 255.0, green: 144.0 / 255.0, blue: 168.0 / 255.0)
    private static let pancia = Color(red: 232.0 / 255.0, green: 251.0 / 255.0, blue: 253.0 / 255.0)
    private static let inchiostro = Color(red: 11.0 / 255.0, green: 37.0 / 255.0, blue: 69.0 / 255.0)

    var body: some View {
        Canvas { contesto, dimensione in
            contesto.scaleBy(x: dimensione.width / 180, y: dimensione.height / 100)

            var coda = Path()
            coda.move(to: CGPoint(x: 40, y: 52))
            coda.addLine(to: CGPoint(x: 4, y: 20))
            coda.addCurve(to: CGPoint(x: 4, y: 84), control1: CGPoint(x: 14, y: 42), control2: CGPoint(x: 14, y: 62))
            coda.closeSubpath()
            contesto.drawLayer { strato in
                strato.translateBy(x: 36, y: 52)
                strato.rotate(by: .degrees(angoloCoda))
                strato.translateBy(x: -36, y: -52)
                strato.fill(coda, with: .color(Self.pinne))
            }

            var corpo = Path()
            corpo.move(to: CGPoint(x: 30, y: 52))
            corpo.addCurve(to: CGPoint(x: 170, y: 50), control1: CGPoint(x: 55, y: 22), control2: CGPoint(x: 120, y: 20))
            corpo.addCurve(to: CGPoint(x: 30, y: 52), control1: CGPoint(x: 120, y: 80), control2: CGPoint(x: 55, y: 78))
            contesto.fill(corpo, with: .color(Self.dorso))

            var pancia = Path()
            pancia.move(to: CGPoint(x: 42, y: 58))
            pancia.addCurve(to: CGPoint(x: 166, y: 53), control1: CGPoint(x: 80, y: 76), control2: CGPoint(x: 132, y: 74))
            pancia.addCurve(to: CGPoint(x: 42, y: 58), control1: CGPoint(x: 132, y: 80), control2: CGPoint(x: 62, y: 80))
            contesto.fill(pancia, with: .color(Self.pancia))

            var dorsale = Path()
            dorsale.move(to: CGPoint(x: 90, y: 32))
            dorsale.addLine(to: CGPoint(x: 104, y: 6))
            dorsale.addCurve(to: CGPoint(x: 126, y: 35), control1: CGPoint(x: 112, y: 20), control2: CGPoint(x: 118, y: 28))
            dorsale.closeSubpath()
            contesto.fill(dorsale, with: .color(Self.pinne))

            var pettorale = Path()
            pettorale.move(to: CGPoint(x: 100, y: 66))
            pettorale.addLine(to: CGPoint(x: 86, y: 92))
            pettorale.addCurve(to: CGPoint(x: 124, y: 68), control1: CGPoint(x: 104, y: 86), control2: CGPoint(x: 116, y: 78))
            pettorale.closeSubpath()
            contesto.drawLayer { strato in
                strato.translateBy(x: 100, y: 66)
                strato.rotate(by: .degrees(angoloPinna))
                strato.translateBy(x: -100, y: -66)
                strato.fill(pettorale, with: .color(Self.pinne))
            }

            contesto.fill(Path(ellipseIn: CGRect(x: 141, y: 41, width: 10, height: 10)), with: .color(.white))
            contesto.fill(Path(ellipseIn: CGRect(x: 145, y: 43.5, width: 5.2, height: 5.2)), with: .color(Self.inchiostro))
            contesto.fill(Path(ellipseIn: CGRect(x: 132.6, y: 54.6, width: 6.8, height: 6.8)), with: .color(WatchTema.corallo.opacity(0.75)))

            var sorriso = Path()
            sorriso.move(to: CGPoint(x: 150, y: 58))
            sorriso.addQuadCurve(to: CGPoint(x: 166, y: 55), control: CGPoint(x: 159, y: 63))
            contesto.stroke(sorriso, with: .color(Self.inchiostro), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }
        .accessibilityHidden(true)
    }
}

/// Lo squalo che nuota lungo una corsia: la posizione è l'avanzamento della ripetizione (0...1).
/// - `nuota`: la coda batte veloce. Nel recupero lo squalo galleggia piano; in pausa sta fermo.
/// - Con il Watch in risparmio energetico (schermo attenuato) l'animazione si ferma: in acqua conta la batteria.
/// Una sola informazione dominante per schermata (docs/GRAFICA.md): lo squalo è piccolo e non copre mai i numeri.
struct CorsiaSqualo: View {
    var progresso: Double
    var nuota: Bool
    var inPausa: Bool

    @Environment(\.isLuminanceReduced) private var schermoAttenuato

    private let larghezza: CGFloat = 38
    private let altezza: CGFloat = 19

    var body: some View {
        let animato = !inPausa && !schermoAttenuato
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 0.1, paused: !animato)) { linea in
                let t = linea.date.timeIntervalSinceReferenceDate
                let coda = animato ? sin(t * (nuota ? 9 : 2.5)) * (nuota ? 14 : 5) : 0
                let pinna = animato ? sin(t * 1.8) * 7 : 0
                let onda = animato && !nuota ? sin(t * 1.4) * 2 : 0
                SqualoDisegno(angoloCoda: coda, angoloPinna: pinna)
                    .frame(width: larghezza, height: altezza)
                    .offset(x: max(0, geo.size.width - larghezza) * min(1, max(0, progresso)), y: onda)
                    .opacity(inPausa ? 0.5 : 1)
            }
            .animation(.easeInOut(duration: 0.5), value: progresso)
        }
        .frame(height: altezza + 3)
        .accessibilityHidden(true)
    }
}
