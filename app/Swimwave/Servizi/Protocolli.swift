import Foundation
import SwimwaveCore

/// Servizi esterni dietro protocolli, così lo stato dell'app non dipende da rete, HealthKit o notifiche
/// e si può provare con finti servizi. Le implementazioni vere sono nei file accanto a questo.

/// Genera l'allenamento di oggi (servizio coach, server/coach). Può fallire: l'app usa l'allenamento di riserva.
protocol ServizioCoach {
    /// L'allenamento per il profilo e la richiesta (durata e obiettivo scelti dall'utente, riepilogo dell'ultimo allenamento).
    func richiedi(profilo: Profilo, richiesta: RichiestaAllenamento) async throws -> Workout
    /// Un commento breve (al massimo due frasi) sul mese, dal tono del coach scelto. Riceve solo conteggi.
    func commentoMese(dati: DatiMese, profilo: Profilo) async throws -> String
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
