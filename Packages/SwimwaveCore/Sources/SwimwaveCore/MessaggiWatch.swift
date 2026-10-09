import Foundation

/// Messaggi tra iPhone e Apple Watch (WatchConnectivity). Chiavi e codifica in un posto solo,
/// così i due lati non si disallineano. Solo tipi ammessi nei dizionari di WatchConnectivity (String, Data, Int).
public enum MessaggiWatch {
    public static let chiaveAllenamento = "allenamento"
    public static let chiaveNuotata = "nuotata"

    /// iPhone -> Watch: l'allenamento di oggi (application context: arriva anche a Watch spento, vale l'ultimo).
    public static func contesto(allenamento: Workout) throws -> [String: Any] {
        [chiaveAllenamento: try JSONEncoder().encode(allenamento)]
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

/// Riepilogo di una nuotata finita, salvato nello storico dell'iPhone.
/// L'`id` è l'UUID dell'allenamento in Apple Salute quando c'è: così la stessa nuotata arrivata dal Watch
/// e letta da Salute non viene contata due volte.
public struct NuotataCompletata: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var data: Date
    public var metri: Int
    public var durataSecondi: Int
    public var titolo: String
    public var sensazione: Sensazione?
    public var origine: OrigineNuotata?

    public init(id: UUID = UUID(), data: Date, metri: Int, durataSecondi: Int, titolo: String,
                sensazione: Sensazione? = nil, origine: OrigineNuotata? = nil) {
        self.id = id
        self.data = data
        self.metri = metri
        self.durataSecondi = durataSecondi
        self.titolo = titolo
        self.sensazione = sensazione
        self.origine = origine
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
