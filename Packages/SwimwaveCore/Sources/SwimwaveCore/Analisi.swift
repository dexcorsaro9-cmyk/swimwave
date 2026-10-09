import Foundation

// Analisi delle nuotate: riepiloghi per periodo, "il tuo anno", record personali, confronto.
// Tutto è calcolato dai dati dell'utente; nessun testo tecnico di nuoto. Il `Calendar` si passa sempre
// (nei test con fuso Europe/Rome esplicito; nell'app `Calendar.italiano`, settimana dal lunedì).

public enum PeriodoRiepilogo: String, Sendable, CaseIterable {
    case settimana, mese, anno, sempre
}

/// Somma di un periodo (una settimana, un mese, ...).
public struct SommaPeriodo: Equatable, Sendable {
    public var inizio: Date
    public var nuotate: Int
    public var metri: Int
    public var durataSecondi: Int

    public init(inizio: Date, nuotate: Int, metri: Int, durataSecondi: Int) {
        self.inizio = inizio
        self.nuotate = nuotate
        self.metri = metri
        self.durataSecondi = durataSecondi
    }
}

public enum Riepiloghi {
    /// Ultime `quante` settimane (la corrente inclusa), dalla più vecchia alla più recente, anche quelle a zero.
    /// `inizio` è l'inizio della settimana. `quante <= 0` dà un elenco vuoto.
    public static func perSettimana(
        nuotate: [NuotataCompletata], quante: Int, rispetto: Date, calendar: Calendar
    ) -> [SommaPeriodo] {
        perPeriodo(nuotate: nuotate, quanti: quante, rispetto: rispetto, calendar: calendar,
                   componente: .weekOfYear)
    }

    /// Ultimi `quanti` mesi (il corrente incluso), come `perSettimana`.
    public static func perMese(
        nuotate: [NuotataCompletata], quanti: Int, rispetto: Date, calendar: Calendar
    ) -> [SommaPeriodo] {
        perPeriodo(nuotate: nuotate, quanti: quanti, rispetto: rispetto, calendar: calendar,
                   componente: .month)
    }

    private static func perPeriodo(
        nuotate: [NuotataCompletata], quanti: Int, rispetto: Date, calendar: Calendar,
        componente: Calendar.Component
    ) -> [SommaPeriodo] {
        guard quanti > 0, let corrente = calendar.dateInterval(of: componente, for: rispetto) else { return [] }
        var risultato: [SommaPeriodo] = []
        for i in 0..<quanti {
            let passo = -(quanti - 1 - i)
            guard let candidato = calendar.date(byAdding: componente, value: passo, to: corrente.start),
                  let intervallo = calendar.dateInterval(of: componente, for: candidato) else { continue }
            let dentro = nuotate.filter { $0.data >= intervallo.start && $0.data < intervallo.end }
            var somma = Riepiloghi.somma(dentro)
            somma.inizio = intervallo.start
            risultato.append(somma)
        }
        return risultato
    }

    /// Nuotate dentro il periodo che contiene `rispetto` (`.sempre` = tutte, nello stesso ordine).
    public static func filtra(
        _ nuotate: [NuotataCompletata], periodo: PeriodoRiepilogo, rispetto: Date, calendar: Calendar
    ) -> [NuotataCompletata] {
        let componente: Calendar.Component
        switch periodo {
        case .sempre: return nuotate
        case .settimana: componente = .weekOfYear
        case .mese: componente = .month
        case .anno: componente = .year
        }
        guard let intervallo = calendar.dateInterval(of: componente, for: rispetto) else { return [] }
        return nuotate.filter { $0.data >= intervallo.start && $0.data < intervallo.end }
    }

    /// Somma di un gruppo di nuotate. `inizio` = data della prima dell'elenco, o `Date.distantPast` se è vuoto.
    public static func somma(_ nuotate: [NuotataCompletata]) -> SommaPeriodo {
        SommaPeriodo(
            inizio: nuotate.first?.data ?? Date.distantPast,
            nuotate: nuotate.count,
            metri: nuotate.reduce(0) { $0 + $1.metri },
            durataSecondi: nuotate.reduce(0) { $0 + $1.durataSecondi }
        )
    }
}

// MARK: Il tuo anno

public struct RiepilogoAnno: Equatable, Sendable {
    public var anno: Int
    public var nuotate: Int
    public var metri: Int
    public var durataSecondi: Int
    public var giorniNuotati: Int
    /// 1...12, il mese con più metri (a parità il primo); nil se nell'anno non ci sono nuotate.
    public var meseMigliore: Int?
    public var metriMeseMigliore: Int
    /// La nuotata con più metri dell'anno (a parità la più vecchia); nil se non ce n'è con metri positivi.
    public var nuotataPiuLunga: NuotataCompletata?
    /// Settimane (con almeno una nuotata dell'anno) in cui l'obiettivo è raggiunto; minimo 1 se il profilo non ha obiettivo.
    /// Si contano solo le nuotate con la data dentro l'anno: una settimana a cavallo di due anni conta per un anno solo
    /// se in quell'anno ha già da sola abbastanza nuotate.
    public var settimaneConObiettivo: Int

