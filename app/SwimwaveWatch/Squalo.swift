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

    /// Quanto salgono le bolle sopra lo squalo, in punti.
    var salita: CGFloat = 12

    var body: some View {
        let animato = !inPausa && !schermoAttenuato
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 0.066, paused: !animato)) { linea in
                let t = linea.date.timeIntervalSinceReferenceDate
                let onda = animato ? sin(t * (nuota ? 3.5 : 1.4)) * (nuota ? 1 : 2) : 0
                let x = max(0, geo.size.width - larghezza) * min(1, max(0, progresso))
                ZStack(alignment: .topLeading) {
                    if animato {
                        // Bolle che salgono dalla coda e scia dietro lo squalo (solo mentre nuota).
                        BolleSqualo(sinistra: x, larghezzaSqualo: larghezza, altezzaSqualo: altezza, tempo: t, nuota: nuota, salita: salita)
                            .frame(width: geo.size.width, height: salita + altezza)
                            .offset(y: 3 + altezza - (salita + altezza))
                            .allowsHitTesting(false)
                    }
                    SqualoSprite(fotogramma: animato ? Int(t * (nuota ? 12 : 8)) % SqualoSprite.totale : 0)
                        .frame(width: larghezza, height: altezza)
                        .offset(x: x, y: 3 + onda)
                        .opacity(inPausa ? 0.5 : 1)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: progresso)
        }
        .frame(height: altezza + 6)
        .accessibilityHidden(true)
    }
}

/// Poche bolle sottili che escono dalla bocca e salgono davanti e sopra il muso (mai sul corpo), e tre trattini di scia dietro
/// la coda mentre nuota. Disegnate con un solo Canvas: costano poco.
struct BolleSqualo: View {
    var sinistra: CGFloat
    var larghezzaSqualo: CGFloat
    var altezzaSqualo: CGFloat
    var tempo: Double
    var nuota: Bool
    var salita: CGFloat

    private static let colore = Color(red: 127.0 / 255.0, green: 227.0 / 255.0, blue: 238.0 / 255.0)

    var body: some View {
        Canvas { contesto, dimensione in
            let centro = dimensione.height - altezzaSqualo / 2
            // Bolle dalla bocca (a destra, un po' sotto il centro): salgono e si spostano appena indietro.
            let bocca = CGPoint(x: sinistra + larghezzaSqualo * 0.96, y: centro + altezzaSqualo * 0.14)
            for k in 0..<3 {
                let ciclo = 1.5 + 0.4 * Double(k)
                let p = (tempo / ciclo + Double(k) * 0.37).truncatingRemainder(dividingBy: 1)
                let bx = bocca.x + 2 + CGFloat(k) * 1.5 - CGFloat(p) * (nuota ? 9 : 2)
                let by = bocca.y - CGFloat(p) * salita
                let d = 1.8 + CGFloat(k) * 0.9
                let opacita = sin(p * .pi) * 0.85
                contesto.stroke(Path(ellipseIn: CGRect(x: bx - d / 2, y: by - d / 2, width: d, height: d)),
                                with: .color(Self.colore.opacity(opacita)), lineWidth: 0.9)
            }
            if nuota {
                for j in 0..<3 {
                    let q = (tempo * 1.6 + Double(j) * 0.33).truncatingRemainder(dividingBy: 1)
                    let x1 = sinistra - 2 - CGFloat(q) * 14
                    var scia = Path()
                    scia.move(to: CGPoint(x: x1, y: centro + CGFloat(j - 1) * 4))
                    scia.addLine(to: CGPoint(x: x1 + 5, y: centro + CGFloat(j - 1) * 4))
                    contesto.stroke(scia, with: .color(Self.colore.opacity((1 - q) * 0.6)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                }
            }
        }
    }
}

/// Fine allenamento: lo squalo salta fuori dall'acqua, con schizzi e un'onda in primo piano.
struct SqualoFesta: View {
    @Environment(\.isLuminanceReduced) private var schermoAttenuato

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.066, paused: schermoAttenuato)) { linea in
            let t = linea.date.timeIntervalSinceReferenceDate
            let q = (t / 2.6).truncatingRemainder(dividingBy: 1)
            let salto = q > 0.5 ? (q - 0.5) / 0.5 : -1     // 0...1 durante il salto
            let altezzaSalto = salto >= 0 ? CGFloat(sin(salto * .pi)) * 30 : 0
            ZStack(alignment: .bottom) {
                OndaSqualo(fase: schermoAttenuato ? 0 : t * 8, ampiezza: schermoAttenuato ? 0 : 0.06)
                    .frame(width: 60, height: 29)
                    .rotationEffect(.degrees(salto >= 0 ? -22 + salto * 44 : 6))
                    .offset(y: salto >= 0 ? 8 - altezzaSalto : 18)
                OndaAcqua(fase: t * 2)
                    .fill(WatchTema.turchese.opacity(0.55))
                    .frame(height: 16)
            }
            .frame(height: 46)
            .clipped()
        }
        .accessibilityHidden(true)
    }
}

/// Una riga d'onda per la fine dell'allenamento.
struct OndaAcqua: Shape {
    var fase: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 6))
        var x = rect.minX
        while x <= rect.maxX {
            p.addLine(to: CGPoint(x: x, y: rect.minY + 6 + CGFloat(sin(Double(x) / 11 + fase)) * 3.5))
            x += 2
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Lo squalo che nuota: una striscia di fotogrammi (Assets.xcassets/squalo-nuota-sheet, 9 colonne x 5 righe, 44 fotogrammi a 12 al secondo)
/// ricavata dal video generato con Flow, con lo sfondo verde tolto e la ripartenza del ciclo rifinita. Sorgenti in assets/squalo/.
struct SqualoSprite: View {
    static let colonne = 9
    static let righe = 5
    static let totale = 44
    var fotogramma: Int

    var body: some View {
        Canvas { contesto, dimensione in
            let immagine = contesto.resolve(Image("squalo-nuota-sheet"))
            let colonna = fotogramma % Self.colonne
            let riga = (fotogramma / Self.colonne) % Self.righe
            let tutta = CGRect(x: -CGFloat(colonna) * dimensione.width, y: -CGFloat(riga) * dimensione.height,
                               width: dimensione.width * CGFloat(Self.colonne), height: dimensione.height * CGFloat(Self.righe))
            contesto.clip(to: Path(CGRect(origin: .zero, size: dimensione)))
            contesto.draw(immagine, in: tutta)
        }
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
