import Foundation

/// Le medaglie (in italiano "traguardi") si sbloccano con dati reali dell'utente. Nomi e grafica li decidono le schermate:
/// qui ci sono solo id, soglie e avanzamento.
public enum CategoriaMedaglia: String, Sendable, CaseIterable {
    case nuotate, distanza, traversate, costanza, percorso
}

public struct Medaglia: Equatable, Sendable, Identifiable {
    /// "prima-nuotata", "nuotate-10", "metri-5000", "traversata-messina", "serie-4", "fedele-vasca", "tappa-5", "test-ritmo", "cento-continui".
    public var id: String
    public var ottenuta: Bool
    /// Valore da raggiungere (per "tappa-N" e "test-ritmo": 1).
    public var soglia: Int
    /// Valore raggiunto finora, non limitato alla soglia (per "tappa-N" e "test-ritmo": 0 o 1).
    public var attuale: Int
    public var categoria: CategoriaMedaglia

    public init(id: String, ottenuta: Bool, soglia: Int, attuale: Int, categoria: CategoriaMedaglia) {
        self.id = id
        self.ottenuta = ottenuta
        self.soglia = soglia
        self.attuale = attuale
        self.categoria = categoria
    }
}

public enum Medaglie {
    public static let sogliaNuotate = [1, 10, 25, 50, 100]
    public static let sogliaMetri = [1000, 5000, 10000, 25000, 50000, 100000]
    /// Come le tappe di content/percorso.json (1...10).
    public static let tappe = Array(1...10)

    /// Traversate simboliche: i metri nuotati in totale (tutte le nuotate) contro la larghezza minima dello stretto.
    /// Larghezze da Wikipedia: Messina 3,1 km, Bonifacio 11 km, Gibilterra 14,2 km, Manica (Dover) 34 km.
    public static let traversate: [(id: String, metri: Int)] = [
        ("traversata-messina", 3_100),
        ("traversata-bonifacio", 11_000),
        ("traversata-gibilterra", 14_200),
        ("traversata-manica", 34_000),
    ]

    /// "Fedele alla vasca": settimane di fila con almeno `nuotateFedele` nuotate.
    public static let settimaneFedele = 3
    public static let nuotateFedele = 2

    /// Elenco completo, ottenute e da ottenere, in ordine di categoria e soglia:
    /// nuotate (1, 10, 25, 50, 100; la prima ha id "prima-nuotata"), distanza (metri totali), traversate (metri totali contro la larghezza di uno stretto), costanza (serie di settimane,
    /// soglie di `SerieSettimane.traguardi`), percorso (tappe 1...10 e "test-ritmo").
    /// `serieSettimane` è il valore da confrontare con le soglie: per non togliere una medaglia a chi interrompe la serie,
    /// chi chiama passa la serie migliore mai raggiunta (`RecordPersonali.serieMassimaSettimane`), non solo quella in corso.
    public static func elenco(
        nuotate: [NuotataCompletata], serieSettimane: Int, tappeSuperate: [Int], testRitmo: TestRitmo?
    ) -> [Medaglia] {
        var risultato: [Medaglia] = []

        let numero = nuotate.count
        for soglia in sogliaNuotate {
            let id = soglia == 1 ? "prima-nuotata" : "nuotate-\(soglia)"
            risultato.append(Medaglia(id: id, ottenuta: numero >= soglia, soglia: soglia, attuale: numero, categoria: .nuotate))
        }

        let metri = nuotate.reduce(0) { $0 + $1.metri }
        for soglia in sogliaMetri {
            risultato.append(Medaglia(id: "metri-\(soglia)", ottenuta: metri >= soglia, soglia: soglia, attuale: metri, categoria: .distanza))
        }

        for t in traversate {
            risultato.append(Medaglia(id: t.id, ottenuta: metri >= t.metri, soglia: t.metri, attuale: metri, categoria: .traversate))
        }

        for soglia in SerieSettimane.traguardi {
            risultato.append(Medaglia(id: "serie-\(soglia)", ottenuta: serieSettimane >= soglia, soglia: soglia, attuale: serieSettimane, categoria: .costanza))
        }
        let fedele = SerieSettimane.serieMassima(conAlmeno: nuotateFedele, date: nuotate.map(\.data))
        risultato.append(Medaglia(id: "fedele-vasca", ottenuta: fedele >= settimaneFedele, soglia: settimaneFedele,
                                  attuale: fedele, categoria: .costanza))

        for tappa in tappe {
            let fatta = tappeSuperate.contains(tappa)
            risultato.append(Medaglia(id: "tappa-\(tappa)", ottenuta: fatta, soglia: 1, attuale: fatta ? 1 : 0, categoria: .percorso))
        }
        let testFatto = testRitmo != nil
        risultato.append(Medaglia(id: "test-ritmo", ottenuta: testFatto, soglia: 1, attuale: testFatto ? 1 : 0, categoria: .percorso))
        // 100 m di stile libero senza soste: servono i tempi delle vasche con il loro istante di inizio (vedi `MiglioriTempi`).
        let cento = !MiglioriTempi.calcola(nuotate: nuotate, stile: .libero, distanze: [100]).isEmpty
        risultato.append(Medaglia(id: "cento-continui", ottenuta: cento, soglia: 1, attuale: cento ? 1 : 0, categoria: .percorso))

        return risultato
    }
}
