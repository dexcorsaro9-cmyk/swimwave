import Foundation

/// Le medaglie (in italiano "traguardi") si sbloccano con dati reali dell'utente. Nomi e grafica li decidono le schermate:
/// qui ci sono solo id, soglie e avanzamento.
public enum CategoriaMedaglia: String, Sendable, CaseIterable {
    case nuotate, distanza, costanza, percorso
}

public struct Medaglia: Equatable, Sendable, Identifiable {
    /// "prima-nuotata", "nuotate-10", "metri-5000", "serie-4", "tappa-5", "test-ritmo".
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

    /// Elenco completo, ottenute e da ottenere, in ordine di categoria e soglia:
    /// nuotate (1, 10, 25, 50, 100; la prima ha id "prima-nuotata"), distanza (metri totali), costanza (serie di settimane,
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

        for soglia in SerieSettimane.traguardi {
            risultato.append(Medaglia(id: "serie-\(soglia)", ottenuta: serieSettimane >= soglia, soglia: soglia, attuale: serieSettimane, categoria: .costanza))
        }

        for tappa in tappe {
            let fatta = tappeSuperate.contains(tappa)
            risultato.append(Medaglia(id: "tappa-\(tappa)", ottenuta: fatta, soglia: 1, attuale: fatta ? 1 : 0, categoria: .percorso))
        }
        let testFatto = testRitmo != nil
        risultato.append(Medaglia(id: "test-ritmo", ottenuta: testFatto, soglia: 1, attuale: testFatto ? 1 : 0, categoria: .percorso))

        return risultato
    }
}
