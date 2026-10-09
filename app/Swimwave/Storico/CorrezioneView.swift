import SwiftUI
import SwimwaveCore

/// Foglio per correggere metri e durata di una nuotata (l'orologio a volte sbaglia).
/// Tre menu a tendina: metri (a passi di 25 da 0 a 10.000), minuti (0-300) e secondi (0-59).
struct CorrezioneView: View {
    let salva: (_ metri: Int, _ durataSecondi: Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var metri: Int
    @State private var minuti: Int
    @State private var secondi: Int

    private let opzioniMetri: [Int]
    private let metriIniziali: Int
    private let durataIniziale: Int

    private static let minutiMassimi = 300

    init(metri: Int, durataSecondi: Int, salva: @escaping (_ metri: Int, _ durataSecondi: Int) -> Void) {
        self.salva = salva
        self.metriIniziali = metri
        let durata = max(0, min(durataSecondi, CorrezioneView.minutiMassimi * 60 + 59))
        self.durataIniziale = durata
        // Se i metri attuali non sono un multiplo di 25 (o superano 10.000) restano comunque tra le scelte.
        var valori = Set(stride(from: 0, through: 10_000, by: 25))
        valori.insert(max(0, metri))
        self.opzioniMetri = valori.sorted()
        _metri = State(initialValue: max(0, metri))
        _minuti = State(initialValue: durata / 60)
        _secondi = State(initialValue: durata % 60)
    }

    private var durataScelta: Int { minuti * 60 + secondi }

    private var cambiato: Bool {
        metri != max(0, metriIniziali) || durataScelta != durataIniziale
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("dettaglio.correggi.spiegazione")
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testoSecondario)

                    campo("dettaglio.correggi.metri") {
                        MenuScelta(
                            titolo: testo("dettaglio.correggi.metri"),
                            opzioni: opzioniMetri,
                            etichetta: { FormatiStorico.metri($0) },
                            selezione: Binding<Int?>(get: { metri }, set: { if let v = $0 { metri = v } })
                        )
                    }
                    campo("dettaglio.correggi.minuti") {
                        MenuScelta(
                            titolo: testo("dettaglio.correggi.minuti"),
                            opzioni: Array(0...CorrezioneView.minutiMassimi),
                            etichetta: { testo("dettaglio.correggi.valoreMinuti", $0) },
                            selezione: Binding<Int?>(get: { minuti }, set: { if let v = $0 { minuti = v } })
                        )
                    }
                    campo("dettaglio.correggi.secondi") {
                        MenuScelta(
                            titolo: testo("dettaglio.correggi.secondi"),
                            opzioni: Array(0...59),
                            etichetta: { testo("dettaglio.correggi.valoreSecondi", $0) },
                            selezione: Binding<Int?>(get: { secondi }, set: { if let v = $0 { secondi = v } })
                        )
                    }

                    Button {
                        salva(metri, durataScelta)
                        dismiss()
                    } label: {
                        Text("dettaglio.correggi.salva")
                    }
                    .buttonStyle(.primario)
                    .disabled(!cambiato)
                    .padding(.top, 8)

                    Button {
                        dismiss()
                    } label: {
                        Text("comune.annulla")
                    }
                    .buttonStyle(.secondario)
                }
                .padding(20)
            }
            .sfondoApp()
            .navigationTitle("dettaglio.correggi")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }

    private func campo<Contenuto: View>(_ chiave: String, @ViewBuilder contenuto: () -> Contenuto) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(chiave))
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            contenuto()
        }
    }
}
