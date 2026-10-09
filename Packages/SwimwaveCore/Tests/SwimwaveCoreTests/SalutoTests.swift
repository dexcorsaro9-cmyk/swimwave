import XCTest
@testable import SwimwaveCore

final class SalutoTests: XCTestCase {
    func testFasceOrarie() {
        XCTAssertEqual(FasciaOraria(ora: 4), .sera)
        XCTAssertEqual(FasciaOraria(ora: 5), .mattina)
        XCTAssertEqual(FasciaOraria(ora: 12), .mattina)
        XCTAssertEqual(FasciaOraria(ora: 13), .pomeriggio)
        XCTAssertEqual(FasciaOraria(ora: 17), .pomeriggio)
        XCTAssertEqual(FasciaOraria(ora: 18), .sera)
        XCTAssertEqual(FasciaOraria(ora: 23), .sera)
        XCTAssertEqual(FasciaOraria(ora: 0), .sera)
    }

    func testTestoConNome() {
        XCTAssertEqual(Saluto(fascia: .mattina, nome: "Luca").testoItaliano, "Buongiorno, Luca")
        XCTAssertEqual(Saluto(fascia: .pomeriggio, nome: "Luca").testoItaliano, "Buon pomeriggio, Luca")
        XCTAssertEqual(Saluto(fascia: .sera, nome: " Paola ").testoItaliano, "Buonasera, Paola")
    }

    func testSenzaNome() {
        XCTAssertEqual(Saluto(fascia: .sera, nome: "  ").testoItaliano, "Buonasera")
    }

    func testDaData() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Rome"))
        let data = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 10, day: 9, hour: 19, minute: 30)))
        XCTAssertEqual(Saluto(nome: "Paola", data: data, calendar: cal).fascia, .sera)
    }
}
