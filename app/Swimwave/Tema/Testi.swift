import Foundation
import SwiftUI
import SwimwaveCore

/// Testo localizzato da una chiave di Localizable.xcstrings.
/// Per i testi fissi nelle viste si scrive direttamente `Text("chiave.del.testo")`;
/// questa funzione serve dove la chiave è una variabile o dove serve una String.
func testo(_ chiave: String) -> String {
    NSLocalizedString(chiave, comment: "")
}

/// Testo localizzato con segnaposto (%@, %d), per esempio "Buongiorno, %@".
func testo(_ chiave: String, _ argomenti: CVarArg...) -> String {
    String(format: NSLocalizedString(chiave, comment: ""), arguments: argomenti)
}

// Etichette dei valori del profilo. Una chiave per valore, scritta per esteso così si può cercare.

extension Livello {
    var etichetta: String {
        switch self {
        case .menoDi25: return testo("livello.menoDi25")
        case .menoDi100: return testo("livello.menoDi100")
        case .cento: return testo("livello.cento")
        case .piuDiCento: return testo("livello.piuDiCento")
        }
    }
}

extension Obiettivo {
    var etichetta: String {
        switch self {
        case .tecnica: return testo("obiettivo.tecnica")
        case .resistenza: return testo("obiettivo.resistenza")
        case .dimagrimento: return testo("obiettivo.dimagrimento")
        case .stareBene: return testo("obiettivo.stareBene")
        }
    }
}

extension Vasca {
    var etichetta: String {
        switch self {
        case .metri25: return testo("vasca.metri25")
        case .metri50: return testo("vasca.metri50")
        case .nonLoSo: return testo("vasca.nonLoSo")
        }
    }
}

extension Ritmo {
    var etichetta: String {
        switch self {
        case .libero: return testo("ritmo.libero")
        case .regolare: return testo("ritmo.regolare")
        case .spronami: return testo("ritmo.spronami")
        }
    }

    var descrizione: String {
        switch self {
        case .libero: return testo("ritmo.libero.descrizione")
        case .regolare: return testo("ritmo.regolare.descrizione")
        case .spronami: return testo("ritmo.spronami.descrizione")
        }
    }
}

extension Stile {
    var etichetta: String {
        switch self {
        case .libero: return testo("stile.libero")
        case .dorso: return testo("stile.dorso")
        case .rana: return testo("stile.rana")
        case .delfino: return testo("stile.delfino")
        case .misto: return testo("stile.misto")
        }
    }
}

extension Intensita {
    var etichetta: String {
        switch self {
        case .facile: return testo("intensita.facile")
        case .media: return testo("intensita.media")
        case .forte: return testo("intensita.forte")
        }
    }
}

extension TipoBlocco {
    var etichetta: String {
        switch self {
        case .riscaldamento: return testo("blocco.riscaldamento")
        case .tecnica: return testo("blocco.tecnica")
        case .principale: return testo("blocco.principale")
        case .defaticamento: return testo("blocco.defaticamento")
        }
    }
}

extension FasciaOraria {
    /// "Buongiorno, %@" / "Buon pomeriggio, %@" / "Buonasera, %@"
    func saluto(nome: String) -> String {
        switch self {
        case .mattina: return testo("saluto.mattina", nome)
        case .pomeriggio: return testo("saluto.pomeriggio", nome)
        case .sera: return testo("saluto.sera", nome)
        }
    }
}

extension CoachID {
    /// Presentazione breve per la scelta del coach. Non usa content/coach.json (che è in bozza e parla di "coach virtuale"):
    /// che i coach siano virtuali si dice in una riga nella scelta e nelle Informazioni (docs/POPUP_COACH.md).
    var presentazione: String {
        switch self {
        case .uomo: return testo("coach.presentazione.uomo")
        case .donna: return testo("coach.presentazione.donna")
        }
    }
}

extension Workout {
    /// Riga di descrizione di una serie: "4 × 50 m · Stile libero · Catch-up · recupero 15 s".
    /// I nomi dei drill vengono da content/drills.json (testo in italiano, non localizzato).
    func descrizione(di serie: Serie, nomeDrill: (String) -> String?) -> String {
        var parti: [String] = [testo("serie.formato", serie.ripetizioni, serie.distanzaMetri), serie.stile.etichetta]
        if let intensita = serie.intensita { parti.append(intensita.etichetta) }
        if let drill = serie.drill { parti.append(nomeDrill(drill) ?? drill) }
        if let recupero = serie.recuperoSecondi, recupero > 0 { parti.append(testo("serie.recupero", recupero)) }
        return parti.joined(separator: " · ")
    }
}
