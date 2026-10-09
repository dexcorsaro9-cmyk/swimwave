import SwiftUI
import SwimwaveCore

/// "Trova il tuo ritmo": due prove (200 m e 400 m) da cui si ricava il ritmo critico e le zone di ritmo.
/// Le zone e le istruzioni vengono da content/zone-ritmo.json; la vista compare solo se ci sono zone visibili.
struct TestRitmoView: View {
    @Environment(StatoApp.self) private var stato
    @Environment(\.dismiss) private var dismiss

    @State private var istruzioni: [String] = []
    @State private var minuti200: Int?
    @State private var secondi200 = 0
    @State private var minuti400: Int?
    @State private var secondi400 = 0
    @State private var rifacendo: Bool

    /// `rifacendo: true` apre subito il modulo per ripetere il test (dall'invito nel Percorso).
    init(rifacendo: Bool = false) {
        _rifacendo = State(initialValue: rifacendo)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let salvato = stato.testRitmo, !rifacendo {
                        testSalvato(salvato)
                    } else {
                        modulo
                    }
                }
                .padding(16)
            }
            .sfondoApp()
            .navigationTitle(Text("ritmo.titolo"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("comune.chiudi") { dismiss() }
                }
            }
        }
        .onAppear {
            if istruzioni.isEmpty {
                istruzioni = IstruzioniTest.parti()
            }
        }
    }

    // MARK: Il test da fare

    @ViewBuilder
    private var modulo: some View {
        if let avviso = istruzioni.first {
            // La prima parte delle istruzioni spiega a cosa serve il test e quando farlo (con l'avvertimento sulla salute).
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(Tema.turchese)
                    .accessibilityHidden(true)
                Text(verbatim: avviso)
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testo)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .carta()
            let passi = Array(istruzioni.dropFirst())
            if !passi.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(passi.enumerated()), id: \.offset) { _, passo in
                        Text(verbatim: passo)
                            .font(Tema.corpo)
                            .foregroundStyle(Tema.testo)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .carta()
            }
        } else {
            Text("ritmo.avviso.fallback")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .carta()
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("ritmo.tempi.titolo")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            Text("ritmo.tempi.nota")
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
            SelettoreTempo(titolo: testo("oggi.metri", 200), minutiPossibili: 1...10,
                           minuti: $minuti200, secondi: $secondi200)
            SelettoreTempo(titolo: testo("oggi.metri", 400), minutiPossibili: 2...20,
                           minuti: $minuti400, secondi: $secondi400)
        }
        .carta()

        risultato

        if stato.testRitmo != nil {
            Button {
                rifacendo = false
            } label: {
                Text("ritmo.indietro")
            }
            .buttonStyle(.secondario)
        }
    }

    @ViewBuilder
    private var risultato: some View {
        if let m200 = minuti200, let m400 = minuti400 {
            let test = TestRitmo(
                tempo200Secondi: m200 * 60 + secondi200,
                tempo400Secondi: m400 * 60 + secondi400
            )
            if let ritmo = test.ritmoCriticoPer100 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ritmo.critico.titolo")
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testoSecondario)
                    Text(verbatim: testo("ritmo.critico.valore", FormatoRitmo.minutiSecondi(ritmo)))
                        .font(Tema.titolo2)
                        .foregroundStyle(Tema.testo)
                }
                .carta()
                .accessibilityElement(children: .combine)

                ElencoZone(zone: stato.contenuti.zone, ritmoCritico: ritmo)

                Button {
                    stato.salva(testRitmo: test)
                    rifacendo = false
                } label: {
                    Text("ritmo.salva")
                }
                .buttonStyle(.primario)
            } else {
                // Tempi non plausibili: nessun rimprovero, si può riprovare quando si vuole.
                Text("ritmo.nonPlausibile")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testo)
                    .carta()
            }
        }
    }

    // MARK: Il test già salvato

    @ViewBuilder
    private func testSalvato(_ test: TestRitmo) -> some View {
        if let ritmo = test.ritmoCriticoPer100 {
            VStack(alignment: .leading, spacing: 6) {
                Text("ritmo.critico.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testoSecondario)
                Text(verbatim: testo("ritmo.critico.valore", FormatoRitmo.minutiSecondi(ritmo)))
                    .font(Tema.titolo2)
                    .foregroundStyle(Tema.testo)
                Text(verbatim: testo("ritmo.salvato.data", FormatiUI.giornoMese(test.data)))
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
            }
            .carta()
            .accessibilityElement(children: .combine)

            ElencoZone(zone: stato.contenuti.zone, ritmoCritico: ritmo)
        } else {
            Text("ritmo.nonPlausibile")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .carta()
        }
        Button {
            minuti200 = nil
            secondi200 = 0
            minuti400 = nil
            secondi400 = 0
            rifacendo = true
        } label: {
            Text("ritmo.rifai")
        }
        .buttonStyle(.secondario)
    }
}

