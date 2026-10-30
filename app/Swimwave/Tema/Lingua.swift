import Foundation

/// Lingue dell'app. "Automatica" segue l'iPhone; le altre valgono solo per Swimwave.
///
/// La scelta si salva in `AppleLanguages` (la chiave che iOS stesso usa per "Impostazioni > Swimwave > Lingua"):
/// così cambiano insieme testi, date e numeri, ma solo dopo aver riaperto l'app, perché il bundle legge la lingua all'avvio.
enum Lingua: String, CaseIterable, Identifiable {
    case italiano = "it", inglese = "en", spagnolo = "es"

    var id: String { rawValue }

    /// Nome nella propria lingua, uguale per tutti: chi non capisce la lingua attuale deve riconoscere la sua.
    var nome: String {
        switch self {
        case .italiano: return "Italiano"
        case .inglese: return "English"
        case .spagnolo: return "Español"
        }
    }

    /// Lingua in uso in questo avvio (quella scelta o, se non c'è, quella dell'iPhone; italiano come ultima scelta).
    static let corrente: Lingua = {
        for codice in Bundle.main.preferredLocalizations {
            if let l = Lingua(rawValue: String(codice.prefix(2))) { return l }
        }
        return .italiano
    }()

    static var locale: Locale { Locale(identifier: corrente.rawValue) }

    /// Lingua scelta dall'utente nell'app, nil = automatica. Si ricorda in una chiave nostra, perché `AppleLanguages`
    /// contiene sempre anche le lingue dell'iPhone e da sola non dice se l'utente ha scelto.
    static var scelta: Lingua? {
        get { UserDefaults.standard.string(forKey: chiaveScelta).flatMap(Lingua.init(rawValue:)) }
        set {
            if let l = newValue {
                UserDefaults.standard.set(l.rawValue, forKey: chiaveScelta)
                UserDefaults.standard.set([l.rawValue], forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.removeObject(forKey: chiaveScelta)
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            }
        }
    }

    private static let chiaveScelta = "swimwave.lingua"
}
