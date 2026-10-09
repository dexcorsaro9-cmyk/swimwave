import XCTest
@testable import SwimwaveCore

final class ContentStoreTests: XCTestCase {
    private func contenutoFinto(stato: String) -> (String) -> Data? {
        let file: [String: String] = [
            "percorso.json": """
            {"tappe":[{"id":2,"nome":"B","obiettivo":"o","test":"t","drill":["d1"],"errori":[],"fonti":[],"stato":"\(stato)"},
                      {"id":1,"nome":"A","obiettivo":"o","test":"t","drill":[],"errori":[],"fonti":[],"stato":"approvato"}]}
            """,
            "drills.json": """
            {"drill":[{"id":"d1","nome":"Drill uno","tappa":1,"scopo":"s","esecuzione":"e","errore_da_evitare":"x","fonti":[],"stato":"\(stato)"}]}
            """,
            "errori-comuni.json": #"{"errori":[]}"#,
            "allenamenti/indice.json": """
            {"allenamenti":[
              {"file":"a.json","livello":"principiante","obiettivi":["tecnica"],"tappe":[1],"stato":"\(stato)"},
              {"file":"b.json","livello":"principiante","obiettivi":["resistenza"],"tappe":[2],"stato":"\(stato)"},
              {"file":"c.json","livello":"intermedio","obiettivi":["tecnica"],"tappe":[3],"stato":"\(stato)"}]}
            """,
            "allenamenti/a.json": """
            {"titolo":"A","vasca_metri":25,"durata_stimata_min":20,"blocchi":[{"tipo":"tecnica","serie":[{"ripetizioni":2,"distanza_m":25,"stile":"libero","drill":"d1"}]}]}
            """,
            "allenamenti/b.json": """
            {"titolo":"B","vasca_metri":25,"durata_stimata_min":20,"blocchi":[{"tipo":"principale","serie":[{"ripetizioni":2,"distanza_m":75,"stile":"libero"}]}]}
            """,
        ]
        return { file[$0].map { Data($0.utf8) } }
    }

    func testUtentiVedonoSoloApprovati() {
        let store = ContentStore(includeBozze: false, lettore: contenutoFinto(stato: "bozza"))
        XCTAssertEqual(store.tappe.map(\.id), [1])      // la tappa 1 è approvata, la 2 è bozza
        XCTAssertTrue(store.drill.isEmpty)
        XCTAssertTrue(store.voci.isEmpty)
        XCTAssertNil(store.scegliRiserva(profilo: Profilo(livello: .menoDi25), scelta: 0))
    }

    func testInDebugSiVedonoLeBozzeOrdinate() {
        let store = ContentStore(includeBozze: true, lettore: contenutoFinto(stato: "bozza"))
        XCTAssertEqual(store.tappe.map(\.id), [1, 2])
        XCTAssertEqual(store.drill(id: "d1")?.nome, "Drill uno")
        XCTAssertEqual(store.voci.count, 3)
    }

    func testScegliRiservaPerObiettivoELivello() throws {
        let store = ContentStore(includeBozze: true, lettore: contenutoFinto(stato: "bozza"))
        let tecnica = try XCTUnwrap(store.scegliRiserva(profilo: Profilo(livello: .menoDi25, obiettivo: .tecnica), scelta: 0))
        XCTAssertEqual(tecnica.titolo, "A")
        let resistenza = try XCTUnwrap(store.scegliRiserva(profilo: Profilo(livello: .menoDi25, obiettivo: .resistenza), scelta: 7))
        XCTAssertEqual(resistenza.titolo, "B")
        // "Stare bene" usa le riserve di tecnica
        let bene = try XCTUnwrap(store.scegliRiserva(profilo: Profilo(livello: .menoDi25, obiettivo: .stareBene), scelta: 0))
        XCTAssertEqual(bene.titolo, "A")
    }

    func testRiservaSaltaIlFileMancante() throws {
        // c.json (intermedio) non esiste: nessun allenamento valido per l'intermedio
        let store = ContentStore(includeBozze: true, lettore: contenutoFinto(stato: "bozza"))
        XCTAssertNil(store.scegliRiserva(profilo: Profilo(livello: .cento), scelta: 0))
    }

    func testAdattaVascaA50() {
        let w = Workout(titolo: "x", vascaMetri: 25, durataStimataMin: 20, blocchi: [
            Blocco(tipo: .principale, serie: [Serie(ripetizioni: 1, distanzaMetri: 25, stile: .libero),
                                              Serie(ripetizioni: 1, distanzaMetri: 125, stile: .libero)])])
        let a = Riserva.adattaVasca(w, vascaMetri: 50)
        XCTAssertEqual(a.vascaMetri, 50)
        XCTAssertEqual(a.blocchi[0].serie[0].distanzaMetri, 50)
        XCTAssertEqual(a.blocchi[0].serie[1].distanzaMetri, 150)  // 2.5 arrotonda a 3 x 50
        XCTAssertEqual(Riserva.adattaVasca(w, vascaMetri: 25), w)
    }

    func testContenutoMancanteNonRompe() {
        let store = ContentStore(includeBozze: true, lettore: { _ in nil })
        XCTAssertTrue(store.tappe.isEmpty)
        XCTAssertEqual(store.problemi.count, 5)   // percorso, drill, errori, indice, zone-ritmo
    }

    // Controlla che i file veri in content/ siano leggibili dal modello Swift e che le riserve passino la validazione.
    func testContenutiRealiDelRepository() throws {
        let radice = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let cartella = radice.appendingPathComponent("content")
        try XCTSkipUnless(FileManager.default.fileExists(atPath: cartella.appendingPathComponent("percorso.json").path),
                          "cartella content non trovata")
        let store = ContentStore(includeBozze: true) { try? Data(contentsOf: cartella.appendingPathComponent($0)) }
        XCTAssertEqual(store.problemi, [])
        XCTAssertEqual(store.tappe.count, 10)
        // I contenuti crescono con le revisioni: non fissiamo i numeri, solo che ci siano.
        XCTAssertFalse(store.drill.isEmpty)
        XCTAssertFalse(store.errori.isEmpty)
        XCTAssertFalse(store.voci.isEmpty)
        for voce in store.voci {
            XCTAssertNotNil(store.workout(della: voce), "\(voce.file) non è valido")
        }
        // Gli utenti finali oggi non vedono nulla: tutto è in bozza.
        let utente = ContentStore(includeBozze: false) { try? Data(contentsOf: cartella.appendingPathComponent($0)) }
        XCTAssertEqual(utente.problemi, [])
    }
}
