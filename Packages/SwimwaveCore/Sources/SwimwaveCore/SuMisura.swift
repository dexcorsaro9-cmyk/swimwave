import Foundation

/// Allenamento su misura: l'utente sceglie quanti metri vuole nuotare e l'app adatta a quella distanza uno degli
/// allenamenti approvati (stessi esercizi, stessa struttura, stesse intensità).
///
/// Come si adatta: si parte dall'allenamento approvato con i metri più vicini, poi si aggiungono o tolgono ripetizioni
/// (nella serie principale) e vasche (nel riscaldamento e nel defaticamento facili) finché i metri coincidono.
/// Non si inventa nulla: esercizi, stili, intensità e recuperi restano quelli dell'allenamento di partenza.
/// PROVVISORIO: i limiti di metri e di aumento delle ripetizioni sono scelte nostre, prudenti e senza fonte (content/REVISIONE.md).
public enum SuMisura {
    /// Passo del selettore dei metri.
    public static let passoMetri = 250

    /// Metri che si possono chiedere, per livello. Il principiante non va oltre i 2 km.
    public static func limiti(per categoria: CategoriaLivello) -> ClosedRange<Int> {
        switch categoria {
        case .principiante: return 500...2000
        case .intermedio: return 500...5000
        }
    }

    /// Di quanto può crescere il numero di ripetizioni di una serie principale, in base all'intensità:
    /// il lavoro forte cresce poco, quello facile molto. Mai oltre 50 ripetizioni (limite del formato).
    static func massimoRipetizioni(originale: Int, intensita: Intensita?) -> Int {
        let fattore: Double
        switch intensita {
        case .forte: fattore = 1.5
        case .media: fattore = 4
        case .facile, .none: fattore = 6
        }
        return min(50, Int((Double(originale) * fattore).rounded(.up)))
    }

    /// Distanza massima di una serie facile di riscaldamento o defaticamento (ripetizioni x distanza).
    static let massimoMetriSerieFacile = 600

    private struct Mossa {
        var scarto: Int
        var priorita: Int
        var blocco: Int
        var serie: Int
        var ripetizioni: Int
        var distanza: Int
    }

