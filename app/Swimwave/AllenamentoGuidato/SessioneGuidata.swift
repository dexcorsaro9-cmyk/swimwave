import Foundation
import SwimwaveCore

/// Allenamento da seguire sul telefono (serve a `fullScreenCover(item:)`).
struct AllenamentoDaSeguire: Identifiable {
    let id = UUID()
    let workout: Workout
}

/// Stato di un allenamento seguito sul telefono: la logica delle ripetizioni è quella di SwimwaveCore
/// (`AvanzamentoAllenamento`), qui si aggiungono solo il tempo e la pausa.
///
/// Il tempo non si ricalcola da una data fissa: si accumulano i tratti in cui il cronometro correva, così la pausa
/// conserva il tempo trascorso e il recupero riparte da dove si era fermato.
/// I metodi ricevono `adesso` come parametro: nessun timer qui dentro, la vista li chiama a ogni battito.
struct SessioneGuidata {
    private(set) var avanzamento: AvanzamentoAllenamento
    private(set) var inPausa = false
    /// Metri delle ripetizioni segnate come fatte. Si tiene qui il conto perché `metriCompletati` del pacchetto
    /// vale tutto il piano dopo `termina()` e non include la ripetizione appena finita durante il recupero.
    private(set) var metriFatti = 0

    private var accumulato: TimeInterval = 0
    private var inizioTratto: Date?
    private var fineRecupero: Date?
    private var recuperoInPausa: TimeInterval = 0

    init(workout: Workout, adesso: Date = Date()) {
        avanzamento = AvanzamentoAllenamento(piano: PianoAllenamento(workout: workout))
        inizioTratto = adesso
        if avanzamento.fase == .finito {
            inizioTratto = nil
        }
    }

    var finito: Bool { avanzamento.fase == .finito }

    var inRecupero: Bool {
        if case .recupero = avanzamento.fase { return true }
        return false
    }

    /// La ripetizione dopo quella corrente, per anticiparla durante il recupero.
    var prossimoPasso: Passo? {
        let i = avanzamento.indice + 1
        let passi = avanzamento.piano.passi
        return passi.indices.contains(i) ? passi[i] : nil
    }

    /// Secondi trascorsi dall'inizio (la pausa non conta).
    func tempoTrascorso(adesso: Date) -> Int {
        var totale = accumulato
        if let t = inizioTratto {
            totale += max(0, adesso.timeIntervalSince(t))
        }
        return Int(totale)
    }

    /// Secondi che mancano alla fine del recupero (0 se non si è in recupero).
    func recuperoRimanente(adesso: Date) -> Int {
        guard inRecupero else { return 0 }
        let residuo: TimeInterval
        if inPausa {
            residuo = recuperoInPausa
        } else if let fine = fineRecupero {
            residuo = fine.timeIntervalSince(adesso)
        } else {
            residuo = 0
        }
        return max(0, Int(residuo.rounded(.up)))
    }

    /// La ripetizione corrente è stata nuotata.
    mutating func completaPasso(adesso: Date) {
        guard !inPausa, avanzamento.fase == .nuoto, let passo = avanzamento.passoCorrente else { return }
        metriFatti += passo.distanzaMetri
        avanzamento.completaPasso()
        if case .recupero(let secondi) = avanzamento.fase {
            fineRecupero = adesso.addingTimeInterval(TimeInterval(secondi))
            recuperoInPausa = TimeInterval(secondi)
        } else {
            fineRecupero = nil
        }
        if finito {
            congela(adesso: adesso)
        }
    }

    /// Da chiamare a ogni battito dell'orologio: a recupero scaduto si riparte da soli.
    /// Restituisce true se è appena finito il recupero.
    @discardableResult
    mutating func aggiorna(adesso: Date) -> Bool {
        guard !inPausa, inRecupero, let fine = fineRecupero, adesso >= fine else { return false }
        avanzamento.finisciRecupero()
        fineRecupero = nil
        return true
    }

    /// Si salta il resto del recupero e si riparte.
    mutating func saltaRecupero() {
        guard !inPausa, inRecupero else { return }
        avanzamento.finisciRecupero()
        fineRecupero = nil
    }

    mutating func pausa(adesso: Date) {
        guard !inPausa, !finito else { return }
        if let t = inizioTratto {
            accumulato += max(0, adesso.timeIntervalSince(t))
        }
        inizioTratto = nil
        if let fine = fineRecupero {
            recuperoInPausa = max(0, fine.timeIntervalSince(adesso))
        }
        inPausa = true
    }

    mutating func riprendi(adesso: Date) {
        guard inPausa, !finito else { return }
        inizioTratto = adesso
        if inRecupero {
            fineRecupero = adesso.addingTimeInterval(recuperoInPausa)
        }
        inPausa = false
    }

    /// Chiude l'allenamento in anticipo. I metri contati sono quelli delle ripetizioni già segnate.
    mutating func termina(adesso: Date) {
        avanzamento.termina()
        fineRecupero = nil
        congela(adesso: adesso)
    }

    private mutating func congela(adesso: Date) {
        if let t = inizioTratto {
            accumulato += max(0, adesso.timeIntervalSince(t))
        }
        inizioTratto = nil
        inPausa = false
    }
}
