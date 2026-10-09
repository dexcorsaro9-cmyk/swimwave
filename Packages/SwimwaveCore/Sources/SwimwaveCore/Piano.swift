import Foundation

extension Workout {
    /// Metri totali dell'allenamento (ripetizioni x distanza, su tutte le serie).
    public var metriTotali: Int {
        blocchi.reduce(0) { somma, blocco in
            somma + blocco.serie.reduce(0) { $0 + $1.ripetizioni * $1.distanzaMetri }
        }
    }
}

/// Una ripetizione da nuotare: l'unità che il Watch mostra e fa avanzare.
public struct Passo: Equatable, Sendable {
    public let tipoBlocco: TipoBlocco
    /// Posizione della serie in tutto l'allenamento (0 = prima serie), per la barra delle serie.
    public let indiceSerie: Int
    /// Ripetizione corrente dentro la serie, da 1.
    public let ripetizione: Int
    public let ripetizioniTotali: Int
    public let distanzaMetri: Int
    public let stile: Stile
    public let intensita: Intensita?
    public let drill: String?
    /// Recupero dopo questa ripetizione (0 se non previsto o se è l'ultima della serie).
    public let recuperoSecondi: Int
}

/// Allenamento "spianato" in una lista di ripetizioni.
public struct PianoAllenamento: Equatable, Sendable {
    public let titolo: String
    public let vascaMetri: Int
    public let passi: [Passo]
    public let serieTotali: Int

    public init(workout: Workout) {
        var passi: [Passo] = []
        var indiceSerie = 0
        for blocco in workout.blocchi {
            for serie in blocco.serie {
                let n = max(1, serie.ripetizioni)
                for r in 1...n {
                    // Il recupero separa una ripetizione dalla successiva della stessa serie.
                    // Dopo l'ultima ripetizione di una serie non c'è recupero fisso: si passa alla serie seguente.
                    let recupero = (r < n) ? (serie.recuperoSecondi ?? 0) : 0
                    passi.append(Passo(
                        tipoBlocco: blocco.tipo,
                        indiceSerie: indiceSerie,
                        ripetizione: r,
                        ripetizioniTotali: n,
                        distanzaMetri: serie.distanzaMetri,
                        stile: serie.stile,
                        intensita: serie.intensita,
                        drill: serie.drill,
                        recuperoSecondi: recupero
                    ))
                }
                indiceSerie += 1
            }
        }
        self.titolo = workout.titolo
        self.vascaMetri = workout.vascaMetri
        self.passi = passi
        self.serieTotali = indiceSerie
    }

    public var metriTotali: Int { passi.reduce(0) { $0 + $1.distanzaMetri } }

    /// Metri delle ripetizioni precedenti a `indice`.
    public func metriPrima(di indice: Int) -> Int {
        passi.prefix(max(0, indice)).reduce(0) { $0 + $1.distanzaMetri }
    }
}

/// Dove si trova il nuotatore nel piano. Logica pura: il Watch la pilota con i metri di HealthKit o con il pulsante.
public struct AvanzamentoAllenamento: Equatable, Sendable {
    public enum Fase: Equatable, Sendable {
        case nuoto
        case recupero(secondi: Int)
        case finito
    }

    public let piano: PianoAllenamento
    public private(set) var indice: Int
    public private(set) var fase: Fase
    /// Metri delle ripetizioni segnate come fatte. Chiudere in anticipo non conta quelle non nuotate.
    public private(set) var metriNuotati: Int

    public init(piano: PianoAllenamento) {
        self.piano = piano
        self.indice = 0
        self.metriNuotati = 0
        self.fase = piano.passi.isEmpty ? .finito : .nuoto
    }

    public var passoCorrente: Passo? {
        piano.passi.indices.contains(indice) ? piano.passi[indice] : nil
    }

    /// Metri completati nelle ripetizioni già finite.
    public var metriCompletati: Int { metriNuotati }

    /// La ripetizione corrente è stata nuotata. Con recupero previsto si passa al recupero, altrimenti alla ripetizione seguente.
    public mutating func completaPasso() {
        guard fase == .nuoto, let passo = passoCorrente else { return }
        metriNuotati += passo.distanzaMetri
        let ultimo = indice >= piano.passi.count - 1
        if ultimo {
            fase = .finito
            indice = piano.passi.count
        } else if passo.recuperoSecondi > 0 {
            fase = .recupero(secondi: passo.recuperoSecondi)
        } else {
            indice += 1
        }
    }

    /// Il recupero è finito (tempo scaduto o pulsante): si riparte con la ripetizione seguente.
    public mutating func finisciRecupero() {
        guard case .recupero = fase else { return }
        indice += 1
        fase = .nuoto
    }

    /// Chiude l'allenamento in anticipo.
    public mutating func termina() {
        fase = .finito
        indice = piano.passi.count
    }
}
