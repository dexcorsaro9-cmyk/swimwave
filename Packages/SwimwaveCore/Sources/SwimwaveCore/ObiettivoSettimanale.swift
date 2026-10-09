import Foundation

extension Calendar {
    /// Calendario italiano: la settimana comincia il lunedì.
    public static var italiano: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }
}

/// Quanto manca all'obiettivo della settimana.
public enum Mancanti: Equatable, Sendable {
    case raggiunto
    case uno
    case piu(Int)
}

/// Avanzamento verso l'obiettivo settimanale (Regolare e Spronami).
public struct ProgressoSettimanale: Equatable, Sendable {
    public let nuotate: Int
    public let obiettivo: Int

    public init(nuotate: Int, obiettivo: Int) {
        self.nuotate = max(0, nuotate)
        self.obiettivo = max(0, obiettivo)
    }

    public var mancano: Int { max(0, obiettivo - nuotate) }
    public var raggiunto: Bool { obiettivo > 0 && nuotate >= obiettivo }

    /// "Ne manca uno" / "Ne mancano N" / raggiunto.
    public var mancanti: Mancanti {
        switch mancano {
        case 0: return .raggiunto
        case 1: return .uno
        default: return .piu(mancano)
        }
    }

    /// Frazione per la barra, tra 0 e 1.
    public var frazione: Double {
        guard obiettivo > 0 else { return 0 }
        return min(1, Double(nuotate) / Double(obiettivo))
    }
}

public enum ObiettivoSettimanale {
    /// Quante date cadono nella settimana che contiene `rispetto` (ogni nuotata conta, anche più di una nello stesso giorno).
    public static func conteggio(
        date: [Date],
        rispetto riferimento: Date,
        calendar: Calendar = .italiano
    ) -> Int {
        guard let settimana = calendar.dateInterval(of: .weekOfYear, for: riferimento) else { return 0 }
        return date.filter { $0 >= settimana.start && $0 < settimana.end }.count
    }

    /// Progresso della settimana, o nil se il profilo non ha un obiettivo settimanale.
    public static func progresso(
        profilo: Profilo,
        date: [Date],
        rispetto riferimento: Date = Date(),
        calendar: Calendar = .italiano
    ) -> ProgressoSettimanale? {
        guard let obiettivo = profilo.obiettivoSettimanale else { return nil }
        let n = conteggio(date: date, rispetto: riferimento, calendar: calendar)
        return ProgressoSettimanale(nuotate: n, obiettivo: obiettivo)
    }

    /// Identificatore della settimana ("2026-W41"), per ricordare quale traguardo è già stato festeggiato.
    public static func idSettimana(_ data: Date, calendar: Calendar = .italiano) -> String {
        let anno = calendar.component(.yearForWeekOfYear, from: data)
        let sett = calendar.component(.weekOfYear, from: data)
        return "\(anno)-W\(sett)"
    }
}
