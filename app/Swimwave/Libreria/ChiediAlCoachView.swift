import SwiftUI
import SwimwaveCore

/// "Chiedi al coach": l'utente sceglie durata e argomento e il coach prepara un allenamento per oggi.
/// Va dentro un `NavigationStack` (lo mette `CambiaAllenamentoView`). Serve il consenso all'IA, che qui non si chiede:
/// si rimanda a Profilo. Se il coach non risponde, si propone la libreria.
struct ChiediAlCoachView: View {
    let chiudi: () -> Void
    let inizia: (Workout) -> Void

    @Environment(StatoApp.self) private var stato
    @State private var durata: Int?
    @State private var obiettivo: Obiettivo?
    @State private var inAttesa = false
    @State private var risultato: Workout?
    @State private var fallito = false
    @State private var compito: Task<Void, Never>?
    @State private var apriLibreria = false

    /// Gli argomenti che si possono chiedere (gli stessi dei gruppi della libreria).
    private static let argomenti: [Obiettivo] = [.tecnica, .resistenza, .dimagrimento]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if stato.consensoIA == true {
                    modulo
                    if inAttesa { attesa }
                    if let w = risultato { cartaRisultato(w) }
                    if fallito { cartaFallito }
                } else {
                    cartaConsenso
                }
            }
            .padding(16)
        }
        .sfondoApp()
        .navigationTitle(Text("chiedi.titolo"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $apriLibreria) {
            LibreriaView(chiudi: chiudi, inizia: inizia)
        }
        .onDisappear {
            // Se si lascia la schermata la richiesta in corso non serve più.
            compito?.cancel()
            compito = nil
            inAttesa = false
        }
    }

    // MARK: Modulo

    private var modulo: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("chiedi.intro")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("chiedi.durata.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Picker(testo("chiedi.durata.titolo"), selection: $durata) {
                    Text("chiedi.durata.coach").tag(Optional<Int>.none)
                    ForEach(RichiestaAllenamento.durateAmmesse, id: \.self) { d in
                        Text(verbatim: testo("oggi.minuti", d)).tag(Optional(d))
                    }
                }
                .modifier(ContornoMenuScelta())
                .disabled(inAttesa)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("chiedi.obiettivo.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Picker(testo("chiedi.obiettivo.titolo"), selection: $obiettivo) {
                    Text("chiedi.obiettivo.comeSempre").tag(Optional<Obiettivo>.none)
                    ForEach(ChiediAlCoachView.argomenti, id: \.self) { o in
                        Text(verbatim: nomeBreveObiettivo(o)).tag(Optional(o))
                    }
                }
                .modifier(ContornoMenuScelta())
                .disabled(inAttesa)
            }

            // Un solo pulsante principale per schermata: con l'allenamento pronto lo diventa "Usa oggi".
            if risultato == nil {
                Button(action: prepara) {
                    Text("chiedi.prepara")
                }
                .buttonStyle(.primario)
                .disabled(inAttesa)
                .padding(.top, 4)
            } else {
                Button(action: prepara) {
                    Text("chiedi.preparaAncora")
                }
                .buttonStyle(.secondario)
                .disabled(inAttesa)
                .padding(.top, 4)
            }
        }
        .carta()
    }

    private var attesa: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Tema.turchese)
            Text("chiedi.attesa")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
            Button(action: annulla) {
                Text("comune.annulla")
            }
            .buttonStyle(.secondario)
        }
        .frame(maxWidth: .infinity)
        .carta()
        .accessibilityElement(children: .contain)
    }

    private func cartaRisultato(_ w: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("chiedi.risultato.titolo")
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
            CartaAnteprimaAllenamento(
                workout: w,
                usaOggi: {
                    stato.scegli(allenamento: w)
                    chiudi()
                },
                iniziaSulTelefono: {
                    inizia(w)
                }
            )
        }
        .carta()
    }

    private var cartaFallito: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("chiedi.fallito.testo")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                apriLibreria = true
            } label: {
                Text("chiedi.fallito.libreria")
            }
            .buttonStyle(.secondario)
        }
        .carta()
    }

    private var cartaConsenso: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("chiedi.consenso")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                apriLibreria = true
            } label: {
                Text("chiedi.consenso.libreria")
            }
            .buttonStyle(.secondario)
        }
        .carta()
    }

    // MARK: Azioni

    private func prepara() {
        guard !inAttesa else { return }
        risultato = nil
        fallito = false
        inAttesa = true
        let richiesta = RichiestaAllenamento(durataMinuti: durata, obiettivo: obiettivo)
        compito = Task { @MainActor in
            let w = await stato.chiediAlCoach(richiesta)
            // Se nel frattempo si è annullato (o si è lasciata la schermata) il risultato non interessa.
            if Task.isCancelled { return }
            inAttesa = false
            if let w {
                risultato = w
            } else {
                fallito = true
            }
        }
    }

    private func annulla() {
        compito?.cancel()
        compito = nil
        inAttesa = false
    }
}
