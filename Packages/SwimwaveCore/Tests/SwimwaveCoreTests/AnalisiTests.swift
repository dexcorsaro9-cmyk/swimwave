import XCTest
@testable import SwimwaveCore

/// Aiuti comuni: calendario italiano (settimana dal lunedì) con fuso Europe/Rome esplicito, mai quello della macchina.
/// Date di riferimento: venerdì 9 ottobre 2026; settimane (lun-dom) 5-11 ott, 28 set-4 ott, 21-27 set, 14-20 set.
/// Il 25 ottobre 2026 finisce l'ora legale (a Roma). Il 1 gennaio 2026 è giovedì, il 31 dicembre 2026 giovedì.
private enum Prova {
    static let cal: Calendar = {
        var c = Calendar.italiano
        c.timeZone = TimeZone(identifier: "Europe/Rome")!
        return c
    }()

    static func data(_ mese: Int, _ giorno: Int, _ ora: Int = 10, _ minuto: Int = 0, anno: Int = 2026) -> Date {
        cal.date(from: DateComponents(year: anno, month: mese, day: giorno, hour: ora, minute: minuto))!
    }

    /// Durata predefinita: 3 secondi per metro (ritmo 300 s ogni 100 m).
    static func nuotata(_ mese: Int, _ giorno: Int, metri: Int = 500, durata: Int? = nil,
                        ora: Int = 10, minuto: Int = 0, anno: Int = 2026) -> NuotataCompletata {
        NuotataCompletata(data: data(mese, giorno, ora, minuto, anno: anno), metri: metri,
                          durataSecondi: durata ?? metri * 3, titolo: "x")
    }

    static let regolare2 = Profilo(coach: .uomo, nome: "Luca", livello: .cento, ritmo: .regolare, frequenzaSettimanale: 2)
    static let libero = Profilo(coach: .donna, nome: "Paola", livello: .menoDi25)
}

// MARK: NuotataCompletata: calcolati, unendo, Codable

final class NuotataCompletataTests: XCTestCase {
    private func piena() -> NuotataCompletata {
        NuotataCompletata(
            id: UUID(),
            data: Date(timeIntervalSince1970: 1_800_000_000),
            metri: 750, durataSecondi: 1650, titolo: "Prova",
            sensazione: .dura, origine: .watch,
            nota: "Bella nuotata, spalle un po' stanche",
            calorie: 310, frequenzaCardiacaMedia: 131, bracciate: 380,
            vascaMetri: 25, ambiente: .vasca,
            vasche: [
                SplitVasca(metri: 25, durataSecondi: 31.5, stile: .libero),
                SplitVasca(metri: 25, durataSecondi: 40.25, stile: nil),
                SplitVasca(metri: 25, durataSecondi: 44, stile: .rana)
            ],
            corretta: true
        )
    }

    func testRitmoPer100() throws {
        let n = Prova.nuotata(10, 6, metri: 500, durata: 1500)
        XCTAssertEqual(try XCTUnwrap(n.ritmoPer100Secondi), 300, accuracy: 0.0001)
        let m = Prova.nuotata(10, 6, metri: 750, durata: 1650)
        XCTAssertEqual(try XCTUnwrap(m.ritmoPer100Secondi), 220, accuracy: 0.0001)   // 1650 / 750 * 100
    }

    func testRitmoNilConMetriZero() {
        XCTAssertNil(Prova.nuotata(10, 6, metri: 0, durata: 1500).ritmoPer100Secondi)
    }

    func testBracciatePerVasca() throws {
        // 500 m in vasca da 25 m = 20 vasche; 400 bracciate / 20 = 20.
        var n = Prova.nuotata(10, 6, metri: 500, durata: 1500)
        n.bracciate = 400
        n.vascaMetri = 25
        XCTAssertEqual(try XCTUnwrap(n.bracciatePerVasca), 20, accuracy: 0.0001)
        // 50 m: 2 vasche da 25.
        n.metri = 50
        n.bracciate = 37
        XCTAssertEqual(try XCTUnwrap(n.bracciatePerVasca), 18.5, accuracy: 0.0001)
    }

    func testBracciatePerVascaNilSeMancanoDati() {
        var n = Prova.nuotata(10, 6, metri: 500, durata: 1500)
        XCTAssertNil(n.bracciatePerVasca)           // né bracciate né vasca
        n.bracciate = 400
        XCTAssertNil(n.bracciatePerVasca)           // manca la vasca
        n.vascaMetri = 0
        XCTAssertNil(n.bracciatePerVasca)           // vasca non valida
        n.vascaMetri = 25
        n.metri = 0
        XCTAssertNil(n.bracciatePerVasca)           // niente metri
        n.metri = 500
        n.bracciate = nil
        XCTAssertNil(n.bracciatePerVasca)           // niente bracciate
    }

    // MARK: unendo

    func testUnendoRiempieIVuotiSenzaCambiareIdEData() {
        let id = UUID()
        let watch = NuotataCompletata(id: id, data: Prova.data(10, 6), metri: 500, durataSecondi: 1500,
                                      titolo: "Allenamento", sensazione: .giusta, origine: .watch)
        let salute = NuotataCompletata(id: id, data: Prova.data(10, 6, 11), metri: 480, durataSecondi: 1490,
                                       titolo: "Nuotata", sensazione: .dura, origine: .salute,
                                       nota: "da salute", calorie: 250, frequenzaCardiacaMedia: 128, bracciate: 300,
                                       vascaMetri: 25, ambiente: .vasca,
                                       vasche: [SplitVasca(metri: 25, durataSecondi: 40)], corretta: false)
        let r = watch.unendo(salute)
        XCTAssertEqual(r.id, id)
        XCTAssertEqual(r.data, Prova.data(10, 6))          // data di self
        XCTAssertEqual(r.metri, 500)                       // metri e durata non vuoti: restano di self
        XCTAssertEqual(r.durataSecondi, 1500)
        XCTAssertEqual(r.titolo, "Allenamento")
        XCTAssertEqual(r.sensazione, .giusta)              // precedenza a self
        XCTAssertEqual(r.origine, .watch)
        XCTAssertEqual(r.nota, "da salute")                // vuoti riempiti
        XCTAssertEqual(r.calorie, 250)
        XCTAssertEqual(r.frequenzaCardiacaMedia, 128)
        XCTAssertEqual(r.bracciate, 300)
        XCTAssertEqual(r.vascaMetri, 25)
        XCTAssertEqual(r.ambiente, .vasca)
        XCTAssertEqual(r.vasche, [SplitVasca(metri: 25, durataSecondi: 40)])
        XCTAssertEqual(r.corretta, false)
    }

