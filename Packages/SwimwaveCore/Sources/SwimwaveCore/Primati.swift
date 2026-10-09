import Foundation

// Migliori tempi, calendario, obiettivo mensile, tempi obiettivo, richieste al coach. Logica pura, calcolata dai dati dell'utente.

// MARK: Migliori tempi su distanza

public struct MigliorTempo: Equatable, Sendable {
    public var distanzaMetri: Int
    public var secondi: Double
    public var nuotataId: UUID
    public var data: Date

    public init(distanzaMetri: Int, secondi: Double, nuotataId: UUID, data: Date) {
        self.distanzaMetri = distanzaMetri
        self.secondi = secondi
        self.nuotataId = nuotataId
        self.data = data
    }
}

/// Il miglior tempo su una distanza (100, 200, ...) trovato dentro le nuotate, sommando vasche CONSECUTIVE dello stesso stile.
/// Si usano solo le nuotate con i tempi delle vasche e il loro istante di inizio: senza, non si può sapere se tra due vasche
/// c'è stata una sosta e il tempo risulterebbe falsamente veloce. Il tempo è quello nuotato, partenza dal bordo o in acqua:
/// non è un record ufficiale.
public enum MiglioriTempi {
    public static let distanzePredefinite = [100, 200, 400, 800, 1500]
    /// Tra la fine di una vasca e l'inizio della successiva oltre questa pausa si considera che ci sia stata una sosta.
    public static let pausaMassimaSecondi = 3.0

    public static func calcola(
        nuotate: [NuotataCompletata], stile: Stile = .libero, distanze: [Int] = distanzePredefinite
    ) -> [MigliorTempo] {
        var migliori: [Int: MigliorTempo] = [:]
        for n in nuotate {
            guard let vasche = n.vasche, !vasche.isEmpty, vasche.allSatisfy({ $0.inizioSecondi != nil }) else { continue }
            let ordinate = vasche.sorted { ($0.inizioSecondi ?? 0) < ($1.inizioSecondi ?? 0) }
            for tratto in tratti(ordinate, stile: stile) {
                for d in distanze where d > 0 {
                    guard let secondi = migliorTempo(in: tratto, distanza: d) else { continue }
                    if let attuale = migliori[d], attuale.secondi <= secondi { continue }
                    migliori[d] = MigliorTempo(distanzaMetri: d, secondi: secondi, nuotataId: n.id, data: n.data)
                }
            }
        }
        return distanze.compactMap { migliori[$0] }
    }

    /// Gruppi di vasche consecutive, dello stile richiesto e senza soste in mezzo.
    static func tratti(_ vasche: [SplitVasca], stile: Stile) -> [[SplitVasca]] {
        var risultato: [[SplitVasca]] = []
        var corrente: [SplitVasca] = []
        var fineUltima: Double?
        for v in vasche {
            let inizio = v.inizioSecondi ?? 0
            let consecutiva: Bool
            if let fine = fineUltima { consecutiva = inizio - fine <= pausaMassimaSecondi } else { consecutiva = true }
            if v.stile == stile && v.metri > 0 && v.durataSecondi > 0 && consecutiva {
                corrente.append(v)
            } else {
                if !corrente.isEmpty { risultato.append(corrente) }
                corrente = (v.stile == stile && v.metri > 0 && v.durataSecondi > 0) ? [v] : []
            }
            fineUltima = inizio + v.durataSecondi
        }
        if !corrente.isEmpty { risultato.append(corrente) }
        return risultato
    }

    /// Il tempo più basso di una finestra di vasche consecutive che somma esattamente `distanza` metri.
    static func migliorTempo(in tratto: [SplitVasca], distanza: Int) -> Double? {
        var migliore: Double?
        for i in tratto.indices {
            var metri = 0
            var secondi = 0.0
            for j in i..<tratto.count {
                metri += tratto[j].metri
                secondi += tratto[j].durataSecondi
                if metri == distanza {
                    if migliore == nil || secondi < (migliore ?? .infinity) { migliore = secondi }
                    break
                }
                if metri > distanza { break }
            }
        }
        return migliore
    }
}

