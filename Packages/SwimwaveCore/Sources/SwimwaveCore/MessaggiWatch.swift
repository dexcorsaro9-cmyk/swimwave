import Foundation

/// Messaggi tra iPhone e Apple Watch (WatchConnectivity). Chiavi e codifica in un posto solo,
/// così i due lati non si disallineano. Solo tipi ammessi nei dizionari di WatchConnectivity (String, Data, Int).
public enum MessaggiWatch {
    public static let chiaveAllenamento = "allenamento"
    public static let chiaveNuotata = "nuotata"
    public static let chiaveTarget = "target"

    /// iPhone -> Watch: l'allenamento di oggi (application context: arriva anche a Watch spento, vale l'ultimo).
    /// `target` = tempo obiettivo in secondi per ogni ripetizione (stesso ordine di `PianoAllenamento.passi`), nil se non c'è.
    /// Si manda come lista di interi con 0 al posto di "nessun obiettivo": WatchConnectivity non ammette valori opzionali.
    public static func contesto(allenamento: Workout, target: [Int?] = []) throws -> [String: Any] {
        [chiaveAllenamento: try JSONEncoder().encode(allenamento),
         chiaveTarget: target.map { $0 ?? 0 }]
    }

    /// Watch: i tempi obiettivo per ripetizione, se presenti e della lunghezza giusta.
    public static func target(da contesto: [String: Any], passi: Int) -> [Int?] {
        guard let valori = contesto[chiaveTarget] as? [Int], valori.count == passi else {
            return Array(repeating: nil, count: passi)
        }
        return valori.map { $0 > 0 ? $0 : nil }
    }

    /// Watch: legge l'allenamento dal contesto ricevuto. La validazione completa (lista drill) è già stata fatta sull'iPhone.
    public static func allenamento(da contesto: [String: Any]) -> Workout? {
        guard let data = contesto[chiaveAllenamento] as? Data else { return nil }
        return try? JSONDecoder().decode(Workout.self, from: data)
    }

    /// Watch -> iPhone: nuotata completata (transferUserInfo: consegna garantita, in coda).
    public static func userInfo(nuotata: NuotataCompletata) throws -> [String: Any] {
        [chiaveNuotata: try nuotata.codificata()]
    }

    public static func nuotata(da userInfo: [String: Any]) -> NuotataCompletata? {
        guard let data = userInfo[chiaveNuotata] as? Data else { return nil }
        return try? NuotataCompletata.decodifica(data)
    }
}

/// Come è andato l'allenamento, secondo chi ha nuotato. Domanda di fine allenamento: "facile, giusta o dura?".
public enum Sensazione: String, Codable, Sendable, CaseIterable {
    case facile, giusta, dura
}

/// Da dove arriva una nuotata nello storico.
public enum OrigineNuotata: String, Codable, Sendable {
    case watch      // allenamento guidato dal Watch
    case iphone     // allenamento fatto seguendo la schermata dell'iPhone
    case salute     // nuotata letta da Apple Salute (altre app o orologi)
}

/// Dove si è nuotato.
public enum AmbienteNuoto: String, Codable, Sendable {
    case vasca
    case acqueLibere
}

/// Una vasca (o un tratto) con il suo tempo, quando l'orologio o Salute lo sanno.
public struct SplitVasca: Codable, Equatable, Sendable {
    public var metri: Int
    public var durataSecondi: Double
    public var stile: Stile?
    /// Secondi dall'inizio dell'allenamento a cui comincia questo tratto, se noti. Servono a capire se due vasche
    /// sono consecutive (senza soste in mezzo) per i migliori tempi.
    public var inizioSecondi: Double?

    public init(metri: Int, durataSecondi: Double, stile: Stile? = nil, inizioSecondi: Double? = nil) {
        self.metri = metri
        self.durataSecondi = durataSecondi
        self.stile = stile
        self.inizioSecondi = inizioSecondi
    }
}