    func testUnendoNonSovrascriveNotaSensazioneCorretta() {
        var a = Prova.nuotata(10, 6)
        a.nota = "mia"
        a.sensazione = .facile
        a.corretta = true
        a.calorie = 100
        var b = a
        b.nota = "altra"
        b.sensazione = .dura
        b.corretta = false
        b.calorie = 999
        let r = a.unendo(b)
        XCTAssertEqual(r.nota, "mia")
        XCTAssertEqual(r.sensazione, .facile)
        XCTAssertEqual(r.corretta, true)
        XCTAssertEqual(r.calorie, 100)
    }

    func testUnendoMetriEDurataVuotiSiRiempionoSeNonCorretta() {
        let id = UUID()
        let a = NuotataCompletata(id: id, data: Prova.data(10, 6), metri: 0, durataSecondi: 0, titolo: "")
        let b = NuotataCompletata(id: id, data: Prova.data(10, 6), metri: 600, durataSecondi: 1800, titolo: "Dal telefono")
        let r = a.unendo(b)
        XCTAssertEqual(r.metri, 600)
        XCTAssertEqual(r.durataSecondi, 1800)
        XCTAssertEqual(r.titolo, "Dal telefono")
    }

    func testUnendoNonCorrettaTieneIPropriMetri() {
        let id = UUID()
        let a = NuotataCompletata(id: id, data: Prova.data(10, 6), metri: 500, durataSecondi: 1500, titolo: "A")
        let b = NuotataCompletata(id: id, data: Prova.data(10, 6), metri: 600, durataSecondi: 1800, titolo: "B")
        let r = a.unendo(b)
        XCTAssertEqual(r.metri, 500)
        XCTAssertEqual(r.durataSecondi, 1500)
        XCTAssertEqual(r.titolo, "A")
    }

    func testUnendoCorrettaBloccaMetriEDurata() {
        // L'utente ha corretto a 0 m e 0 s: nemmeno i valori "vuoti" si riempiono.
        let id = UUID()
        let a = NuotataCompletata(id: id, data: Prova.data(10, 6), metri: 0, durataSecondi: 0, titolo: "A", corretta: true)
        let b = NuotataCompletata(id: id, data: Prova.data(10, 6), metri: 600, durataSecondi: 1800, titolo: "B")
        let r = a.unendo(b)
        XCTAssertEqual(r.metri, 0)
        XCTAssertEqual(r.durataSecondi, 0)
        XCTAssertEqual(r.corretta, true)
    }

    func testUnendoConSeStessaNonCambiaNulla() {
        let n = piena()
        XCTAssertEqual(n.unendo(n), n)
    }

    // MARK: Codable e messaggi per il Watch

    func testAndataERitornoConTuttiICampiNuovi() throws {
        let n = piena()
        let info = try MessaggiWatch.userInfo(nuotata: n)
        let letta = try XCTUnwrap(MessaggiWatch.nuotata(da: info))
        XCTAssertEqual(letta, n)
        XCTAssertEqual(letta.vasche?.count, 3)
        XCTAssertEqual(letta.vasche?[0].durataSecondi, 31.5)
        XCTAssertEqual(letta.vasche?[1].stile, nil)
        XCTAssertEqual(letta.vasche?[2].stile, .rana)
        XCTAssertEqual(letta.ambiente, .vasca)
        XCTAssertEqual(letta.corretta, true)
    }

    func testAndataERitornoAcqueLibere() throws {
        var n = Prova.nuotata(10, 6, metri: 1500, durata: 2700)
        n.ambiente = .acqueLibere
        n.origine = .watch
        let info = try MessaggiWatch.userInfo(nuotata: n)
        XCTAssertEqual(MessaggiWatch.nuotata(da: info), n)
        XCTAssertEqual(MessaggiWatch.nuotata(da: info)?.ambiente, .acqueLibere)
    }

    func testCodificaUsaSecondiDal1970EOmetteIVuoti() throws {
        let n = piena()
        let json = try JSONSerialization.jsonObject(with: n.codificata()) as? [String: Any]
        XCTAssertEqual(json?["data"] as? Double, 1_800_000_000)
        XCTAssertEqual(json?["ambiente"] as? String, "vasca")
        XCTAssertEqual((json?["vasche"] as? [Any])?.count, 3)

        let vuota = Prova.nuotata(10, 6)
        let jsonVuota = try JSONSerialization.jsonObject(with: vuota.codificata()) as? [String: Any]
        XCTAssertNil(jsonVuota?["nota"])
        XCTAssertNil(jsonVuota?["vasche"])
    }

    func testAndataERitornoConCodificaPredefinita() throws {
        // StatoApp salva con JSONEncoder() predefinito.
        let n = piena()
        let data = try JSONEncoder().encode(n)
        XCTAssertEqual(try JSONDecoder().decode(NuotataCompletata.self, from: data), n)
    }

    func testJSONVecchioConDecodificaDelWatchSiLegge() throws {
        let json = #"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","data":1760000000,"metri":500,"durataSecondi":1500,"titolo":"x","sensazione":"dura","origine":"watch"}"#
        let n = try NuotataCompletata.decodifica(Data(json.utf8))
        XCTAssertEqual(n.metri, 500)
        XCTAssertEqual(n.sensazione, .dura)
        XCTAssertNil(n.nota)
        XCTAssertNil(n.calorie)
        XCTAssertNil(n.frequenzaCardiacaMedia)
        XCTAssertNil(n.bracciate)
        XCTAssertNil(n.vascaMetri)
        XCTAssertNil(n.ambiente)
        XCTAssertNil(n.vasche)
        XCTAssertNil(n.corretta)
        XCTAssertEqual(n.data, Date(timeIntervalSince1970: 1_760_000_000))
    }

    func testJSONConCampiNuoviSiLegge() throws {
        let json = #"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","data":1760000000,"metri":500,"durataSecondi":1500,"titolo":"x","calorie":200,"ambiente":"acqueLibere","vasche":[{"metri":25,"durataSecondi":30.5,"stile":"dorso"}]}"#
        let n = try NuotataCompletata.decodifica(Data(json.utf8))
        XCTAssertEqual(n.calorie, 200)
        XCTAssertEqual(n.ambiente, .acqueLibere)
        XCTAssertEqual(n.vasche, [SplitVasca(metri: 25, durataSecondi: 30.5, stile: .dorso)])
    }
}

