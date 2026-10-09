import Foundation
import SwimwaveCore

/// Client del servizio coach (server/coach). Invia SOLO i campi ammessi dal server:
/// livello, obiettivo, vasca, ritmo, coach e un riepilogo di una riga. Mai il nome.
/// Nessuna cache, nessun cookie, nessun log del contenuto di richiesta e risposta.
struct ClientCoachHTTP: ServizioCoach {
    enum Errore: Error {
        case rispostaNonValida
        case statoHTTP(Int)
    }

    /// Chiave di Info.plist con l'URL https del servizio (impostata in app/project.yml).
    static let chiaveURL = "SwimwaveCoachURL"

    /// Corpo della richiesta. Le chiavi sono quelle di server/coach/src/modello.js (CAMPI_AMMESSI).
    private struct Corpo: Encodable {
        let livello: String
        let obiettivo: String
        let vascaMetri: Int
        let ritmo: String?
        let coach: String?
        let riepilogo: String?

        enum CodingKeys: String, CodingKey {
            case livello, obiettivo
            case vascaMetri = "vasca_metri"
            case ritmo, coach, riepilogo
        }
    }

    private struct Risposta: Decodable {
        let workout: Workout
    }

    let baseURL: URL
    private let sessione: URLSession

    /// `sessione` nil = sessione effimera (niente cache né cookie su disco) con timeout di 10 secondi.
    init(baseURL: URL, sessione: URLSession? = nil) {
        self.baseURL = baseURL
        self.sessione = sessione ?? ClientCoachHTTP.sessioneEffimera()
    }

    /// Legge l'URL da Info.plist. Se manca, è vuoto o non è un URL https valido, restituisce nil
    /// e l'app usa gli allenamenti fissi.
    static func daConfigurazione(bundle: Bundle = .main) -> ClientCoachHTTP? {
        guard let valore = bundle.object(forInfoDictionaryKey: chiaveURL) as? String else { return nil }
        guard let url = urlValido(valore) else { return nil }
        return ClientCoachHTTP(baseURL: url)
    }

    /// Accetta solo URL https con un host.
    static func urlValido(_ testo: String) -> URL? {
        let pulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pulito.isEmpty, let url = URL(string: pulito),
              url.scheme?.lowercased() == "https",
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    private static func sessioneEffimera() -> URLSession {
        let configurazione = URLSessionConfiguration.ephemeral
        configurazione.timeoutIntervalForRequest = 10
        configurazione.timeoutIntervalForResource = 10
        configurazione.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configurazione.urlCache = nil
        configurazione.httpCookieStorage = nil
        configurazione.httpShouldSetCookies = false
        return URLSession(configuration: configurazione)
    }

    /// La tappa non fa parte del protocollo `ServizioCoach` e quindi non viene inviata (il server la ammette ma non la richiede).
    func richiedi(profilo: Profilo, riepilogo: String?) async throws -> Workout {
        let corpo = Corpo(
            livello: profilo.categoriaLivello.rawValue,
            obiettivo: profilo.obiettivoEffettivo.chiaveIndice,
            vascaMetri: profilo.vascaMetri,
            ritmo: profilo.ritmo?.rawValue,
            coach: profilo.coach?.rawValue,
            riepilogo: riepilogo
        )
        var richiesta = URLRequest(url: baseURL.appendingPathComponent("allenamento"))
        richiesta.httpMethod = "POST"
        richiesta.timeoutInterval = 10
        richiesta.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        richiesta.setValue("application/json", forHTTPHeaderField: "Content-Type")
        richiesta.setValue("application/json", forHTTPHeaderField: "Accept")
        richiesta.httpBody = try JSONEncoder().encode(corpo)

        let (dati, risposta) = try await sessione.data(for: richiesta)
        guard let http = risposta as? HTTPURLResponse else { throw Errore.rispostaNonValida }
        guard (200...299).contains(http.statusCode) else { throw Errore.statoHTTP(http.statusCode) }
        return try JSONDecoder().decode(Risposta.self, from: dati).workout
    }
}
