import Foundation

/// Test per trovare il proprio ritmo di riferimento: una prova a tutta sui 200 m di stile libero.
/// Il test dei 400 m non si propone agli adulti (decisione dell'istruttore, 11 ottobre 2026); `tempo400Secondi`
/// resta opzionale solo per leggere i test già salvati. Le zone (percentuali e parole) sono in
/// content/zone-ritmo.json e restano in bozza finché l'istruttore non le approva (CLAUDE.md).
public struct TestRitmo: Codable, Equatable, Sendable {
    public var data: Date
    public var tempo200Secondi: Int
    public var tempo400Secondi: Int?

    public init(data: Date = Date(), tempo200Secondi: Int, tempo400Secondi: Int? = nil) {
        self.data = data
        self.tempo200Secondi = tempo200Secondi
        self.tempo400Secondi = tempo400Secondi
    }

    /// Secondi ogni 100 m alla velocità critica: (T400 - T200) / 2. Nil senza il tempo dei 400 m o se i tempi non
    /// sono plausibili (il 400 deve richiedere più del doppio del 200). Non usato dall'app, che parte dai 200 m.
    public var ritmoCriticoPer100: Double? {
        guard let t400 = tempo400Secondi, tempo200Secondi > 0, t400 > 2 * tempo200Secondi else { return nil }
        return Double(t400 - tempo200Secondi) / 2.0
    }

    /// Tempi dei 200 m che l'app considera plausibili: da 1:30 a 15:00.
    public static let durata200Plausibile = 90...900

    /// Secondi ogni 100 m al ritmo dei 200 m a tutta: T200 / 2. È il ritmo di riferimento delle zone
    /// (percentuali della velocità sui 200 m, vedi content/zone-ritmo.json). Nil se il tempo non è plausibile.
    public var ritmoRiferimentoPer100: Double? {
        guard Self.durata200Plausibile.contains(tempo200Secondi) else { return nil }
        return Double(tempo200Secondi) / 2.0
    }
}

/// Zona di ritmo di content/zone-ritmo.json: un intervallo di velocità in percentuale della velocità sui 200 m a tutta.
public struct ZonaRitmo: Codable, Equatable, Sendable, Identifiable, ContenutoConStato {
    public var id: String
    public var nome: String
    public var descrizione: String
    public var velocitaDaPercentuale: Double
    public var velocitaAPercentuale: Double
    public var fonti: [String]
    public var stato: StatoContenuto
    /// Intensità dei file di allenamento ("facile", "media", "forte") che usano questa zona come ritmo di riferimento.
    /// Scelta provvisoria in content/zone-ritmo.json, da confermare con l'istruttore.
    public var intensita: [String]? = nil

    enum CodingKeys: String, CodingKey {
        case id, nome, descrizione, fonti, stato, intensita
        case velocitaDaPercentuale = "velocita_da_pct"
        case velocitaAPercentuale = "velocita_a_pct"
    }

    /// Ritmo ogni 100 m (secondi) per questa zona, dato il ritmo critico. Più veloce = numero più basso.
    /// Velocità = percentuale della velocità di riferimento, quindi ritmo = ritmo di riferimento * 100 / percentuale.
    public func intervalloRitmo(ritmoCriticoPer100: Double) -> (piuVeloce: Double, piuLento: Double)? {
        guard velocitaDaPercentuale > 0, velocitaAPercentuale > 0, ritmoCriticoPer100 > 0 else { return nil }
        let a = ritmoCriticoPer100 * 100.0 / velocitaDaPercentuale
        let b = ritmoCriticoPer100 * 100.0 / velocitaAPercentuale
        return (min(a, b), max(a, b))
    }
}

struct FileZoneRitmo: Decodable { let zone: [ZonaRitmo] }

public enum FormatoRitmo {
    /// 95 secondi -> "1:35".
    public static func minutiSecondi(_ secondi: Double) -> String {
        let totale = Int(secondi.rounded())
        return String(format: "%d:%02d", totale / 60, totale % 60)
    }
}