// MARK: Riepiloghi

final class RiepiloghiTests: XCTestCase {
    private let cal = Prova.cal

    func testSommaVuotaEPiena() {
        let vuota = Riepiloghi.somma([])
        XCTAssertEqual(vuota, SommaPeriodo(inizio: Date.distantPast, nuotate: 0, metri: 0, durataSecondi: 0))
        let s = Riepiloghi.somma([Prova.nuotata(10, 6, metri: 500, durata: 1500), Prova.nuotata(10, 2, metri: 700, durata: 1800)])
        XCTAssertEqual(s.inizio, Prova.data(10, 6))     // data della prima dell'elenco
        XCTAssertEqual(s.nuotate, 2)
        XCTAssertEqual(s.metri, 1200)
        XCTAssertEqual(s.durataSecondi, 3300)
    }

    func testPerSettimana() {
        let nuotate = [
            Prova.nuotata(10, 6, metri: 500, durata: 1500),
            Prova.nuotata(10, 9, metri: 1000, durata: 2400, ora: 8),
            Prova.nuotata(10, 2, metri: 700, durata: 1800),
            Prova.nuotata(9, 21, metri: 300, durata: 900, ora: 7),
            Prova.nuotata(9, 13, metri: 250, durata: 600, ora: 23, minuto: 30)   // settimana 7-13 set: fuori dalle 4
        ]
        let r = Riepiloghi.perSettimana(nuotate: nuotate, quante: 4, rispetto: Prova.data(10, 9), calendar: cal)
        XCTAssertEqual(r, [
            SommaPeriodo(inizio: Prova.data(9, 14, 0), nuotate: 0, metri: 0, durataSecondi: 0),
            SommaPeriodo(inizio: Prova.data(9, 21, 0), nuotate: 1, metri: 300, durataSecondi: 900),
            SommaPeriodo(inizio: Prova.data(9, 28, 0), nuotate: 1, metri: 700, durataSecondi: 1800),
            SommaPeriodo(inizio: Prova.data(10, 5, 0), nuotate: 2, metri: 1500, durataSecondi: 3900)
        ])
    }

    func testPerSettimanaConfiniMezzanotte() {
        // Domenica 27 set 23:59 è nella settimana 21-27; lunedì 28 set 00:00 apre la successiva.
        let nuotate = [Prova.nuotata(9, 27, metri: 100, ora: 23, minuto: 59), Prova.nuotata(9, 28, metri: 200, ora: 0, minuto: 0)]
        let r = Riepiloghi.perSettimana(nuotate: nuotate, quante: 3, rispetto: Prova.data(10, 5, 0), calendar: cal)
        XCTAssertEqual(r.map(\.nuotate), [1, 1, 0])
        XCTAssertEqual(r.map(\.metri), [100, 200, 0])
        XCTAssertEqual(r.map(\.inizio), [Prova.data(9, 21, 0), Prova.data(9, 28, 0), Prova.data(10, 5, 0)])
    }

    func testPerSettimanaACavalloDiAnno() {
        // 28 dic 2026 (lun) - 3 gen 2027 (dom) è una sola settimana, a cavallo dell'anno.
        let nuotate = [
            Prova.nuotata(12, 31, metri: 500),
            Prova.nuotata(1, 1, metri: 600, anno: 2027),
            Prova.nuotata(1, 3, metri: 400, ora: 23, anno: 2027),
            Prova.nuotata(1, 4, metri: 800, ora: 8, anno: 2027)
        ]
        let r = Riepiloghi.perSettimana(nuotate: nuotate, quante: 3, rispetto: Prova.data(1, 4, 9, anno: 2027), calendar: cal)
        XCTAssertEqual(r, [
            SommaPeriodo(inizio: Prova.data(12, 21, 0), nuotate: 0, metri: 0, durataSecondi: 0),
            SommaPeriodo(inizio: Prova.data(12, 28, 0), nuotate: 3, metri: 1500, durataSecondi: 4500),
            SommaPeriodo(inizio: Prova.data(1, 4, 0, anno: 2027), nuotate: 1, metri: 800, durataSecondi: 2400)
        ])
    }

    func testPerSettimanaAttraversoFineOraLegale() {
        // Il 25 ott 2026 (domenica) si torna all'ora solare: la settimana 19-25 dura 7 giorni + 1 ora.
        let nuotate = [Prova.nuotata(10, 25, metri: 300, ora: 23), Prova.nuotata(10, 26, metri: 400, ora: 0, minuto: 0)]
        let r = Riepiloghi.perSettimana(nuotate: nuotate, quante: 2, rispetto: Prova.data(10, 27), calendar: cal)
        XCTAssertEqual(r.map(\.inizio), [Prova.data(10, 19, 0), Prova.data(10, 26, 0)])
        XCTAssertEqual(r.map(\.nuotate), [1, 1])
        XCTAssertEqual(r.map(\.metri), [300, 400])
    }

    func testPerSettimanaSenzaNuotateEQuanteNonValido() {
        let r = Riepiloghi.perSettimana(nuotate: [], quante: 3, rispetto: Prova.data(10, 9), calendar: cal)
        XCTAssertEqual(r.count, 3)
        XCTAssertTrue(r.allSatisfy { $0.nuotate == 0 && $0.metri == 0 && $0.durataSecondi == 0 })
        XCTAssertEqual(r.map(\.inizio), [Prova.data(9, 21, 0), Prova.data(9, 28, 0), Prova.data(10, 5, 0)])
        XCTAssertEqual(Riepiloghi.perSettimana(nuotate: [], quante: 0, rispetto: Prova.data(10, 9), calendar: cal), [])
        XCTAssertEqual(Riepiloghi.perSettimana(nuotate: [], quante: -2, rispetto: Prova.data(10, 9), calendar: cal), [])
    }

