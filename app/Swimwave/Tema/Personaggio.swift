import SwiftUI
import UIKit

/// Un foglio di fotogrammi (sprite sheet a 9 colonne) di un personaggio per l'iPhone.
struct FoglioPersonaggio {
    let nome: String
    let totale: Int
    /// Altezza / larghezza di un fotogramma.
    let proporzione: CGFloat
    static let colonne = 9

    /// Righe del foglio: i fotogrammi sono messi in fila, 9 per riga.
    var righe: Int { (totale + Self.colonne - 1) / Self.colonne }
}

/// I personaggi acquatici che accompagnano l'utente: nessuno ha un nome, solo la specie.
/// Si sceglie al primo avvio e si cambia dal Profilo (`Profilo.personaggio`).
///
/// COME SI AGGIUNGE UN PERSONAGGIO: dai video di Flow `tools/crea_fogli_personaggio.py` crea i fogli
/// (`<id>-nuota-sheet`, `<id>-festa-sheet`, `<id>-stanco-sheet` per l'iPhone, più concentrato e attesa per il Watch) e stampa
/// numero di fotogrammi e proporzione: vanno riportati qui e in app/SwimwaveWatch/Squalo.swift.
/// Finché i fogli non ci sono il personaggio non compare nella scelta.
struct Personaggio: Identifiable, Equatable {
    let id: String
    /// Chiave in Localizable.xcstrings con la specie ("Squalo", "Delfino"…).
    let chiaveSpecie: String
    let nuota: FoglioPersonaggio
    let festa: FoglioPersonaggio
    let stanco: FoglioPersonaggio
    /// Dove nascono le bolle, in frazioni del fotogramma di nuoto (x da sinistra, y dall'alto). Predefinito: il muso dello squalo.
    var bocca = CGPoint(x: 0.9, y: 0.55)

    static func == (a: Personaggio, b: Personaggio) -> Bool { a.id == b.id }

    static let squalo = Personaggio(
        id: "squalo",
        chiaveSpecie: "personaggio.squalo",
        nuota: FoglioPersonaggio(nome: "squalo-nuota-sheet", totale: 44, proporzione: 123.0 / 240.0),
        festa: FoglioPersonaggio(nome: "squalo-festa-sheet", totale: 42, proporzione: 121.0 / 200.0),
        stanco: FoglioPersonaggio(nome: "squalo-stanco-sheet", totale: 44, proporzione: 105.0 / 200.0)
    )

    static let delfino = Personaggio(
        id: "delfino",
        chiaveSpecie: "personaggio.delfino",
        nuota: FoglioPersonaggio(nome: "delfino-nuota-sheet", totale: 20, proporzione: 110.0 / 240.0),
        festa: FoglioPersonaggio(nome: "delfino-festa-sheet", totale: 44, proporzione: 112.0 / 200.0),
        stanco: FoglioPersonaggio(nome: "delfino-stanco-sheet", totale: 44, proporzione: 90.0 / 200.0),
        bocca: CGPoint(x: 0.94, y: 0.5)
    )

    static let tartaruga = Personaggio(
        id: "tartaruga",
        chiaveSpecie: "personaggio.tartaruga",
        nuota: FoglioPersonaggio(nome: "tartaruga-nuota-sheet", totale: 37, proporzione: 123.0 / 240.0),
        festa: FoglioPersonaggio(nome: "tartaruga-festa-sheet", totale: 44, proporzione: 119.0 / 200.0),
        stanco: FoglioPersonaggio(nome: "tartaruga-stanco-sheet", totale: 44, proporzione: 99.0 / 200.0),
        bocca: CGPoint(x: 0.94, y: 0.4)
    )

    static let manta = Personaggio(
        id: "manta",
        chiaveSpecie: "personaggio.manta",
        nuota: FoglioPersonaggio(nome: "manta-nuota-sheet", totale: 35, proporzione: 99.0 / 240.0),
        festa: FoglioPersonaggio(nome: "manta-festa-sheet", totale: 44, proporzione: 122.0 / 200.0),
        stanco: FoglioPersonaggio(nome: "manta-stanco-sheet", totale: 44, proporzione: 86.0 / 200.0),
        bocca: CGPoint(x: 0.93, y: 0.45)
    )

    static let polpo = Personaggio(
        id: "polpo",
        chiaveSpecie: "personaggio.polpo",
        nuota: FoglioPersonaggio(nome: "polpo-nuota-sheet", totale: 30, proporzione: 202.0 / 240.0),
        festa: FoglioPersonaggio(nome: "polpo-festa-sheet", totale: 44, proporzione: 169.0 / 200.0),
        stanco: FoglioPersonaggio(nome: "polpo-stanco-sheet", totale: 44, proporzione: 160.0 / 200.0),
        bocca: CGPoint(x: 0.62, y: 0.3)
    )

    static let pinguino = Personaggio(
        id: "pinguino",
        chiaveSpecie: "personaggio.pinguino",
        nuota: FoglioPersonaggio(nome: "pinguino-nuota-sheet", totale: 44, proporzione: 140.0 / 240.0),
        festa: FoglioPersonaggio(nome: "pinguino-festa-sheet", totale: 44, proporzione: 149.0 / 200.0),
        stanco: FoglioPersonaggio(nome: "pinguino-stanco-sheet", totale: 44, proporzione: 108.0 / 200.0),
        bocca: CGPoint(x: 0.96, y: 0.38)
    )

    /// Tutti i personaggi previsti, il primo è quello di partenza.
    static let tutti: [Personaggio] = [squalo, delfino, tartaruga, manta, polpo, pinguino]

    /// Quelli che hanno davvero i fogli nell'app: solo questi si possono scegliere.
    static var disponibili: [Personaggio] {
        tutti.filter { UIImage(named: $0.nuota.nome) != nil }
    }

    /// Il personaggio scelto, o lo squalo se l'id manca o non è più disponibile.
    static func con(id: String?) -> Personaggio {
        disponibili.first { $0.id == id } ?? squalo
    }
}
