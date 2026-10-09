import Foundation
import SwimwaveCore

/// Servizi esterni dietro protocolli, così lo stato dell'app non dipende da rete, HealthKit o notifiche
/// e si può provare con finti servizi. Le implementazioni vere sono nei file accanto a questo.

/// Genera l'allenamento di oggi (servizio coach, server/coach). Può fallire: l'app usa l'allenamento di riserva.
protocol ServizioCoach {
    func richiedi(profilo: Profilo, riepilogo: String?) async throws -> Workout
}

/// Legge le nuotate da Apple Salute (anche di altre app e orologi).
protocol LettoreSalute {
    /// Chiede il permesso di lettura. false se negato o Salute non disponibile.
    func richiediPermesso() async -> Bool
    /// Nuotate in vasca o in acque libere dalla data indicata. L'id è l'UUID dell'allenamento in Salute.
    func leggiNuotate(dal data: Date) async -> [NuotataCompletata]
}

/// Notifiche locali per il ritmo "Spronami". Solo notifiche sul telefono: nessun dato esce dal dispositivo.
protocol ProgrammatoreNotifiche {
    func richiediPermesso() async -> Bool
    /// Sostituisce tutti i promemoria programmati con questi.
    func programma(date: [Date], titolo: String, testo: String) async
    func cancellaTutti() async
}
