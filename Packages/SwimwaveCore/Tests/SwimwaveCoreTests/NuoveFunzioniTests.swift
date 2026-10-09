import XCTest
@testable import SwimwaveCore

final class SerieSettimaneTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar.italiano
        c.timeZone = TimeZone(identifier: "Europe/Rome")!
        return c
    }()

    private func data(_ giorno: Int, mese: Int = 10, ora: Int = 10) -> Date {
        cal.date(from: DateComponents(year: 2026, month: mese, day: giorno, hour: ora))!
    }

    private let regolare2 = Profilo(coach: .uomo, nome: "Luca", livello: .cento, ritmo: .regolare, frequenzaSettimanale: 2)

    // 9 ottobre 2026 è venerdì: settimana 5-11 ottobre. Settimane precedenti: 28 set-4 ott, 21-27 set.
    func testSettimanaCorrenteNonRaggiuntaNonInterrompe() {
        let nuotate = [data(30, mese: 9), data(1), data(22, mese: 9), data(24, mese: 9)]
        XCTAssertEqual(SerieSettimane.settimaneDiFila(profilo: regolare2, date: nuotate, rispetto: data(9), calendar: cal), 2)
    }

    func testSettimanaCorrenteRaggiuntaSiAggiunge() {
        let nuotate = [data(30, mese: 9), data(1), data(6), data(8)]
        XCTAssertEqual(SerieSettimane.settimaneDiFila(profilo: regolare2, date: nuotate, rispetto: data(9), calendar: cal), 2)
    }

    func testSettimanaSaltataFermaLaSerie() {
        // Raggiunta la settimana del 21-27 set, saltata quella del 28 set-4 ott.
        let nuotate = [data(22, mese: 9), data(24, mese: 9), data(6), data(8)]
        XCTAssertEqual(SerieSettimane.settimaneDiFila(profilo: regolare2, date: nuotate, rispetto: data(9), calendar: cal), 1)
    }

    func testLiberoBastaUnaNuotataASettimana() {
        let libero = Profilo(coach: .donna, nome: "Paola", livello: .menoDi25)
        let nuotate = [data(7), data(2), data(23, mese: 9)]
        XCTAssertEqual(SerieSettimane.settimaneDiFila(profilo: libero, date: nuotate, rispetto: data(9), calendar: cal), 3)
    }

    func testNessunaNuotata() {
        XCTAssertEqual(SerieSettimane.settimaneDiFila(profilo: regolare2, date: [], rispetto: data(9), calendar: cal), 0)
    }

    func testTraguardi() {
        XCTAssertEqual(SerieSettimane.traguardo(per: 4), 4)
        XCTAssertNil(SerieSettimane.traguardo(per: 5))
        XCTAssertEqual(SerieSettimane.prossimoTraguardo(dopo: 4), 8)
        XCTAssertNil(SerieSettimane.prossimoTraguardo(dopo: 52))
    }
}