// MARK: - Zone

/// Le zone con il ritmo ogni 100 m calcolato dal ritmo critico. Descrizioni e nomi vengono da content/ (italiano).
private struct ElencoZone: View {
    let zone: [ZonaRitmo]
    let ritmoCritico: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ritmo.zone.titolo")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            ForEach(zone) { zona in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(verbatim: zona.nome)
                            .font(Tema.sottotitolo)
                            .foregroundStyle(Tema.testo)
                        Spacer(minLength: 8)
                        if let intervallo = zona.intervalloRitmo(ritmoCriticoPer100: ritmoCritico) {
                            Text(verbatim: testo(
                                "ritmo.zona.intervallo",
                                FormatoRitmo.minutiSecondi(intervallo.piuVeloce),
                                FormatoRitmo.minutiSecondi(intervallo.piuLento)
                            ))
                            .font(Tema.sottotitolo)
                            .monospacedDigit()
                            .foregroundStyle(Tema.testo)
                        }
                    }
                    Text(verbatim: zona.descrizione)
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .carta()
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Selettore dei tempi

/// Minuti e secondi con due menu a tendina, senza tastiera.
private struct SelettoreTempo: View {
    let titolo: String
    let minutiPossibili: ClosedRange<Int>
    @Binding var minuti: Int?
    @Binding var secondi: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(verbatim: titolo)
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
                .frame(width: 70, alignment: .leading)

            Picker(titolo, selection: $minuti) {
                // Il segno "-" compare solo finché non si è scelto un valore.
                if minuti == nil {
                    Text(verbatim: "-").tag(Optional<Int>.none)
                }
                ForEach(Array(minutiPossibili), id: \.self) { m in
                    Text(verbatim: "\(m)").tag(Optional(m))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(Tema.testo)
            .modifier(ContornoMenu())
            .accessibilityLabel(Text(verbatim: testo("ritmo.a11y.minuti", titolo)))
            Text("ritmo.min")
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)

            Picker(titolo, selection: $secondi) {
                ForEach(0..<60, id: \.self) { s in
                    Text(verbatim: String(format: "%02ld", s)).tag(s)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(Tema.testo)
            .modifier(ContornoMenu())
            .accessibilityLabel(Text(verbatim: testo("ritmo.a11y.secondi", titolo)))
            Text("ritmo.sec")
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
            Spacer(minLength: 0)
        }
    }
}

private struct ContornoMenu: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Tema.turchese, lineWidth: 2)
            )
    }
}

// MARK: - Istruzioni da content/zone-ritmo.json

/// Legge `istruzioni_test` direttamente dal file nel bundle (cartella `content/`). Se il file manca non succede nulla:
/// la vista usa un avviso breve.
private enum IstruzioniTest {
    private struct FileIstruzioni: Decodable {
        let istruzioniTest: String?

        enum CodingKeys: String, CodingKey {
            case istruzioniTest = "istruzioni_test"
        }
    }

    static func testoCompleto() -> String? {
        let url = Bundle.main.url(forResource: "zone-ritmo", withExtension: "json", subdirectory: "content")
            ?? Bundle.main.resourceURL?.appendingPathComponent("content/zone-ritmo.json")
        guard let url,
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(FileIstruzioni.self, from: data) else { return nil }
        return file.istruzioniTest
    }

    /// Divide il testo in parti: l'introduzione e poi un passo per ogni numerazione "1) ... 2) ...".
    /// Se non ci sono numerazioni resta tutto in una parte sola.
    static func parti() -> [String] {
        guard let completo = testoCompleto(), !completo.isEmpty else { return [] }
        var parti: [String] = []
        var corrente = ""
        for parola in completo.split(separator: " ", omittingEmptySubsequences: true) {
            let inizioPasso = parola.count == 2 && parola.last == ")" && (parola.first?.isNumber ?? false)
            if inizioPasso, !corrente.isEmpty {
                parti.append(corrente)
                corrente = ""
            }
            corrente += corrente.isEmpty ? String(parola) : " " + String(parola)
        }
        if !corrente.isEmpty { parti.append(corrente) }
        return parti
    }
}
