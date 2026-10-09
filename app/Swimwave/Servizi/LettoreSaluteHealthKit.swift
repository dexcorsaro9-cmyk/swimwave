import Foundation
import HealthKit
import SwimwaveCore

/// Legge le nuotate da Apple Salute (allenamenti di tipo nuoto, in vasca e in acque libere), con calorie,
/// frequenza cardiaca media, bracciate, lunghezza della vasca, ambiente e vasche con il loro tempo, quando Salute li ha.
/// Tutto è difensivo: un dato mancante o non plausibile (non finito, negativo, zero) diventa nil, mai un errore.
///
/// Nota: per scelta di Apple, Salute non dice se l'utente ha negato la lettura. Se il permesso è stato negato
/// la ricerca restituisce semplicemente zero risultati: non c'è modo di distinguerlo da "nessuna nuotata".
/// Per questo `richiediPermesso()` restituisce true se la richiesta è stata presentata senza errori.
final class LettoreSaluteHealthKit: LettoreSalute {
    private let store = HKHealthStore()

    private var tipiDaLeggere: Set<HKObjectType> {
        [
            HKObjectType.workoutType(),
            HKQuantityType(.distanceSwimming),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
            HKQuantityType(.swimmingStrokeCount)
        ]
    }

    func richiediPermesso() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: tipiDaLeggere)
            return true
        } catch {
            return false
        }
    }

    func leggiNuotate(dal data: Date) async -> [NuotataCompletata] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        // Tutto il nuoto: non si filtra per vasca o acque libere.
        let tipo = HKQuery.predicateForWorkouts(with: .swimming)
        let periodo = HKQuery.predicateForSamples(withStart: data, end: nil, options: [])
        let predicato = NSCompoundPredicate(andPredicateWithSubpredicates: [tipo, periodo])
        let descrittore = HKSampleQueryDescriptor<HKWorkout>(
            predicates: [.workout(predicato)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 200
        )
        do {
            let allenamenti = try await descrittore.result(for: store)
            return allenamenti.map { nuotata(da: $0) }
        } catch {
            return []
        }
    }

    private func nuotata(da workout: HKWorkout) -> NuotataCompletata {
        let metri = Self.metri(di: workout)
        let vascaMetri = Self.lunghezzaVasca(di: workout)
        return NuotataCompletata(
            id: workout.uuid,
            data: workout.endDate,
            metri: metri,
            durataSecondi: Self.interoSicuro(workout.duration),
            titolo: testo("salute.nuotata"),
            origine: .salute,
            calorie: Self.calorie(di: workout),
            frequenzaCardiacaMedia: Self.frequenzaMedia(di: workout),
            bracciate: Self.bracciate(di: workout),
            vascaMetri: vascaMetri,
            ambiente: Self.ambiente(di: workout, vascaMetri: vascaMetri),
            vasche: Self.vasche(di: workout, metriTotali: metri, vascaMetri: vascaMetri)
        )
    }

    // MARK: Lettura difensiva

    /// Un numero in un intero >= 0: nei casi non finiti, negativi o troppo grandi vale 0.
    static func interoSicuro(_ valore: Double) -> Int {
        guard valore.isFinite, valore > 0, valore < 1_000_000_000 else { return 0 }
        return Int(valore.rounded())
    }

    /// Un numero in un intero > 0 entro un massimo, altrimenti nil.
    static func interoPositivo(_ valore: Double?, massimo: Double) -> Int? {
        guard let valore, valore.isFinite, valore > 0, valore <= massimo else { return nil }
        let intero = Int(valore.rounded())
        return intero > 0 ? intero : nil
    }

    /// Il valore di una quantità nell'unità indicata, solo se l'unità è compatibile (altrimenti HealthKit solleva un'eccezione).
    static func valore(_ quantita: HKQuantity?, unita: HKUnit) -> Double? {
        guard let quantita, quantita.is(compatibleWith: unita) else { return nil }
        let v = quantita.doubleValue(for: unita)
        return v.isFinite ? v : nil
    }

    /// Distanza a nuoto dalle statistiche (iOS 16+), con riserva sulla distanza totale dell'allenamento.
    private static func metri(di workout: HKWorkout) -> Int {
        let nuoto = valore(workout.statistics(for: HKQuantityType(.distanceSwimming))?.sumQuantity(), unita: .meter())
        let totale = valore(workout.totalDistance, unita: .meter())
        return interoSicuro(nuoto ?? totale ?? 0)
    }

    /// Energia attiva in kilocalorie.
    private static func calorie(di workout: HKWorkout) -> Int? {
        let somma = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()
        return interoPositivo(valore(somma, unita: .kilocalorie()), massimo: 100_000)
    }

    /// Frequenza cardiaca media in battiti al minuto.
    private static func frequenzaMedia(di workout: HKWorkout) -> Int? {
        let unita = HKUnit.count().unitDivided(by: HKUnit.minute())
        let media = workout.statistics(for: HKQuantityType(.heartRate))?.averageQuantity()
        return interoPositivo(valore(media, unita: unita), massimo: 300)
    }

    /// Bracciate totali.
    private static func bracciate(di workout: HKWorkout) -> Int? {
        let somma = workout.statistics(for: HKQuantityType(.swimmingStrokeCount))?.sumQuantity()
        return interoPositivo(valore(somma, unita: .count()), massimo: 1_000_000)
    }

    /// Lunghezza della vasca in metri, dal metadato dell'allenamento.
    private static func lunghezzaVasca(di workout: HKWorkout) -> Int? {
        guard let quantita = workout.metadata?[HKMetadataKeyLapLength] as? HKQuantity else { return nil }
        return interoPositivo(valore(quantita, unita: .meter()), massimo: 1000)
    }

    /// Vasca o acque libere. Se il metadato manca (o è "sconosciuto") e la lunghezza della vasca è nota, è una vasca.
    private static func ambiente(di workout: HKWorkout, vascaMetri: Int?) -> AmbienteNuoto? {
        if let numero = workout.metadata?[HKMetadataKeySwimmingLocationType] as? NSNumber,
           let luogo = HKWorkoutSwimmingLocationType(rawValue: numero.intValue) {
            switch luogo {
            case .pool: return .vasca
            case .openWater: return .acqueLibere
            case .unknown: break
            @unknown default: break
            }
        }
        return vascaMetri != nil ? .vasca : nil
    }

    /// Lo stile di una vasca dal metadato dell'evento. Gli altri valori (per esempio la tavoletta) non hanno stile.
    private static func stile(di evento: HKWorkoutEvent) -> Stile? {
        guard let numero = evento.metadata?[HKMetadataKeySwimmingStrokeStyle] as? NSNumber,
              let tipo = HKSwimmingStrokeStyle(rawValue: numero.intValue) else { return nil }
        switch tipo {
        case .freestyle: return .libero
        case .backstroke: return .dorso
        case .breaststroke: return .rana
        case .butterfly: return .delfino
        case .mixed: return .misto
        default: return nil
        }
    }

    /// Le vasche con il loro tempo, dagli eventi `.lap` dell'allenamento; se non ce ne sono, dagli eventi `.segment`.
    /// Nil se non c'è nulla di utilizzabile. `inizioSecondi` è l'inizio dell'evento meno l'inizio dell'allenamento.
    private static func vasche(di workout: HKWorkout, metriTotali: Int, vascaMetri: Int?) -> [SplitVasca]? {
        let eventi = workout.workoutEvents ?? []
        let lap = eventi.filter { $0.type == .lap }
        if let risultato = vasche(da: lap, workout: workout, metriTotali: metriTotali, vascaMetri: vascaMetri) {
            return risultato
        }
        // I segmenti non sono lunghi come la vasca: qui i metri sono sempre la distanza totale divisa per il numero di eventi.
        let segmenti = eventi.filter { $0.type == .segment }
        return vasche(da: segmenti, workout: workout, metriTotali: metriTotali, vascaMetri: nil)
    }

    private static func vasche(da eventi: [HKWorkoutEvent], workout: HKWorkout,
                               metriTotali: Int, vascaMetri: Int?) -> [SplitVasca]? {
        let validi = eventi.filter { $0.dateInterval.duration.isFinite && $0.dateInterval.duration > 0 }
        guard !validi.isEmpty, validi.count <= 5000 else { return nil }
        let metriPerEvento: Int
        if let vascaMetri {
            metriPerEvento = vascaMetri
        } else if metriTotali > 0 {
            metriPerEvento = Int((Double(metriTotali) / Double(validi.count)).rounded())
        } else {
            return nil
        }
        guard metriPerEvento > 0 else { return nil }
        let inizioAllenamento = workout.startDate
        var risultato: [SplitVasca] = []
        for evento in validi {
            let distanza = evento.dateInterval.start.timeIntervalSince(inizioAllenamento)
            guard distanza.isFinite else { continue }
            let inizio = max(0, distanza)
            risultato.append(SplitVasca(
                metri: metriPerEvento,
                durataSecondi: evento.dateInterval.duration,
                stile: stile(di: evento),
                inizioSecondi: inizio
            ))
        }
        return risultato.isEmpty ? nil : risultato
    }
}