// MARK: Calendario

public struct CellaCalendario: Equatable, Sendable {
    /// Nil per le celle vuote prima del primo giorno e dopo l'ultimo.
    public var giorno: Int?
    public var data: Date?
    public var nuotate: Int
    public var metri: Int
}

public enum CalendarioNuotate {
    /// Le celle di un mese, a righe di 7 (settimana dal lunedì con `Calendar.italiano`), con celle vuote all'inizio e alla fine.
    public static func celle(nuotate: [NuotataCompletata], mese: Date, calendar: Calendar) -> [CellaCalendario] {
        guard let intervallo = calendar.dateInterval(of: .month, for: mese),
              let giorni = calendar.range(of: .day, in: .month, for: mese) else { return [] }
        let primo = intervallo.start
        let weekdayPrimo = calendar.component(.weekday, from: primo)
        let vuoteIniziali = (weekdayPrimo - calendar.firstWeekday + 7) % 7

        var perGiorno: [Int: (Int, Int)] = [:]
        for n in nuotate where n.data >= intervallo.start && n.data < intervallo.end {
            let g = calendar.component(.day, from: n.data)
            let v = perGiorno[g] ?? (0, 0)
            perGiorno[g] = (v.0 + 1, v.1 + n.metri)
        }

        var celle: [CellaCalendario] = Array(repeating: CellaCalendario(giorno: nil, data: nil, nuotate: 0, metri: 0), count: vuoteIniziali)
        for g in giorni {
            let data = calendar.date(byAdding: .day, value: g - 1, to: primo)
            let v = perGiorno[g] ?? (0, 0)
            celle.append(CellaCalendario(giorno: g, data: data, nuotate: v.0, metri: v.1))
        }
        while celle.count % 7 != 0 {
            celle.append(CellaCalendario(giorno: nil, data: nil, nuotate: 0, metri: 0))
        }
        return celle
    }
}

// MARK: Obiettivo mensile di metri

public struct ProgressoMetri: Equatable, Sendable {
    public let metri: Int
    public let obiettivo: Int

    public init(metri: Int, obiettivo: Int) {
        self.metri = max(0, metri)
        self.obiettivo = max(0, obiettivo)
    }

    public var mancano: Int { max(0, obiettivo - metri) }
    public var raggiunto: Bool { obiettivo > 0 && metri >= obiettivo }
    public var frazione: Double { obiettivo > 0 ? min(1, Double(metri) / Double(obiettivo)) : 0 }
}

public enum ObiettivoMensile {
    public static let minimo = 500
    public static let massimo = 50_000
    /// Valori proposti nel menu (scelta nostra).
    public static let proposte = [1000, 2000, 3000, 5000, 8000, 10_000, 15_000, 20_000]

    public static func progresso(
        obiettivoMetri: Int?, nuotate: [NuotataCompletata], rispetto: Date, calendar: Calendar
    ) -> ProgressoMetri? {
        guard let o = obiettivoMetri, (minimo...massimo).contains(o) else { return nil }
        let dentro = Riepiloghi.filtra(nuotate, periodo: .mese, rispetto: rispetto, calendar: calendar)
        return ProgressoMetri(metri: Riepiloghi.somma(dentro).metri, obiettivo: o)
    }
}

// MARK: Tempi obiettivo per ripetizione

public enum TargetRitmo {
    /// La zona associata a un'intensità (campo `intensita` di content/zone-ritmo.json).
    public static func zona(per intensita: Intensita, tra zone: [ZonaRitmo]) -> ZonaRitmo? {
        zone.first { ($0.intensita ?? []).contains(intensita.rawValue) }
    }

    /// Tempo obiettivo in secondi su `distanzaMetri`, al ritmo centrale della zona. Nil se manca l'intensità, il test o la zona.
    public static func tempoObiettivo(
        distanzaMetri: Int, intensita: Intensita?, ritmoCriticoPer100: Double?, zone: [ZonaRitmo]
    ) -> Int? {
        guard distanzaMetri > 0, let intensita, let critico = ritmoCriticoPer100,
              let z = zona(per: intensita, tra: zone),
              let r = z.intervalloRitmo(ritmoCriticoPer100: critico) else { return nil }
        let centrale = (r.piuVeloce + r.piuLento) / 2.0
        return Int((centrale * Double(distanzaMetri) / 100.0).rounded())
    }

