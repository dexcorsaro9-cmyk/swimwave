import XCTest
@testable import SwimwaveCore

final class PrimatiTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar.italiano
        c.timeZone = TimeZone(identifier: "Europe/Rome")!
        return c
    }()

    private func data(_ giorno: Int, mese: Int = 10, ora: Int = 10) -> Date {
        cal.date(from: DateComponents(year: 2026, month: mese, day: giorno, hour: ora))!
    }

    private func vasche(_ durate: [Double], metri: Int = 25, stile: Stile = .libero, inizio: Double = 0, pausaDopo: [Int: Double] = [:]) -> [SplitVasca] {
        var t = inizio
        var risultato: [SplitVasca] = []
        for (i, d) in durate.enumerated() {
            risultato.append(SplitVasca(metri: metri, durataSecondi: d, stile: stile, inizioSecondi: t))
            t += d + (pausaDopo[i] ?? 0)
        }
        return risultato
    }

    // MARK: Migliori tempi

    func testMiglioriTempiVascheConsecutive() {
        let n = NuotataCompletata(data: data(5), metri: 200, durataSecondi: 170, titolo: "x",
                                  vasche: vasche([20, 20, 20, 20, 22, 22, 22, 22]))
        let r = MiglioriTempi.calcola(nuotate: [n], distanze: [50, 100, 200])
        XCTAssertEqual(r.map(\.distanzaMetri), [50, 100, 200])
        XCTAssertEqual(r[0].secondi, 40, accuracy: 0.0001)
        XCTAssertEqual(r[1].secondi, 80, accuracy: 0.0001)
        XCTAssertEqual(r[2].secondi, 168, accuracy: 0.0001)
        XCTAssertEqual(r[0].nuotataId, n.id)
    }

    func testUnaSostaInterrompeLeVasche() {
        // 20, 20, sosta di 30 s, 20, 20: non esistono 100 m consecutivi.
        let n = NuotataCompletata(data: data(5), metri: 100, durataSecondi: 140, titolo: "x",
                                  vasche: vasche([20, 20, 20, 20], pausaDopo: [1: 30]))
        let r = MiglioriTempi.calcola(nuotate: [n], distanze: [50, 100])
        XCTAssertEqual(r.map(\.distanzaMetri), [50])
        XCTAssertEqual(r[0].secondi, 40, accuracy: 0.0001)
    }

    func testSoloLoStileRichiestoESoloConGliIstanti() {
        let rana = NuotataCompletata(data: data(5), metri: 100, durataSecondi: 200, titolo: "x",
                                     vasche: vasche([25, 25, 25, 25], stile: .rana))
        let senzaIstanti = NuotataCompletata(data: data(6), metri: 100, durataSecondi: 100, titolo: "x",
                                             vasche: [SplitVasca(metri: 50, durataSecondi: 40, stile: .libero)])
        XCTAssertTrue(MiglioriTempi.calcola(nuotate: [rana, senzaIstanti], distanze: [50]).isEmpty)
        XCTAssertEqual(MiglioriTempi.calcola(nuotate: [rana], stile: .rana, distanze: [50]).first?.secondi ?? 0, 50, accuracy: 0.0001)
    }

    func testIlMiglioreTraPiuNuotate() {
        let lenta = NuotataCompletata(data: data(5), metri: 100, durataSecondi: 100, titolo: "a", vasche: vasche([25, 25, 25, 25]))
        let veloce = NuotataCompletata(data: data(7), metri: 100, durataSecondi: 90, titolo: "b", vasche: vasche([22, 22, 22, 22]))
        let r = MiglioriTempi.calcola(nuotate: [lenta, veloce], distanze: [100])
        XCTAssertEqual(r.first?.secondi ?? 0, 88, accuracy: 0.0001)
        XCTAssertEqual(r.first?.nuotataId, veloce.id)
    }

    // MARK: Calendario

    func testCelleDelMese() {
        // 1 ottobre 2026 è giovedì: 3 celle vuote prima (lun, mar, mer), 31 giorni, 1 vuota in fondo (totale 35).
        let n = [NuotataCompletata(data: data(9), metri: 500, durataSecondi: 900, titolo: "x"),
                 NuotataCompletata(data: data(9, ora: 18), metri: 250, durataSecondi: 500, titolo: "y")]
        let celle = CalendarioNuotate.celle(nuotate: n, mese: data(15), calendar: cal)
        XCTAssertEqual(celle.count, 35)
        XCTAssertEqual(celle.prefix(3).compactMap(\.giorno).count, 0)
        XCTAssertEqual(celle[3].giorno, 1)
        XCTAssertEqual(celle[3 + 8].giorno, 9)
        XCTAssertEqual(celle[3 + 8].nuotate, 2)
        XCTAssertEqual(celle[3 + 8].metri, 750)
        XCTAssertEqual(celle[3 + 9].nuotate, 0)
        XCTAssertNil(celle[34].giorno)
    }

    // MARK: Obiettivo mensile

    func testObiettivoMensile() {
        let n = [NuotataCompletata(data: data(2), metri: 500, durataSecondi: 900, titolo: "x"),
                 NuotataCompletata(data: data(8), metri: 1000, durataSecondi: 1800, titolo: "y"),
                 NuotataCompletata(data: data(28, mese: 9), metri: 4000, durataSecondi: 5000, titolo: "z")]
        let p = ObiettivoMensile.progresso(obiettivoMetri: 3000, nuotate: n, rispetto: data(9), calendar: cal)!
        XCTAssertEqual(p.metri, 1500)
        XCTAssertEqual(p.mancano, 1500)
        XCTAssertEqual(p.frazione, 0.5, accuracy: 0.0001)
        XCTAssertFalse(p.raggiunto)
        XCTAssertNil(ObiettivoMensile.progresso(obiettivoMetri: nil, nuotate: n, rispetto: data(9), calendar: cal))
        XCTAssertNil(ObiettivoMensile.progresso(obiettivoMetri: 100, nuotate: n, rispetto: data(9), calendar: cal))
        XCTAssertTrue(ObiettivoMensile.progresso(obiettivoMetri: 1000, nuotate: n, rispetto: data(9), calendar: cal)!.raggiunto)
    }

    // MARK: Tempi obiettivo

    private let zone = [
        ZonaRitmo(id: "f", nome: "Facile", descrizione: "", velocitaDaPercentuale: 80, velocitaAPercentuale: 90, fonti: [], stato: .bozza, intensita: ["facile"]),
        ZonaRitmo(id: "c", nome: "Critico", descrizione: "", velocitaDaPercentuale: 97, velocitaAPercentuale: 103, fonti: [], stato: .bozza, intensita: ["forte"]),
    ]

    func testTempoObiettivo() {
        // Ritmo critico 90 s/100 m, zona 80-90%: da 100 a 112,5 s, centro 106,25 s ogni 100 m. Su 50 m: 53,125 -> 53.
        XCTAssertEqual(TargetRitmo.tempoObiettivo(distanzaMetri: 50, intensita: .facile, ritmoCriticoPer100: 90, zone: zone), 53)
        XCTAssertNil(TargetRitmo.tempoObiettivo(distanzaMetri: 50, intensita: .media, ritmoCriticoPer100: 90, zone: zone))
        XCTAssertNil(TargetRitmo.tempoObiettivo(distanzaMetri: 50, intensita: nil, ritmoCriticoPer100: 90, zone: zone))
        XCTAssertNil(TargetRitmo.tempoObiettivo(distanzaMetri: 50, intensita: .facile, ritmoCriticoPer100: nil, zone: zone))
    }

    func testTargetPerPiano() {
        let w = Workout(titolo: "t", vascaMetri: 25, durataStimataMin: 20, blocchi: [
            Blocco(tipo: .principale, serie: [
                Serie(ripetizioni: 2, distanzaMetri: 50, stile: .libero, intensita: .facile),
                Serie(ripetizioni: 1, distanzaMetri: 50, stile: .rana, intensita: .facile),
                Serie(ripetizioni: 1, distanzaMetri: 50, stile: .libero),
            ])
        ])
        let t = TargetRitmo.target(per: PianoAllenamento(workout: w), ritmoCriticoPer100: 90, zone: zone)
        XCTAssertEqual(t, [53, 53, nil, nil])
    }

    // MARK: Richiesta e dati del mese

    func testRichiestaPersonalizzata() {
        XCTAssertFalse(RichiestaAllenamento().personalizzata)
        XCTAssertFalse(RichiestaAllenamento(riepilogo: "ultimo allenamento: dura").personalizzata)
        XCTAssertTrue(RichiestaAllenamento(durataMinuti: 30).personalizzata)
        XCTAssertTrue(RichiestaAllenamento(obiettivo: .resistenza).personalizzata)
    }

    func testDatiMese() {
        let n = [NuotataCompletata(data: data(2), metri: 500, durataSecondi: 900, titolo: "x", sensazione: .facile),
                 NuotataCompletata(data: data(8), metri: 1000, durataSecondi: 1800, titolo: "y", sensazione: .dura),
                 NuotataCompletata(data: data(8, ora: 19), metri: 500, durataSecondi: 600, titolo: "w"),
                 NuotataCompletata(data: data(28, mese: 9), metri: 4000, durataSecondi: 5000, titolo: "z")]
        let p = Profilo(coach: .uomo, nome: "Luca", livello: .cento)
        let d = DatiMese.calcola(nuotate: n, profilo: p, rispetto: data(9), calendar: cal)
        XCTAssertEqual(d.nuotate, 3)
        XCTAssertEqual(d.metri, 2000)
        XCTAssertEqual(d.minuti, 55)
        XCTAssertEqual(d.metriMesePrecedente, 4000)
        XCTAssertEqual(d.facili, 1)
        XCTAssertEqual(d.dure, 1)
        XCTAssertEqual(d.giuste, 0)
    }

    func testZonaConIntensitaSiLegge() throws {
        let json = #"{"id":"a","nome":"A","descrizione":"d","velocita_da_pct":70,"velocita_a_pct":80,"fonti":[],"stato":"bozza","intensita":["facile"]}"#
        let z = try JSONDecoder().decode(ZonaRitmo.self, from: Data(json.utf8))
        XCTAssertEqual(z.intensita, ["facile"])
        let senza = #"{"id":"a","nome":"A","descrizione":"d","velocita_da_pct":70,"velocita_a_pct":80,"fonti":[],"stato":"bozza"}"#
        XCTAssertNil(try JSONDecoder().decode(ZonaRitmo.self, from: Data(senza.utf8)).intensita)
    }

    func testTargetNelContestoWatch() throws {
        let w = Workout(titolo: "t", vascaMetri: 25, durataStimataMin: 20, blocchi: [
            Blocco(tipo: .principale, serie: [Serie(ripetizioni: 2, distanzaMetri: 50, stile: .libero)])
        ])
        let c = try MessaggiWatch.contesto(allenamento: w, target: [53, nil])
        XCTAssertEqual(MessaggiWatch.target(da: c, passi: 2), [53, nil])
        // Lunghezza diversa dai passi: nessun obiettivo, mai valori sfasati.
        XCTAssertEqual(MessaggiWatch.target(da: c, passi: 3), [nil, nil, nil])
        // Senza target (iPhone vecchio): nessun obiettivo.
        let senza = try MessaggiWatch.contesto(allenamento: w)
        XCTAssertEqual(MessaggiWatch.target(da: senza, passi: 2), [nil, nil])
        XCTAssertNotNil(MessaggiWatch.allenamento(da: c))
    }
}
