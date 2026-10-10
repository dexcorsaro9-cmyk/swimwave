import Foundation

/// Serie di settimane "in regola": quante settimane di fila l'obiettivo è stato raggiunto.
/// Con ritmo Libero (nessun obiettivo) basta una nuotata nella settimana.
/// Regole di tono (docs/POPUP_COACH.md): la serie non si "perde" con un messaggio di colpa. La settimana in corso
/// non interrompe la serie finché non è finita; se la serie si ferma, l'app mostra semplicemente zero.
public enum SerieSettimane {
    /// Tappe da festeggiare, in settimane di fila. Scelta nostra, facile da cambiare qui.
    public static let traguardi = [2, 4, 8, 12, 26, 52]

    public static func obiettivoMinimo(profilo: Profilo) -> Int {
        profilo.obiettivoSettimanale ?? 1
    }

    /// Settimane di fila con l'obiettivo raggiunto. La settimana corrente conta se è già raggiunta.
    public static func settimaneDiFila(
        profilo: Profilo,
        date: [Date],
        rispetto riferimento: Date = Date(),
        calendar: Calendar = .italiano
    ) -> Int {
        let minimo = obiettivoMinimo(profilo: profilo)
        var perSettimana: [Date: Int] = [:]
        for d in date {
            if let inizio = calendar.dateInterval(of: .weekOfYear, for: d)?.start {
                perSettimana[inizio, default: 0] += 1
            }
        }
        guard var inizio = calendar.dateInterval(of: .weekOfYear, for: riferimento)?.start else { return 0 }
        var serie = 0
        // La settimana corrente: se non è ancora raggiunta non interrompe, si parte dalla precedente.
        if (perSettimana[inizio] ?? 0) >= minimo {
            serie += 1
        }
        while let precedente = calendar.date(byAdding: .weekOfYear, value: -1, to: inizio) {
            inizio = precedente
            if (perSettimana[inizio] ?? 0) >= minimo {
                serie += 1
            } else {
                break
            }
            if serie > 520 { break } // protezione: dieci anni
        }
        return serie
    }

    /// La serie più lunga mai fatta di settimane di fila con almeno `minimo` nuotate (a prescindere dal profilo).
    public static func serieMassima(conAlmeno minimo: Int, date: [Date], calendar: Calendar = .italiano) -> Int {
        var perSettimana: [Date: Int] = [:]
        for d in date {
            if let inizio = calendar.dateInterval(of: .weekOfYear, for: d)?.start {
                perSettimana[inizio, default: 0] += 1
            }
        }
        let valide = perSettimana.filter { $0.value >= minimo }.keys.sorted()
        var migliore = 0
        var corrente = 0
        var precedente: Date?
        for inizio in valide {
            if let p = precedente, calendar.date(byAdding: .weekOfYear, value: 1, to: p) == inizio {
                corrente += 1
            } else {
                corrente = 1
            }
            migliore = max(migliore, corrente)
            precedente = inizio
        }
        return migliore
    }

    /// Il traguardo appena raggiunto con questo valore, se `serie` è proprio uno dei traguardi.
    public static func traguardo(per serie: Int) -> Int? {
        traguardi.contains(serie) ? serie : nil
    }

    public static func prossimoTraguardo(dopo serie: Int) -> Int? {
        traguardi.first { $0 > serie }
    }
}
