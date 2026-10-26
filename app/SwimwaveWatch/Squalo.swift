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
    /// Quale squalo disegnare: quello che nuota, o quello concentrato nella serie principale.
    var foglio: FoglioSprite = .nuota

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
                    SqualoSprite(foglio: foglio, fotogramma: animato ? Int(t * (nuota ? 12 : 8)) : 0)
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

/// Fine allenamento: lo squalo fa un balzo di gioia (video di Flow a fotogrammi) con un'onda in primo piano.
struct SqualoFesta: View {
    @Environment(\.isLuminanceReduced) private var schermoAttenuato

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08, paused: schermoAttenuato)) { linea in
            let t = linea.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .bottom) {
                SqualoSprite(foglio: .festa, fotogramma: schermoAttenuato ? 0 : Int(t * 12))
                    .frame(width: 66, height: 40)
                    .offset(y: -6)
                OndaAcqua(fase: schermoAttenuato ? 0 : t * 2)
                    .fill(WatchTema.turchese.opacity(0.55))
                    .frame(height: 14)
            }
            .frame(height: 50)
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

/// Una striscia di fotogrammi dentro un'unica immagine (colonne x righe, tutti della stessa misura).
struct FoglioSprite {
    let nome: String
    let colonne: Int
    let righe: Int
    let totale: Int

    /// Lo squalo che nuota in loop (4 s a 12 fotogrammi al secondo). Ricavato dal video generato con Flow.
    static let nuota = FoglioSprite(nome: "squalo-nuota-sheet", colonne: 9, righe: 5, totale: 44)
    /// Lo squalo che festeggia con un balzo (3,5 s a 12 fotogrammi al secondo).
    static let festa = FoglioSprite(nome: "squalo-festa-sheet", colonne: 9, righe: 5, totale: 42)
    /// Lo squalo concentrato, per la serie principale (2,7 s a 12 fotogrammi al secondo).
    static let concentrato = FoglioSprite(nome: "squalo-concentrato-sheet", colonne: 9, righe: 4, totale: 32)
    /// Lo squalo stanco che sbadiglia e dondola, per il recupero (3,7 s a 12 fotogrammi al secondo).
    static let stanco = FoglioSprite(nome: "squalo-stanco-sheet", colonne: 9, righe: 5, totale: 44)
}

/// Un fotogramma di un foglio sprite. Le immagini sono senza sfondo (verde tolto, ciclo rifinito): sorgenti in assets/squalo/.
struct SqualoSprite: View {
    var foglio: FoglioSprite
    var fotogramma: Int

    var body: some View {
        Canvas { contesto, dimensione in
            let immagine = contesto.resolve(Image(foglio.nome))
            let indice = ((fotogramma % foglio.totale) + foglio.totale) % foglio.totale
            let colonna = indice % foglio.colonne
            let riga = indice / foglio.colonne
            let tutta = CGRect(x: -CGFloat(colonna) * dimensione.width, y: -CGFloat(riga) * dimensione.height,
                               width: dimensione.width * CGFloat(foglio.colonne), height: dimensione.height * CGFloat(foglio.righe))
            contesto.clip(to: Path(CGRect(origin: .zero, size: dimensione)))
            contesto.draw(immagine, in: tutta)
        }
        .accessibilityHidden(true)
    }
}

