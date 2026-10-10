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

    /// Attrezzi da portare a bordo vasca, ricavati dai drill dell'allenamento. Gli id sconosciuti si ignorano.
    public func attrezzatura(per workout: Workout) -> Attrezzatura {
        var necessari: [Attrezzo] = []
        var facoltativi: [Attrezzo] = []
        for serie in workout.blocchi.flatMap(\.serie) {
            guard let id = serie.drill, let d = drill(id: id) else { continue }
            for a in (d.attrezzi ?? []).compactMap(Attrezzo.init(rawValue:)) where !necessari.contains(a) {
                necessari.append(a)
            }
            for a in (d.attrezziFacoltativi ?? []).compactMap(Attrezzo.init(rawValue:)) where !facoltativi.contains(a) {
                facoltativi.append(a)
            }
        }
        facoltativi.removeAll { necessari.contains($0) }
        return Attrezzatura(necessari: necessari, facoltativi: facoltativi)
    }

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
    public func scegliRiserva(profilo: Profilo, scelta: Int, motivo: MotivoDifficolta? = nil) -> Workout? {
        guard let voce = Riserva.scegli(
            voci: voci,
            categoria: profilo.categoriaLivello,
            obiettivo: profilo.obiettivoEffettivo,
            scelta: scelta,
            motivo: motivo
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

    /// Con `motivo == .esercizio` (l'ultimo allenamento era "dura" perché l'esercizio era troppo difficile)
    /// sceglie tra la metà di allenamenti con le tappe più basse, cioè con gli esercizi più semplici.
    public static func scegli(voci: [VoceAllenamento], categoria: CategoriaLivello, obiettivo: Obiettivo, scelta: Int,
                              motivo: MotivoDifficolta? = nil) -> VoceAllenamento? {
        var c = candidate(voci: voci, categoria: categoria, obiettivo: obiettivo)
        guard !c.isEmpty else { return nil }
        if motivo == .esercizio, c.count > 1 {
            // sorted non è stabile: l'indice originale fa da spareggio.
            let ordinate = c.enumerated().sorted {
                let a = $0.element.tappe.max() ?? 0, b = $1.element.tappe.max() ?? 0
                return a != b ? a < b : $0.offset < $1.offset
            }.map(\.element)
            c = Array(ordinate.prefix((ordinate.count + 1) / 2))
        }
        return c[((scelta % c.count) + c.count) % c.count]
    }

    /// Alleggerisce un allenamento dopo una nuotata "dura". PROVVISORIO: le percentuali sono una scelta nostra,
    /// da confermare con l'istruttore (content/REVISIONE.md).
    /// - `.fiato`: recuperi più lunghi (+50%, almeno +5 s, in multipli di 5 s) nelle serie che ne hanno uno.
    /// - `.stanchezza`: un quarto di ripetizioni in meno nelle serie principali (le serie da una sola ripetizione restano).
    /// - `.esercizio`, `.altro`, nil: nessuna modifica qui (per `.esercizio` cambia la scelta dell'allenamento, vedi `scegli`).
    public static func alleggerisci(_ workout: Workout, motivo: MotivoDifficolta?) -> Workout {
        guard let motivo, motivo == .fiato || motivo == .stanchezza else { return workout }
        var w = workout
        let metriPrima = workout.metriTotali
        var secondiInPiu = 0
        for i in w.blocchi.indices {
            for j in w.blocchi[i].serie.indices {
                switch motivo {
                case .fiato:
                    guard let r = w.blocchi[i].serie[j].recuperoSecondi else { continue }
                    let nuovo = min(600, max(r + 5, ((r * 3 / 2 + 4) / 5) * 5))
                    w.blocchi[i].serie[j].recuperoSecondi = nuovo
                    secondiInPiu += (nuovo - r) * w.blocchi[i].serie[j].ripetizioni
                case .stanchezza:
                    guard w.blocchi[i].tipo == .principale else { continue }
                    let rip = w.blocchi[i].serie[j].ripetizioni
                    guard rip >= 2 else { continue }
                    w.blocchi[i].serie[j].ripetizioni = max(1, rip * 3 / 4)
                default:
                    break
                }
            }
        }
        if motivo == .fiato {
            w.durataStimataMin = min(180, w.durataStimataMin + (secondiInPiu + 59) / 60)
        } else if motivo == .stanchezza, metriPrima > 0 {
            let rapporto = Double(w.metriTotali) / Double(metriPrima)
            w.durataStimataMin = max(5, Int((Double(workout.durataStimataMin) * rapporto).rounded()))
        }
        return w
    }

    /// Adatta un allenamento alla vasca dell'utente (16, 20, 25, 33, 50 m o altra misura) arrotondando ogni distanza
    /// al multiplo della vasca più vicino (minimo una vasca, massimo 2000 m). Come `adattaVasca` del server.
    public static func adattaVasca(_ workout: Workout, vascaMetri: Int) -> Workout {
        guard vascaMetri > 0, workout.vascaMetri != vascaMetri else { return workout }
        var w = workout
        w.vascaMetri = vascaMetri
        for i in w.blocchi.indices {
            for j in w.blocchi[i].serie.indices {
                let d = w.blocchi[i].serie[j].distanzaMetri
                var multipli = max(1, Int((Double(d) / Double(vascaMetri)).rounded()))
                if multipli * vascaMetri > 2000 { multipli = 2000 / vascaMetri }
                w.blocchi[i].serie[j].distanzaMetri = multipli * vascaMetri
            }
        }
        return w
    }
}
