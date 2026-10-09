import Foundation
import Observation
import SwimwaveCore

/// Stato dell'app: profilo, nuotate, tappa attuale, contenuti.
///
/// PERSISTENZA: UserDefaults con un solo blocco JSON (Codable). Scelta voluta rispetto a SwiftData
/// (docs/ARCHITECTURE.md): senza poter compilare, SwiftData richiede macro @Model, ModelContainer e query
/// che non posso verificare; per pochi dati (un profilo e qualche decina di nuotate) UserDefaults è sufficiente
/// e sicuro da scrivere. Quando lo storico crescerà (letture da Apple Salute) si potrà passare a SwiftData
/// cambiando solo questa classe.
@Observable
final class StatoApp {
    // MARK: Dati salvati
    var profilo = Profilo()
    var onboardingCompletato = false
    var nuotate: [NuotataCompletata] = []
    var tappaAttuale = 1
    /// Ultimo giorno in cui è comparso un popup del coach (al massimo uno al giorno).
    var giornoUltimoPopup: Date?
    /// Settimana per cui è già stato festeggiato l'obiettivo.
    var settimanaFesteggiata: String?

    // MARK: Non osservati
    @ObservationIgnored let contenuti: ContentStore
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let watch = WatchLink()
    @ObservationIgnored private var cacheAllenamento: (chiave: String, workout: Workout?)?

    private static let chiaveDati = "swimwave.dati.v1"

    /// Dopo quanti giorni senza nuotare compare il popup di ripartenza.
    /// PROVVISORIO: "fino a 2 settimane" è una soglia in bozza di content/REVISIONE.md, da confermare.
    static let giorniPerRipartenza = 14

    init(defaults: UserDefaults = .standard, contenuti: ContentStore = StatoApp.contenutiDaBundle()) {
        self.defaults = defaults
        self.contenuti = contenuti
        carica()
        watch.onNuotata = { [weak self] nuotata in self?.registra(nuotata) }
        watch.attiva()
    }

    // MARK: Contenuti

    /// Gli utenti vedono solo i contenuti "approvato" (CLAUDE.md). In debug si includono le bozze.
    /// ATTENZIONE: oggi tutti i contenuti sono "bozza", quindi una build di release mostra schermate vuote
    /// finché l'istruttore non approva (content/REVISIONE.md).
    static func contenutiDaBundle() -> ContentStore {
        #if DEBUG
        let bozze = true
        #else
        let bozze = false
        #endif
        // La cartella content/ è inclusa nell'app come "folder reference" (vedi project.yml).
        let base = Bundle.main.resourceURL?.appendingPathComponent("content")
        return ContentStore(includeBozze: bozze) { percorso in
            guard let url = base?.appendingPathComponent(percorso) else { return nil }
            return try? Data(contentsOf: url)
        }
    }

    // MARK: Salvataggio

    private struct DatiSalvati: Codable {
        var profilo: Profilo
        var onboardingCompletato: Bool
        var nuotate: [NuotataCompletata]
        var tappaAttuale: Int
        var giornoUltimoPopup: Date?
        var settimanaFesteggiata: String?
    }

    private func carica() {
        guard let data = defaults.data(forKey: StatoApp.chiaveDati),
              let d = try? JSONDecoder().decode(DatiSalvati.self, from: data) else { return }
        profilo = d.profilo
        onboardingCompletato = d.onboardingCompletato
        nuotate = d.nuotate
        tappaAttuale = d.tappaAttuale
        giornoUltimoPopup = d.giornoUltimoPopup
        settimanaFesteggiata = d.settimanaFesteggiata
    }

    func salva() {
        let d = DatiSalvati(
            profilo: profilo,
            onboardingCompletato: onboardingCompletato,
            nuotate: nuotate,
            tappaAttuale: tappaAttuale,
            giornoUltimoPopup: giornoUltimoPopup,
            settimanaFesteggiata: settimanaFesteggiata
        )
        if let data = try? JSONEncoder().encode(d) {
            defaults.set(data, forKey: StatoApp.chiaveDati)
        }
    }

