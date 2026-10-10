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
    /// Conferma "ho almeno 18 anni", chiesta prima di tutto (docs/legale/CHECKLIST.md).
    var maggiorenneConfermato = false
    /// Consenso all'uso dell'IA per generare gli allenamenti. nil = non ancora chiesto; false = rifiutato (si usano gli allenamenti fissi).
    var consensoIA: Bool?
    /// Tappe del percorso superate (il test è stato dichiarato superato).
    var tappeSuperate: [Int] = []
    /// Ultimo test per trovare il proprio ritmo (200 m e 400 m).
    var testRitmo: TestRitmo?
    /// Ultimo traguardo di serie di settimane già festeggiato.
    var traguardoSerieFesteggiato: Int?
    /// Il permesso di leggere da Salute è già stato chiesto (la richiesta del sistema compare una volta sola).
    var permessoSaluteChiesto = false
    var ultimaLetturaSalute: Date?
    /// Allenamento generato dal servizio coach per `chiaveGenerato` (cambia ogni giorno o se cambia il profilo).
    var allenamentoGenerato: Workout?
    var chiaveGenerato: String?
    /// Obiettivo personale di metri al mese (nil = nessuno).
    var obiettivoMensileMetri: Int?
    /// Commenti del coach sul mese, per mese ("2026-10"): si chiedono una volta e si ricordano.
    var commentiMese: [String: String] = [:]
    /// Allenamento scelto dall'utente per oggi (dalla libreria o chiesto al coach): vale fino a fine giornata.
    var allenamentoScelto: Workout?
    var giornoAllenamentoScelto: Int?
    /// Medaglie già festeggiate a schermo intero.
    var medaglieViste: Set<String> = []

    // MARK: Non osservati
    // Le costanti (`let`) non sono mai osservate dalla macro @Observable: qui @ObservationIgnored serve solo per le `var`.
    let contenuti: ContentStore
    private let defaults: UserDefaults
    private let watch = WatchLink()
    let servizioCoach: ServizioCoach?
    let lettoreSalute: LettoreSalute
    let notifiche: ProgrammatoreNotifiche
    @ObservationIgnored private var cacheAllenamento: (chiave: String, workout: Workout?)?

    private static let chiaveDati = "swimwave.dati.v1"

    /// Dopo quanti giorni senza nuotare compare il popup di ripartenza.
    /// PROVVISORIO: "fino a 2 settimane" è una soglia in bozza di content/REVISIONE.md, da confermare.
    static let giorniPerRipartenza = 14

    init(
        defaults: UserDefaults = .standard,
        contenuti: ContentStore = StatoApp.contenutiDaBundle(),
        servizioCoach: ServizioCoach? = ClientCoachHTTP.daConfigurazione(),
        lettoreSalute: LettoreSalute = LettoreSaluteHealthKit(),
        notifiche: ProgrammatoreNotifiche = NotificheLocali()
    ) {
        self.defaults = defaults
        self.contenuti = contenuti
        self.servizioCoach = servizioCoach
        self.lettoreSalute = lettoreSalute
        self.notifiche = notifiche
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
        // Campi aggiunti dopo: opzionali, così i dati salvati da versioni precedenti si leggono ancora.
        var maggiorenneConfermato: Bool?
        var consensoIA: Bool?
        var tappeSuperate: [Int]?
        var testRitmo: TestRitmo?
        var traguardoSerieFesteggiato: Int?
        var permessoSaluteChiesto: Bool?
        var ultimaLetturaSalute: Date?
        var allenamentoGenerato: Workout?
        var chiaveGenerato: String?
        var obiettivoMensileMetri: Int?
        var commentiMese: [String: String]?
        var allenamentoScelto: Workout?
        var giornoAllenamentoScelto: Int?
        /// Id delle medaglie già mostrate con la celebrazione a schermo intero.
        var medaglieViste: [String]?
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
        maggiorenneConfermato = d.maggiorenneConfermato ?? false
        consensoIA = d.consensoIA
        tappeSuperate = d.tappeSuperate ?? []
        testRitmo = d.testRitmo
        traguardoSerieFesteggiato = d.traguardoSerieFesteggiato
        permessoSaluteChiesto = d.permessoSaluteChiesto ?? false
        ultimaLetturaSalute = d.ultimaLetturaSalute
        allenamentoGenerato = d.allenamentoGenerato
        chiaveGenerato = d.chiaveGenerato
        obiettivoMensileMetri = d.obiettivoMensileMetri
        commentiMese = d.commentiMese ?? [:]
        allenamentoScelto = d.allenamentoScelto
        giornoAllenamentoScelto = d.giornoAllenamentoScelto
        // Chi aggiorna l'app non rivede la festa per le medaglie già ottenute.
        medaglieViste = Set(d.medaglieViste ?? medaglie.filter(\.ottenuta).map(\.id))
    }

    func salva() {
        let d = DatiSalvati(
            profilo: profilo,
            onboardingCompletato: onboardingCompletato,
            nuotate: nuotate,
            tappaAttuale: tappaAttuale,
            giornoUltimoPopup: giornoUltimoPopup,
            settimanaFesteggiata: settimanaFesteggiata,
            maggiorenneConfermato: maggiorenneConfermato,
            consensoIA: consensoIA,
            tappeSuperate: tappeSuperate,
            testRitmo: testRitmo,
            traguardoSerieFesteggiato: traguardoSerieFesteggiato,
            permessoSaluteChiesto: permessoSaluteChiesto,
            ultimaLetturaSalute: ultimaLetturaSalute,
            allenamentoGenerato: allenamentoGenerato,
            chiaveGenerato: chiaveGenerato,
            obiettivoMensileMetri: obiettivoMensileMetri,
            commentiMese: commentiMese,
            allenamentoScelto: allenamentoScelto,
            giornoAllenamentoScelto: giornoAllenamentoScelto,
            medaglieViste: medaglieViste.sorted()
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
        maggiorenneConfermato = false
        consensoIA = nil
        tappeSuperate = []
        testRitmo = nil
        traguardoSerieFesteggiato = nil
        permessoSaluteChiesto = false
        ultimaLetturaSalute = nil
        allenamentoGenerato = nil
        chiaveGenerato = nil
        obiettivoMensileMetri = nil
        commentiMese = [:]
        allenamentoScelto = nil
        giornoAllenamentoScelto = nil
        medaglieViste = []
        cacheAllenamento = nil
        Task { await self.notifiche.cancellaTutti() }
    }

    // MARK: Onboarding

    func completaOnboarding(con nuovo: Profilo) {
        profilo = nuovo
        tappaAttuale = nuovo.livello?.tappaDiPartenza ?? 1
        onboardingCompletato = true
        salva()
    }

    // MARK: Nuotate e obiettivo

    /// Aggiunge una nuotata. Se c'è già (stesso id: la stessa nuotata arrivata dal Watch e da Salute) le due versioni
    /// si uniscono: restano i valori già presenti e si completano i vuoti (calorie, frequenza cardiaca, vasche...).
    func registra(_ nuotata: NuotataCompletata) {
        if let i = nuotate.firstIndex(where: { $0.id == nuotata.id }) {
            nuotate[i] = nuotate[i].unendo(nuotata)
        } else {
            nuotate.append(nuotata)
        }
        nuotate.sort { $0.data > $1.data }
        salva()
        Task { await self.riprogrammaPromemoria() }
    }

    /// Sostituisce la nuotata con lo stesso id (per esempio dopo una modifica).
    func aggiorna(nuotata: NuotataCompletata) {
        guard let i = nuotate.firstIndex(where: { $0.id == nuotata.id }) else { return }
        nuotate[i] = nuotata
        nuotate.sort { $0.data > $1.data }
        salva()
    }

    func elimina(nuotataConId id: UUID) {
        nuotate.removeAll { $0.id == id }
        salva()
        Task { await self.riprogrammaPromemoria() }
    }

    /// L'orologio a volte sbaglia: l'utente corregge metri e durata. Da quel momento le altre fonti non li sovrascrivono.
    func correggi(nuotataConId id: UUID, metri: Int, durataSecondi: Int) {
        guard let i = nuotate.firstIndex(where: { $0.id == id }), metri >= 0, durataSecondi >= 0 else { return }
        nuotate[i].metri = metri
        nuotate[i].durataSecondi = durataSecondi
        nuotate[i].corretta = true
        salva()
    }

    /// Nota personale sulla nuotata; vuota (o solo spazi) la toglie.
    func imposta(nota: String, perNuotata id: UUID) {
        guard let i = nuotate.firstIndex(where: { $0.id == id }) else { return }
        let pulita = nota.trimmingCharacters(in: .whitespacesAndNewlines)
        nuotate[i].nota = pulita.isEmpty ? nil : String(pulita.prefix(500))
        salva()
    }

    /// Risposta alla domanda di fine allenamento: "facile, giusta o dura?".
    func imposta(sensazione: Sensazione, perNuotata id: UUID) {
        guard let i = nuotate.firstIndex(where: { $0.id == id }) else { return }
        nuotate[i].sensazione = sensazione
        // Il motivo ha senso solo per "dura".
        if sensazione != .dura { nuotate[i].motivoDifficolta = nil }
        salva()
    }

    /// Risposta a "Cosa non andava?" dopo una nuotata "dura". Resta sul telefono.
    func imposta(motivoDifficolta motivo: MotivoDifficolta, perNuotata id: UUID) {
        guard let i = nuotate.firstIndex(where: { $0.id == id }), nuotate[i].sensazione == .dura else { return }
        nuotate[i].motivoDifficolta = motivo
        salva()
    }

    /// Il motivo dell'ultima nuotata con una risposta, se quella risposta è "dura".
    var ultimoMotivoDifficolta: MotivoDifficolta? {
        guard let ultima = nuotate.first(where: { $0.sensazione != nil }), ultima.sensazione == .dura else { return nil }
        return ultima.motivoDifficolta
    }

    /// Ultima sensazione dichiarata, per adattare il prossimo allenamento.
    var ultimaSensazione: Sensazione? {
        nuotate.first(where: { $0.sensazione != nil })?.sensazione
    }

    var progressoSettimana: ProgressoSettimanale? {
        ObiettivoSettimanale.progresso(profilo: profilo, date: nuotate.map(\.data))
    }

    var nuotateQuestaSettimana: Int {
        ObiettivoSettimanale.conteggio(date: nuotate.map(\.data), rispetto: Date())
    }

    /// Settimane di fila con l'obiettivo raggiunto (vedi SerieSettimane).
    var serieSettimane: Int {
        SerieSettimane.settimaneDiFila(profilo: profilo, date: nuotate.map(\.data))
    }

    // MARK: Analisi

    var records: RecordPersonali {
        Record.calcola(nuotate: nuotate, testRitmo: testRitmo, profilo: profilo, calendar: .italiano)
    }

    /// Le medaglie ("traguardi"). Per la costanza conta la serie migliore mai raggiunta: interrompere la serie non toglie nulla.
    var medaglie: [Medaglia] {
        Medaglie.elenco(
            nuotate: nuotate,
            serieSettimane: max(serieSettimane, records.serieMassimaSettimane),
            tappeSuperate: tappeSuperate,
            testRitmo: testRitmo
        )
    }

    /// Medaglie ottenute che l'utente non ha ancora visto con la celebrazione, nell'ordine dell'elenco.
    var medaglieDaFesteggiare: [Medaglia] {
        medaglie.filter { $0.ottenuta && !medaglieViste.contains($0.id) }
    }

    func segnaVista(medaglia id: String) {
        guard !medaglieViste.contains(id) else { return }
        medaglieViste.insert(id)
        salva()
    }

    func riepilogoAnno(_ anno: Int) -> RiepilogoAnno {
        RiepilogoAnnuale.calcola(nuotate: nuotate, anno: anno, profilo: profilo, calendar: .italiano)
    }

    var anniConNuotate: [Int] {
        RiepilogoAnnuale.anniConNuotate(nuotate, calendar: .italiano)
    }

    /// Migliori tempi su 100, 200, ... m a stile libero, dalle nuotate con i tempi delle vasche.
    var miglioriTempi: [MigliorTempo] {
        MiglioriTempi.calcola(nuotate: nuotate)
    }

    func celleCalendario(mese: Date) -> [CellaCalendario] {
        CalendarioNuotate.celle(nuotate: nuotate, mese: mese, calendar: .italiano)
    }

    // MARK: Obiettivo mensile

    var progressoMensile: ProgressoMetri? {
        ObiettivoMensile.progresso(obiettivoMetri: obiettivoMensileMetri, nuotate: nuotate, rispetto: Date(), calendar: .italiano)
    }

    func imposta(obiettivoMensile metri: Int?) {
        if let m = metri, !(ObiettivoMensile.minimo...ObiettivoMensile.massimo).contains(m) { return }
        obiettivoMensileMetri = metri
        salva()
    }

    // MARK: Commento del coach sul mese

    static func chiaveMese(_ data: Date) -> String {
        let c = Calendar.italiano
        return String(format: "%04ld-%02ld", c.component(.year, from: data), c.component(.month, from: data))
    }

    func datiMese(rispetto data: Date = Date()) -> DatiMese {
        DatiMese.calcola(nuotate: nuotate, profilo: profilo, rispetto: data, calendar: .italiano)
    }

    /// Il commento del coach sul mese, se l'utente ha acconsentito all'IA e il servizio risponde; altrimenti nil
    /// (la schermata mostra allora una frase fissa). Ricordato per mese: si chiede una sola volta per mese e per numero di nuotate.
    @MainActor
    func commentoMese(rispetto data: Date = Date()) async -> String? {
        guard consensoIA == true, let servizio = servizioCoach else { return nil }
        let dati = datiMese(rispetto: data)
        guard dati.nuotate > 0 else { return nil }
        let chiave = "\(StatoApp.chiaveMese(data))|\(dati.nuotate)"
        if let gia = commentiMese[chiave] { return gia }
        guard let testo = try? await servizio.commentoMese(dati: dati, profilo: profilo) else { return nil }
        let pulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pulito.isEmpty, pulito.count <= 400 else { return nil }
        commentiMese[chiave] = pulito
        salva()
        return pulito
    }

    // MARK: Consensi

    func confermaMaggiorenne() {
        maggiorenneConfermato = true
        salva()
    }

    func imposta(consensoIA nuovo: Bool) {
        consensoIA = nuovo
        // Cambiato il consenso, l'allenamento generato non vale più.
        if !nuovo {
            allenamentoGenerato = nil
            chiaveGenerato = nil
            cacheAllenamento = nil
        }
        salva()
    }

    // MARK: Percorso

    func vai(allaTappa id: Int) {
        tappaAttuale = id
        salva()
    }

    /// L'utente dichiara di aver superato il test della tappa. Le tappe guidano ma non bloccano (content/percorso.json):
    /// si passa alla tappa seguente, e si può sempre tornare indietro.
    func superaTappa(_ id: Int) {
        if !tappeSuperate.contains(id) { tappeSuperate.append(id) }
        if let prossima = contenuti.tappe.map(\.id).sorted().first(where: { $0 > id }) {
            tappaAttuale = prossima
        }
        salva()
    }

    func tappaSuperata(_ id: Int) -> Bool { tappeSuperate.contains(id) }

    func salva(testRitmo nuovo: TestRitmo) {
        testRitmo = nuovo
        salva()
    }

    // MARK: Allenamento di oggi

    private func chiaveOggi(adesso: Date) -> (giorno: Int, chiave: String) {
        let giorno = Calendar.italiano.ordinality(of: .day, in: .year, for: adesso) ?? 0
        let chiave = "\(giorno)|\(profilo.categoriaLivello.rawValue)|\(profilo.obiettivoEffettivo.rawValue)|\(profilo.vascaMetri)|\(contenuti.voci.count)"
        return (giorno, chiave)
    }

    /// L'allenamento di oggi: quello generato dal coach se c'è (e se l'utente ha dato il consenso all'IA),
    /// altrimenti un allenamento fisso adatto a livello, obiettivo e vasca. Cambia da un giorno all'altro.
    func allenamentoDiOggi(adesso: Date = Date()) -> Workout? {
        let (giorno, chiave) = chiaveOggi(adesso: adesso)
        if let scelto = allenamentoScelto, giornoAllenamentoScelto == giorno { return scelto }
        // Dopo una nuotata "dura" l'allenamento proposto si alleggerisce in base al motivo (solo sul telefono).
        let motivo = ultimoMotivoDifficolta
        if consensoIA == true, let generato = allenamentoGenerato, chiaveGenerato == chiave {
            return Riserva.alleggerisci(generato, motivo: motivo)
        }
        let chiaveFissa = chiave + "|" + (motivo?.rawValue ?? "")
        if let cache = cacheAllenamento, cache.chiave == chiaveFissa {
            return cache.workout.map { Riserva.alleggerisci($0, motivo: motivo) }
        }
        let w = contenuti.scegliRiserva(profilo: profilo, scelta: giorno, motivo: motivo)
        cacheAllenamento = (chiaveFissa, w)
        return w.map { Riserva.alleggerisci($0, motivo: motivo) }
    }

    /// Il motivo per cui l'allenamento proposto oggi è stato alleggerito (nil se non lo è, o se l'ha scelto l'utente).
    func alleggerimentoDiOggi(adesso: Date = Date()) -> MotivoDifficolta? {
        let giorno = Calendar.italiano.ordinality(of: .day, in: .year, for: adesso) ?? 0
        if allenamentoScelto != nil, giornoAllenamentoScelto == giorno { return nil }
        guard let m = ultimoMotivoDifficolta, m != .altro else { return nil }
        return m
    }

    /// Chiede al servizio coach l'allenamento di oggi. Solo con il consenso all'IA e il servizio configurato.
    /// Se qualcosa non va (rete, risposta non valida) non cambia nulla: resta l'allenamento fisso.
    /// Il risultato è controllato con lo stesso validatore del server e del Watch (lista chiusa di drill).
    @MainActor
    func aggiornaAllenamentoIA(adesso: Date = Date()) async {
        guard consensoIA == true, let servizio = servizioCoach, onboardingCompletato else { return }
        let (_, chiave) = chiaveOggi(adesso: adesso)
        if chiaveGenerato == chiave, allenamentoGenerato != nil { return }
        var richiesta = RichiestaAllenamento()
        if let s = ultimaSensazione { richiesta.riepilogo = "ultimo allenamento: \(s.rawValue)" }
        guard let w = try? await servizio.richiedi(profilo: profilo, richiesta: richiesta),
              WorkoutValidator.validate(w, allowedDrills: contenuti.drillAmmessi).isEmpty else { return }
        allenamentoGenerato = Riserva.adattaVasca(w, vascaMetri: profilo.vascaMetri)
        chiaveGenerato = chiave
        salva()
    }

    /// Tempo obiettivo per ogni ripetizione, se l'utente ha fatto il test del ritmo e le zone sono visibili.
    func targetRitmo(per workout: Workout) -> [Int?] {
        TargetRitmo.target(per: PianoAllenamento(workout: workout),
                           ritmoCriticoPer100: testRitmo?.ritmoRiferimentoPer100,
                           zone: contenuti.zone)
    }

    func inviaAlWatch() -> EsitoInvioWatch {
        guard let w = allenamentoDiOggi() else { return .errore }
        return watch.invia(allenamento: w, target: targetRitmo(per: w))
    }

    // MARK: Libreria e richieste al coach

    /// Tutti gli allenamenti approvati, adattati alla vasca dell'utente, per scegliere un allenamento diverso da quello di oggi.
    /// Ogni elemento ha la voce dell'indice (livello, obiettivi) e l'allenamento già validato.
    func libreria() -> [(voce: VoceAllenamento, workout: Workout)] {
        contenuti.voci.compactMap { voce in
            guard let w = contenuti.workout(della: voce) else { return nil }
            return (voce, Riserva.adattaVasca(w, vascaMetri: profilo.vascaMetri))
        }
    }

    /// L'utente sceglie un allenamento per oggi (dalla libreria o chiesto al coach): sostituisce quello proposto fino a fine giornata.
    func scegli(allenamento: Workout, adesso: Date = Date()) {
        allenamentoScelto = allenamento
        giornoAllenamentoScelto = Calendar.italiano.ordinality(of: .day, in: .year, for: adesso) ?? 0
        _ = watch.invia(allenamento: allenamento, target: targetRitmo(per: allenamento))
        salva()
    }

    /// Torna all'allenamento proposto.
    func annullaSceltaAllenamento() {
        allenamentoScelto = nil
        giornoAllenamentoScelto = nil
        salva()
    }

    /// Chiede al coach un allenamento con durata e obiettivo scelti. Serve il consenso all'IA e il servizio; nil se non riesce
    /// (l'app propone allora la libreria). La risposta passa dallo stesso validatore degli altri allenamenti.
    @MainActor
    func chiediAlCoach(_ richiesta: RichiestaAllenamento) async -> Workout? {
        guard consensoIA == true, let servizio = servizioCoach, onboardingCompletato else { return nil }
        var r = richiesta
        if let d = r.durataMinuti, !RichiestaAllenamento.durateAmmesse.contains(d) { r.durataMinuti = nil }
        if r.riepilogo == nil, let s = ultimaSensazione { r.riepilogo = "ultimo allenamento: \(s.rawValue)" }
        guard let w = try? await servizio.richiedi(profilo: profilo, richiesta: r),
              WorkoutValidator.validate(w, allowedDrills: contenuti.drillAmmessi).isEmpty else { return nil }
        return Riserva.adattaVasca(w, vascaMetri: profilo.vascaMetri)
    }

    /// Quante settimane fa è stato fatto l'ultimo test del ritmo (nil se non fatto).
    var settimaneDalTestRitmo: Int? {
        guard let t = testRitmo else { return nil }
        return Calendar.italiano.dateComponents([.weekOfYear], from: t.data, to: Date()).weekOfYear
    }

    /// Dopo quante settimane si propone di rifare il test. PROVVISORIO: scelta nostra, da confermare con l'istruttore.
    static let settimanePerRifareTest = 8

    // MARK: Apple Salute

    /// Chiede il permesso (una volta) e importa le nuotate nuove. Le nuotate già note (stesso id) non si duplicano: si uniscono.
    @MainActor
    func importaDaSalute(chiediPermesso: Bool = false) async {
        if !permessoSaluteChiesto {
            guard chiediPermesso else { return }
            _ = await lettoreSalute.richiediPermesso()
            permessoSaluteChiesto = true
            salva()
        }
        // Si riparte da 14 giorni prima dell'ultima lettura: le nuotate sincronizzate in ritardo da altri orologi
        // hanno date più vecchie. Quelle già note non si contano due volte (stesso id, `registra` le unisce).
        let dal: Date
        if let ultima = ultimaLetturaSalute {
            dal = Calendar.italiano.date(byAdding: .day, value: -14, to: ultima) ?? ultima
        } else {
            dal = Calendar.italiano.date(byAdding: .day, value: -90, to: Date()) ?? Date.distantPast
        }
        let lette = await lettoreSalute.leggiNuotate(dal: dal)
        ultimaLetturaSalute = Date()
        // Anche le nuotate già note passano da `registra`, che le unisce e completa le metriche mancanti.
        for n in lette {
            var nuova = n
            if nuova.origine == nil { nuova.origine = .salute }
            registra(nuova)
        }
        salva()
    }

    // MARK: Promemoria (ritmo Spronami)

    /// Chiede il permesso delle notifiche solo a chi sceglie Spronami; con gli altri ritmi cancella i promemoria.
    @MainActor
    func riprogrammaPromemoria(chiediPermesso: Bool = false) async {
        guard profilo.ritmo == .spronami, onboardingCompletato else {
            await notifiche.cancellaTutti()
            return
        }
        if chiediPermesso {
            guard await notifiche.richiediPermesso() else { return }
        }
        let date = PromemoriaSpronami.date(profilo: profilo, nuotate: nuotate.map(\.data))
        await notifiche.programma(
            date: date,
            titolo: "Swimwave",
            testo: testo("promemoria.testo", profilo.nomePulito)
        )
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
            let serie = serieSettimane
            if let t = SerieSettimane.traguardo(per: serie), traguardoSerieFesteggiato != t {
                return PopupCoach(momento: .serieSettimane(t), espressione: .traguardo,
                                  messaggio: testo("popup.serie.messaggio", profilo.nomePulito, t))
            }
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
        switch popup.momento {
        case .obiettivoRaggiunto:
            settimanaFesteggiata = ObiettivoSettimanale.idSettimana(adesso)
        case .serieSettimane(let t):
            settimanaFesteggiata = ObiettivoSettimanale.idSettimana(adesso)
            traguardoSerieFesteggiato = t
        default:
            break
        }
        salva()
    }
}

/// Interruttori di funzioni previste ma non offerte.
enum Funzioni {
    /// Test del ritmo: solo i 200 m a tutta. Il test dei 400 m non si propone agli adulti (decisione dell'istruttore, 11 ottobre 2026).
    static let testRitmoAgliAdulti = true
}
