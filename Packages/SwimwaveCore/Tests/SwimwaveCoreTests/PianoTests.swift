import XCTest
@testable import SwimwaveCore

final class PianoTests: XCTestCase {
    private func workout() -> Workout {
        Workout(titolo: "Prova", vascaMetri: 25, durataStimataMin: 20, blocchi: [
            Blocco(tipo: .riscaldamento, serie: [Serie(ripetizioni: 1, distanzaMetri: 50, stile: .libero, intensita: .facile)]),
            Blocco(tipo: .principale, serie: [Serie(ripetizioni: 3, distanzaMetri: 25, stile: .libero, intensita: .media, recuperoSecondi: 20)]),
        ])
    }

    func testMetriTotali() {
        XCTAssertEqual(workout().metriTotali, 125)
        XCTAssertEqual(PianoAllenamento(workout: workout()).metriTotali, 125)
    }

    func testPassiESerie() {
        let piano = PianoAllenamento(workout: workout())
        XCTAssertEqual(piano.passi.count, 4)
        XCTAssertEqual(piano.serieTotali, 2)
        XCTAssertEqual(piano.passi[0].recuperoSecondi, 0)
        XCTAssertEqual(piano.passi[1].recuperoSecondi, 20)
        XCTAssertEqual(piano.passi[2].recuperoSecondi, 20)
        XCTAssertEqual(piano.passi[3].recuperoSecondi, 0, "dopo l'ultima ripetizione della serie non c'è recupero")
        XCTAssertEqual(piano.passi[3].ripetizione, 3)
        XCTAssertEqual(piano.passi[3].indiceSerie, 1)
        XCTAssertEqual(piano.metriPrima(di: 2), 75)
    }

    func testAvanzamentoConRecupero() {
        var a = AvanzamentoAllenamento(piano: PianoAllenamento(workout: workout()))
        XCTAssertEqual(a.fase, .nuoto)
        a.completaPasso()                       // 50 m finiti, nessun recupero
        XCTAssertEqual(a.indice, 1)
        XCTAssertEqual(a.fase, .nuoto)
        XCTAssertEqual(a.metriCompletati, 50)
        a.completaPasso()                       // prima ripetizione da 25 m: recupero 20 s
        XCTAssertEqual(a.fase, .recupero(secondi: 20))
        a.completaPasso()                       // ignorato durante il recupero
        XCTAssertEqual(a.indice, 1)
        a.finisciRecupero()
        XCTAssertEqual(a.indice, 2)
        XCTAssertEqual(a.fase, .nuoto)
        a.completaPasso()
        a.finisciRecupero()
        a.completaPasso()                       // ultima ripetizione
        XCTAssertEqual(a.fase, .finito)
        XCTAssertNil(a.passoCorrente)
        XCTAssertEqual(a.metriCompletati, 125)
    }

    func testTermina() {
        var a = AvanzamentoAllenamento(piano: PianoAllenamento(workout: workout()))
        a.termina()
        XCTAssertEqual(a.fase, .finito)
    }

    func testPianoVuoto() {
        let w = Workout(titolo: "x", vascaMetri: 25, durataStimataMin: 5, blocchi: [])
        XCTAssertEqual(AvanzamentoAllenamento(piano: PianoAllenamento(workout: w)).fase, .finito)
    }

    func testMessaggiWatch() throws {
        let w = workout()
        let ctx = try MessaggiWatch.contesto(allenamento: w)
        XCTAssertEqual(MessaggiWatch.allenamento(da: ctx), w)
        XCTAssertNil(MessaggiWatch.allenamento(da: [:]))

        let n = NuotataCompletata(data: Date(timeIntervalSince1970: 1_800_000_000), metri: 500, durataSecondi: 1800, titolo: "Prova")
        let info = try MessaggiWatch.userInfo(nuotata: n)
        XCTAssertEqual(MessaggiWatch.nuotata(da: info), n)
    }
}