    /// Porta l'allenamento il più vicino possibile ai metri richiesti. Restituisce il risultato migliore trovato:
    /// per i tipi di allenamento duri (molto lavoro forte) i metri raggiungibili sono meno di quelli di uno di fondo.
    public static func adatta(_ originale: Workout, metriObiettivo: Int, titolo: String? = nil) -> Workout {
        var w = originale
        let vasca = max(1, w.vascaMetri)
        let minimoFacile = max(2 * vasca, 50)
        let metriOriginali = max(1, originale.metriTotali)

        for _ in 0..<300 {
            let diff = metriObiettivo - w.metriTotali
            if diff == 0 { break }
            var migliore: Mossa?

            func valuta(_ m: Mossa) {
                guard m.scarto < abs(diff) else { return }
                if let b = migliore {
                    let a = (m.scarto, m.priorita, m.blocco, m.serie)
                    let c = (b.scarto, b.priorita, b.blocco, b.serie)
                    if a < c { migliore = m }
                } else {
                    migliore = m
                }
            }

            for (bi, blocco) in w.blocchi.enumerated() {
                for (si, serie) in blocco.serie.enumerated() {
                    let rip = serie.ripetizioni
                    let dist = serie.distanzaMetri
                    let attuale = rip * dist
                    let base = originale.blocchi[bi].serie[si]

                    // Una mossa cambia le ripetizioni o la distanza di una serie; `nuovi` sono i metri della serie dopo la mossa.
                    func prova(_ priorita: Int, ripetizioni: Int, distanza: Int) {
                        let delta = ripetizioni * distanza - attuale
                        valuta(Mossa(scarto: abs(diff - delta), priorita: priorita, blocco: bi, serie: si,
                                     ripetizioni: ripetizioni, distanza: distanza))
                    }

                    switch blocco.tipo {
                    case .principale:
                        let massimo = massimoRipetizioni(originale: base.ripetizioni, intensita: serie.intensita)
                        if diff > 0, rip < massimo { prova(0, ripetizioni: rip + 1, distanza: dist) }
                        if diff < 0, rip > 1 { prova(0, ripetizioni: rip - 1, distanza: dist) }
                    case .riscaldamento, .defaticamento:
                        guard serie.drill == nil else { break }
                        if diff > 0 {
                            if (rip + 1) * dist <= massimoMetriSerieFacile { prova(1, ripetizioni: rip + 1, distanza: dist) }
                            if rip * (dist + vasca) <= massimoMetriSerieFacile { prova(1, ripetizioni: rip, distanza: dist + vasca) }
                        } else {
                            if rip > 1, (rip - 1) * dist >= minimoFacile { prova(1, ripetizioni: rip - 1, distanza: dist) }
                            if dist - vasca >= max(vasca, 25), rip * (dist - vasca) >= minimoFacile {
                                prova(1, ripetizioni: rip, distanza: dist - vasca)
                            }
                        }
                    case .tecnica:
                        let massimo = min(8, max(base.ripetizioni * 2, 4))
                        if diff > 0, rip < massimo { prova(2, ripetizioni: rip + 1, distanza: dist) }
                        if diff < 0, rip > 1 { prova(2, ripetizioni: rip - 1, distanza: dist) }
                    }
                }
            }

            guard let m = migliore else { break }
            w.blocchi[m.blocco].serie[m.serie].ripetizioni = m.ripetizioni
            w.blocchi[m.blocco].serie[m.serie].distanzaMetri = m.distanza
        }

        let rapporto = Double(w.metriTotali) / Double(metriOriginali)
        w.durataStimataMin = min(180, max(5, Int((Double(originale.durataStimataMin) * rapporto).rounded())))
        if let titolo, !titolo.isEmpty { w.titolo = String(titolo.prefix(80)) }
        return w
    }
}

extension ContentStore {
    /// Un allenamento su misura per `metri` (portati dentro i limiti del livello), adatto al profilo.
    /// `scelta` varia tra le (al massimo) tre proposte di partenza più vicine ("un'altra proposta").
    /// `titolo` costruisce il titolo dai metri finali (così nella lingua dell'app).
    public func suMisura(profilo: Profilo, metri: Int, tipologia: Tipologia? = nil, scelta: Int = 0,
                         titolo: (Int) -> String) -> Workout? {
        let categoria = profilo.categoriaLivello
        let limiti = SuMisura.limiti(per: categoria)
        let obiettivo = min(max(metri, limiti.lowerBound), limiti.upperBound)

        var candidate = voci.filter { $0.livello == categoria.rawValue }
        if let tipologia {
            let dellaTipologia = candidate.filter { $0.tipologia == tipologia.rawValue }
            if !dellaTipologia.isEmpty { candidate = dellaTipologia }
        }
        // L'obiettivo dell'utente (tecnica, resistenza…) si rispetta se lascia abbastanza scelta.
        let perObiettivo = candidate.filter { $0.obiettivi.contains(profilo.obiettivoEffettivo.chiaveIndice) }
        if perObiettivo.count >= 4 { candidate = perObiettivo }

        let partenze = candidate
            .compactMap { workout(della: $0) }
            .map { Riserva.adattaVasca($0, vascaMetri: profilo.vascaMetri) }
        guard !partenze.isEmpty else { return nil }

        // sorted non è stabile: l'indice originale fa da spareggio.
        let vicine = partenze.enumerated().sorted {
            let a = abs($0.element.metriTotali - obiettivo), b = abs($1.element.metriTotali - obiettivo)
            return a != b ? a < b : $0.offset < $1.offset
        }.map(\.element)
        let n = min(3, vicine.count)
        let base = vicine[((scelta % n) + n) % n]

        var risultato = SuMisura.adatta(base, metriObiettivo: obiettivo)
        risultato.titolo = String(titolo(risultato.metriTotali).prefix(80))
        return risultato
    }
}
