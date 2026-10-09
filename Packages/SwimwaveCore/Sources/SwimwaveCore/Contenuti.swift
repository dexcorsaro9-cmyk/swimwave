import Foundation

/// Stato di un contenuto tecnico (CLAUDE.md): nasce "bozza", diventa "approvato" dopo il controllo dell'istruttore.
/// Un valore sconosciuto viene letto come bozza, cioè nascosto agli utenti.
public enum StatoContenuto: String, Codable, Sendable {
    case bozza, approvato

    public init(from decoder: Decoder) throws {
        let valore = try decoder.singleValueContainer().decode(String.self)
        self = StatoContenuto(rawValue: valore) ?? .bozza
    }
}

public protocol ContenutoConStato {
    var stato: StatoContenuto { get }
}

extension Array where Element: ContenutoConStato {
    /// Gli utenti vedono solo i contenuti approvati; in debug si possono includere le bozze.
    public func visibili(includeBozze: Bool) -> [Element] {
        includeBozze ? self : filter { $0.stato == .approvato }
    }
}

/// Tappa di content/percorso.json.
public struct Tappa: Codable, Equatable, Sendable, Identifiable, ContenutoConStato {
    public var id: Int
    public var nome: String
    public var obiettivo: String
    public var test: String
    public var drill: [String]
    public var errori: [String]
    public var fonti: [String]
    public var stato: StatoContenuto

    public init(id: Int, nome: String, obiettivo: String, test: String,
                drill: [String] = [], errori: [String] = [], fonti: [String] = [], stato: StatoContenuto = .bozza) {
        self.id = id
        self.nome = nome
        self.obiettivo = obiettivo
        self.test = test
        self.drill = drill
        self.errori = errori
        self.fonti = fonti
        self.stato = stato
    }
}

/// Drill di content/drills.json.
public struct Drill: Codable, Equatable, Sendable, Identifiable, ContenutoConStato {
    public var id: String
    public var nome: String
    public var tappa: Int
    public var scopo: String
    public var esecuzione: String
    public var erroreDaEvitare: String
    public var fonti: [String]
    public var stato: StatoContenuto

    enum CodingKeys: String, CodingKey {
        case id, nome, tappa, scopo, esecuzione
        case erroreDaEvitare = "errore_da_evitare"
        case fonti, stato
    }
}

/// Errore comune di content/errori-comuni.json.
public struct ErroreComune: Codable, Equatable, Sendable, Identifiable, ContenutoConStato {
    public var id: String
    public var nome: String
    public var comeSiRiconosce: String
    public var perche: String
    public var correzione: String
    public var drill: [String]
    public var fonti: [String]
    public var stato: StatoContenuto

    enum CodingKeys: String, CodingKey {
        case id, nome
        case comeSiRiconosce = "come_si_riconosce"
        case perche = "perche_e_un_problema"
        case correzione, drill, fonti, stato
    }
}

/// Voce di content/allenamenti/indice.json.
public struct VoceAllenamento: Codable, Equatable, Sendable, ContenutoConStato {
    public var file: String
    public var livello: String
    public var obiettivi: [String]
    public var tappe: [Int]
    public var stato: StatoContenuto
}

// Contenitori dei file JSON (la chiave "nota" viene ignorata).
struct FilePercorso: Decodable { let tappe: [Tappa] }
struct FileDrill: Decodable { let drill: [Drill] }
struct FileErrori: Decodable { let errori: [ErroreComune] }
struct FileIndice: Decodable { let allenamenti: [VoceAllenamento] }
