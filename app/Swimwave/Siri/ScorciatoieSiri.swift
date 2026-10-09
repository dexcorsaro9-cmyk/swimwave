import AppIntents
import Foundation

/// Richiesta di avvio fatta da Siri o dall'app Comandi Rapidi. L'intento apre l'app e lascia un segno con l'ora:
/// la schermata Oggi lo legge e apre l'allenamento di oggi, ma solo se il segno è recente (così un avvio
/// vecchio, lasciato mentre l'app era ferma al primo avvio, non parte da solo ore dopo).
enum RichiestaAvvio {
    static let chiave = "swimwave.richiestaAvvio"
    private static let validitaSecondi: Double = 120

    static func segna(adesso: Date = Date()) {
        UserDefaults.standard.set(adesso.timeIntervalSince1970, forKey: chiave)
    }

    /// Vero una sola volta per ogni richiesta recente; la richiesta si consuma.
    static func consuma(adesso: Date = Date()) -> Bool {
        let ora = UserDefaults.standard.double(forKey: chiave)
        guard ora > 0 else { return false }
        UserDefaults.standard.removeObject(forKey: chiave)
        return adesso.timeIntervalSince1970 - ora <= validitaSecondi
    }
}

struct ApriAllenamentoDiOggiIntent: AppIntent {
    static var title: LocalizedStringResource = "siri.apriAllenamento.titolo"
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        RichiestaAvvio.segna()
        return .result()
    }
}

struct ScorciatoieSwimwave: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ApriAllenamentoDiOggiIntent(),
            phrases: [
                "Apri l'allenamento di oggi con \(.applicationName)",
                "Inizia l'allenamento con \(.applicationName)"
            ],
            shortTitle: "siri.apriAllenamento.titolo",
            systemImageName: "figure.pool.swim"
        )
    }
}
