import SwiftUI

/// Colori e stile di docs/GRAFICA.md.
/// I colori sono "nominati" nell'asset catalog (Assets.xcassets) con la variante chiara e quella scura.
/// Navy e Turchese/Corallo restano uguali nei due temi: il testo sul corallo e sul turchese è sempre navy.
enum Tema {
    static let sfondo = Color("SfondoApp")
    static let carta = Color("Carta")
    static let testo = Color("TestoPrimario")
    static let testoSecondario = Color("TestoSecondario")
    static let navy = Color("Navy")
    static let navyChiaro = Color("NavyChiaro")
    static let turchese = Color("Turchese")
    static let turcheseChiaro = Color("TurcheseChiaro")
    static let corallo = Color("Corallo")
    static let coralloOmbra = Color("CoralloOmbra")
    /// Bordo sottile delle carte: invisibile nel tema chiaro, visibile nello scuro (dove la carta non ha ombra).
    static let bordo = Color("Bordo")
    /// Ombra delle carte: leggera nel tema chiaro, assente nello scuro.
    static let ombra = Color("OmbraCarta")
    /// Barra in basso (TabView).
    static let barra = Color("BarraInferiore")
    /// Testo sulle superfici navy (intestazioni e lavagnetta): chiaro in tutti e due i temi.
    static let testoSuNavy = Color("TestoSuNavy")

    static let raggio: CGFloat = 20

    // Font arrotondato (docs/GRAFICA.md). Usano gli stili di sistema, quindi seguono il testo dinamico.
    static let titolo = Font.system(.largeTitle, design: .rounded).weight(.heavy)
    static let titolo2 = Font.system(.title2, design: .rounded).weight(.heavy)
    static let sottotitolo = Font.system(.headline, design: .rounded).weight(.bold)
    static let corpo = Font.system(.body, design: .rounded)
    static let piccolo = Font.system(.footnote, design: .rounded)
    static let bottone = Font.system(.title3, design: .rounded).weight(.heavy)
    static let numeroGrande = Font.system(size: 44, weight: .heavy, design: .rounded)
}

// MARK: - Bottoni

/// Bottone principale: grande, tondo, corallo, con ombra piena sotto. Uno solo per schermata.
struct BottonePrimario: ButtonStyle {
    @Environment(\.isEnabled) private var abilitato

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Tema.bottone)
            .foregroundStyle(Tema.navy)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Capsule().fill(Tema.corallo))
            .background(Capsule().fill(Tema.coralloOmbra).offset(y: 5))
            .offset(y: configuration.isPressed ? 4 : 0)
            .opacity(abilitato ? 1 : 0.45)
            .padding(.bottom, 5)
    }
}

/// Bottone secondario: tondo, con bordo, senza ombra.
struct BottoneSecondario: ButtonStyle {
    @Environment(\.isEnabled) private var abilitato

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Tema.sottotitolo)
            .foregroundStyle(Tema.testo)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(Capsule().fill(Tema.carta))
            .overlay(Capsule().stroke(Tema.turchese, lineWidth: 2))
            .opacity(abilitato ? (configuration.isPressed ? 0.7 : 1) : 0.45)
    }
}

extension ButtonStyle where Self == BottonePrimario {
    static var primario: BottonePrimario { BottonePrimario() }
}

extension ButtonStyle where Self == BottoneSecondario {
    static var secondario: BottoneSecondario { BottoneSecondario() }
}

// MARK: - Carta bianca

extension View {
    /// Carta arrotondata: ombra leggera nel tema chiaro, bordo sottile nel tema scuro (colori "OmbraCarta" e "Bordo").
    func carta(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                    .fill(Tema.carta)
                    .shadow(color: Tema.ombra, radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                    .stroke(Tema.bordo, lineWidth: 1)
            )
    }

    /// Sfondo di schermata.
    func sfondoApp() -> some View {
        self.background(Tema.sfondo.ignoresSafeArea())
    }
}

// MARK: - Onda e intestazione

/// Rettangolo con il bordo inferiore a onda.
struct Onda: Shape {
    var ampiezza: CGFloat = 8
    var lunghezzaOnda: CGFloat = 140

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        let base = rect.maxY - ampiezza
        var x = rect.maxX
        while x >= rect.minX {
            let fase = Double(x) / Double(lunghezzaOnda) * 2.0 * Double.pi
            p.addLine(to: CGPoint(x: x, y: base + ampiezza * CGFloat(sin(fase))))
            x -= 4
        }
        p.addLine(to: CGPoint(x: rect.minX, y: base))
        p.closeSubpath()
        return p
    }
}

/// Intestazione navy con l'onda in basso. Il testo dentro è chiaro.
struct IntestazioneOnda<Contenuto: View>: View {
    private let contenuto: Contenuto

    init(@ViewBuilder contenuto: () -> Contenuto) {
        self.contenuto = contenuto()
    }

    var body: some View {
        contenuto
            .foregroundStyle(Tema.testoSuNavy)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Onda()
                    .fill(LinearGradient(colors: [Tema.navy, Tema.navyChiaro],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .ignoresSafeArea(edges: .top)
            )
    }
}

// MARK: - Barra di avanzamento

struct BarraAvanzamento: View {
    let frazione: Double
    var colore: Color = Tema.turchese

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Tema.turchese.opacity(0.2))
                Capsule()
                    .fill(colore)
                    .frame(width: max(0, min(1, frazione)) * geo.size.width)
            }
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }
}

// MARK: - Menu a tendina

/// Menu a tendina per le risposte a più opzioni (docs/ONBOARDING.md): un valore alla volta, quello scelto evidenziato.
struct MenuScelta<Valore: Hashable>: View {
    let titolo: String
    let opzioni: [Valore]
    let etichetta: (Valore) -> String
    @Binding var selezione: Valore?

    var body: some View {
        Picker(titolo, selection: $selezione) {
            // "Scegli" compare solo finché non c'è un valore: i campi obbligatori non tornano vuoti.
            if selezione == nil {
                Text(verbatim: testo("picker.scegli")).tag(Optional<Valore>.none)
            }
            ForEach(opzioni, id: \.self) { opzione in
                Text(verbatim: etichetta(opzione)).tag(Optional(opzione))
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .tint(Tema.testo)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Tema.turchese, lineWidth: 2)
        )
        .accessibilityLabel(Text(verbatim: titolo))
    }
}

#Preview("Bottoni e carta") {
    VStack(spacing: 20) {
        IntestazioneOnda {
            Text(verbatim: "Buongiorno, Luca").font(Tema.titolo2)
        }
        Button(action: {}) { Text(verbatim: "Mandalo al Watch") }
            .buttonStyle(.primario)
            .padding(.horizontal)
        Button(action: {}) { Text(verbatim: "Più tardi") }
            .buttonStyle(.secondario)
            .padding(.horizontal)
        Text(verbatim: "Una carta").carta().padding(.horizontal)
        Spacer()
    }
    .sfondoApp()
}
