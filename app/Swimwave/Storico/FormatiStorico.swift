import Foundation
import SwimwaveCore

/// Date e numeri per lo Storico, sempre in italiano (Locale it_IT).
/// Estende quanto c'è già in AllenamentoGuidato/Formati.swift (FormatoTempo, FormatiUI) senza toccarlo.
enum FormatiStorico {
    private static let locale = Locale(identifier: "it_IT")

    private static func formatoData(_ modello: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate(modello)
        return f
    }

    private static let dataLungaFormato: DateFormatter = formatoData("EEEE d MMMM y")
    private static let giornoMeseLungoFormato: DateFormatter = formatoData("d MMMM")
    private static let meseAnnoFormato: DateFormatter = formatoData("LLLL y")
    private static let oraFormato: DateFormatter = formatoData("HH:mm")

    private static let decimaleFormato: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = locale
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()

    /// "venerdì 9 ottobre 2026"
    static func dataLunga(_ data: Date) -> String {
        dataLungaFormato.string(from: data)
    }

    /// "9 ottobre"
    static func giornoMeseLungo(_ data: Date) -> String {
        giornoMeseLungoFormato.string(from: data)
    }

    /// "18:30"
    static func ora(_ data: Date) -> String {
        oraFormato.string(from: data)
    }

    /// "Ottobre 2026"
    static func meseAnno(_ data: Date) -> String {
        let s = meseAnnoFormato.string(from: data)
        guard let primo = s.first else { return s }
        return String(primo).uppercased() + s.dropFirst()
    }

    /// 18.5 -> "18,5"
    static func decimale(_ valore: Double) -> String {
        decimaleFormato.string(from: NSNumber(value: valore)) ?? String(format: "%.1f", valore)
    }

    /// "+" per i valori positivi o nulli, "−" (segno meno vero) per i negativi.
    static func segno(_ valore: Double) -> String {
        valore < 0 ? "\u{2212}" : "+"
    }

    static func segno(_ valore: Int) -> String {
        valore < 0 ? "\u{2212}" : "+"
    }

    /// Calendario italiano (settimana dal lunedì) anche per i nomi dei giorni.
    static var calendario: Calendar {
        var c = Calendar.italiano
        c.locale = locale
        return c
    }

    /// Iniziali dei giorni, dal lunedì: L M M G V S D.
    static var inizialiGiorni: [String] {
        let simboli = calendario.veryShortWeekdaySymbols   // dalla domenica: D L M M G V S
        guard simboli.count == 7 else { return ["L", "M", "M", "G", "V", "S", "D"] }
        return [1, 2, 3, 4, 5, 6, 0].map { simboli[$0] }
    }

    /// Tempo di una vasca: sotto i 100 secondi "31,4 s", oltre "1:42".
    static func tempoVasca(_ secondi: Double) -> String {
        if secondi < 100 {
            return testo("dettaglio.vasche.secondi", decimale(secondi))
        }
        return FormatoRitmo.minutiSecondi(secondi)
    }

    /// "800 m" con le migliaia separate (1.250 m).
    static func metri(_ metri: Int) -> String {
        testo("dettaglio.valore.metri", FormatiUI.numero(metri))
    }

    /// "1:30 / 100 m". Nil se manca il ritmo.
    static func ritmo(_ nuotata: NuotataCompletata) -> String? {
        guard let r = nuotata.ritmoPer100Secondi else { return nil }
        return testo("dettaglio.valore.ritmo", FormatoRitmo.minutiSecondi(r))
    }

    /// Il titolo della nuotata, o una parola generica se è vuoto.
    static func titolo(_ nuotata: NuotataCompletata) -> String {
        nuotata.titolo.isEmpty ? testo("dettaglio.titolo.predefinito") : nuotata.titolo
    }
}
