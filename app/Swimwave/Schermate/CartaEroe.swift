import SwiftUI

/// La zona d'acqua in alto nella carta eroe di Oggi (bozza: docs/mockup/oggi-eroe.html).
/// Lo squalo nuota sul posto con un leggero dondolio, dentro margini larghi, e lascia salire le bolle dalla bocca.
/// Con "Riduci movimento" attivo, o con l'app non in primo piano, l'animazione si ferma (e con lei il consumo di batteria).
struct AcquaEroe: View {
    var etichetta: String?
    var cambia: () -> Void

    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @Environment(\.scenePhase) private var fase

    static let altezza: CGFloat = 128

    var body: some View {
        let ferma = riduciMovimento || fase != .active
        TimelineView(.animation(minimumInterval: 1.0 / 15.0, paused: ferma)) { linea in
            let t = ferma ? 0 : linea.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color(squaloHex: 0x46CFE0), Color(squaloHex: 0x1FB5C9), Color(squaloHex: 0x1A86AD), Color(squaloHex: 0x145F94)],
                    startPoint: .top, endPoint: .bottom
                )
                RaggiNellAcqua(t: t)
                OndaSuperficie(fase: t * 1.1)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 14)
                SqualoEBolle(t: t, ferma: ferma)
                HStack(alignment: .top) {
                    if let etichetta {
                        Text(verbatim: etichetta)
                            .font(Tema.piccolo.weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.22)))
                    }
                    Spacer(minLength: 8)
                    Button(action: cambia) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.22)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("libreria.cambia"))
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
            }
        }
        .frame(height: AcquaEroe.altezza)
        .clipped()
    }
}

/// Lo squalo (un fotogramma dopo l'altro dal foglio "squalo-nuota-sheet") con l'ombra e le bolle.
private struct SqualoEBolle: View {
    let t: Double
    let ferma: Bool

    private static let colonne = 9
    private static let righe = 5
    private static let totale = 44
    private static let proporzione: CGFloat = 123.0 / 240.0   // altezza / larghezza di un fotogramma

    var body: some View {
        GeometryReader { geo in
            let larghezza = min(geo.size.width * 0.58, 200)
            let altezza = larghezza * Self.proporzione
            // Deriva lenta, sempre dentro l'acqua: lascia almeno ~16 pt di margine su tutti i lati.
            let dx = sin(t * 0.55) * min(12, max(0, (geo.size.width - larghezza) / 2 - 16))
            let dy = sin(t * 1.4) * 3
            let sinistra = (geo.size.width - larghezza) / 2 + dx
            let alto = (geo.size.height - altezza) / 2 + 8 + dy
            ZStack(alignment: .topLeading) {
                Ellipse()
                    .fill(RadialGradient(colors: [Color.black.opacity(0.28), .clear], center: .center, startRadius: 0, endRadius: larghezza * 0.45))
                    .frame(width: larghezza * 0.8, height: 12)
                    .position(x: sinistra + larghezza / 2, y: geo.size.height - 12)
                BolleDellaBocca(t: t, bocca: CGPoint(x: sinistra + larghezza * 0.9, y: alto + altezza * 0.55), alto: 12)
                    .allowsHitTesting(false)
                Canvas { contesto, dimensione in
                    let immagine = contesto.resolve(Image("squalo-nuota-sheet"))
                    let i = ferma ? 0 : Int(t * 12) % Self.totale
                    let col = i % Self.colonne, riga = i / Self.colonne
                    let tutta = CGRect(x: -CGFloat(col) * dimensione.width, y: -CGFloat(riga) * dimensione.height,
                                       width: dimensione.width * CGFloat(Self.colonne), height: dimensione.height * CGFloat(Self.righe))
                    contesto.clip(to: Path(CGRect(origin: .zero, size: dimensione)))
                    contesto.draw(immagine, in: tutta)
                }
                .frame(width: larghezza, height: altezza)
                .offset(x: sinistra, y: alto)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Bolle sottili che nascono dalla bocca, salgono ondeggiando e svaniscono verso la superficie.
private struct BolleDellaBocca: View {
    let t: Double
    let bocca: CGPoint
    let alto: CGFloat

    var body: some View {
        Canvas { contesto, _ in
            guard t > 0 else { return }
            for k in 0..<6 {
                let ciclo = 2.0 + 0.45 * Double(k)
                let p = (t / ciclo + Double(k) * 0.23).truncatingRemainder(dividingBy: 1)
                let salita = max(0, bocca.y - alto)
                let x = bocca.x + CGFloat(sin(p * 6 + Double(k))) * 5 - CGFloat(p) * 12
                let y = bocca.y - CGFloat(p) * salita
                let d = 3 + CGFloat(k % 3) * 1.6 + CGFloat(p) * 2
                let o = sin(p * .pi) * 0.85
                let cerchio = Path(ellipseIn: CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d))
                contesto.fill(cerchio, with: .color(Color.white.opacity(o * 0.14)))
                contesto.stroke(cerchio, with: .color(Color.white.opacity(o)), lineWidth: 1.3)
            }
        }
    }
}

/// Fasci di luce che dall'alto scendono nell'acqua e si spostano piano.
private struct RaggiNellAcqua: View {
    let t: Double

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    let base = geo.size.width * (0.18 + 0.28 * CGFloat(i))
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, Color.white.opacity(0.14), .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 44, height: geo.size.height * 1.6)
                        .rotationEffect(.degrees(16))
                        .position(x: base + CGFloat(sin(t * 0.3 + Double(i))) * 14, y: geo.size.height * 0.4)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// La linea d'onda sulla superficie dell'acqua.
struct OndaSuperficie: Shape {
    var fase: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        var x = rect.minX
        while x <= rect.maxX {
            p.addLine(to: CGPoint(x: x, y: rect.minY + 6 + CGFloat(sin(Double(x) / 12 + fase)) * 3.5))
            x += 2
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

extension Color {
    /// Colore da 0xRRGGBB (solo per la carta eroe: sfumature dell'acqua).
    init(squaloHex valore: UInt32) {
        self.init(red: Double((valore >> 16) & 0xFF) / 255, green: Double((valore >> 8) & 0xFF) / 255, blue: Double(valore & 0xFF) / 255)
    }
}

/// Etichetta chiara sulla parte blu della carta (minuti, metri, vasca).
struct EtichettaChiara: View {
    let contenuto: String

    var body: some View {
        Text(verbatim: contenuto)
            .font(Tema.piccolo.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.18)))
    }
}