    func testPerMeseACavalloDiAnno() {
        let nuotate = [
            Prova.nuotata(11, 30, metri: 400, ora: 23, minuto: 59),
            Prova.nuotata(12, 1, metri: 500, ora: 0, minuto: 0),
            Prova.nuotata(12, 31, metri: 600, ora: 23, minuto: 59),
            Prova.nuotata(1, 1, metri: 700, ora: 0, minuto: 0, anno: 2027),
            Prova.nuotata(1, 20, metri: 1000, anno: 2027)
        ]
        let r = Riepiloghi.perMese(nuotate: nuotate, quanti: 3, rispetto: Prova.data(1, 15, anno: 2027), calendar: cal)
        XCTAssertEqual(r, [
            SommaPeriodo(inizio: Prova.data(11, 1, 0), nuotate: 1, metri: 400, durataSecondi: 1200),
            SommaPeriodo(inizio: Prova.data(12, 1, 0), nuotate: 2, metri: 1100, durataSecondi: 3300),
            SommaPeriodo(inizio: Prova.data(1, 1, 0, anno: 2027), nuotate: 2, metri: 1700, durataSecondi: 5100)
        ])
        let uno = Riepiloghi.perMese(nuotate: nuotate, quanti: 1, rispetto: Prova.data(1, 15, anno: 2027), calendar: cal)
        XCTAssertEqual(uno.map(\.metri), [1700])
        XCTAssertEqual(Riepiloghi.perMese(nuotate: nuotate, quanti: 0, rispetto: Prova.data(1, 15, anno: 2027), calendar: cal), [])
    }

    func testPerMeseSenzaNuotate() {
        let r = Riepiloghi.perMese(nuotate: [], quanti: 2, rispetto: Prova.data(10, 9), calendar: cal)
        XCTAssertEqual(r.map(\.inizio), [Prova.data(9, 1, 0), Prova.data(10, 1, 0)])
        XCTAssertEqual(r.map(\.nuotate), [0, 0])
    }

    // MARK: filtra

    private func dodici() -> [NuotataCompletata] {
        // I metri identificano la nuotata.
        [
            Prova.nuotata(12, 31, metri: 100, ora: 23, minuto: 59, anno: 2025),
            Prova.nuotata(1, 1, metri: 200, ora: 0, minuto: 0),
            Prova.nuotata(9, 30, metri: 300),
            Prova.nuotata(10, 1, metri: 400, ora: 0, minuto: 0),
            Prova.nuotata(10, 4, metri: 500, ora: 23, minuto: 59),
            Prova.nuotata(10, 5, metri: 600, ora: 0, minuto: 0),
            Prova.nuotata(10, 11, metri: 700, ora: 23, minuto: 59),
            Prova.nuotata(10, 12, metri: 800, ora: 0, minuto: 0),
            Prova.nuotata(10, 31, metri: 900, ora: 23, minuto: 59),
            Prova.nuotata(11, 1, metri: 1000, ora: 0, minuto: 0),
            Prova.nuotata(12, 31, metri: 1100, ora: 23, minuto: 59),
            Prova.nuotata(1, 1, metri: 1200, ora: 0, minuto: 0, anno: 2027)
        ]
    }

    func testFiltraPerPeriodo() {
        let tutte = dodici()
        let rif = Prova.data(10, 9)
        XCTAssertEqual(Riepiloghi.filtra(tutte, periodo: .settimana, rispetto: rif, calendar: cal).map(\.metri), [600, 700])
        XCTAssertEqual(Riepiloghi.filtra(tutte, periodo: .mese, rispetto: rif, calendar: cal).map(\.metri), [400, 500, 600, 700, 800, 900])
        XCTAssertEqual(Riepiloghi.filtra(tutte, periodo: .anno, rispetto: rif, calendar: cal).map(\.metri),
                       [200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100])
        XCTAssertEqual(Riepiloghi.filtra(tutte, periodo: .sempre, rispetto: rif, calendar: cal), tutte)
    }

    func testFiltraSenzaNuotate() {
        for p in PeriodoRiepilogo.allCases {
            XCTAssertEqual(Riepiloghi.filtra([], periodo: p, rispetto: Prova.data(10, 9), calendar: cal), [])
        }
    }

    func testPeriodiSono4() {
        XCTAssertEqual(PeriodoRiepilogo.allCases, [.settimana, .mese, .anno, .sempre])
    }
}

// MARK: Il tuo anno

final class RiepilogoAnnualeTests: XCTestCase {
    private let cal = Prova.cal

    private func nuotateDiProva() -> [NuotataCompletata] {
        [
            Prova.nuotata(12, 31, metri: 600, durata: 1800, anno: 2025),     // fuori (2025)
            Prova.nuotata(1, 1, metri: 500, durata: 1500, ora: 10),          // gio 1 gen
            Prova.nuotata(1, 1, metri: 300, durata: 900, ora: 18),           // stesso giorno
            Prova.nuotata(1, 2, metri: 400, durata: 1200),
            Prova.nuotata(3, 10, metri: 2000, durata: 3600),
            Prova.nuotata(3, 12, metri: 1500, durata: 2700),
            Prova.nuotata(10, 6, metri: 1200, durata: 2400),
            Prova.nuotata(1, 1, metri: 1000, durata: 3000, anno: 2027)       // fuori (2027)
        ]
    }

    func testRiepilogoDel2026() {
        let r = RiepilogoAnnuale.calcola(nuotate: nuotateDiProva(), anno: 2026, profilo: Prova.regolare2, calendar: cal)
        XCTAssertEqual(r.anno, 2026)
        XCTAssertEqual(r.nuotate, 6)
        XCTAssertEqual(r.metri, 5900)
        XCTAssertEqual(r.durataSecondi, 12300)
        XCTAssertEqual(r.giorniNuotati, 5)               // 1 gen (due nuotate), 2 gen, 10 mar, 12 mar, 6 ott
        XCTAssertEqual(r.meseMigliore, 3)                // marzo: 3500 m (gennaio e ottobre 1200)
        XCTAssertEqual(r.metriMeseMigliore, 3500)
        XCTAssertEqual(r.nuotataPiuLunga?.metri, 2000)
        XCTAssertEqual(r.nuotataPiuLunga?.data, Prova.data(3, 10))
        // Obiettivo 2: settimana 29 dic-4 gen (3 nuotate del 2026) e settimana 9-15 mar (2). Quella del 5 ott ne ha 1.
        XCTAssertEqual(r.settimaneConObiettivo, 2)
    }

    func testSettimaneConObiettivoConProfiloLiberoMinimoUno() {
        let r = RiepilogoAnnuale.calcola(nuotate: nuotateDiProva(), anno: 2026, profilo: Prova.libero, calendar: cal)
        XCTAssertEqual(r.settimaneConObiettivo, 3)       // 29 dic-4 gen, 9-15 mar, 5-11 ott
    }

