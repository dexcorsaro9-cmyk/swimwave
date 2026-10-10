import SwiftUI
import SwimwaveCore
import CoreMotion

// Le medaglie "spettacolari": dischi metallici con bordo che riflette la luce, faccia navy con onde, simbolo in rilievo
// e un riflesso che si muove con l'inclinazione. Tutta la grafica è disegnata da noi in SwiftUI (gradienti e simboli di sistema).

// MARK: - Colori del metallo

/// Quattro tinte di un metallo: luce, tono medio, ombra e il colore dell'alone.
struct TavolozzaMetallo {
    let luce: Color
    let medio: Color
    let ombra: Color
}

extension Medaglia {
    /// Il metallo cambia con la categoria: acqua, rame rosato, oro, indaco, argento.
    var metallo: TavolozzaMetallo {
        switch categoria {
        case .nuotate:
            return TavolozzaMetallo(luce: Color(red: 0.64, green: 0.96, blue: 0.98),
                                    medio: Color(red: 0.12, green: 0.72, blue: 0.80),
                                    ombra: Color(red: 0.03, green: 0.30, blue: 0.40))
        case .distanza:
            return TavolozzaMetallo(luce: Color(red: 1.00, green: 0.84, blue: 0.74),
                                    medio: Color(red: 0.96, green: 0.45, blue: 0.38),
                                    ombra: Color(red: 0.50, green: 0.15, blue: 0.15))
        case .traversate:
            return TavolozzaMetallo(luce: Color(red: 1.00, green: 0.94, blue: 0.64),
                                    medio: Color(red: 0.93, green: 0.70, blue: 0.15),
                                    ombra: Color(red: 0.45, green: 0.30, blue: 0.03))
        case .costanza:
            return TavolozzaMetallo(luce: Color(red: 0.82, green: 0.80, blue: 1.00),
                                    medio: Color(red: 0.46, green: 0.40, blue: 0.92),
                                    ombra: Color(red: 0.15, green: 0.12, blue: 0.45))
        case .percorso:
            return TavolozzaMetallo(luce: Color(red: 0.96, green: 0.98, blue: 1.00),
                                    medio: Color(red: 0.66, green: 0.72, blue: 0.80),
                                    ombra: Color(red: 0.25, green: 0.30, blue: 0.38))
        }
    }
}

// MARK: - La medaglia

/// Medaglia tonda e metallica. `inclinazione` va da -1 a 1 (x verso destra, y verso il basso) e sposta luci e riflessi:
/// a zero la luce arriva da in alto a sinistra. Una medaglia non ottenuta è un disco spento con il lucchetto.
struct MedagliaMetallica: View {
    let medaglia: Medaglia
    var dimensione: CGFloat = 96
    var inclinazione: CGSize = .zero

    var body: some View {
        ZStack {
            if medaglia.ottenuta {
                ottenuta
            } else {
                bloccata
            }
        }
        .frame(width: dimensione, height: dimensione)
        .accessibilityHidden(true)
    }

    // MARK: Ottenuta

    private var ottenuta: some View {
        let m = medaglia.metallo
        let d = dimensione
        let tx = Double(inclinazione.width)
        let ty = Double(inclinazione.height)
        return ZStack {
            // Bordo: un cono di luce che gira con l'inclinazione.
            Circle()
                .fill(AngularGradient(
                    gradient: Gradient(colors: [m.luce, m.medio, m.ombra, m.medio, m.luce, m.medio, m.ombra, m.medio, m.luce]),
                    center: .center,
                    angle: .degrees(tx * 70 + ty * 40 - 20)
                ))
            // Gola incavata tra bordo e faccia.
            Circle()
                .fill(LinearGradient(colors: [m.ombra, m.luce.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(d * 0.075)
            // Faccia navy con la luce che si sposta.
            Circle()
                .fill(RadialGradient(
                    colors: [Tema.navyChiaro, Tema.navy, Color.black.opacity(0.92)],
                    center: UnitPoint(x: 0.5 - tx * 0.18, y: 0.38 - ty * 0.18),
                    startRadius: 0,
                    endRadius: d * 0.58
                ))
                .padding(d * 0.115)
            // Onde decorative, appena visibili.
            Image(systemName: "water.waves")
                .font(.system(size: d * 0.52, weight: .bold))
                .foregroundStyle(m.medio.opacity(0.13))
                .offset(x: CGFloat(-tx * 4), y: d * 0.04)
            // Filo sottile attorno al simbolo.
            Circle()
                .strokeBorder(LinearGradient(colors: [m.luce, m.ombra], startPoint: .top, endPoint: .bottom),
                              lineWidth: max(1, d * 0.012))
                .padding(d * 0.17)
            // Simbolo in rilievo.
            Image(systemName: medaglia.simbolo)
                .font(.system(size: d * 0.34, weight: .heavy, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [m.luce, m.medio], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.black.opacity(0.55), radius: d * 0.02, x: CGFloat(tx) * -d * 0.01, y: d * 0.018)
                .offset(x: CGFloat(tx) * d * 0.012, y: CGFloat(ty) * d * 0.012)
            // Soglia sul bordo basso.
            if !medaglia.scrittaSoglia.isEmpty {
                Text(verbatim: medaglia.scrittaSoglia)
                    .font(.system(size: d * 0.15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Tema.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, d * 0.07)
                    .padding(.vertical, d * 0.018)
                    .background(Capsule().fill(LinearGradient(colors: [m.luce, m.medio], startPoint: .top, endPoint: .bottom)))
                    .overlay(Capsule().stroke(Tema.navy, lineWidth: max(1, d * 0.018)))
                    .offset(y: d * 0.385)
            }
            riflesso(m)
        }
        .shadow(color: m.medio.opacity(0.5), radius: d * 0.12, x: CGFloat(tx) * -d * 0.04, y: d * 0.05 + CGFloat(ty) * d * 0.03)
    }

    /// Fascia di luce diagonale che scorre sul disco quando lo si inclina.
    private func riflesso(_ m: TavolozzaMetallo) -> some View {
        let centro = min(0.8, max(0.2, 0.5 + Double(inclinazione.width) * 0.3 + Double(inclinazione.height) * 0.12))
        return Circle()
            .fill(LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0), location: max(0, centro - 0.2)),
                    .init(color: Color.white.opacity(0.55), location: centro),
                    .init(color: Color.white.opacity(0), location: min(1, centro + 0.2)),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .blendMode(.plusLighter)
            .opacity(0.55)
    }

    // MARK: Non ottenuta

    private var bloccata: some View {
        let d = dimensione
        return ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.03)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .strokeBorder(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: max(2, d * 0.04), dash: [d * 0.05, d * 0.04]))
            Image(systemName: medaglia.simbolo)
                .font(.system(size: d * 0.32, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.10))
            Image(systemName: "lock.fill")
                .font(.system(size: d * 0.2, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.45))
                .offset(y: d * 0.30)
        }
    }
}

// MARK: - Inclinazione del telefono

/// Legge l'inclinazione del telefono (giroscopio e accelerometro) e la dà tra -1 e 1, ammorbidita.
/// Si avvia quando la schermata compare e si ferma quando sparisce.
@Observable
final class MotoreInclinazione {
    private(set) var x: Double = 0
    private(set) var y: Double = 0
    @ObservationIgnored private let manager = CMMotionManager()

