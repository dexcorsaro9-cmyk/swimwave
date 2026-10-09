import Foundation
import SwimwaveCore

/// Client del servizio coach (server/coach). Invia SOLO i campi ammessi dal server.
/// Allenamento: livello, obiettivo (quello scelto per questo allenamento, altrimenti quello del profilo), vasca, ritmo, coach,
/// durata scelta e un riepilogo di una riga. Commento del mese: soltanto conteggi e il coach. Mai il nome.
/// Nessuna cache, nessun cookie, nessun log del contenuto di richiesta e risposta.
struct ClientCoachHTTP: ServizioCoach {
    enum Errore: Error {
        case rispostaNonValida
        case statoHTTP(Int)
        case commentoVuoto
    }

    /// Chiave di Info.plist con l'URL https del servizio (impostata in app/project.yml).
    static let chiaveURL = "SwimwaveCoachURL"

    /// Corpo della richiesta di allenamento. Le chiavi sono quelle di server/coach/src/modello.js (CAMPI_AMMESSI).
    private struct Corpo: Encodable {
        let livello: String
        let obiettivo: String
        let vascaMetri: Int
        let ritmo: String?
        let coach: String?
        let riepilogo: String?
        let durataMin: Int?

        enum CodingKeys: String, CodingKey {
            case livello, obiettivo
            case vascaMetri = "vasca_metri"
            case ritmo, coach, riepilogo
            case durataMin = "durata_min"
        }
    }

    private struct Risposta: Decodable {
        let workout: Workout
    }

    /// Corpo della richiesta del commento del mese: solo questi nove campi (vedi server/coach/src/commento.js).
    private struct CorpoCommento: Encodable {
        let nuotate: Int
        let metri: Int
        let minuti: Int
        let metriMesePrecedente: Int
        let settimaneDiFila: Int
        let facili: Int
        let giuste: Int
        let dure: Int
        let coach: String?

        enum CodingKeys: String, CodingKey {
            case nuotate, metri, minuti
            case metriMesePrecedente = "metri_mese_precedente"
            case settimaneDiFila = "settimane_di_fila"
            case facili, giuste, dure, coach
        }
    }

    private struct RispostaCommento: Decodable {
        let testo: String?
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
    /// La durata si invia solo se è tra quelle ammesse; l'obiettivo della richiesta, se c'è, prende il posto di quello del profilo.
    func richiedi(profilo: Profilo, richiesta: RichiestaAllenamento) async throws -> Workout {
        var durata: Int?
        if let d = richiesta.durataMinuti, RichiestaAllenamento.durateAmmesse.contains(d) { durata = d }
        let obiettivo = richiesta.obiettivo ?? profilo.obiettivoEffettivo
        let corpo = Corpo(
            livello: profilo.categoriaLivello.rawValue,
            obiettivo: obiettivo.chiaveIndice,
            vascaMetri: profilo.vascaMetri,
            ritmo: profilo.ritmo?.rawValue,
            coach: profilo.coach?.rawValue,
            riepilogo: richiesta.riepilogo,
            durataMin: durata
        )
        let dati = try await invia(corpo, a: "allenamento")
        return try JSONDecoder().decode(Risposta.self, from: dati).workout
    }

    /// Il commento del coach sul mese. Invia solo conteggi (ognuno tenuto tra 0 e 100000, come chiede il server) e il coach.
    /// Se il servizio non risponde con un testo (nil o vuoto) lancia un errore: l'app usa allora una frase fissa.
    func commentoMese(dati: DatiMese, profilo: Profilo) async throws -> String {
        let corpo = CorpoCommento(
            nuotate: Self.conteggio(dati.nuotate),
            metri: Self.conteggio(dati.metri),
            minuti: Self.conteggio(dati.minuti),
            metriMesePrecedente: Self.conteggio(dati.metriMesePrecedente),
            settimaneDiFila: Self.conteggio(dati.settimaneDiFila),
            facili: Self.conteggio(dati.facili),
            giuste: Self.conteggio(dati.giuste),
            dure: Self.conteggio(dati.dure),
            coach: profilo.coach?.rawValue
        )
        let risposta = try await invia(corpo, a: "commento")
        let testo = try JSONDecoder().decode(RispostaCommento.self, from: risposta).testo
        guard let pulito = testo?.trimmingCharacters(in: .whitespacesAndNewlines), !pulito.isEmpty else {
            throw Errore.commentoVuoto
        }
        return pulito
    }

    /// Un conteggio dentro 0...100000.
    static func conteggio(_ valore: Int) -> Int {
        min(max(valore, 0), 100_000)
    }

    /// POST JSON a `<url>/<percorso>`; restituisce il corpo della risposta se lo stato è 2xx.
    private func invia<C: Encodable>(_ corpo: C, a percorso: String) async throws -> Data {
        var richiesta = URLRequest(url: baseURL.appendingPathComponent(percorso))
        richiesta.httpMethod = "POST"
        richiesta.timeoutInterval = 10
        richiesta.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        richiesta.setValue("application/json", forHTTPHeaderField: "Content-Type")
        richiesta.setValue("application/json", forHTTPHeaderField: "Accept")
        richiesta.httpBody = try JSONEncoder().encode(corpo)

        let (dati, risposta) = try await sessione.data(for: richiesta)
        guard let http = risposta as? HTTPURLResponse else { throw Errore.rispostaNonValida }
        guard (200...299).contains(http.statusCode) else { throw Errore.statoHTTP(http.statusCode) }
        return dati
    }
}