    func testSettimanaACavalloDiAnnoContaSoloLeNuotateDellAnno() {
        // Una nuotata il 31 dic 2025 e una l'1 gen 2026, stessa settimana. Obiettivo 2: in nessuno dei due anni ce ne sono 2.
        let nuotate = [Prova.nuotata(12, 31, anno: 2025), Prova.nuotata(1, 1)]
        XCTAssertEqual(RiepilogoAnnuale.calcola(nuotate: nuotate, anno: 2025, profilo: Prova.regolare2, calendar: cal).settimaneConObiettivo, 0)
        XCTAssertEqual(RiepilogoAnnuale.calcola(nuotate: nuotate, anno: 2026, profilo: Prova.regolare2, calendar: cal).settimaneConObiettivo, 0)
        XCTAssertEqual(RiepilogoAnnuale.calcola(nuotate: nuotate, anno: 2025, profilo: Prova.libero, calendar: cal).settimaneConObiettivo, 1)
        XCTAssertEqual(RiepilogoAnnuale.calcola(nuotate: nuotate, anno: 2026, profilo: Prova.libero, calendar: cal).settimaneConObiettivo, 1)
    }

    func testAnnoSenzaNuotate() {
        let r = RiepilogoAnnuale.calcola(nuotate: nuotateDiProva(), anno: 2020, profilo: Prova.regolare2, calendar: cal)
        XCTAssertEqual(r.nuotate, 0)
        XCTAssertEqual(r.metri, 0)
        XCTAssertEqual(r.durataSecondi, 0)
        XCTAssertEqual(r.giorniNuotati, 0)
        XCTAssertNil(r.meseMigliore)
        XCTAssertEqual(r.metriMeseMigliore, 0)
        XCTAssertNil(r.nuotataPiuLunga)
        XCTAssertEqual(r.settimaneConObiettivo, 0)
        let senzaNulla = RiepilogoAnnuale.calcola(nuotate: [], anno: 2026, profilo: Prova.libero, calendar: cal)
        XCTAssertEqual(senzaNulla.nuotate, 0)
        XCTAssertNil(senzaNulla.meseMigliore)
    }

    func testMeseMiglioreAParitaSceglieIlPrimo() {
        let nuotate = [Prova.nuotata(4, 7, metri: 1000), Prova.nuotata(2, 5, metri: 1000)]
        let r = RiepilogoAnnuale.calcola(nuotate: nuotate, anno: 2026, profilo: Prova.libero, calendar: cal)
        XCTAssertEqual(r.meseMigliore, 2)
        XCTAssertEqual(r.metriMeseMigliore, 1000)
    }

    func testNuotataSenzaMetri() {
        let nuotate = [Prova.nuotata(5, 5, metri: 0, durata: 900)]
        let r = RiepilogoAnnuale.calcola(nuotate: nuotate, anno: 2026, profilo: Prova.libero, calendar: cal)
        XCTAssertEqual(r.nuotate, 1)
        XCTAssertEqual(r.giorniNuotati, 1)
        XCTAssertEqual(r.meseMigliore, 5)
        XCTAssertEqual(r.metriMeseMigliore, 0)
        XCTAssertNil(r.nuotataPiuLunga)                  // nessuna con metri positivi
    }

    func testAnnoSiLeggeNelFusoDiRoma() {
        // 1 gen 2027 alle 00:30 a Roma sono le 23:30 del 31 dic 2026 in UTC: per Roma è 2027.
        let n = Prova.nuotata(1, 1, metri: 500, ora: 0, minuto: 30, anno: 2027)
        XCTAssertEqual(RiepilogoAnnuale.anniConNuotate([n], calendar: cal), [2027])
        XCTAssertEqual(RiepilogoAnnuale.calcola(nuotate: [n], anno: 2026, profilo: Prova.libero, calendar: cal).nuotate, 0)
        XCTAssertEqual(RiepilogoAnnuale.calcola(nuotate: [n], anno: 2027, profilo: Prova.libero, calendar: cal).nuotate, 1)
    }

    func testAnniConNuotate() {
        let nuotate = [
            Prova.nuotata(3, 3, anno: 2025), Prova.nuotata(1, 1, anno: 2027), Prova.nuotata(5, 5),
            Prova.nuotata(6, 6), Prova.nuotata(12, 31, ora: 23, minuto: 59, anno: 2025)
        ]
        XCTAssertEqual(RiepilogoAnnuale.anniConNuotate(nuotate, calendar: cal), [2027, 2026, 2025])
        XCTAssertEqual(RiepilogoAnnuale.anniConNuotate([], calendar: cal), [])
    }
}

// MARK: Record

final class RecordTests: XCTestCase {
    private let cal = Prova.cal

    private func calcola(_ nuotate: [NuotataCompletata], test: TestRitmo? = nil, profilo: Profilo = Prova.libero) -> RecordPersonali {
        Record.calcola(nuotate: nuotate, testRitmo: test, profilo: profilo, calendar: cal)
    }

    func testNessunaNuotata() {
        let r = calcola([])
        XCTAssertNil(r.nuotataPiuLunga)
        XCTAssertNil(r.ritmoMigliore)
        XCTAssertNil(r.settimanaPiuLunga)
        XCTAssertEqual(r.serieMassimaSettimane, 0)
        XCTAssertEqual(r.nuotateTotali, 0)
        XCTAssertEqual(r.metriTotali, 0)
        XCTAssertNil(r.tempo200)
        XCTAssertNil(r.tempo400)
    }

    func testTotaliEPiuLunga() {
        let a = Prova.nuotata(3, 10, metri: 2000)
        let b = Prova.nuotata(2, 3, metri: 2000)      // stessi metri, più vecchia: vince
        let c = Prova.nuotata(4, 4, metri: 800)
        let r = calcola([a, b, c])
        XCTAssertEqual(r.nuotataPiuLunga, b)
        XCTAssertEqual(r.nuotateTotali, 3)
        XCTAssertEqual(r.metriTotali, 4800)
    }

    func testTempiDelTest() {
        let t = TestRitmo(data: Prova.data(10, 1), tempo200Secondi: 180, tempo400Secondi: 390)
        let r = calcola([], test: t)
        XCTAssertEqual(r.tempo200, 180)
        XCTAssertEqual(r.tempo400, 390)
    }

