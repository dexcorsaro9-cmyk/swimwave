import Foundation
import WatchConnectivity
import SwimwaveCore

/// Collegamento Watch <-> iPhone (WatchConnectivity).
/// Riceve l'allenamento di oggi (application context) e rimanda la nuotata finita (transferUserInfo).
/// DA TESTARE su dispositivi veri: il simulatore accoppiato non è affidabile per WatchConnectivity.
final class PhoneLink: NSObject, WCSessionDelegate {
    /// Chiamata sul thread principale quando arriva un allenamento dall'iPhone.
    var onAllenamento: ((Workout) -> Void)?

    override init() {
        super.init()
    }

    func attiva() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func invia(nuotata: NuotataCompletata) {
        guard WCSession.isSupported(),
              let info = try? MessaggiWatch.userInfo(nuotata: nuotata) else { return }
        // transferUserInfo mette in coda e consegna anche più tardi, quando l'iPhone è raggiungibile.
        WCSession.default.transferUserInfo(info)
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // All'attivazione leggi l'ultimo contesto già ricevuto (arrivato mentre l'app era chiusa).
        guard activationState == .activated else { return }
        consegna(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        consegna(applicationContext)
    }

    private func consegna(_ contesto: [String: Any]) {
        guard let workout = MessaggiWatch.allenamento(da: contesto) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onAllenamento?(workout)
        }
    }
}
