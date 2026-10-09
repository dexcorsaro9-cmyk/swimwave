import SwiftUI
import SwimwaveCore

/// Gli allenamenti approvati, raggruppati per obiettivo, con due filtri (livello e durata).
/// Va dentro un `NavigationStack` (lo mette `CambiaAllenamentoView`): le righe aprono l'anteprima con un push.
/// `chiudi` chiude tutto il foglio (dopo "Usa oggi"); `inizia` apre la schermata guidata, che la scheda Oggi presenta a tutto schermo.
struct LibreriaView: View {
    let chiudi: () -> Void
    let inizia: (Workout) -> Void

    @Environment(StatoApp.self) private var stato
    @State private var elementi: [ElementoLibreria] = []
    @State private var caricata = false
    @State private var livello: String?
    @State private var durata: FasciaDurata = .tutte

    /// Livelli proposti nel filtro (valori di `livello` in content/allenamenti/indice.json).
    private static let livelli = ["principiante", "intermedio"]
    /// Ordine dei gruppi e valori di `obiettivi` nell'indice.
    private static let obiettivi = ["tecnica", "resistenza", "dimagrimento"]

    enum FasciaDurata: Hashable, CaseIterable {
        case tutte, fino30, da30a45, oltre45

        func contiene(_ minuti: Int) -> Bool {
            switch self {
            case .tutte: return true
            case .fino30: return minuti <= 30
            case .da30a45: return minuti > 30 && minuti <= 45
            case .oltre45: return minuti > 45
            }
        }

        var chiave: String {
            switch self {
            case .tutte: return "libreria.durata.tutte"
            case .fino30: return "libreria.durata.fino30"
            case .da30a45: return "libreria.durata.da30a45"
            case .oltre45: return "libreria.durata.oltre45"
            }
        }
    }

    private struct GruppoLibreria: Identifiable {
        let id: String
        let titolo: String
        let elementi: [ElementoLibreria]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if caricata && elementi.isEmpty {
                    vuoto
                } else {
                    filtri
                    contenuto
                }
            }
            .padding(16)
        }
        .sfondoApp()
        .navigationTitle(Text("libreria.titolo"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !caricata {
                elementi = stato.libreria().map {
                    ElementoLibreria(id: $0.voce.file, voce: $0.voce, workout: $0.workout)
                }
                caricata = true
            }
        }
    }

    // MARK: Filtri

    private var filtri: some View {
        HStack(spacing: 10) {
            Picker(testo("libreria.filtro.livello"), selection: $livello) {
                Text("libreria.filtro.tuttiLivelli").tag(Optional<String>.none)
                ForEach(LibreriaView.livelli, id: \.self) { l in
                    Text(verbatim: etichettaLivelloAllenamento(l)).tag(Optional(l))
                }
            }
            .modifier(ContornoMenuScelta())

            Picker(testo("libreria.filtro.durata"), selection: $durata) {
                ForEach(FasciaDurata.allCases, id: \.self) { f in
                    Text(LocalizedStringKey(f.chiave)).tag(f)
                }
            }
            .modifier(ContornoMenuScelta())
        }
    }

    private func passaFiltri(_ e: ElementoLibreria) -> Bool {
        if let scelto = livello, e.voce.livello != scelto { return false }
        return durata.contiene(e.workout.durataStimataMin)
    }

    private var gruppi: [GruppoLibreria] {
        let filtrati = elementi.filter { passaFiltri($0) }
        var risultato: [GruppoLibreria] = []
        for chiave in LibreriaView.obiettivi {
            let dentro = filtrati.filter { $0.voce.obiettivi.contains(chiave) }
            if !dentro.isEmpty {
                risultato.append(GruppoLibreria(id: chiave, titolo: testo("libreria.gruppo.\(chiave)"), elementi: dentro))
            }
        }
        // Allenamenti con un obiettivo che qui non ha un gruppo: non spariscono.
        let altri = filtrati.filter { e in
            !e.voce.obiettivi.contains(where: { LibreriaView.obiettivi.contains($0) })
        }
        if !altri.isEmpty {
            risultato.append(GruppoLibreria(id: "altri", titolo: testo("libreria.gruppo.altri"), elementi: altri))
        }
        return risultato
    }

    // MARK: Elenco

    @ViewBuilder
    private var contenuto: some View {
        let elenco = gruppi
        if elenco.isEmpty {
            Text("libreria.nessunRisultato")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
                .carta()
        } else {
            ForEach(elenco) { gruppo in
                VStack(alignment: .leading, spacing: 10) {
                    Text(verbatim: gruppo.titolo)
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testo)
                    ForEach(gruppo.elementi) { e in
                        NavigationLink {
                            AnteprimaLibreriaView(elemento: e, chiudi: chiudi, inizia: inizia)
                        } label: {
                            RigaLibreria(elemento: e)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var vuoto: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("libreria.vuoto.titolo")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            Text("libreria.vuoto.testo")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
        }
        .carta()
    }
}

/// Un allenamento della libreria: la voce dell'indice (livello, obiettivi) e l'allenamento già validato e adattato alla vasca.
struct ElementoLibreria: Identifiable {
    let id: String
    let voce: VoceAllenamento
    let workout: Workout
}

// MARK: - Riga

private struct RigaLibreria: View {
    let elemento: ElementoLibreria

    var body: some View {
        let w = elemento.workout
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // Il titolo viene da content/ (testo in italiano, non ancora localizzato).
                Text(verbatim: w.titolo)
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    Etichetta(contenuto: testo("oggi.minuti", w.durataStimataMin))
                    Etichetta(contenuto: testo("oggi.metri", w.metriTotali))
                    Etichetta(contenuto: testo("oggi.vasca", w.vascaMetri))
                }
                Etichetta(contenuto: etichettaLivelloAllenamento(elemento.voce.livello))
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Tema.testoSecondario)
                .accessibilityHidden(true)
        }
        .carta(padding: 14)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Anteprima

/// Tutti i blocchi dell'allenamento, con "Usa oggi" e "Inizia sul telefono".
private struct AnteprimaLibreriaView: View {
    let elemento: ElementoLibreria
    let chiudi: () -> Void
    let inizia: (Workout) -> Void

    @Environment(StatoApp.self) private var stato

    var body: some View {
        ScrollView {
            CartaAnteprimaAllenamento(
                workout: elemento.workout,
                bozza: elemento.voce.stato == .bozza,
                usaOggi: {
                    stato.scegli(allenamento: elemento.workout)
                    chiudi()
                },
                iniziaSulTelefono: {
                    inizia(elemento.workout)
                }
            )
            .carta()
            .padding(16)
        }
        .sfondoApp()
        .navigationTitle(Text(verbatim: elemento.workout.titolo))
        .navigationBarTitleDisplayMode(.inline)
    }
}