    func testRitmoMiglioreSoloDa400mE5Minuti() {
        let n1 = Prova.nuotata(1, 5, metri: 300, durata: 600)      // sotto 400 m: esclusa (ritmo 200)
        let n2 = Prova.nuotata(1, 6, metri: 1000, durata: 2000)    // 200
        let n3 = Prova.nuotata(1, 7, metri: 400, durata: 700)      // 175
        let n4 = Prova.nuotata(1, 8, metri: 2000, durata: 3200)    // 160
        XCTAssertEqual(calcola([n1, n2, n3, n4]).ritmoMigliore, n4)

        let corta = Prova.nuotata(1, 9, metri: 500, durata: 299)     // meno di 5 minuti: esclusa (ritmo 59,8)
        let pocoMetri = Prova.nuotata(1, 10, metri: 399, durata: 400) // 399 m: esclusa
        let senzaMetri = Prova.nuotata(1, 11, metri: 0, durata: 900)  // ritmo nil: esclusa
        XCTAssertEqual(calcola([n1, n2, n3, n4, corta, pocoMetri, senzaMetri]).ritmoMigliore, n4)

        let limite = Prova.nuotata(1, 12, metri: 400, durata: 300)    // esattamente 400 m e 300 s: inclusa (ritmo 75)
        XCTAssertEqual(calcola([n1, n2, n3, n4, corta, pocoMetri, senzaMetri, limite]).ritmoMigliore, limite)
    }

    func testRitmoMiglioreNilConMenoDi400m() {
        let r = calcola([Prova.nuotata(1, 5, metri: 399, durata: 600), Prova.nuotata(1, 6, metri: 100, durata: 400)])
        XCTAssertNil(r.ritmoMigliore)
        XCTAssertNotNil(r.nuotataPiuLunga)
        XCTAssertEqual(r.nuotateTotali, 2)
    }

    func testSettimanaPiuLunga() {
        let nuotate = [
            Prova.nuotata(9, 29, metri: 1500, durata: 3000),
            Prova.nuotata(10, 6, metri: 500, durata: 1500),
            Prova.nuotata(10, 8, metri: 700, durata: 2000)
        ]
        // 28 set-4 ott: 1500 m con una nuotata; 5-11 ott: 1200 m con due.
        XCTAssertEqual(calcola(nuotate).settimanaPiuLunga,
                       SommaPeriodo(inizio: Prova.data(9, 28, 0), nuotate: 1, metri: 1500, durataSecondi: 3000))

        // A parità di metri vince la settimana più vecchia.
        let pari = [nuotate[0], Prova.nuotata(10, 6, metri: 700, durata: 1000), Prova.nuotata(10, 8, metri: 800, durata: 1100)]
        XCTAssertEqual(calcola(pari).settimanaPiuLunga?.inizio, Prova.data(9, 28, 0))

        // Con 900 m al posto di 800 vince la settimana del 5 ottobre.
        let sopra = [nuotate[0], Prova.nuotata(10, 6, metri: 700, durata: 1000), Prova.nuotata(10, 8, metri: 900, durata: 1100)]
        XCTAssertEqual(calcola(sopra).settimanaPiuLunga,
                       SommaPeriodo(inizio: Prova.data(10, 5, 0), nuotate: 2, metri: 1600, durataSecondi: 2100))
    }

    func testSettimanaPiuLungaACavalloDiAnno() {
        // Una sola settimana (28 dic-3 gen) con nuotate in due anni diversi.
        let nuotate = [Prova.nuotata(12, 31, metri: 500), Prova.nuotata(1, 2, metri: 600, anno: 2027)]
        let r = calcola(nuotate).settimanaPiuLunga
        XCTAssertEqual(r?.inizio, Prova.data(12, 28, 0))
        XCTAssertEqual(r?.nuotate, 2)
        XCTAssertEqual(r?.metri, 1100)
    }

    func testSerieMassimaConObiettivo() {
        // Obiettivo 2. Settimane (lun) 7, 14, 21 set con 2 nuotate; 28 set con 1; 5 ott con 2.
        let nuotate = [
            Prova.nuotata(9, 8), Prova.nuotata(9, 10),
            Prova.nuotata(9, 15), Prova.nuotata(9, 17),
            Prova.nuotata(9, 22), Prova.nuotata(9, 24),
            Prova.nuotata(9, 29),
            Prova.nuotata(10, 6), Prova.nuotata(10, 8)
        ]
        XCTAssertEqual(calcola(nuotate, profilo: Prova.regolare2).serieMassimaSettimane, 3)
        // Senza obiettivo basta una nuotata a settimana: 5 settimane di fila.
        XCTAssertEqual(calcola(nuotate, profilo: Prova.libero).serieMassimaSettimane, 5)
    }

    func testSerieMassimaACavalloDiAnno() {
        // Libero: settimane del 2 nov (isolata), 21 dic, 28 dic, 4 gen. La serie più lunga è 3.
        let nuotate = [
            Prova.nuotata(11, 3), Prova.nuotata(12, 22), Prova.nuotata(12, 30),
            Prova.nuotata(1, 5, anno: 2027)
        ]
        XCTAssertEqual(calcola(nuotate).serieMassimaSettimane, 3)
    }

    func testSerieMassimaAttraversoFineOraLegale() {
        // Settimane del 12, 19 e 26 ottobre: il 25 ottobre cambia l'ora.
        let nuotate = [Prova.nuotata(10, 13), Prova.nuotata(10, 20), Prova.nuotata(10, 27)]
        XCTAssertEqual(calcola(nuotate).serieMassimaSettimane, 3)
    }

    func testSerieMassimaSettimanaSaltataInterrompe() {
        // Settimane del 7 e del 21 set: in mezzo manca quella del 14.
        let nuotate = [Prova.nuotata(9, 8), Prova.nuotata(9, 22)]
        XCTAssertEqual(calcola(nuotate).serieMassimaSettimane, 1)
    }

    func testSerieMassimaPiuNuotateNelloStessoGiorno() {
        let nuotate = [Prova.nuotata(9, 8, ora: 8), Prova.nuotata(9, 8, ora: 18)]
        XCTAssertEqual(calcola(nuotate, profilo: Prova.regolare2).serieMassimaSettimane, 1)
        XCTAssertEqual(calcola(nuotate, profilo: Prova.libero).serieMassimaSettimane, 1)
    }
}

// MARK: Medaglie

final class MedaglieTests: XCTestCase {
    private func trova(_ elenco: [Medaglia], _ id: String) -> Medaglia? {
        elenco.first { $0.id == id }
    }

