import Foundation
import HealthKit
import SwimwaveCore

/// Legge le nuotate da Apple Salute (allenamenti di tipo nuoto, in vasca e in acque libere).
///
/// Nota: per scelta di Apple, Salute non dice se l'utente ha negato la lettura. Se il permesso è stato negato
/// la ricerca restituisce semplicemente zero risultati: non c'è modo di distinguerlo da "nessuna nuotata".
/// Per questo `richiediPermesso()` restituisce true se la richiesta è stata presentata senza errori.
final class LettoreSaluteHealthKit: LettoreSalute {
    private let store = HKHealthStore()

    private var tipiDaLeggere: Set<HKObjectType> {
        [HKObjectType.workoutType(), HKQuantityType(.distanceSwimming)]
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
        let descrittore = HKSampleQueryDescriptor(
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
        return NuotataCompletata(
            id: workout.uuid,
            data: workout.endDate,
            metri: metri,
            durataSecondi: Int(workout.duration),
            titolo: testo("salute.nuotata"),
            origine: .salute
        )
    }

    /// Distanza a nuoto dalle statistiche (iOS 16+), con riserva sulla distanza totale dell'allenamento.
    private static func metri(di workout: HKWorkout) -> Int {
        let nuoto = workout.statistics(for: HKQuantityType(.distanceSwimming))?.sumQuantity()?.doubleValue(for: .meter())
        let totale = workout.totalDistance?.doubleValue(for: .meter())
        let valore = nuoto ?? totale ?? 0
        guard valore.isFinite, valore > 0 else { return 0 }
        return Int(valore.rounded())
    }
}