    public init(anno: Int, nuotate: Int, metri: Int, durataSecondi: Int, giorniNuotati: Int,
                meseMigliore: Int?, metriMeseMigliore: Int, nuotataPiuLunga: NuotataCompletata?,
                settimaneConObiettivo: Int) {
        self.anno = anno
        self.nuotate = nuotate
        self.metri = metri
        self.durataSecondi = durataSecondi
        self.giorniNuotati = giorniNuotati
        self.meseMigliore = meseMigliore
        self.metriMeseMigliore = metriMeseMigliore
        self.nuotataPiuLunga = nuotataPiuLunga
        self.settimaneConObiettivo = settimaneConObiettivo
    }
}

public enum RiepilogoAnnuale {
    public static func calcola(
        nuotate: [NuotataCompletata], anno: Int, profilo: Profilo, calendar: Calendar
    ) -> RiepilogoAnno {
        let dellAnno = nuotate.filter { calendar.component(.year, from: $0.data) == anno }
        let totale = Riepiloghi.somma(dellAnno)

        let giorni = Set(dellAnno.map { calendar.startOfDay(for: $0.data) })

        var metriPerMese: [Int: Int] = [:]
        for n in dellAnno {
            metriPerMese[calendar.component(.month, from: n.data), default: 0] += n.metri
        }
        var meseMigliore: Int?
        var metriMese = 0
        for mese in metriPerMese.keys.sorted() {
            let m = metriPerMese[mese] ?? 0
            if meseMigliore == nil || m > metriMese {
                meseMigliore = mese
                metriMese = m
            }
        }

        let minimo = SerieSettimane.obiettivoMinimo(profilo: profilo)
        var perSettimana: [Date: Int] = [:]
        for n in dellAnno {
            if let inizio = calendar.dateInterval(of: .weekOfYear, for: n.data)?.start {
                perSettimana[inizio, default: 0] += 1
            }
        }
        let settimane = perSettimana.values.filter { $0 >= minimo }.count

        return RiepilogoAnno(
            anno: anno,
            nuotate: totale.nuotate,
            metri: totale.metri,
            durataSecondi: totale.durataSecondi,
            giorniNuotati: giorni.count,
            meseMigliore: meseMigliore,
            metriMeseMigliore: metriMese,
            nuotataPiuLunga: Record.piuLunga(dellAnno),
            settimaneConObiettivo: settimane
        )
    }

    /// Anni in cui c'è almeno una nuotata, dal più recente al più vecchio.
    public static func anniConNuotate(_ nuotate: [NuotataCompletata], calendar: Calendar) -> [Int] {
        let anni = Set(nuotate.map { calendar.component(.year, from: $0.data) })
        return anni.sorted(by: >)
    }
}

// MARK: Record personali

public struct RecordPersonali: Equatable, Sendable {
    /// La nuotata con più metri.
    public var nuotataPiuLunga: NuotataCompletata?
    /// Il ritmo medio (secondi ogni 100 m) più basso tra le nuotate di almeno 400 m e almeno 5 minuti.
    /// È un ritmo MEDIO di tutta la nuotata, non un tempo su una distanza.
    public var ritmoMigliore: NuotataCompletata?
    /// La settimana con più metri (`inizio` = lunedì).
    public var settimanaPiuLunga: SommaPeriodo?
    public var serieMassimaSettimane: Int
    public var nuotateTotali: Int
    public var metriTotali: Int
    public var tempo200: Int?
    public var tempo400: Int?

    public init(nuotataPiuLunga: NuotataCompletata? = nil, ritmoMigliore: NuotataCompletata? = nil,
                settimanaPiuLunga: SommaPeriodo? = nil, serieMassimaSettimane: Int = 0,
                nuotateTotali: Int = 0, metriTotali: Int = 0, tempo200: Int? = nil, tempo400: Int? = nil) {
        self.nuotataPiuLunga = nuotataPiuLunga
        self.ritmoMigliore = ritmoMigliore
        self.settimanaPiuLunga = settimanaPiuLunga
        self.serieMassimaSettimane = serieMassimaSettimane
        self.nuotateTotali = nuotateTotali
        self.metriTotali = metriTotali
        self.tempo200 = tempo200
        self.tempo400 = tempo400
    }
}

public enum Record {
    /// Soglie minime per il ritmo migliore: sotto, un ritmo medio dice poco (scelta nostra, facile da cambiare qui).
    public static let metriMinimiPerRitmo = 400
    public static let durataMinimaPerRitmoSecondi = 300

