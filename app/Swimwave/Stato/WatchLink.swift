import Foundation
import WatchConnectivity
import SwimwaveCore

enum EsitoInvioWatch: Equatable {
    case inviato
    case watchNonDisponibile      // Watch non accoppiato o app Watch non installata
    case errore
}

/// Collegamento iPhone -> Watch (WatchConnectivity).
/// Manda l'allenamento di oggi con `updateApplicationContext` (vale l'ultimo) e riceve le nuotate finite con `transferUserInfo`.
/// DA TESTARE su dispositivi veri: il simulatore accoppiato non è affidabile per WatchConnectivity.
final class WatchLink: NSObject, WCSessionDelegate {
    /// Chiamata sul thread principale quando il Watch consegna una nuotata finita.
    var onNuotata: ((NuotataCompletata) -> Void)?

    override init() {
        super.init()
    }

    func attiva() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func invia(allenamento: Workout, target: [Int?] = []) -> EsitoInvioWatch {
        guard WCSession.isSupported() else { return .watchNonDisponibile }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else {
            return .watchNonDisponibile
        }
        do {
            try session.updateApplicationContext(try MessaggiWatch.contesto(allenamento: allenamento, target: target))
            return .inviato
        } catch {
            return .errore
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    // Richiesti su iOS. Dopo un cambio di Watch accoppiato la sessione va riattivata.
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let nuotata = MessaggiWatch.nuotata(da: userInfo) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onNuotata?(nuotata)
        }
    }
}
