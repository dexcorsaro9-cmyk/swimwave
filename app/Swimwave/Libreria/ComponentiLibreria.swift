import SwiftUI
import SwimwaveCore

// Pezzi condivisi da Oggi, Libreria e "Chiedi al coach": anteprima delle serie, carta con i pulsanti, menu, tempi obiettivo.

// MARK: - Tempo obiettivo

enum TempoObiettivo {
    /// "Obiettivo 0:53" (secondi -> m:ss). Nessun giudizio: è solo un riferimento.
    static func riga(_ secondi: Int) -> String {
        testo("target.obiettivo", FormatoRitmo.minutiSecondi(Double(secondi)))
    }
}

// MARK: - Etichette

/// "principiante" -> "Principiante". Un livello sconosciuto si mostra com'è, con l'iniziale maiuscola.
func etichettaLivelloAllenamento(_ livello: String) -> String {
    switch livello {
    case "principiante": return testo("libreria.livello.principiante")
    case "intermedio": return testo("libreria.livello.intermedio")
    default: return livello.capitalized
    }
}

/// Nome breve dell'obiettivo ("Tecnica", "Resistenza", "Dimagrimento") per titoli di gruppo e menu.
/// "Stare bene" usa le riserve di tecnica (come `chiaveIndice`).
func nomeBreveObiettivo(_ obiettivo: Obiettivo) -> String {
    switch obiettivo {
    case .tecnica, .stareBene: return testo("libreria.gruppo.tecnica")
    case .resistenza: return testo("libreria.gruppo.resistenza")
    case .dimagrimento: return testo("libreria.gruppo.dimagrimento")
    }
}

// MARK: - Menu a tendina

/// Contorno turchese dei menu a tendina (come `MenuScelta` di Tema, ma per Picker con una voce "tutti" o "come vuoi").
struct ContornoMenuScelta: ViewModifier {
    func body(content: Content) -> some View {
        content
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
    }
}

// MARK: - Anteprima delle serie

/// I blocchi di un allenamento con una riga per serie ("4 × 50 m · Stile libero · Media · recupero 15 s").
/// In coda alla riga, "Obiettivo 0:53" solo se l'utente ha fatto il test del ritmo e tutte le ripetizioni
/// della serie hanno lo stesso tempo obiettivo.
struct AnteprimaAllenamento: View {
    let workout: Workout
    @Environment(StatoApp.self) private var stato

    private struct RigaSerie: Identifiable {
        let id: Int
        let testo: String
    }

    private struct RigaBlocco: Identifiable {
        let id: Int
        let titolo: String
        let serie: [RigaSerie]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(righe()) { blocco in
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: blocco.titolo)
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testo)
                    ForEach(blocco.serie) { riga in
                        Text(verbatim: riga.testo)
                            .font(Tema.corpo)
                            .foregroundStyle(Tema.testoSecondario)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Titolo e righe vengono da content/ (testo in italiano, non ancora localizzato).
    /// L'ordine delle ripetizioni è quello di `PianoAllenamento`: `targetRitmo(per:)` ha un valore per ripetizione.
    private func righe() -> [RigaBlocco] {
        let target = stato.targetRitmo(per: workout)
        var indice = 0
        var risultato: [RigaBlocco] = []
        for (b, blocco) in workout.blocchi.enumerated() {
            var righeSerie: [RigaSerie] = []
            for (s, voce) in blocco.serie.enumerated() {
                let n = max(1, voce.ripetizioni)
                var testoRiga = workout.descrizione(di: voce) { stato.contenuti.drill(id: $0)?.nome }
                let fine = indice + n
                if fine <= target.count {
                    let fetta = Array(target[indice..<fine])
                    if let primo = fetta.first, let t = primo, fetta.allSatisfy({ $0 == t }) {
                        testoRiga += " · " + TempoObiettivo.riga(t)
                    }
                }
                indice = fine
                righeSerie.append(RigaSerie(id: s, testo: testoRiga))
            }
            risultato.append(RigaBlocco(id: b, titolo: blocco.tipo.etichetta, serie: righeSerie))
        }
        return risultato
    }
}

// MARK: - Carta con titolo, dati, serie e pulsanti

/// Titolo, minuti, metri, vasca, serie e i due pulsanti "Usa oggi" (principale) e "Inizia sul telefono".
/// Chi la usa la mette in una `.carta()` o direttamente sullo sfondo.
struct CartaAnteprimaAllenamento: View {
    let workout: Workout
    var bozza: Bool = false
    let usaOggi: () -> Void
    let iniziaSulTelefono: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if bozza {
                // Le bozze si vedono solo nelle build di debug.
                Etichetta(contenuto: "BOZZA (solo debug)")
            }
            Text(verbatim: workout.titolo)
                .font(Tema.titolo2)
                .foregroundStyle(Tema.testo)
            HStack(spacing: 8) {
                Etichetta(contenuto: testo("oggi.minuti", workout.durataStimataMin))
                Etichetta(contenuto: testo("oggi.metri", workout.metriTotali))
                Etichetta(contenuto: testo("oggi.vasca", workout.vascaMetri))
            }
            AnteprimaAllenamento(workout: workout)
            Button(action: usaOggi) {
                Text("libreria.usaOggi")
            }
            .buttonStyle(.primario)
            .padding(.top, 4)
            Button(action: iniziaSulTelefono) {
                Text("oggi.inizia")
            }
            .buttonStyle(.secondario)
        }
    }
}
