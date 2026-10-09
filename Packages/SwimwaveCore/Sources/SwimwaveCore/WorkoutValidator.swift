import Foundation

/// Errore di validazione di un allenamento.
public struct WorkoutValidationError: Error, Equatable, Sendable, CustomStringConvertible {
    public let posizione: String
    public let messaggio: String

    public init(posizione: String, messaggio: String) {
        self.posizione = posizione
        self.messaggio = messaggio
    }

    public var description: String { "\(posizione): \(messaggio)" }
}

/// Stesse regole di server/coach/src/validate.js. I limiti numerici rispecchiano lo schema JSON.
public enum WorkoutValidator {
    public static func validate(_ workout: Workout, allowedDrills: Set<String>) -> [WorkoutValidationError] {
        var errori: [WorkoutValidationError] = []

        if workout.titolo.isEmpty || workout.titolo.count > 80 {
            errori.append(.init(posizione: "titolo", messaggio: "deve avere da 1 a 80 caratteri"))
        }
        if !(10...100).contains(workout.vascaMetri) {
            errori.append(.init(posizione: "vasca_metri", messaggio: "fuori dai limiti (10-100)"))
        }
        if !(5...180).contains(workout.durataStimataMin) {
            errori.append(.init(posizione: "durata_stimata_min", messaggio: "fuori dai limiti (5-180)"))
        }
        if workout.blocchi.isEmpty || workout.blocchi.count > 8 {
            errori.append(.init(posizione: "blocchi", messaggio: "servono da 1 a 8 blocchi"))
        }

        for (i, blocco) in workout.blocchi.enumerated() {
            if blocco.serie.isEmpty || blocco.serie.count > 12 {
                errori.append(.init(posizione: "blocchi[\(i)].serie", messaggio: "servono da 1 a 12 serie"))
            }
            for (j, serie) in blocco.serie.enumerated() {
                let dove = "blocchi[\(i)].serie[\(j)]"
                if !(1...50).contains(serie.ripetizioni) {
                    errori.append(.init(posizione: dove, messaggio: "ripetizioni fuori dai limiti (1-50)"))
                }
                if !(10...2000).contains(serie.distanzaMetri) {
                    errori.append(.init(posizione: dove, messaggio: "distanza_m fuori dai limiti (10-2000)"))
                } else if workout.vascaMetri > 0, serie.distanzaMetri % workout.vascaMetri != 0 {
                    errori.append(.init(
                        posizione: dove,
                        messaggio: "distanza_m \(serie.distanzaMetri) non è multipla della vasca (\(workout.vascaMetri) m)"
                    ))
                }
                if let recupero = serie.recuperoSecondi, !(0...600).contains(recupero) {
                    errori.append(.init(posizione: dove, messaggio: "recupero_s fuori dai limiti (0-600)"))
                }
                if let drill = serie.drill {
                    if drill.isEmpty || drill.count > 60 {
                        errori.append(.init(posizione: dove, messaggio: "drill deve avere da 1 a 60 caratteri"))
                    } else if !allowedDrills.contains(drill) {
                        errori.append(.init(posizione: dove, messaggio: "drill \"\(drill)\" non è nella lista chiusa"))
                    }
                }
            }
        }
        return errori
    }

    /// Decodifica e valida in un passo. Restituisce l'allenamento o l'elenco degli errori.
    public static func decodeAndValidate(
        _ data: Data,
        allowedDrills: Set<String>
    ) -> Result<Workout, ElencoErroriWorkout> {
        let workout: Workout
        do {
            workout = try JSONDecoder().decode(Workout.self, from: data)
        } catch {
            return .failure(ElencoErroriWorkout(errori: [.init(posizione: "/", messaggio: "JSON non conforme al formato: \(error.localizedDescription)")]))
        }
        let errori = validate(workout, allowedDrills: allowedDrills)
        return errori.isEmpty ? .success(workout) : .failure(ElencoErroriWorkout(errori: errori))
    }
}

/// L'elenco degli errori di validazione, in un tipo che è un `Error` (un array da solo non lo è: serve a `Result`).
public struct ElencoErroriWorkout: Error, Sendable {
    public let errori: [WorkoutValidationError]
    public init(errori: [WorkoutValidationError]) { self.errori = errori }
}
