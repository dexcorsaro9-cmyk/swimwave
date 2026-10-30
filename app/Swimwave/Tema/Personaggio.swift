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
        nuota: FoglioPersonaggio(nome: "delfino-nuota-sheet", totale: 19, proporzione: 135.0 / 240.0),
        festa: FoglioPersonaggio(nome: "delfino-festa-sheet", totale: 44, proporzione: 113.0 / 200.0),
        stanco: FoglioPersonaggio(nome: "delfino-stanco-sheet", totale: 44, proporzione: 91.0 / 200.0)
    )

    /// Tutti i personaggi previsti, il primo è quello di partenza.
    static let tutti: [Personaggio] = [squalo, delfino]

    /// Quelli che hanno davvero i fogli nell'app: solo questi si possono scegliere.
    static var disponibili: [Personaggio] {
        tutti.filter { UIImage(named: $0.nuota.nome) != nil }
    }

    /// Il personaggio scelto, o lo squalo se l'id manca o non è più disponibile.
    static func con(id: String?) -> Personaggio {
        disponibili.first { $0.id == id } ?? squalo
    }
}
