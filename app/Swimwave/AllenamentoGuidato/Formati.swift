import Foundation

/// Tempo come "mm:ss" (oppure "h:mm:ss" oltre l'ora).
enum FormatoTempo {
    static func mmss(_ secondi: Int) -> String {
        let s = max(0, secondi)
        let ore = s / 3600
        let minuti = (s % 3600) / 60
        let sec = s % 60
        if ore > 0 {
            return String(format: "%ld:%02ld:%02ld", ore, minuti, sec)
        }
        return String(format: "%02ld:%02ld", minuti, sec)
    }

    /// Minuti interi più vicini (30 s o più contano come un minuto in più).
    static func minutiArrotondati(_ secondi: Int) -> Int {
        max(0, (secondi + 30) / 60)
    }
}

/// Date e numeri nelle schermate, sempre in italiano.
enum FormatiUI {
    private static func formatoData(_ modello: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.setLocalizedDateFormatFromTemplate(modello)
        return f
    }

    private static let giornoMeseFormato: DateFormatter = formatoData("d MMM")
    private static let dataEOraFormato: DateFormatter = formatoData("EEE d MMM HH:mm")
    private static let numeroFormato: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "it_IT")
        return f
    }()

    /// "9 ott"
    static func giornoMese(_ data: Date) -> String {
        giornoMeseFormato.string(from: data)
    }

    /// "ven 9 ott 18:30"
    static func dataEOra(_ data: Date) -> String {
        dataEOraFormato.string(from: data)
    }

    /// 4200 -> "4.200"
    static func numero(_ n: Int) -> String {
        numeroFormato.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