    public static func calcola(
        nuotate: [NuotataCompletata], testRitmo: TestRitmo?, profilo: Profilo, calendar: Calendar
    ) -> RecordPersonali {
        let somma = Riepiloghi.somma(nuotate)
        return RecordPersonali(
            nuotataPiuLunga: piuLunga(nuotate),
            ritmoMigliore: ritmoMigliore(nuotate),
            settimanaPiuLunga: settimanaPiuLunga(nuotate, calendar: calendar),
            serieMassimaSettimane: serieMassima(nuotate, profilo: profilo, calendar: calendar),
            nuotateTotali: somma.nuotate,
            metriTotali: somma.metri,
            tempo200: testRitmo?.tempo200Secondi,
            tempo400: testRitmo?.tempo400Secondi
        )
    }

    /// Più metri; a parità la più vecchia. Nil se non ce n'è con metri positivi.
    static func piuLunga(_ nuotate: [NuotataCompletata]) -> NuotataCompletata? {
        var migliore: NuotataCompletata?
        for n in nuotate where n.metri > 0 {
            guard let attuale = migliore else { migliore = n; continue }
            if n.metri > attuale.metri || (n.metri == attuale.metri && n.data < attuale.data) {
                migliore = n
            }
        }
        return migliore
    }

    /// Ritmo più basso tra le nuotate con almeno 400 m e 5 minuti; a parità la più vecchia.
    static func ritmoMigliore(_ nuotate: [NuotataCompletata]) -> NuotataCompletata? {
        var migliore: NuotataCompletata?
        var ritmoTrovato = Double.infinity
        for n in nuotate where n.metri >= metriMinimiPerRitmo && n.durataSecondi >= durataMinimaPerRitmoSecondi {
            guard let r = n.ritmoPer100Secondi else { continue }
            if r < ritmoTrovato || (r == ritmoTrovato && n.data < (migliore?.data ?? Date.distantFuture)) {
                migliore = n
                ritmoTrovato = r
            }
        }
        return migliore
    }

    /// La settimana con più metri; a parità la più vecchia. Nil se non ci sono metri positivi.
    static func settimanaPiuLunga(_ nuotate: [NuotataCompletata], calendar: Calendar) -> SommaPeriodo? {
        var perSettimana: [Date: SommaPeriodo] = [:]
        for n in nuotate {
            guard let inizio = calendar.dateInterval(of: .weekOfYear, for: n.data)?.start else { continue }
            var s = perSettimana[inizio] ?? SommaPeriodo(inizio: inizio, nuotate: 0, metri: 0, durataSecondi: 0)
            s.nuotate += 1
            s.metri += n.metri
            s.durataSecondi += n.durataSecondi
            perSettimana[inizio] = s
        }
        var migliore: SommaPeriodo?
        for inizio in perSettimana.keys.sorted() {
            guard let s = perSettimana[inizio], s.metri > 0 else { continue }
            if migliore == nil || s.metri > (migliore?.metri ?? 0) { migliore = s }
        }
        return migliore
    }

    /// La serie più lunga di settimane di fila con l'obiettivo raggiunto (min = 1 se il profilo non ha obiettivo),
    /// su tutto lo storico. Stessa regola di `SerieSettimane`, ma senza guardare la settimana corrente.
    static func serieMassima(_ nuotate: [NuotataCompletata], profilo: Profilo, calendar: Calendar) -> Int {
        let minimo = SerieSettimane.obiettivoMinimo(profilo: profilo)
        var perSettimana: [Date: Int] = [:]
        for n in nuotate {
            if let inizio = calendar.dateInterval(of: .weekOfYear, for: n.data)?.start {
                perSettimana[inizio, default: 0] += 1
            }
        }
        let buone = perSettimana.filter { $0.value >= minimo }.keys.sorted()
        var massima = 0
        var corrente = 0
        var precedente: Date?
        for inizio in buone {
            if let p = precedente,
               let prossima = calendar.date(byAdding: .weekOfYear, value: 1, to: p),
               let inizioProssima = calendar.dateInterval(of: .weekOfYear, for: prossima)?.start,
               inizioProssima == inizio {
                corrente += 1
            } else {
                corrente = 1
            }
            massima = max(massima, corrente)
            precedente = inizio
        }
        return massima
    }
}

// MARK: Confronto

public struct ConfrontoNuotate: Equatable, Sendable {
    public var a: NuotataCompletata
    public var b: NuotataCompletata
    /// b - a
    public var differenzaMetri: Int
    /// b - a
    public var differenzaDurataSecondi: Int
    /// b - a, in secondi ogni 100 m (negativo = b più veloce). Nil se manca il ritmo di una delle due.
    public var differenzaRitmoPer100: Double?

    public init(a: NuotataCompletata, b: NuotataCompletata) {
        self.a = a
        self.b = b
        self.differenzaMetri = b.metri - a.metri
        self.differenzaDurataSecondi = b.durataSecondi - a.durataSecondi
        if let ra = a.ritmoPer100Secondi, let rb = b.ritmoPer100Secondi {
            self.differenzaRitmoPer100 = rb - ra
        } else {
            self.differenzaRitmoPer100 = nil
        }
    }
}
