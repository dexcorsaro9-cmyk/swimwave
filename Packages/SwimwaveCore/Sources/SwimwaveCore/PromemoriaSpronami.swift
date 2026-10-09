import Foundation

/// Promemoria del ritmo "Spronami": l'unico ritmo che può mandare notifiche (docs/PRODUCT.md).
/// Logica pura: dice a quali date mandare un promemoria; le notifiche vere le programma l'app.
/// Regole: al massimo uno al giorno, mai nei giorni in cui hai già nuotato, solo se l'obiettivo della settimana
/// non è ancora raggiunto, sempre alla stessa ora, tono mai colpevolizzante.
public enum PromemoriaSpronami {
    public static let oraPredefinita = 18
    public static let minutoPredefinito = 30
    /// Orizzonte: settimana in corso e successiva (l'app riprogramma a ogni apertura).
    public static let massimoPromemoria = 14

    public static func date(
        profilo: Profilo,
        nuotate: [Date],
        adesso: Date = Date(),
        ora: Int = oraPredefinita,
        minuto: Int = minutoPredefinito,
        calendar: Calendar = .italiano
    ) -> [Date] {
        guard profilo.ritmo == .spronami, let obiettivo = profilo.obiettivoSettimanale,
              let questa = calendar.dateInterval(of: .weekOfYear, for: adesso),
              let prossima = calendar.dateInterval(of: .weekOfYear, for: questa.end) else { return [] }

        let giorniNuotati = Set(nuotate.map { calendar.startOfDay(for: $0) })
        var risultato: [Date] = []

        for (settimana, target) in [(questa, max(0, obiettivo - ObiettivoSettimanale.conteggio(date: nuotate, rispetto: adesso, calendar: calendar))),
                                    (prossima, obiettivo)] {
            guard target > 0 else { continue }
            // Giorni candidati: dall'oggi (se l'ora del promemoria non è passata) alla fine della settimana, senza giorni già nuotati.
            var candidati: [Date] = []
            var giorno = max(calendar.startOfDay(for: adesso), settimana.start)
            while giorno < settimana.end {
                if let momento = calendar.date(bySettingHour: ora, minute: minuto, second: 0, of: giorno),
                   momento > adesso, !giorniNuotati.contains(giorno) {
                    candidati.append(momento)
                }
                guard let successivo = calendar.date(byAdding: .day, value: 1, to: giorno) else { break }
                giorno = successivo
            }
            risultato += distribuisci(candidati, quanti: target)
        }
        return Array(risultato.prefix(massimoPromemoria))
    }

    /// Sceglie `quanti` date ben distanziate tra i candidati (tutte se sono meno o uguali).
    static func distribuisci(_ candidati: [Date], quanti: Int) -> [Date] {
        guard quanti > 0, !candidati.isEmpty else { return [] }
        if quanti >= candidati.count { return candidati }
        return (0..<quanti).map { i in
            let posizione = (Double(i) + 0.5) * Double(candidati.count) / Double(quanti)
            return candidati[min(candidati.count - 1, Int(posizione))]
        }
    }
}
