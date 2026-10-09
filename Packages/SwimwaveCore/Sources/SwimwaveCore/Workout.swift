import Foundation

/// Allenamento condiviso tra coach IA, iPhone e Apple Watch.
/// Rispecchia docs/schema/workout.schema.json e docs/WORKOUT_FORMAT.md.
public struct Workout: Codable, Equatable, Sendable {
    public var titolo: String
    public var vascaMetri: Int
    public var durataStimataMin: Int
    public var blocchi: [Blocco]

    public init(titolo: String, vascaMetri: Int, durataStimataMin: Int, blocchi: [Blocco]) {
        self.titolo = titolo
        self.vascaMetri = vascaMetri
        self.durataStimataMin = durataStimataMin
        self.blocchi = blocchi
    }

    enum CodingKeys: String, CodingKey {
        case titolo
        case vascaMetri = "vasca_metri"
        case durataStimataMin = "durata_stimata_min"
        case blocchi
    }
}

public struct Blocco: Codable, Equatable, Sendable {
    public var tipo: TipoBlocco
    public var serie: [Serie]

    public init(tipo: TipoBlocco, serie: [Serie]) {
        self.tipo = tipo
        self.serie = serie
    }
}

public enum TipoBlocco: String, Codable, Sendable, CaseIterable {
    case riscaldamento, tecnica, principale, defaticamento
}

public struct Serie: Codable, Equatable, Sendable {
    public var ripetizioni: Int
    public var distanzaMetri: Int
    public var stile: Stile
    public var intensita: Intensita?
    public var drill: String?
    public var recuperoSecondi: Int?

    public init(
        ripetizioni: Int,
        distanzaMetri: Int,
        stile: Stile,
        intensita: Intensita? = nil,
        drill: String? = nil,
        recuperoSecondi: Int? = nil
    ) {
        self.ripetizioni = ripetizioni
        self.distanzaMetri = distanzaMetri
        self.stile = stile
        self.intensita = intensita
        self.drill = drill
        self.recuperoSecondi = recuperoSecondi
    }

    enum CodingKeys: String, CodingKey {
        case ripetizioni
        case distanzaMetri = "distanza_m"
        case stile
        case intensita
        case drill
        case recuperoSecondi = "recupero_s"
    }
}

public enum Stile: String, Codable, Sendable, CaseIterable {
    case libero, dorso, rana, delfino, misto
}

/// Scala a parole, da confermare con l'istruttore (vedi docs/PRODUCT.md).
public enum Intensita: String, Codable, Sendable, CaseIterable {
    case facile, media, forte
}
