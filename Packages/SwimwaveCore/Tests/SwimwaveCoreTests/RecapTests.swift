import XCTest
@testable import SwimwaveCore

final class RecapTests: XCTestCase {
    private func nuotata(giorno: Int, metri: Int, minuti: Int) -> NuotataCompletata {
        NuotataCompletata(data: Date(timeIntervalSince1970: 1_700_000_000 + Double(giorno) * 86_400),
                          metri: metri, durataSecondi: minuti * 60, titolo: "x")
    }

    func testLaPrimaNuotataNonHaRecord() {
        let n = nuotata(giorno: 1, metri: 600, minuti: 20)
        let e = Recap.evidenze(nuotata: n, precedenti: [], metriPrevisti: 600, sensazione: .giusta, progresso: nil, serieSettimane: 0)
        XCTAssertEqual(e, [.programmaCompleto])
    }

    func testNuotataPiuLungaERitmoMigliore() {
        let prima = nuotata(giorno: 1, metri: 500, minuti: 20)            // 4:00 ogni 100 m
        let oggi = nuotata(giorno: 5, metri: 800, minuti: 28)             // 3:30 ogni 100 m
        let e = Recap.evidenze(nuotata: oggi, precedenti: [prima], metriPrevisti: 800, sensazione: .giusta, progresso: nil, serieSettimane: 0)
        XCTAssertEqual(e, [.piuLunga(metri: 800), .ritmoMigliore(secondiPer100: 210), .programmaCompleto])
    }

    func testPiuVeloceDellUltimaSenzaRecord() {
        let vecchia = nuotata(giorno: 1, metri: 800, minuti: 24)          // 3:00 ogni 100 m (la migliore)
        let ultima = nuotata(giorno: 3, metri: 800, minuti: 32)           // 4:00 ogni 100 m
        let oggi = nuotata(giorno: 5, metri: 600, minuti: 22)             // 3:40 ogni 100 m: non è un record, ma batte l'ultima di 20 s
        let e = Recap.evidenze(nuotata: oggi, precedenti: [vecchia, ultima], metriPrevisti: 0, sensazione: .giusta, progresso: nil, serieSettimane: 0)
        XCTAssertEqual(e, [.piuVeloceDellUltima(secondi: 20)])
    }

    func testDopoUnaDuraNientePrimatiESoloProgrammaEObiettivo() {
        let prima = nuotata(giorno: 1, metri: 500, minuti: 25)
        let oggi = nuotata(giorno: 5, metri: 900, minuti: 27)
        let e = Recap.evidenze(nuotata: oggi, precedenti: [prima], metriPrevisti: 1200, sensazione: .dura,
                               progresso: ProgressoSettimanale(nuotate: 2, obiettivo: 3), serieSettimane: 5)
        XCTAssertEqual(e, [.programmaParziale(fatti: 900, previsti: 1200), .obiettivoSettimana(fatte: 2, totale: 3)])
    }

    func testAlMassimoTreEvidenze() {
        let prima = nuotata(giorno: 1, metri: 500, minuti: 20)
        let oggi = nuotata(giorno: 5, metri: 800, minuti: 28)
        let e = Recap.evidenze(nuotata: oggi, precedenti: [prima], metriPrevisti: 800, sensazione: .giusta,
                               progresso: ProgressoSettimanale(nuotate: 3, obiettivo: 3), serieSettimane: 4)
        XCTAssertEqual(e.count, Recap.massimoEvidenze)
    }

    func testErroreConsigliatoSoloSeCollegatoAiDrillUsati() {
        func errore(_ id: String, _ drill: [String]) -> ErroreComune {
            ErroreComune(id: id, nome: id, comeSiRiconosce: "a", perche: "b", correzione: "c", drill: drill, fonti: [], stato: .approvato)
        }
        func serie(_ d: String?) -> Serie { Serie(ripetizioni: 1, distanzaMetri: 25, stile: .libero, drill: d) }
        let w = Workout(titolo: "x", vascaMetri: 25, durataStimataMin: 20,
                        blocchi: [Blocco(tipo: .tecnica, serie: [serie("catch-up"), serie(nil)])])
        let errori = [errore("b-mulino", ["catch-up"]), errore("a-incrociate", ["catch-up", "altro"]), errore("z-altro", ["altro"])]
        XCTAssertEqual(Recap.erroreConsigliato(workout: w, errori: errori, giorno: 0)?.id, "a-incrociate")
        XCTAssertEqual(Recap.erroreConsigliato(workout: w, errori: errori, giorno: 1)?.id, "b-mulino")
        let senzaDrill = Workout(titolo: "y", vascaMetri: 25, durataStimataMin: 20, blocchi: [Blocco(tipo: .principale, serie: [serie(nil)])])
        XCTAssertNil(Recap.erroreConsigliato(workout: senzaDrill, errori: errori, giorno: 0))
        XCTAssertNil(Recap.erroreConsigliato(workout: w, errori: [errore("z", ["altro"])], giorno: 0))
    }
}