    func avvia() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] movimento, _ in
            guard let self, let movimento else { return }
            // Il telefono tenuto in mano è inclinato di circa 50 gradi: quella è la posizione "ferma".
            let nuovoX = max(-1, min(1, movimento.attitude.roll / 0.6))
            let nuovoY = max(-1, min(1, (movimento.attitude.pitch - 0.9) / 0.6))
            self.x = self.x * 0.8 + nuovoX * 0.2
            self.y = self.y * 0.8 + nuovoY * 0.2
        }
    }

    func ferma() {
        manager.stopDeviceMotionUpdates()
        x = 0
        y = 0
    }

    deinit {
        manager.stopDeviceMotionUpdates()
    }
}

// MARK: - Fondali

/// Fasci di luce che girano piano dietro la medaglia.
struct RaggiDiLuce: View {
    var colore: Color
    var fermi = false

    var body: some View {
        TimelineView(.animation(paused: fermi)) { contesto in
            let t = contesto.date.timeIntervalSinceReferenceDate
            Canvas { gc, dimensione in
                let centro = CGPoint(x: dimensione.width / 2, y: dimensione.height / 2)
                let raggio = max(dimensione.width, dimensione.height)
                let fasci = 14
                let rotazione = fermi ? 0 : t * 0.12
                for i in 0..<fasci {
                    let a0 = rotazione + Double(i) * 2 * .pi / Double(fasci)
                    let a1 = a0 + .pi / Double(fasci) * 0.9
                    var p = Path()
                    p.move(to: centro)
                    p.addLine(to: CGPoint(x: centro.x + CGFloat(cos(a0)) * raggio, y: centro.y + CGFloat(sin(a0)) * raggio))
                    p.addLine(to: CGPoint(x: centro.x + CGFloat(cos(a1)) * raggio, y: centro.y + CGFloat(sin(a1)) * raggio))
                    p.closeSubpath()
                    gc.fill(p, with: .color(colore.opacity(0.10)))
                }
            }
            .mask(
                RadialGradient(colors: [Color.white, Color.white.opacity(0)], center: .center, startRadius: 20, endRadius: 360)
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Coriandoli che cadono per qualche secondo. Posizioni e colori sono calcolati dal numero della particella,
/// così non serve nessuno stato: la vista si ridisegna solo con il tempo.
struct Coriandoli: View {
    var colori: [Color]
    var durata: Double = 5.5
    @State private var inizio = Date()

    var body: some View {
        TimelineView(.animation) { contesto in
            let t = contesto.date.timeIntervalSince(inizio)
            Canvas { gc, dimensione in
                guard t < durata + 2 else { return }
                let quanti = 90
                for i in 0..<quanti {
                    let seme = Double(i) * 12.9898
                    let r1 = frazione(seme)
                    let r2 = frazione(seme * 1.7 + 3)
                    let r3 = frazione(seme * 2.3 + 7)
                    let ritardo = r1 * 0.9
                    let tempo = t - ritardo
                    guard tempo > 0 else { continue }
                    let velocita = 160 + r2 * 220
                    let fase: Double = tempo * (1.5 + r1 * 2) + seme
                    let ondeggia: CGFloat = CGFloat(sin(fase)) * 26
                    let x: CGFloat = dimensione.width * CGFloat(r3) + ondeggia
                    let y: CGFloat = -20 + CGFloat(tempo * velocita)
                    guard y < dimensione.height + 30 else { continue }
                    let dissolvenza = t > durata ? max(0, 1 - (t - durata) / 2) : 1
                    var pezzo = gc
                    pezzo.translateBy(x: x, y: y)
                    pezzo.rotate(by: .radians(tempo * (2 + r2 * 5) + seme))
                    let largo = 6 + r1 * 6
                    let rect = CGRect(x: -largo / 2, y: -largo / 3, width: largo, height: largo * 0.6)
                    pezzo.fill(Path(roundedRect: rect, cornerRadius: 1.5),
                               with: .color(colori[i % max(1, colori.count)].opacity(dissolvenza)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func frazione(_ valore: Double) -> Double {
        let s = sin(valore) * 43758.5453
        return s - floor(s)
    }
}
