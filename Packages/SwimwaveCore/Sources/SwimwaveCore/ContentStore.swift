import Foundation

/// Carica i contenuti (content/*.json) e mostra solo quelli approvati.
///
/// Il `lettore` riceve un percorso relativo alla cartella content (es. "percorso.json",
/// "allenamenti/indice.json") e restituisce i byte, o nil se manca. In app legge dal Bundle,
/// nei test legge dalla cartella content del repository.
///
/// ATTENZIONE: oggi tutti i contenuti sono in stato "bozza": con `includeBozze == false`
/// l'app non mostra nulla finché l'istruttore non approva.
public final class ContentStore {
    public let includeBozze: Bool
    public private(set) var tappe: [Tappa] = []
    public private(set) var drill: [Drill] = []
    public private(set) var errori: [ErroreComune] = []
    public private(set) var voci: [VoceAllenamento] = []
    public private(set) var zone: [ZonaRitmo] = []
    /// Errori incontrati leggendo i file (file mancante o JSON non conforme). Utile in debug.
    public private(set) var problemi: [String] = []

    private let lettore: (String) -> Data?

    public init(includeBozze: Bool, lettore: @escaping (String) -> Data?) {
        self.includeBozze = includeBozze
        self.lettore = lettore
        ricarica()
    }

    public func ricarica() {
        problemi = []
        tappe = carica("percorso.json", FilePercorso.self)?.tappe.visibili(includeBozze: includeBozze).sorted { $0.id < $1.id } ?? []
        drill = carica("drills.json", FileDrill.self)?.drill.visibili(includeBozze: includeBozze) ?? []
        errori = carica("errori-comuni.json", FileErrori.self)?.errori.visibili(includeBozze: includeBozze) ?? []
        voci = carica("allenamenti/indice.json", FileIndice.self)?.allenamenti.visibili(includeBozze: includeBozze) ?? []
        zone = carica("zone-ritmo.json", FileZoneRitmo.self)?.zone.visibili(includeBozze: includeBozze).sorted { $0.velocitaDaPercentuale < $1.velocitaDaPercentuale } ?? []
    }

    private func carica<T: Decodable>(_ percorso: String, _ tipo: T.Type) -> T? {
        guard let data = lettore(percorso) else {
            problemi.append("\(percorso): file non trovato")
            return nil
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            problemi.append("\(percorso): \(error)")
            return nil
        }
    }

    /// Id dei drill visibili: la lista chiusa usata per validare gli allenamenti.
    public var drillAmmessi: Set<String> { Set(drill.map(\.id)) }

    public func drill(id: String) -> Drill? { drill.first { $0.id == id } }
    public func errore(id: String) -> ErroreComune? { errori.first { $0.id == id } }
    public func tappa(id: Int) -> Tappa? { tappe.first { $0.id == id } }

    /// Legge e valida l'allenamento di una voce dell'indice (stessa validazione del Watch e del server).
    public func workout(della voce: VoceAllenamento) -> Workout? {
        guard let data = lettore("allenamenti/\(voce.file)") else { return nil }
        switch WorkoutValidator.decodeAndValidate(data, allowedDrills: drillAmmessi) {
        case .success(let w): return w
        case .failure: return nil
        }
    }

    /// Allenamento fisso per livello e obiettivo, adattato alla vasca. Stessa logica di `scegliRiserva` in server/coach/src/coach.js.
    /// `scelta` varia tra gli allenamenti adatti (per esempio il giorno dell'anno).
    public func scegliRiserva(profilo: Profilo, scelta: Int) -> Workout? {
        guard let voce = Riserva.scegli(
            voci: voci,
            categoria: profilo.categoriaLivello,
            obiettivo: profilo.obiettivoEffettivo,
            scelta: scelta
        ) else { return nil }
        // Se la voce scelta non è valida (file mancante o drill non visibile) prova le altre, in ordine.
        if let w = workout(della: voce) { return Riserva.adattaVasca(w, vascaMetri: profilo.vascaMetri) }
        let altre = Riserva.candidate(voci: voci, categoria: profilo.categoriaLivello, obiettivo: profilo.obiettivoEffettivo)
        for v in altre where v != voce {
            if let w = workout(della: v) { return Riserva.adattaVasca(w, vascaMetri: profilo.vascaMetri) }
        }
        return nil
    }
}

public enum Riserva {
    /// Voci adatte: stesso gruppo di livello (avanzato usa intermedio), poi per obiettivo se ce ne sono.
    public static func candidate(voci: [VoceAllenamento], categoria: CategoriaLivello, obiettivo: Obiettivo) -> [VoceAllenamento] {
        let delLivello = voci.filter { $0.livello == categoria.rawValue }
        let perObiettivo = delLivello.filter { $0.obiettivi.contains(obiettivo.chiaveIndice) }
        return perObiettivo.isEmpty ? delLivello : perObiettivo
    }

    public static func scegli(voci: [VoceAllenamento], categoria: CategoriaLivello, obiettivo: Obiettivo, scelta: Int) -> VoceAllenamento? {
        let c = candidate(voci: voci, categoria: categoria, obiettivo: obiettivo)
        guard !c.isEmpty else { return nil }
        return c[((scelta % c.count) + c.count) % c.count]
    }

    /// Adatta un allenamento da 25 m a una vasca da 50 m arrotondando le distanze al multiplo di 50 più vicino
    /// (minimo 50). Come `adattaVasca` del server. Altre lunghezze non sono adattate.
    public static func adattaVasca(_ workout: Workout, vascaMetri: Int) -> Workout {
        guard vascaMetri == 50, workout.vascaMetri != 50 else { return workout }
        var w = workout
        w.vascaMetri = 50
        for i in w.blocchi.indices {
            for j in w.blocchi[i].serie.indices {
                let d = w.blocchi[i].serie[j].distanzaMetri
                let arrotondata = Int((Double(d) / 50.0).rounded()) * 50
                w.blocchi[i].serie[j].distanzaMetri = max(50, arrotondata)
            }
        }
        return w
    }
}