    private func nuotate(_ quante: Int, metriCiascuna: Int) -> [NuotataCompletata] {
        (0..<quante).map { i in Prova.nuotata(1 + i / 28, 1 + i % 28, metri: metriCiascuna) }
    }

    func testElencoCompletoNellOrdineAtteso() {
        let e = Medaglie.elenco(nuotate: [], serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertEqual(e.map(\.id), [
            "prima-nuotata", "nuotate-10", "nuotate-25", "nuotate-50", "nuotate-100",
            "metri-1000", "metri-5000", "metri-10000", "metri-25000", "metri-50000", "metri-100000",
            "traversata-messina", "traversata-bonifacio", "traversata-gibilterra", "traversata-manica",
            "serie-2", "serie-4", "serie-8", "serie-12", "serie-26", "serie-52", "fedele-vasca",
            "tappa-1", "tappa-2", "tappa-3", "tappa-4", "tappa-5", "tappa-6", "tappa-7", "tappa-8", "tappa-9", "tappa-10",
            "test-ritmo", "cento-continui"
        ])
        XCTAssertEqual(Set(e.map(\.id)).count, e.count)                  // id tutti diversi
        XCTAssertTrue(e.allSatisfy { !$0.ottenuta && $0.attuale == 0 })
        // Ordine per categoria.
        XCTAssertEqual(e.map(\.categoria), CategoriaMedaglia.allCases.flatMap { c in e.filter { $0.categoria == c }.map(\.categoria) })
        XCTAssertEqual(CategoriaMedaglia.allCases, [.nuotate, .distanza, .traversate, .costanza, .percorso])
    }

    func testSoglie() {
        let e = Medaglie.elenco(nuotate: [], serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertEqual(e.filter { $0.categoria == .nuotate }.map(\.soglia), [1, 10, 25, 50, 100])
        XCTAssertEqual(e.filter { $0.categoria == .distanza }.map(\.soglia), [1000, 5000, 10000, 25000, 50000, 100000])
        XCTAssertEqual(e.filter { $0.categoria == .traversate }.map(\.soglia), [3_100, 11_000, 14_200, 34_000])
        XCTAssertEqual(e.filter { $0.categoria == .costanza }.map(\.soglia), SerieSettimane.traguardi + [Medaglie.settimaneFedele])
        XCTAssertEqual(e.filter { $0.categoria == .percorso }.map(\.soglia), Array(repeating: 1, count: 12))
    }

    func testNuotateAllaSoglia() throws {
        let nove = Medaglie.elenco(nuotate: nuotate(9, metriCiascuna: 0), serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertTrue(try XCTUnwrap(trova(nove, "prima-nuotata")).ottenuta)
        XCTAssertFalse(try XCTUnwrap(trova(nove, "nuotate-10")).ottenuta)
        XCTAssertEqual(try XCTUnwrap(trova(nove, "nuotate-10")).attuale, 9)

        let dieci = Medaglie.elenco(nuotate: nuotate(10, metriCiascuna: 0), serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertTrue(try XCTUnwrap(trova(dieci, "nuotate-10")).ottenuta)       // attuale >= soglia
        XCTAssertFalse(try XCTUnwrap(trova(dieci, "nuotate-25")).ottenuta)
        XCTAssertEqual(try XCTUnwrap(trova(dieci, "nuotate-25")).attuale, 10)
    }

    func testMetriTotali() throws {
        let sotto = Medaglie.elenco(nuotate: nuotate(10, metriCiascuna: 99) , serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertFalse(try XCTUnwrap(trova(sotto, "metri-1000")).ottenuta)       // 990 m
        XCTAssertEqual(try XCTUnwrap(trova(sotto, "metri-1000")).attuale, 990)

        let esatti = Medaglie.elenco(nuotate: nuotate(10, metriCiascuna: 100), serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertTrue(try XCTUnwrap(trova(esatti, "metri-1000")).ottenuta)       // 1000 m: soglia raggiunta
        XCTAssertFalse(try XCTUnwrap(trova(esatti, "metri-5000")).ottenuta)

        let tante = Medaglie.elenco(nuotate: [Prova.nuotata(1, 1, metri: 100_000)], serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertTrue(e(tante, "metri-100000"))
        XCTAssertEqual(try XCTUnwrap(trova(tante, "metri-100000")).attuale, 100_000)
    }

    private func e(_ elenco: [Medaglia], _ id: String) -> Bool {
        trova(elenco, id)?.ottenuta ?? false
    }

    func testSerieSettimane() throws {
        let quattro = Medaglie.elenco(nuotate: [], serieSettimane: 4, tappeSuperate: [], testRitmo: nil)
        XCTAssertTrue(e(quattro, "serie-2"))
        XCTAssertTrue(e(quattro, "serie-4"))
        XCTAssertFalse(e(quattro, "serie-8"))
        XCTAssertEqual(try XCTUnwrap(trova(quattro, "serie-8")).attuale, 4)
        let tre = Medaglie.elenco(nuotate: [], serieSettimane: 3, tappeSuperate: [], testRitmo: nil)
        XCTAssertFalse(e(tre, "serie-4"))
        let massima = Medaglie.elenco(nuotate: [], serieSettimane: 52, tappeSuperate: [], testRitmo: nil)
        XCTAssertTrue(e(massima, "serie-52"))
    }

    func testTraversateSuMetriTotali() {
        let sotto = Medaglie.elenco(nuotate: [Prova.nuotata(1, 1, metri: 3_099)], serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertFalse(e(sotto, "traversata-messina"))
        let messina = Medaglie.elenco(nuotate: [Prova.nuotata(1, 1, metri: 3_100)], serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertTrue(e(messina, "traversata-messina"))
        XCTAssertFalse(e(messina, "traversata-bonifacio"))
        let manica = Medaglie.elenco(nuotate: [Prova.nuotata(1, 1, metri: 20_000), Prova.nuotata(2, 1, metri: 14_000)],
                                     serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertTrue(e(manica, "traversata-manica"))
        XCTAssertEqual(trova(manica, "traversata-gibilterra")?.attuale, 34_000)
    }

    func testFedeleAllaVasca() {
        // Tre settimane di fila con due nuotate (settimane del 5, 12 e 19 gennaio 2026, lunedì).
        let date = [(1, 5), (1, 7), (1, 12), (1, 14), (1, 19), (1, 21)].map { Prova.data($0.0, $0.1) }
        XCTAssertEqual(SerieSettimane.serieMassima(conAlmeno: 2, date: date), 3)
        // Una settimana con una sola nuotata interrompe la serie.
        let interrotta = [(1, 5), (1, 7), (1, 12), (1, 19), (1, 21), (1, 26), (1, 28)].map { Prova.data($0.0, $0.1) }
        XCTAssertEqual(SerieSettimane.serieMassima(conAlmeno: 2, date: interrotta), 2)
        XCTAssertEqual(SerieSettimane.serieMassima(conAlmeno: 2, date: []), 0)
        let con = Medaglie.elenco(nuotate: date.map { NuotataCompletata(data: $0, metri: 500, durataSecondi: 900, titolo: "x") },
                                  serieSettimane: 0, tappeSuperate: [], testRitmo: nil)
        XCTAssertTrue(e(con, "fedele-vasca"))
        XCTAssertEqual(trova(con, "fedele-vasca")?.attuale, 3)
        XCTAssertFalse(e(Medaglie.elenco(nuotate: [], serieSettimane: 0, tappeSuperate: [], testRitmo: nil), "fedele-vasca"))
    }

    func testCentoContinui() {
        func vasca(_ inizio: Double) -> SplitVasca {
            SplitVasca(metri: 25, durataSecondi: 30, stile: .libero, inizioSecondi: inizio)
        }
        let continue_ = NuotataCompletata(data: Prova.data(1, 5), metri: 100, durataSecondi: 120, titolo: "x",
                                          vasche: [vasca(0), vasca(30), vasca(60), vasca(90)])
        XCTAssertTrue(e(Medaglie.elenco(nuotate: [continue_], serieSettimane: 0, tappeSuperate: [], testRitmo: nil), "cento-continui"))
        // Con una sosta di 10 secondi a metà non vale.
        let conSosta = NuotataCompletata(data: Prova.data(1, 5), metri: 100, durataSecondi: 130, titolo: "x",
                                         vasche: [vasca(0), vasca(30), vasca(70), vasca(100)])
        XCTAssertFalse(e(Medaglie.elenco(nuotate: [conSosta], serieSettimane: 0, tappeSuperate: [], testRitmo: nil), "cento-continui"))
        // Senza i tempi delle vasche non si può sapere.
        let senza = NuotataCompletata(data: Prova.data(1, 5), metri: 100, durataSecondi: 120, titolo: "x")
        XCTAssertFalse(e(Medaglie.elenco(nuotate: [senza], serieSettimane: 0, tappeSuperate: [], testRitmo: nil), "cento-continui"))
    }

    func testPercorsoETest() throws {
        let t = TestRitmo(data: Prova.data(10, 1), tempo200Secondi: 180, tempo400Secondi: 390)
        let el = Medaglie.elenco(nuotate: [], serieSettimane: 0, tappeSuperate: [1, 3, 10], testRitmo: t)
        XCTAssertTrue(e(el, "tappa-1"))
        XCTAssertFalse(e(el, "tappa-2"))
        XCTAssertTrue(e(el, "tappa-3"))
        XCTAssertTrue(e(el, "tappa-10"))
        XCTAssertEqual(try XCTUnwrap(trova(el, "tappa-1")).attuale, 1)
        XCTAssertEqual(try XCTUnwrap(trova(el, "tappa-2")).attuale, 0)
        XCTAssertEqual(try XCTUnwrap(trova(el, "tappa-2")).soglia, 1)
        XCTAssertTrue(e(el, "test-ritmo"))
        XCTAssertEqual(try XCTUnwrap(trova(el, "test-ritmo")).attuale, 1)
        XCTAssertEqual(try XCTUnwrap(trova(el, "tappa-3")).categoria, .percorso)
        // Tappe fuori elenco (es. 11) non creano medaglie.
        let fuori = Medaglie.elenco(nuotate: [], serieSettimane: 0, tappeSuperate: [11], testRitmo: nil)
        XCTAssertEqual(fuori.count, 34)
        XCTAssertFalse(e(fuori, "test-ritmo"))
    }
}

// MARK: Confronto

final class ConfrontoNuotateTests: XCTestCase {
    func testDifferenzeBMenoA() throws {
        let a = Prova.nuotata(10, 2, metri: 500, durata: 1500)    // 300 s / 100 m
        let b = Prova.nuotata(10, 6, metri: 1000, durata: 2800)   // 280 s / 100 m
        let c = ConfrontoNuotate(a: a, b: b)
        XCTAssertEqual(c.a, a)
        XCTAssertEqual(c.b, b)
        XCTAssertEqual(c.differenzaMetri, 500)
        XCTAssertEqual(c.differenzaDurataSecondi, 1300)
        XCTAssertEqual(try XCTUnwrap(c.differenzaRitmoPer100), -20, accuracy: 0.0001)   // b più veloce

        let inverso = ConfrontoNuotate(a: b, b: a)
        XCTAssertEqual(inverso.differenzaMetri, -500)
        XCTAssertEqual(inverso.differenzaDurataSecondi, -1300)
        XCTAssertEqual(try XCTUnwrap(inverso.differenzaRitmoPer100), 20, accuracy: 0.0001)
    }

    func testRitmoMancanteDaUnaParte() {
        let a = Prova.nuotata(10, 2, metri: 500, durata: 1500)
        let senzaMetri = Prova.nuotata(10, 6, metri: 0, durata: 900)
        let c = ConfrontoNuotate(a: a, b: senzaMetri)
        XCTAssertNil(c.differenzaRitmoPer100)
        XCTAssertEqual(c.differenzaMetri, -500)
        XCTAssertEqual(c.differenzaDurataSecondi, -600)
        XCTAssertNil(ConfrontoNuotate(a: senzaMetri, b: a).differenzaRitmoPer100)
        XCTAssertNil(ConfrontoNuotate(a: senzaMetri, b: senzaMetri).differenzaRitmoPer100)
    }

    func testStessaNuotata() throws {
        let a = Prova.nuotata(10, 2, metri: 500, durata: 1500)
        let c = ConfrontoNuotate(a: a, b: a)
        XCTAssertEqual(c.differenzaMetri, 0)
        XCTAssertEqual(c.differenzaDurataSecondi, 0)
        XCTAssertEqual(try XCTUnwrap(c.differenzaRitmoPer100), 0, accuracy: 0.0001)
    }
}