/// Riepilogo di una nuotata finita, salvato nello storico dell'iPhone.
/// L'`id` è l'UUID dell'allenamento in Apple Salute quando c'è: così la stessa nuotata arrivata dal Watch
/// e letta da Salute non viene contata due volte (le due versioni si uniscono con `unendo`).
/// I campi dopo `origine` sono opzionali: i dati salvati prima della loro introduzione si leggono ancora.
public struct NuotataCompletata: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var data: Date
    public var metri: Int
    public var durataSecondi: Int
    public var titolo: String
    public var sensazione: Sensazione?
    public var origine: OrigineNuotata?
    public var nota: String?
    public var calorie: Int?
    public var frequenzaCardiacaMedia: Int?
    public var bracciate: Int?
    public var vascaMetri: Int?
    public var ambiente: AmbienteNuoto?
    public var vasche: [SplitVasca]?
    /// true se l'utente ha corretto metri o durata a mano: da quel momento le altre fonti non li sovrascrivono.
    public var corretta: Bool?

    public init(id: UUID = UUID(), data: Date, metri: Int, durataSecondi: Int, titolo: String,
                sensazione: Sensazione? = nil, origine: OrigineNuotata? = nil,
                nota: String? = nil, calorie: Int? = nil, frequenzaCardiacaMedia: Int? = nil,
                bracciate: Int? = nil, vascaMetri: Int? = nil, ambiente: AmbienteNuoto? = nil,
                vasche: [SplitVasca]? = nil, corretta: Bool? = nil) {
        self.id = id
        self.data = data
        self.metri = metri
        self.durataSecondi = durataSecondi
        self.titolo = titolo
        self.sensazione = sensazione
        self.origine = origine
        self.nota = nota
        self.calorie = calorie
        self.frequenzaCardiacaMedia = frequenzaCardiacaMedia
        self.bracciate = bracciate
        self.vascaMetri = vascaMetri
        self.ambiente = ambiente
        self.vasche = vasche
        self.corretta = corretta
    }

    /// Secondi ogni 100 m (ritmo medio). Nil se i metri sono zero (o negativi).
    public var ritmoPer100Secondi: Double? {
        guard metri > 0 else { return nil }
        return Double(durataSecondi) / Double(metri) * 100.0
    }

    /// Bracciate per vasca: bracciate / (metri / vascaMetri). Nil se mancano bracciate o lunghezza della vasca,
    /// o se i metri non sono positivi.
    public var bracciatePerVasca: Double? {
        guard let bracciate, let vascaMetri, vascaMetri > 0, metri > 0 else { return nil }
        let numeroVasche = Double(metri) / Double(vascaMetri)
        return Double(bracciate) / numeroVasche
    }

    /// La stessa nuotata arrivata da due fonti (Watch e Salute, o una rilettura): tiene i valori di `self`
    /// e riempie i vuoti con quelli di `altra`. `id` e `data` restano di `self`.
    /// - Valori opzionali (sensazione, origine, nota, calorie, ..., corretta): quello di `self` se presente, altrimenti quello di `altra`.
    /// - `metri` e `durataSecondi` (non opzionali): "vuoto" vuol dire 0; il valore di `altra` si usa solo se quello di `self` è 0.
    ///   Se `self.corretta == true` metri e durata di `self` non si toccano mai.
    /// - `titolo`: quello di `altra` solo se quello di `self` è vuoto.
    public func unendo(_ altra: NuotataCompletata) -> NuotataCompletata {
        var r = self
        if corretta != true {
            if r.metri == 0 { r.metri = altra.metri }
            if r.durataSecondi == 0 { r.durataSecondi = altra.durataSecondi }
        }
        if r.titolo.isEmpty { r.titolo = altra.titolo }
        if r.sensazione == nil { r.sensazione = altra.sensazione }
        if r.origine == nil { r.origine = altra.origine }
        if r.nota == nil { r.nota = altra.nota }
        if r.calorie == nil { r.calorie = altra.calorie }
        if r.frequenzaCardiacaMedia == nil { r.frequenzaCardiacaMedia = altra.frequenzaCardiacaMedia }
        if r.bracciate == nil { r.bracciate = altra.bracciate }
        if r.vascaMetri == nil { r.vascaMetri = altra.vascaMetri }
        if r.ambiente == nil { r.ambiente = altra.ambiente }
        if r.vasche == nil { r.vasche = altra.vasche }
        if r.corretta == nil { r.corretta = altra.corretta }
        return r
    }

    public func codificata() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(self)
    }

    public static func decodifica(_ data: Data) throws -> NuotataCompletata {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(NuotataCompletata.self, from: data)
    }
}
