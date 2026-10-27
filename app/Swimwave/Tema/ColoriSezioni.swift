import SwiftUI
import SwimwaveCore

/// Ogni parte dell'app ha il suo colore, così non è tutta blu e celeste (bozze: docs/mockup/oggi-direzioni.html):
/// Oggi cambia con la tipologia, Percorso è verde acqua, Storico arancio, Profilo viola, Progressi bacca.
enum SezioneColore {
    case percorso, storico, profilo, analisi

    /// Gradiente dell'intestazione: dallo scuro (dove sta il titolo, a sinistra in alto) al più chiaro.
    var gradiente: [Color] {
        switch self {
        case .percorso: return [Color(squaloHex: 0x0B5E52), Color(squaloHex: 0x1F9F82)]
        case .storico: return [Color(squaloHex: 0xAE3F18), Color(squaloHex: 0xE0702C)]
        case .profilo: return [Color(squaloHex: 0x37278A), Color(squaloHex: 0x6B49D6)]
        case .analisi: return [Color(squaloHex: 0x8F2662), Color(squaloHex: 0xCC4482)]
        }
    }

    /// Colore degli accenti (icone, segni sulle carte, grafici).
    var accento: Color {
        switch self {
        case .percorso: return Color(squaloHex: 0x2BB594)
        case .storico: return Color(squaloHex: 0xFF8A4C)
        case .profilo: return Color(squaloHex: 0x9B6BFF)
        case .analisi: return Color(squaloHex: 0xE0508F)
        }
    }
}

/// Un colore per ogni tappa del percorso: dal verde menta al giallo, come un arcobaleno di progressi.
enum PaletteTappe {
    private static let valori: [UInt32] = [
        0x5CCB9B, 0x38C7A8, 0x1FB5C9, 0x3FA5E8, 0x5C8DF0, 0x8A6BF5, 0xB45CE0, 0xE0508F, 0xFF8A4C, 0xFFC857
    ]

    static func colore(_ tappa: Int) -> Color {
        Color(squaloHex: valori[((tappa - 1) % valori.count + valori.count) % valori.count])
    }

    /// Testo sopra il colore della tappa: bianco sui toni scuri (indaco, viola, rosa), navy sugli altri.
    static func testoSu(_ tappa: Int) -> Color {
        (6...8).contains(tappa) ? .white : Tema.navy
    }
}

extension Sensazione {
    /// Facile verde, giusta turchese, dura arancio.
    var colore: Color {
        switch self {
        case .facile: return Color(squaloHex: 0x5CCB9B)
        case .giusta: return Color(squaloHex: 0x1FB5C9)
        case .dura: return Color(squaloHex: 0xFF8A4C)
        }
    }
}

/// Una pillola di testo su un colore pieno (per la sensazione di una nuotata e simili).
struct PillolaColore: View {
    let testoPillola: String
    let colore: Color
    var testoSuColore: Color = Tema.navy

    var body: some View {
        Text(verbatim: testoPillola)
            .font(Tema.piccolo.weight(.heavy))
            .foregroundStyle(testoSuColore)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(colore))
    }
}

/// Colori per le righe del Profilo (uno per voce, sempre lo stesso per la stessa voce).
enum PalettePagine {
    private static let valori: [UInt32] = [0x9B6BFF, 0x1FB5C9, 0xFFC857, 0xFF8A4C, 0x5CCB9B, 0xE0508F]

    static func colore(per titolo: String) -> Color {
        let somma = titolo.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Color(squaloHex: valori[somma % valori.count])
    }
}
