import XCTest
@testable import SwimwaveCore

final class WorkoutTests: XCTestCase {
    private let drills: Set<String> = ["catch-up"]

    private func fixtureData() throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "resistenza-base", withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    func testEsempioDelFormatoEValido() throws {
        let risultato = WorkoutValidator.decodeAndValidate(try fixtureData(), allowedDrills: drills)
        guard case .success(let workout) = risultato else {
            return XCTFail("atteso successo, ottenuto \(risultato)")
        }
        XCTAssertEqual(workout.titolo, "Resistenza base")
        XCTAssertEqual(workout.vascaMetri, 25)
        XCTAssertEqual(workout.blocchi.count, 4)
        XCTAssertEqual(workout.blocchi[1].serie[0].drill, "catch-up")
        XCTAssertEqual(workout.blocchi[2].serie[0].recuperoSecondi, 20)
    }

    func testRifiutaDrillFuoriLista() throws {
        var workout = try JSONDecoder().decode(Workout.self, from: try fixtureData())
        workout.blocchi[1].serie[0].drill = "inventato"
        let errori = WorkoutValidator.validate(workout, allowedDrills: drills)
        XCTAssertEqual(errori.count, 1)
        XCTAssertTrue(errori[0].messaggio.contains("lista chiusa"))
    }

    func testRifiutaDistanzaNonMultiplaDellaVasca() throws {
        var workout = try JSONDecoder().decode(Workout.self, from: try fixtureData())
        workout.blocchi[2].serie[0].distanzaMetri = 110
        let errori = WorkoutValidator.validate(workout, allowedDrills: drills)
        XCTAssertEqual(errori.count, 1)
        XCTAssertTrue(errori[0].messaggio.contains("multipla"))
    }

    func testRifiutaStileSconosciuto() {
        let json = """
        {"titolo":"X","vasca_metri":25,"durata_stimata_min":30,
         "blocchi":[{"tipo":"principale","serie":[{"ripetizioni":1,"distanza_m":50,"stile":"farfalla"}]}]}
        """
        let risultato = WorkoutValidator.decodeAndValidate(Data(json.utf8), allowedDrills: drills)
        guard case .failure = risultato else { return XCTFail("atteso fallimento") }
    }

    func testCodificaMantieneLeChiaviDelContratto() throws {
        let workout = try JSONDecoder().decode(Workout.self, from: try fixtureData())
        let data = try JSONEncoder().encode(workout)
        let testo = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(testo.contains("\"vasca_metri\""))
        XCTAssertTrue(testo.contains("\"distanza_m\""))
        XCTAssertTrue(testo.contains("\"recupero_s\""))
    }
}
