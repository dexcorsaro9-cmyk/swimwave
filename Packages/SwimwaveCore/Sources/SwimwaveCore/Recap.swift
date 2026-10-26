import Foundation

/// Una cosa che spicca nell'allenamento appena finito, per il recap del coach.
public enum Evidenza: Equatable, Sendable {
    /// La nuotata più lunga finora (con almeno un'altra nuotata prima).
    case piuLunga(metri: Int)
    /// Il ritmo medio migliore tra le nuotate valide (secondi ogni 100 m).
    case ritmoMigliore(secondiPer100: Int)
    /// Più veloce dell'ultima nuotata confrontabile, di almeno `Recap.secondiMinimiPiuVeloce` secondi ogni 100 m.
    case piuVeloceDellUltima(secondi: Int)
    case programmaCompleto
    case programmaParziale(fatti: Int, previsti: Int)
    /// Nuotate fatte e nuotate dell'obiettivo della settimana (Regolare e Spronami).
    case obiettivoSettimana(fatte: Int, totale: Int)
    case serieSettimane(Int)
}

/// Il recap del coach a fine allenamento: cosa spicca e quale errore comune consigliare.
/// Tutto è calcolato con regole sui dati, senza IA: ogni frase è verificabile e il consiglio tecnico viene solo dai contenuti con fonti.
public enum Recap {
    /// Sopra questa frazione dei metri previsti il programma conta come completo.
    public static let sogliaProgrammaCompleto = 0.95
    /// Differenza minima di ritmo per dire "più veloce dell'ultima volta" (scelta nostra, facile da cambiare qui).
    public static let secondiMinimiPiuVeloce = 3
    /// Quante cose che spiccano si mostrano al massimo.
    public static let massimoEvidenze = 3

    /// Le cose che spiccano, in ordine di importanza, al massimo `massimoEvidenze`.
    /// Dopo una nuotata "dura" non si mettono record né velocità: contano solo il programma e l'obiettivo.
    /// - `precedenti`: le nuotate fatte prima di questa (qualsiasi ordine).
    /// - `progresso`: avanzamento della settimana, già comprensivo di questa nuotata.
    public static func evidenze(
        nuotata: NuotataCompletata,
        precedenti: [NuotataCompletata],
        metriPrevisti: Int,
        sensazione: Sensazione?,
        progresso: ProgressoSettimanale?,
        serieSettimane: Int
    ) -> [Evidenza] {
        var elenco: [Evidenza] = []
        let dura = sensazione == .dura
        let ordinate = precedenti.sorted { $0.data > $1.data }

        if !dura {
            if !ordinate.isEmpty, let massimo = ordinate.map(\.metri).max(), nuotata.metri > massimo {
                elenco.append(.piuLunga(metri: nuotata.metri))
            }
            if let mio = ritmoValido(nuotata) {
                let altri = ordinate.compactMap(ritmoValido)
                if let migliore = altri.min(), mio < migliore {
                    elenco.append(.ritmoMigliore(secondiPer100: Int(mio.rounded())))
                } else if let ultimo = ordinate.first(where: { ritmoValido($0) != nil }).flatMap(ritmoValido) {
                    let differenza = ultimo - mio
                    if differenza >= Double(secondiMinimiPiuVeloce) {
                        elenco.append(.piuVeloceDellUltima(secondi: Int(differenza.rounded())))
                    }
                }
            }
        }
        if metriPrevisti > 0 {
            if Double(nuotata.metri) >= Double(metriPrevisti) * sogliaProgrammaCompleto {
                elenco.append(.programmaCompleto)
            } else {
                elenco.append(.programmaParziale(fatti: nuotata.metri, previsti: metriPrevisti))
            }
        }
        if let p = progresso, p.obiettivo > 0 {
            elenco.append(.obiettivoSettimana(fatte: p.nuotate, totale: p.obiettivo))
        }
        if !dura, serieSettimane >= 2 {
            elenco.append(.serieSettimane(serieSettimane))
        }
        return Array(elenco.prefix(massimoEvidenze))
    }

    /// Il ritmo medio (secondi ogni 100 m) se la nuotata è abbastanza lunga da dire qualcosa (stesse soglie dei record).
    static func ritmoValido(_ n: NuotataCompletata) -> Double? {
        guard n.metri >= Record.metriMinimiPerRitmo, n.durataSecondi >= Record.durataMinimaPerRitmoSecondi else { return nil }
        return n.ritmoPer100Secondi
    }

    /// L'errore comune da consigliare: tra quelli collegati ai drill usati nell'allenamento, uno scelto a rotazione per giorno.
    /// Nil se l'allenamento non ha drill o nessun errore è collegato ai suoi drill.
    public static func erroreConsigliato(workout: Workout, errori: [ErroreComune], giorno: Int) -> ErroreComune? {
        let usati = Set(workout.blocchi.flatMap(\.serie).compactMap(\.drill))
        guard !usati.isEmpty else { return nil }
        let collegati = errori.filter { !usati.isDisjoint(with: $0.drill) }.sorted { $0.id < $1.id }
        guard !collegati.isEmpty else { return nil }
        return collegati[((giorno % collegati.count) + collegati.count) % collegati.count]
    }
}
