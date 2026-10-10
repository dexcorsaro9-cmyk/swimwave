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

    func testAdattaVascaAMisureNonConvenzionali() {
        let w = Workout(titolo: "x", vascaMetri: 25, durataStimataMin: 20, blocchi: [
            Blocco(tipo: .principale, serie: [Serie(ripetizioni: 1, distanzaMetri: 25, stile: .libero),
                                              Serie(ripetizioni: 1, distanzaMetri: 100, stile: .libero),
                                              Serie(ripetizioni: 1, distanzaMetri: 2000, stile: .libero)])])
        let a33 = Riserva.adattaVasca(w, vascaMetri: 33)
        XCTAssertEqual(a33.blocchi[0].serie.map(\.distanzaMetri), [33, 99, 1980])
        let a20 = Riserva.adattaVasca(w, vascaMetri: 20)
        XCTAssertEqual(a20.vascaMetri, 20)
        XCTAssertEqual(a20.blocchi[0].serie.map(\.distanzaMetri), [20, 100, 2000])
        // Il risultato deve rispettare la regola "distanza multipla della vasca".
        for v in [16, 20, 33, 50] {
            let r = Riserva.adattaVasca(w, vascaMetri: v)
            for s in r.blocchi[0].serie { XCTAssertEqual(s.distanzaMetri % v, 0) }
        }
    }

    func testAttrezzaturaDagliDrill() {
        let file: [String: String] = [
            "drills.json": """
            {"drill":[
              {"id":"t","nome":"T","tappa":1,"scopo":"s","esecuzione":"e","errore_da_evitare":"x","fonti":[],"stato":"approvato","attrezzi":["tavoletta"]},
              {"id":"p","nome":"P","tappa":1,"scopo":"s","esecuzione":"e","errore_da_evitare":"x","fonti":[],"stato":"approvato","attrezzi":["pull_buoy"],"attrezzi_facoltativi":["pinne","tavoletta"]},
              {"id":"f","nome":"F","tappa":1,"scopo":"s","esecuzione":"e","errore_da_evitare":"x","fonti":[],"stato":"approvato","attrezzi_facoltativi":["pinne","remo"]},
              {"id":"n","nome":"N","tappa":1,"scopo":"s","esecuzione":"e","errore_da_evitare":"x","fonti":[],"stato":"approvato"}]}
            """,
        ]
        let store = ContentStore(includeBozze: false, lettore: { file[$0].map { Data($0.utf8) } })
        func serie(_ d: String?) -> Serie { Serie(ripetizioni: 1, distanzaMetri: 25, stile: .libero, drill: d) }
        let w = Workout(titolo: "x", vascaMetri: 25, durataStimataMin: 20, blocchi: [
            Blocco(tipo: .tecnica, serie: [serie("t"), serie("p"), serie("f"), serie("n"), serie(nil), serie("t")])])
        let a = store.attrezzatura(per: w)
        XCTAssertEqual(a.necessari, [.tavoletta, .pullBuoy])
        XCTAssertEqual(a.facoltativi, [.pinne])  // tavoletta è già necessaria, "remo" è sconosciuto
        let senza = Workout(titolo: "y", vascaMetri: 25, durataStimataMin: 20, blocchi: [
            Blocco(tipo: .principale, serie: [serie("n"), serie(nil)])])
        XCTAssertTrue(store.attrezzatura(per: senza).isVuota)
    }

    private func allenamentoDiProva() -> Workout {
        Workout(titolo: "x", vascaMetri: 25, durataStimataMin: 30, blocchi: [
            Blocco(tipo: .riscaldamento, serie: [Serie(ripetizioni: 4, distanzaMetri: 25, stile: .libero, recuperoSecondi: 15)]),
            Blocco(tipo: .principale, serie: [Serie(ripetizioni: 4, distanzaMetri: 50, stile: .libero, recuperoSecondi: 20),
                                              Serie(ripetizioni: 1, distanzaMetri: 100, stile: .libero)])])
    }

    func testAlleggerisciPerIlFiatoAllungaIRecuperi() {
        let a = Riserva.alleggerisci(allenamentoDiProva(), motivo: .fiato)
        XCTAssertEqual(a.blocchi[0].serie[0].recuperoSecondi, 25)  // 15 x 1,5 = 22,5 -> 25
        XCTAssertEqual(a.blocchi[1].serie[0].recuperoSecondi, 30)
        XCTAssertNil(a.blocchi[1].serie[1].recuperoSecondi)         // senza recupero resta senza
        XCTAssertEqual(a.blocchi[1].serie[0].ripetizioni, 4)
        XCTAssertGreaterThan(a.durataStimataMin, 30)
    }

    func testAlleggerisciPerLaStanchezzaTogliRipetizioniSoloAlPrincipale() {
        let a = Riserva.alleggerisci(allenamentoDiProva(), motivo: .stanchezza)
        XCTAssertEqual(a.blocchi[0].serie[0].ripetizioni, 4)  // riscaldamento invariato
        XCTAssertEqual(a.blocchi[1].serie[0].ripetizioni, 3)  // 4 -> 3
        XCTAssertEqual(a.blocchi[1].serie[1].ripetizioni, 1)  // una sola ripetizione resta
        XCTAssertLessThan(a.durataStimataMin, 30)
        XCTAssertGreaterThanOrEqual(a.durataStimataMin, 5)
    }

    func testAlleggerisciSenzaMotivoOConEsercizioNonCambiaNulla() {
        let w = allenamentoDiProva()
        XCTAssertEqual(Riserva.alleggerisci(w, motivo: nil), w)
        XCTAssertEqual(Riserva.alleggerisci(w, motivo: .esercizio), w)
        XCTAssertEqual(Riserva.alleggerisci(w, motivo: .altro), w)
    }

    func testAlleggerisciRestaValido() {
        for m in [MotivoDifficolta.fiato, .stanchezza] {
            let a = Riserva.alleggerisci(allenamentoDiProva(), motivo: m)
            XCTAssertTrue(WorkoutValidator.validate(a, allowedDrills: []).isEmpty)
        }
    }

    func testMotivoEsercizioScegliTraGliAllenamentiPiuSemplici() {
        func voce(_ f: String, _ tappe: [Int]) -> VoceAllenamento {
            VoceAllenamento(file: f, livello: "principiante", obiettivi: ["tecnica"], tappe: tappe, stato: .approvato)
        }
        let voci = [voce("alto.json", [8]), voce("medio.json", [5]), voce("basso.json", [2]), voce("medio2.json", [6])]
        for scelta in 0..<8 {
            let v = Riserva.scegli(voci: voci, categoria: .principiante, obiettivo: .tecnica, scelta: scelta, motivo: .esercizio)
            XCTAssertTrue(["basso.json", "medio.json"].contains(v?.file ?? ""), v?.file ?? "nil")
        }
        // Senza motivo restano tutte possibili.
        let tutte = Set((0..<4).compactMap { Riserva.scegli(voci: voci, categoria: .principiante, obiettivo: .tecnica, scelta: $0)?.file })
        XCTAssertEqual(tutte.count, 4)
    }

    func testMotivoSiUniscePerNuotataDaDueFonti() {
        let a = NuotataCompletata(data: Date(), metri: 500, durataSecondi: 900, titolo: "t", sensazione: .dura, motivoDifficolta: .fiato)
        let b = NuotataCompletata(id: a.id, data: a.data, metri: 500, durataSecondi: 900, titolo: "t")
        XCTAssertEqual(b.unendo(a).motivoDifficolta, .fiato)
        XCTAssertEqual(a.unendo(b).motivoDifficolta, .fiato)
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

final class EfficienzaTests: XCTestCase {
    private func nuotata(giorno: Int, bracciate: Int?, vasca: Int? = 25, metri: Int = 500,
                         ambiente: AmbienteNuoto? = .vasca) -> NuotataCompletata {
        let data = Date(timeIntervalSince1970: 1_700_000_000 + Double(giorno) * 86_400)
        return NuotataCompletata(data: data, metri: metri, durataSecondi: 900, titolo: "x",
                                 bracciate: bracciate, vascaMetri: vasca, ambiente: ambiente)
    }

    func testMenoBracciateDellUltimaVolta() {
        // 500 m in vasca da 25 = 20 vasche: 400 bracciate = 20 per vasca; 360 = 18.
        let prima = nuotata(giorno: 1, bracciate: 400)
        let oggi = nuotata(giorno: 3, bracciate: 360)
        guard case .meno(let o, let p)? = Efficienza.confronto(di: oggi, con: [prima, oggi]) else {
            return XCTFail("atteso .meno")
        }
        XCTAssertEqual(o, 18, accuracy: 0.001)
        XCTAssertEqual(p, 20, accuracy: 0.001)
    }

    func testPiuEUgualiConSoglia() {
        let prima = nuotata(giorno: 1, bracciate: 400)                       // 20
        XCTAssertEqual(Efficienza.confronto(di: nuotata(giorno: 2, bracciate: 440), con: [prima]),
                       .piu(oggi: 22, prima: 20))
        XCTAssertEqual(Efficienza.confronto(di: nuotata(giorno: 2, bracciate: 410), con: [prima]),
                       .simile(oggi: 20.5, prima: 20))
        // Differenza di esattamente una bracciata per vasca: conta.
        XCTAssertEqual(Efficienza.confronto(di: nuotata(giorno: 2, bracciate: 380), con: [prima]),
                       .meno(oggi: 19, prima: 20))
    }

    func testUsaSoloL_UltimaConfrontabile() {
        let vecchia = nuotata(giorno: 1, bracciate: 500)                       // 25
        let altraVasca = nuotata(giorno: 2, bracciate: 200, vasca: 50)         // altra lunghezza
        let acqueLibere = nuotata(giorno: 3, bracciate: 300, ambiente: .acqueLibere)
        let senzaDato = nuotata(giorno: 4, bracciate: nil)
        let futura = nuotata(giorno: 9, bracciate: 100)
        let oggi = nuotata(giorno: 5, bracciate: 400)                          // 20
        XCTAssertEqual(Efficienza.confronto(di: oggi, con: [vecchia, altraVasca, acqueLibere, senzaDato, futura]),
                       .meno(oggi: 20, prima: 25))
    }

    func testSenzaConfrontoONessunDato() {
        XCTAssertNil(Efficienza.confronto(di: nuotata(giorno: 2, bracciate: 400), con: []))
        XCTAssertNil(Efficienza.confronto(di: nuotata(giorno: 2, bracciate: nil), con: [nuotata(giorno: 1, bracciate: 400)]))
        XCTAssertNil(Efficienza.confronto(di: nuotata(giorno: 2, bracciate: 400, ambiente: .acqueLibere),
                                          con: [nuotata(giorno: 1, bracciate: 400)]))
    }

    func testDistribuzioneStili() {
        let v = [SplitVasca(metri: 25, durataSecondi: 30, stile: .libero), SplitVasca(metri: 25, durataSecondi: 30, stile: .libero),
                 SplitVasca(metri: 25, durataSecondi: 30, stile: .libero), SplitVasca(metri: 25, durataSecondi: 40, stile: .dorso),
                 SplitVasca(metri: 25, durataSecondi: 40, stile: nil)]
        let q = Efficienza.distribuzioneStili(v)
        XCTAssertEqual(q.map(\.stile), [.libero, .dorso])
        XCTAssertEqual(q.map(\.metri), [75, 25])
        XCTAssertEqual(q.map(\.percentuale), [75, 25])
    }

    func testPercentualiSommanoSempreCento() {
        // Tre stili uguali: 33 + 33 + 33 = 99, il punto che manca va al primo nell'ordine.
        let v = [Stile.libero, .dorso, .rana].map { SplitVasca(metri: 25, durataSecondi: 30, stile: $0) }
        let q = Efficienza.distribuzioneStili(v)
        XCTAssertEqual(q.map(\.percentuale).reduce(0, +), 100)
        XCTAssertEqual(q.map(\.percentuale), [34, 33, 33])
        XCTAssertEqual(q.map(\.stile), [.libero, .dorso, .rana])
        XCTAssertTrue(Efficienza.distribuzioneStili([]).isEmpty)
        XCTAssertTrue(Efficienza.distribuzioneStili([SplitVasca(metri: 25, durataSecondi: 30)]).isEmpty)
    }
}
