import Foundation

// Efficienza e stili di una nuotata, in parole semplici per chi ha iniziato da poco. Logica pura, calcolata dai dati dell'utente.

/// Come sono andate le bracciate per vasca rispetto all'ultima nuotata confrontabile.
public enum ConfrontoBracciate: Equatable, Sendable {
    /// Meno bracciate per vasca dell'ultima volta: (oggi, ultima volta).
    case meno(oggi: Double, prima: Double)
    case simile(oggi: Double, prima: Double)
    case piu(oggi: Double, prima: Double)
}

/// Quota di un stile dentro una nuotata, in metri e in percentuale intera (le quote sommano 100).
public struct QuotaStile: Equatable, Sendable, Identifiable {
    public var stile: Stile
    public var metri: Int
    public var percentuale: Int
    public var id: Stile { stile }

    public init(stile: Stile, metri: Int, percentuale: Int) {
        self.stile = stile
        self.metri = metri
        self.percentuale = percentuale
    }
}

public enum Efficienza {
    /// Sotto questa differenza di bracciate per vasca le due nuotate si considerano uguali.
    /// PROVVISORIO: scelta nostra, da confermare con l'istruttore.
    public static let sogliaDifferenza = 1.0

    /// Confronta le bracciate per vasca di `nuotata` con quelle dell'ultima nuotata precedente nella stessa vasca
    /// (stessa lunghezza, non in acque libere) che abbia le bracciate. Nil se manca il dato o non c'è un confronto.
    public static func confronto(di nuotata: NuotataCompletata, con altre: [NuotataCompletata]) -> ConfrontoBracciate? {
        guard nuotata.ambiente != .acqueLibere,
              let oggi = nuotata.bracciatePerVasca,
              let lunghezza = nuotata.vascaMetri, lunghezza > 0 else { return nil }
        let precedente = altre
            .filter {
                $0.id != nuotata.id && $0.data < nuotata.data && $0.ambiente != .acqueLibere
                    && $0.vascaMetri == lunghezza && $0.bracciatePerVasca != nil
            }
            .max { $0.data < $1.data }
        guard let prima = precedente?.bracciatePerVasca else { return nil }
        let differenza = oggi - prima
        if differenza <= -sogliaDifferenza { return .meno(oggi: oggi, prima: prima) }
        if differenza >= sogliaDifferenza { return .piu(oggi: oggi, prima: prima) }
        return .simile(oggi: oggi, prima: prima)
    }

    /// Quanti metri per stile, dalle vasche che hanno lo stile. Dal più nuotato al meno nuotato.
    /// Le percentuali sono intere e sommano sempre 100 (metodo del resto più grande). Vuoto se nessuna vasca ha lo stile.
    public static func distribuzioneStili(_ vasche: [SplitVasca]) -> [QuotaStile] {
        var metriPerStile: [Stile: Int] = [:]
        for v in vasche where v.metri > 0 {
            guard let s = v.stile else { continue }
            metriPerStile[s, default: 0] += v.metri
        }
        let totale = metriPerStile.values.reduce(0, +)
        guard totale > 0 else { return [] }
        // Ordine stabile: più metri prima, a parità l'ordine di `Stile.allCases`.
        let ordine = Stile.allCases
        let ordinati = metriPerStile.sorted {
            $0.value != $1.value ? $0.value > $1.value
                : (ordine.firstIndex(of: $0.key) ?? 0) < (ordine.firstIndex(of: $1.key) ?? 0)
        }
        var percentuali = ordinati.map { Int((Double($0.value) * 100 / Double(totale)).rounded(.down)) }
        var resto = 100 - percentuali.reduce(0, +)
        // Chi ha il resto frazionario più alto prende il punto che manca.
        let resti = ordinati.enumerated().map { voce in
            (indice: voce.offset, resto: Double(voce.element.value) * 100 / Double(totale) - Double(percentuali[voce.offset]))
        }
        for r in resti.sorted(by: { $0.resto != $1.resto ? $0.resto > $1.resto : $0.indice < $1.indice }) where resto > 0 {
            percentuali[r.indice] += 1
            resto -= 1
        }
        return ordinati.enumerated().map { QuotaStile(stile: $0.element.key, metri: $0.element.value, percentuale: percentuali[$0.offset]) }
    }
}
