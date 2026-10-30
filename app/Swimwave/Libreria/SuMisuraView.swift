import SwiftUI
import SwimwaveCore

/// Allenamento su misura: l'utente sceglie quanti metri vuole nuotare e l'app propone un allenamento approvato adattato a quella
/// distanza (SuMisura nel pacchetto). Va dentro il `NavigationStack` della libreria.
struct SuMisuraView: View {
    /// Chiude tutto il foglio (dopo "Usa oggi").
    let chiudi: () -> Void
    /// Apre la schermata guidata con l'allenamento scelto.
    let inizia: (Workout) -> Void

    @Environment(StatoApp.self) private var stato
    @State private var metri = 1500
    /// nil = il tipo consigliato per oggi.
    @State private var tipologia: Tipologia?
    @State private var altra = 0
    @State private var proposta: Workout?
    @State private var pronto = false

    private var limiti: ClosedRange<Int> { SuMisura.limiti(per: stato.profilo.categoriaLivello) }
    private var tipologiaUsata: Tipologia { tipologia ?? stato.consiglioDiOggi().tipologia }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                selettoreMetri
                selettoreTipologia
                risultato
            }
            .padding(16)
        }
        .sfondoApp()
        .navigationTitle(Text("sumisura.titolo"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !pronto else { return }
            metri = min(max(metri, limiti.lowerBound), limiti.upperBound)
            pronto = true
            aggiorna()
        }
        .onChange(of: metri) { _, _ in altra = 0; aggiorna() }
        .onChange(of: tipologia) { _, _ in altra = 0; aggiorna() }
        .onChange(of: altra) { _, _ in aggiorna() }
    }

    // MARK: Metri

    private var selettoreMetri: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("sumisura.distanza.titolo")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            HStack(spacing: 16) {
                bottone("minus", etichetta: "sumisura.meno") { cambia(-SuMisura.passoMetri) }
                    .disabled(metri <= limiti.lowerBound)
                Text(verbatim: SuMisuraView.formatta(metri))
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Tema.turchese)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                bottone("plus", etichetta: "sumisura.piu") { cambia(SuMisura.passoMetri) }
                    .disabled(metri >= limiti.upperBound)
            }
            // Scelte rapide dentro i limiti del livello.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([500, 1000, 1500, 2000, 3000, 4000, 5000].filter { limiti.contains($0) }, id: \.self) { m in
                        Button { metri = m } label: {
                            Text(verbatim: SuMisuraView.formatta(m))
                                .font(Tema.piccolo.weight(.bold))
                                .foregroundStyle(metri == m ? Color.white : Tema.testo)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(metri == m ? Tema.turchese : Tema.turchese.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Text(verbatim: testo("sumisura.distanza.limiti", SuMisuraView.formatta(limiti.lowerBound), SuMisuraView.formatta(limiti.upperBound)))
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
        }
        .carta()
    }

    private func bottone(_ icona: String, etichetta: String, azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            Image(systemName: icona)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Tema.turchese)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Tema.turchese.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(etichetta)))
    }

    private func cambia(_ delta: Int) {
        metri = min(max(metri + delta, limiti.lowerBound), limiti.upperBound)
    }

    // MARK: Tipo

    private var selettoreTipologia: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("sumisura.tipologia.titolo")
                .font(Tema.piccolo.weight(.bold))
                .foregroundStyle(Tema.testoSecondario)
            Picker(testo("sumisura.tipologia.titolo"), selection: $tipologia) {
                Text(verbatim: testo("sumisura.tipologia.consigliata", nomeTipologia(stato.consiglioDiOggi().tipologia)))
                    .tag(Optional<Tipologia>.none)
                ForEach(Tipologia.allCases) { t in
                    Text(verbatim: nomeTipologia(t)).tag(Optional(t))
                }
            }
            .modifier(ContornoMenuScelta())
        }
        .carta()
    }

    // MARK: Proposta

    @ViewBuilder
    private var risultato: some View {
        if let w = proposta {
            VStack(alignment: .leading, spacing: 12) {
                if abs(w.metriTotali - metri) > max(stato.profilo.vascaMetri, metri / 10) {
                    // L'allenamento di questo tipo non arriva alla distanza chiesta (per esempio troppo lavoro forte): lo si dice.
                    Text(verbatim: testo("sumisura.vicino", SuMisuraView.formatta(w.metriTotali)))
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .fixedSize(horizontal: false, vertical: true)
                }
                CartaAnteprimaAllenamento(
                    workout: w,
                    usaOggi: {
                        stato.scegli(allenamento: w)
                        chiudi()
                    },
                    iniziaSulTelefono: { inizia(w) }
                )
                Button { altra += 1 } label: {
                    Label("sumisura.altra", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.secondario)
            }
            .carta()
        } else if pronto {
            Text("sumisura.nessuna")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
                .carta()
        }
    }

    private func aggiorna() {
        proposta = stato.allenamentoSuMisura(metri: metri, tipologia: tipologiaUsata, scelta: altra)
    }

    /// "750 m", "1 km", "2,5 km" (virgola o punto secondo la lingua dell'app).
    static func formatta(_ metri: Int) -> String {
        if metri < 1000 { return "\(metri) m" }
        let f = NumberFormatter()
        f.locale = Lingua.locale
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        let km = f.string(from: NSNumber(value: Double(metri) / 1000)) ?? "\(metri / 1000)"
        return "\(km) km"
    }
}
