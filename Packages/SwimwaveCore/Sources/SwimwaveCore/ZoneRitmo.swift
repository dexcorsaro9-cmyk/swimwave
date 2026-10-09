import Foundation

/// Test per trovare il proprio ritmo di riferimento: due prove a tutta (200 m e 400 m di stile libero),
/// da cui si ricava la velocità critica (CSS). Il calcolo è matematica; le zone (percentuali e parole)
/// sono in content/zone-ritmo.json e restano in bozza finché l'istruttore non le approva (CLAUDE.md).
public struct TestRitmo: Codable, Equatable, Sendable {
    public var data: Date
    public var tempo200Secondi: Int
    public var tempo400Secondi: Int

    public init(data: Date = Date(), tempo200Secondi: Int, tempo400Secondi: Int) {
        self.data = data
        self.tempo200Secondi = tempo200Secondi
        self.tempo400Secondi = tempo400Secondi
    }

    /// Secondi ogni 100 m alla velocità critica: (T400 - T200) / 2. Nil se i tempi non sono plausibili
    /// (il 400 deve richiedere più del doppio del 200, e i tempi devono essere positivi).
    public var ritmoCriticoPer100: Double? {
        guard tempo200Secondi > 0, tempo400Secondi > 2 * tempo200Secondi else { return nil }
        return Double(tempo400Secondi - tempo200Secondi) / 2.0
    }
}

/// Zona di ritmo di content/zone-ritmo.json: un intervallo di velocità in percentuale della velocità critica.
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
    /// Velocità = percentuale della velocità critica, quindi ritmo = ritmo critico * 100 / percentuale.
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
