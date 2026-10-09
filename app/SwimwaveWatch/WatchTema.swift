import SwiftUI

/// Colori del Watch (docs/GRAFICA.md). Sfondo nero, nessuna immagine.
enum WatchTema {
    static let navy = Color(red: 11.0 / 255.0, green: 37.0 / 255.0, blue: 69.0 / 255.0)
    static let turchese = Color(red: 31.0 / 255.0, green: 181.0 / 255.0, blue: 201.0 / 255.0)
    static let corallo = Color(red: 255.0 / 255.0, green: 122.0 / 255.0, blue: 102.0 / 255.0)
}

/// "mm:ss", oppure "h:mm:ss" oltre l'ora.
func formattaTempo(_ secondi: TimeInterval) -> String {
    let totale = max(0, Int(secondi))
    let h = totale / 3600
    let m = (totale % 3600) / 60
    let s = totale % 60
    if h > 0 { return String(format: "%ld:%02ld:%02ld", h, m, s) }
    return String(format: "%02ld:%02ld", m, s)
}

/// Tempo obiettivo "m:ss" (per esempio 53 -> "0:53", 125 -> "2:05").
func formattaObiettivo(_ secondi: Int) -> String {
    let totale = max(0, secondi)
    return String(format: "%ld:%02ld", totale / 60, totale % 60)
}