final class PromemoriaSpronamiTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar.italiano
        c.timeZone = TimeZone(identifier: "Europe/Rome")!
        return c
    }()

    private func data(_ giorno: Int, ora: Int = 10, minuto: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 10, day: giorno, hour: ora, minute: minuto))!
    }

    private func profilo(_ ritmo: Ritmo, _ f: Int) -> Profilo {
        Profilo(coach: .uomo, nome: "Luca", livello: .cento, ritmo: ritmo, frequenzaSettimanale: f)
    }

    func testSoloSpronami() {
        XCTAssertTrue(PromemoriaSpronami.date(profilo: profilo(.regolare, 3), nuotate: [], adesso: data(5), calendar: cal).isEmpty)
        XCTAssertTrue(PromemoriaSpronami.date(profilo: profilo(.libero, 3), nuotate: [], adesso: data(5), calendar: cal).isEmpty)
    }

    func testUnoAlGiornoEAlleOreFisse() {
        // Lunedì 5 ottobre mattina, obiettivo 3: tre promemoria nella settimana + tre nella successiva.
        let date = PromemoriaSpronami.date(profilo: profilo(.spronami, 3), nuotate: [], adesso: data(5), calendar: cal)
        XCTAssertEqual(date.count, 6)
        let giorni = Set(date.map { cal.startOfDay(for: $0) })
        XCTAssertEqual(giorni.count, date.count)
        for d in date {
            XCTAssertEqual(cal.component(.hour, from: d), PromemoriaSpronami.oraPredefinita)
            XCTAssertEqual(cal.component(.minute, from: d), PromemoriaSpronami.minutoPredefinito)
            XCTAssertGreaterThan(d, data(5))
        }
    }

    func testObiettivoRaggiuntoNessunPromemoriaQuestaSettimana() {
        let nuotate = [data(5), data(6), data(7)]
        let date = PromemoriaSpronami.date(profilo: profilo(.spronami, 3), nuotate: nuotate, adesso: data(8), calendar: cal)
        // Solo la settimana successiva (dal 12 ottobre in poi).
        XCTAssertEqual(date.count, 3)
        XCTAssertTrue(date.allSatisfy { $0 >= data(12, ora: 0) })
    }

    func testNonNeiGiorniGiaNuotati() {
        let nuotate = [data(9)]
        let date = PromemoriaSpronami.date(profilo: profilo(.spronami, 3), nuotate: nuotate, adesso: data(9, ora: 12), calendar: cal)
        let giorni = date.map { cal.component(.day, from: $0) }
        XCTAssertFalse(giorni.contains(9))
    }

    func testOraPassataSaltaOggi() {
        // Venerdì 9 ore 20: il promemoria delle 18:30 di oggi è già passato.
        let date = PromemoriaSpronami.date(profilo: profilo(.spronami, 3), nuotate: [], adesso: data(9, ora: 20), calendar: cal)
        XCTAssertFalse(date.contains { cal.component(.day, from: $0) == 9 && cal.component(.month, from: $0) == 10 })
    }

    func testDistribuisci() {
        let giorni = (1...7).map { data($0, ora: 18, minuto: 30) }
        XCTAssertEqual(PromemoriaSpronami.distribuisci(giorni, quanti: 7), giorni)
        XCTAssertEqual(PromemoriaSpronami.distribuisci(giorni, quanti: 10), giorni)
        XCTAssertEqual(PromemoriaSpronami.distribuisci(giorni, quanti: 0), [])
        XCTAssertEqual(PromemoriaSpronami.distribuisci(giorni, quanti: 2).count, 2)
    }
}

final class ZoneRitmoTests: XCTestCase {
    func testRitmoCritico() {
        // 200 m in 3:00 (180 s) e 400 m in 6:30 (390 s): (390-180)/2 = 105 s ogni 100 m.
        let t = TestRitmo(tempo200Secondi: 180, tempo400Secondi: 390)
        XCTAssertEqual(t.ritmoCriticoPer100!, 105, accuracy: 0.0001)
    }

    func testTempiNonPlausibili() {
        XCTAssertNil(TestRitmo(tempo200Secondi: 180, tempo400Secondi: 300).ritmoCriticoPer100)  // 400 non oltre il doppio del 200
        XCTAssertNil(TestRitmo(tempo200Secondi: 0, tempo400Secondi: 300).ritmoCriticoPer100)
        XCTAssertNil(TestRitmo(tempo200Secondi: 180, tempo400Secondi: 360).ritmoCriticoPer100)  // uguale al doppio
    }

    func testIntervalloRitmoDellaZona() {
        let zona = ZonaRitmo(id: "x", nome: "Facile", descrizione: "", velocitaDaPercentuale: 80, velocitaAPercentuale: 90, fonti: [], stato: .bozza)
        let r = zona.intervalloRitmo(ritmoCriticoPer100: 90)!
        XCTAssertEqual(r.piuVeloce, 100, accuracy: 0.0001)   // 90 * 100 / 90
        XCTAssertEqual(r.piuLento, 112.5, accuracy: 0.0001)  // 90 * 100 / 80
    }

    func testFormato() {
        XCTAssertEqual(FormatoRitmo.minutiSecondi(95), "1:35")
        XCTAssertEqual(FormatoRitmo.minutiSecondi(125.4), "2:05")
    }

    func testNuotataVecchiaSenzaCampiNuoviSiLegge() throws {
        let json = #"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","data":1760000000,"metri":500,"durataSecondi":1500,"titolo":"x"}"#
        let decoder = JSONDecoder()
        let n = try decoder.decode(NuotataCompletata.self, from: Data(json.utf8))
        XCTAssertNil(n.sensazione)
        XCTAssertNil(n.origine)
    }
}
