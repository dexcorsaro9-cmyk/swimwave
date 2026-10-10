import XCTest
@testable import SwimwaveCore

final class ProfiloTests: XCTestCase {
    func testProfiloVuotoHaTuttiICampiObbligatoriMancanti() {
        let p = Profilo()
        // vasca e ritmo partono con i valori predefiniti (25 m, Libero)
        XCTAssertEqual(p.campiMancanti, [.coach, .nome, .livello])
        XCTAssertFalse(p.isCompleto)
    }

    func testProfiloCompletoConRitmoLibero() {
        let p = Profilo(coach: .donna, nome: "Paola", livello: .menoDi100)
        XCTAssertTrue(p.isCompleto)
        XCTAssertNil(p.obiettivoSettimanale)
        XCTAssertEqual(p.obiettivoEffettivo, .tecnica)
    }

    func testNomeSoloSpaziNonVale() {
        let p = Profilo(coach: .uomo, nome: "   ", livello: .cento)
        XCTAssertEqual(p.campiMancanti, [.nome])
    }

    func testNomeTroppoLungoNonVale() {
        let p = Profilo(coach: .uomo, nome: String(repeating: "a", count: 31), livello: .cento)
        XCTAssertEqual(p.campiMancanti, [.nome])
    }

    func testNomeVieneRitagliato() {
        XCTAssertEqual(Profilo(nome: "  Luca \n").nomePulito, "Luca")
    }

    func testFrequenzaObbligatoriaSoloConRitmoRegolareOSpronami() {
        var p = Profilo(coach: .uomo, nome: "Luca", livello: .cento)
        p.ritmo = .regolare
        XCTAssertEqual(p.campiMancanti, [.frequenza])
        p.frequenzaSettimanale = 3
        XCTAssertTrue(p.isCompleto)
        XCTAssertEqual(p.obiettivoSettimanale, 3)
        p.ritmo = .libero
        XCTAssertNil(p.obiettivoSettimanale)
        XCTAssertTrue(p.isCompleto)
    }

    func testFrequenzaFuoriDa1a5NonVale() {
        var p = Profilo(coach: .uomo, nome: "Luca", livello: .cento, ritmo: .spronami, frequenzaSettimanale: 6)
        XCTAssertEqual(p.campiMancanti, [.frequenza])
        XCTAssertNil(p.obiettivoSettimanale)
        p.frequenzaSettimanale = 0
        XCTAssertEqual(p.campiMancanti, [.frequenza])
    }

    func testScegliRitmoProponeFrequenzaPredefinita() {
        var p = Profilo(coach: .uomo, nome: "Luca", livello: .cento)
        p.scegli(ritmo: .spronami)
        XCTAssertEqual(p.frequenzaSettimanale, Profilo.frequenzaPredefinita)
        p.frequenzaSettimanale = 4
        p.scegli(ritmo: .regolare)
        XCTAssertEqual(p.frequenzaSettimanale, 4)
    }

    func testVascaNonLoSoVale25() {
        XCTAssertEqual(Profilo(vasca: .nonLoSo).vascaMetri, 25)
        XCTAssertEqual(Profilo(vasca: .metri50).vascaMetri, 50)
    }

    func testVascheNonConvenzionali() {
        XCTAssertEqual(Profilo(vasca: .metri16).vascaMetri, 16)
        XCTAssertEqual(Profilo(vasca: .metri20).vascaMetri, 20)
        XCTAssertEqual(Profilo(vasca: .metri33).vascaMetri, 33)
    }

    func testAltraMisura() {
        var p = Profilo(vasca: .metri25)
        p.vasca = .altra
        XCTAssertEqual(p.vascaPersonalizzata, 25)  // proposta di partenza
        p.vascaPersonalizzata = 18
        XCTAssertEqual(p.vascaMetri, 18)
        p.vascaPersonalizzata = 500
        XCTAssertEqual(p.vascaMetri, 25)           // fuori limiti: valore prudente
        XCTAssertTrue(p.campiMancanti.contains(.vasca))
        XCTAssertFalse(Vasca.opzioniLavagnetta.contains(.altra))
    }

    func testProfiloVecchioSenzaMisuraLiberaSiDecodifica() throws {
        let json = #"{"nome":"Anna","vasca":"metri50","ritmo":"libero"}"#.data(using: .utf8)!
        let p = try JSONDecoder().decode(Profilo.self, from: json)
        XCTAssertEqual(p.vascaMetri, 50)
        XCTAssertNil(p.vascaPersonalizzata)
    }

    func testLivelloCategoriaETappa() {
        XCTAssertEqual(Livello.menoDi25.categoria, .principiante)
        XCTAssertEqual(Livello.menoDi100.categoria, .principiante)
        XCTAssertEqual(Livello.cento.categoria, .intermedio)
        XCTAssertEqual(Livello.piuDiCento.categoria, .intermedio)
        XCTAssertEqual(Livello.menoDi25.tappaDiPartenza, 1)
    }

    func testCodificaERilettura() throws {
        let p = Profilo(coach: .donna, nome: "Paola", livello: .cento, obiettivo: .resistenza,
                        vasca: .metri50, ritmo: .regolare, frequenzaSettimanale: 3)
        let data = try JSONEncoder().encode(p)
        XCTAssertEqual(try JSONDecoder().decode(Profilo.self, from: data), p)
    }

    func testCoachImmagini() {
        XCTAssertEqual(CoachID.uomo.nome, "Antonio")
        XCTAssertEqual(CoachID.donna.prefissoImmagini, "pamela")
    }
}
