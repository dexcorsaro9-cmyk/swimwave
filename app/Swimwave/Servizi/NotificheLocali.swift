import Foundation
import UserNotifications

/// Promemoria locali per il ritmo "Spronami". Nessun dato lascia il telefono.
final class NotificheLocali: ProgrammatoreNotifiche {
    private static let prefisso = "swimwave.promemoria."
    /// iOS tiene al massimo 64 notifiche in attesa per app.
    private static let massimo = 60

    private var centro: UNUserNotificationCenter { UNUserNotificationCenter.current() }

    func richiediPermesso() async -> Bool {
        do {
            return try await centro.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func programma(date: [Date], titolo: String, testo: String) async {
        await cancellaTutti()
        let impostazioni = await centro.notificationSettings()
        switch impostazioni.authorizationStatus {
        case .authorized, .provisional:
            break
        default:
            return
        }
        let adesso = Date()
        let calendario = Calendar.current
        let future = date.filter { $0 > adesso }.sorted().prefix(Self.massimo)
        for (indice, data) in future.enumerated() {
            let contenuto = UNMutableNotificationContent()
            contenuto.title = titolo
            contenuto.body = testo
            contenuto.sound = .default
            let componenti = calendario.dateComponents([.year, .month, .day, .hour, .minute], from: data)
            let trigger = UNCalendarNotificationTrigger(dateMatching: componenti, repeats: false)
            let richiesta = UNNotificationRequest(identifier: "\(Self.prefisso)\(indice)", content: contenuto, trigger: trigger)
            try? await centro.add(richiesta)
        }
    }

    func cancellaTutti() async {
        let inAttesa = await centro.pendingNotificationRequests()
        let ids = inAttesa.map(\.identifier).filter { $0.hasPrefix(Self.prefisso) }
        if !ids.isEmpty {
            centro.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
