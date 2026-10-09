import XCTest
@testable import SwimwaveCore

final class ObiettivoSettimanaleTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar.italiano
        c.timeZone = TimeZone(identifier: "Europe/Rome")!
        return c
    }()

    private func data(_ g: Int, _ ora: Int = 10, mese: Int = 10) -> Date {
        cal.date(from: DateComponents(year: 2026, month: mese, day: g, hour: ora))!
    }

    // 9 ottobre 2026 è un venerdì: la settimana va da lunedì 5 a domenica 11.
    func testContaSoloLaSettimanaDelRiferimento() {
        let nuotate = [data(4, 23), data(5, 7), data(7), data(11, 22), data(12, 6)]
        XCTAssertEqual(ObiettivoSettimanale.conteggio(date: nuotate, rispetto: data(9), calendar: cal), 3)
    }

    func testPiuNuotateNelloStessoGiornoContanoTutte() {
        let nuotate = [data(6, 8), data(6, 18)]
        XCTAssertEqual(ObiettivoSettimanale.conteggio(date: nuotate, rispetto: data(9), calendar: cal), 2)
    }

    func testNessunaNuotata() {
        XCTAssertEqual(ObiettivoSettimanale.conteggio(date: [], rispetto: data(9), calendar: cal), 0)
    }

    func testMancanti() {
        XCTAssertEqual(ProgressoSettimanale(nuotate: 0, obiettivo: 3).mancanti, .piu(3))
        XCTAssertEqual(ProgressoSettimanale(nuotate: 2, obiettivo: 3).mancanti, .uno)
        XCTAssertEqual(ProgressoSettimanale(nuotate: 3, obiettivo: 3).mancanti, .raggiunto)
        XCTAssertEqual(ProgressoSettimanale(nuotate: 5, obiettivo: 3).mancanti, .raggiunto)
        XCTAssertTrue(ProgressoSettimanale(nuotate: 3, obiettivo: 3).raggiunto)
        XCTAssertEqual(ProgressoSettimanale(nuotate: 5, obiettivo: 3).frazione, 1, accuracy: 0.0001)
    }

    func testProgressoSoloConObiettivo() {
        let libero = Profilo(coach: .uomo, nome: "Luca", livello: .cento)
        XCTAssertNil(ObiettivoSettimanale.progresso(profilo: libero, date: [data(6)], rispetto: data(9), calendar: cal))

        let regolare = Profilo(coach: .uomo, nome: "Luca", livello: .cento, ritmo: .regolare, frequenzaSettimanale: 2)
        let p = ObiettivoSettimanale.progresso(profilo: regolare, date: [data(6)], rispetto: data(9), calendar: cal)
        XCTAssertEqual(p, ProgressoSettimanale(nuotate: 1, obiettivo: 2))
        XCTAssertEqual(p?.mancanti, .uno)
    }

    func testIdSettimanaUgualeNellaStessaSettimana() {
        XCTAssertEqual(ObiettivoSettimanale.idSettimana(data(5), calendar: cal), ObiettivoSettimanale.idSettimana(data(11, 23), calendar: cal))
        XCTAssertNotEqual(ObiettivoSettimanale.idSettimana(data(11), calendar: cal), ObiettivoSettimanale.idSettimana(data(12), calendar: cal))
    }
}