    /// L'utente può vedere e cancellare tutto ciò che l'app ha memorizzato (docs/EXPERIENCE.md).
    func cancellaTutto() {
        defaults.removeObject(forKey: StatoApp.chiaveDati)
        profilo = Profilo()
        onboardingCompletato = false
        nuotate = []
        tappaAttuale = 1
        giornoUltimoPopup = nil
        settimanaFesteggiata = nil
        cacheAllenamento = nil
    }

    // MARK: Onboarding

    func completaOnboarding(con nuovo: Profilo) {
        profilo = nuovo
        tappaAttuale = nuovo.livello?.tappaDiPartenza ?? 1
        onboardingCompletato = true
        salva()
    }

    // MARK: Nuotate e obiettivo

    func registra(_ nuotata: NuotataCompletata) {
        guard !nuotate.contains(where: { $0.id == nuotata.id }) else { return }
        nuotate.append(nuotata)
        nuotate.sort { $0.data > $1.data }
        salva()
    }

    var progressoSettimana: ProgressoSettimanale? {
        ObiettivoSettimanale.progresso(profilo: profilo, date: nuotate.map(\.data))
    }

    var nuotateQuestaSettimana: Int {
        ObiettivoSettimanale.conteggio(date: nuotate.map(\.data), rispetto: Date())
    }

    // MARK: Percorso

    func vai(allaTappa id: Int) {
        tappaAttuale = id
        salva()
    }

    // MARK: Allenamento di oggi

    /// Allenamento fisso (riserva) adatto a livello, obiettivo e vasca. Cambia da un giorno all'altro.
    /// Quando ci sarà il servizio coach (server/coach) qui arriverà l'allenamento generato, con questa come riserva.
    func allenamentoDiOggi(adesso: Date = Date()) -> Workout? {
        let giorno = Calendar.italiano.ordinality(of: .day, in: .year, for: adesso) ?? 0
        let chiave = "\(giorno)|\(profilo.categoriaLivello.rawValue)|\(profilo.obiettivoEffettivo.rawValue)|\(profilo.vascaMetri)|\(contenuti.voci.count)"
        if let cache = cacheAllenamento, cache.chiave == chiave { return cache.workout }
        let w = contenuti.scegliRiserva(profilo: profilo, scelta: giorno)
        cacheAllenamento = (chiave, w)
        return w
    }

    func inviaAlWatch() -> EsitoInvioWatch {
        guard let w = allenamentoDiOggi() else { return .errore }
        return watch.invia(allenamento: w)
    }

    // MARK: Popup del coach

    /// Il popup da mostrare adesso, se c'è. Regole di docs/POPUP_COACH.md: uno solo al giorno, mai colpevolizzante,
    /// il benvenuto solo con un ritmo che prevede messaggi (Regolare o Spronami).
    func popupDaMostrare(adesso: Date = Date()) -> PopupCoach? {
        guard onboardingCompletato else { return nil }
        let cal = Calendar.italiano
        if let ultimo = giornoUltimoPopup, cal.isDate(ultimo, inSameDayAs: adesso) { return nil }

        if let p = progressoSettimana, p.raggiunto,
           settimanaFesteggiata != ObiettivoSettimanale.idSettimana(adesso) {
            return PopupCoach(momento: .obiettivoRaggiunto, espressione: .traguardo,
                              messaggio: testo("popup.traguardo.messaggio", profilo.nomePulito))
        }
        if let ultimaNuotata = nuotate.map(\.data).max(),
           let giorni = cal.dateComponents([.day], from: ultimaNuotata, to: adesso).day,
           giorni >= StatoApp.giorniPerRipartenza {
            // Nessun conteggio dei giorni saltati nel testo.
            return PopupCoach(momento: .ripartenza, espressione: .ripartenza,
                              messaggio: testo("popup.ripartenza.messaggio"))
        }
        if let ritmo = profilo.ritmo, ritmo.richiedeFrequenza {
            return PopupCoach(momento: .benvenutoGiornata, espressione: .benvenuto,
                              messaggio: testo("popup.benvenuto.messaggio", profilo.nomePulito))
        }
        return nil
    }

    func segnaMostrato(_ popup: PopupCoach, adesso: Date = Date()) {
        giornoUltimoPopup = adesso
        if popup.momento == .obiettivoRaggiunto {
            settimanaFesteggiata = ObiettivoSettimanale.idSettimana(adesso)
        }
        salva()
    }
}