    /// Un tempo obiettivo per ogni ripetizione del piano (stesso ordine di `piano.passi`).
    /// Solo per lo stile libero: il test del ritmo è fatto a stile libero.
    public static func target(
        per piano: PianoAllenamento, ritmoCriticoPer100: Double?, zone: [ZonaRitmo]
    ) -> [Int?] {
        piano.passi.map { passo in
            guard passo.stile == .libero else { return nil }
            return tempoObiettivo(distanzaMetri: passo.distanzaMetri, intensita: passo.intensita,
                                  ritmoCriticoPer100: ritmoCriticoPer100, zone: zone)
        }
    }
}

// MARK: Richieste al coach

/// Cosa può chiedere l'app al servizio coach oltre al profilo. Il servizio accetta solo questi valori.
public struct RichiestaAllenamento: Equatable, Sendable {
    public static let durateAmmesse = [20, 30, 45, 60]

    /// Durata desiderata in minuti, tra `durateAmmesse`.
    public var durataMinuti: Int?
    /// Obiettivo diverso da quello del profilo, solo per questo allenamento.
    public var obiettivo: Obiettivo?
    /// "ultimo allenamento: facile|giusta|dura".
    public var riepilogo: String?

    public init(durataMinuti: Int? = nil, obiettivo: Obiettivo? = nil, riepilogo: String? = nil) {
        self.durataMinuti = durataMinuti
        self.obiettivo = obiettivo
        self.riepilogo = riepilogo
    }

    /// Vero se la richiesta va oltre il profilo (durata o obiettivo scelti dall'utente): l'allenamento non è quello "di oggi".
    public var personalizzata: Bool { durataMinuti != nil || obiettivo != nil }
}

/// Numeri del mese per il commento del coach. Solo conteggi: niente nomi, niente testo libero.
public struct DatiMese: Equatable, Sendable {
    public var nuotate: Int
    public var metri: Int
    public var minuti: Int
    public var metriMesePrecedente: Int
    public var settimaneDiFila: Int
    public var facili: Int
    public var giuste: Int
    public var dure: Int

    public init(nuotate: Int, metri: Int, minuti: Int, metriMesePrecedente: Int, settimaneDiFila: Int,
                facili: Int, giuste: Int, dure: Int) {
        self.nuotate = nuotate
        self.metri = metri
        self.minuti = minuti
        self.metriMesePrecedente = metriMesePrecedente
        self.settimaneDiFila = settimaneDiFila
        self.facili = facili
        self.giuste = giuste
        self.dure = dure
    }

    public static func calcola(
        nuotate: [NuotataCompletata], profilo: Profilo, rispetto: Date, calendar: Calendar
    ) -> DatiMese {
        let del = Riepiloghi.filtra(nuotate, periodo: .mese, rispetto: rispetto, calendar: calendar)
        let somma = Riepiloghi.somma(del)
        var precedente = 0
        if let inizio = calendar.dateInterval(of: .month, for: rispetto)?.start,
           let mesePrima = calendar.date(byAdding: .month, value: -1, to: inizio) {
            precedente = Riepiloghi.somma(Riepiloghi.filtra(nuotate, periodo: .mese, rispetto: mesePrima, calendar: calendar)).metri
        }
        return DatiMese(
            nuotate: somma.nuotate,
            metri: somma.metri,
            minuti: somma.durataSecondi / 60,
            metriMesePrecedente: precedente,
            settimaneDiFila: SerieSettimane.settimaneDiFila(profilo: profilo, date: nuotate.map(\.data), rispetto: rispetto, calendar: calendar),
            facili: del.filter { $0.sensazione == .facile }.count,
            giuste: del.filter { $0.sensazione == .giusta }.count,
            dure: del.filter { $0.sensazione == .dura }.count
        )
    }
}
