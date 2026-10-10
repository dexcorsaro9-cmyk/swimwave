import Combine
import Foundation
import HealthKit
import WatchKit
import SwimwaveCore

/// Guida l'allenamento sul Watch: sessione HealthKit di nuoto + avanzamento serie per serie (modo `.scheda`),
/// oppure nuotata libera senza scheda, in vasca o in acque libere (modo `.libera`). La sessione è la stessa
/// in entrambi i modi: cambia solo la configurazione HealthKit e il fatto che in `.libera` non c'è avanzamento a serie.
///
/// NON TESTATO: scritto senza Xcode. Da provare su un Apple Watch vero, in piscina (il simulatore non produce
/// dati di nuoto). Cose da verificare sul campo:
///  - il rilevamento delle vasche (distanceSwimming arriva a ogni vasca? con che ritardo?);
///  - il blocco dello schermo in acqua (Water Lock, attivato all'avvio con `enableWaterLock()`) e il pulsante "Fatto" come
///    riserva dell'avanzamento automatico (per toccarlo bisogna prima sbloccare con la Digital Crown);
///  - le vibrazioni (si distinguono in acqua?) e la durata della batteria;
///  - pausa e ripresa (HKWorkoutSession.pause()/resume()): il cronometro e il recupero si fermano davvero? l'avanzamento
///    automatico resta fermo? la distanza nuotata dopo la ripresa viene contata bene?
///  - cosa succede se l'app va in background o viene chiusa a metà: la sessione NON viene ripresa (scelta voluta, troppo
///    rischioso senza prove). Al riavvio si mostra "Pronto" con l'ultimo allenamento ricevuto. Da vedere in piscina se la
///    sessione rimasta aperta blocca l'avvio della successiva (in quel caso compare l'errore "Impossibile avviare").
///  - nuotata libera in acque libere: i metri arrivano dal sistema (GPS/accelerometro) solo se l'utente concede la
///    posizione; da vedere se il sistema chiede il permesso da solo all'avvio della sessione e quanto tempo serve
///    per avere i primi metri;
///  - riepilogo: calorie, frequenza media e bracciate vengono dal builder; se mancano (nessun sensore, permesso
///    negato) restano nil e non si mostrano.
final class WorkoutManager: NSObject, ObservableObject {
    /// `sceltaLibera`: schermata con i tre pulsanti (vasca 25 m, vasca 50 m, acque libere) prima di una nuotata libera.
    enum Stato { case inAttesa, pronto, sceltaLibera, inCorso, finito }
    /// `.scheda`: allenamento guidato serie per serie. `.libera`: solo tracciamento (cronometro e metri).
    enum Modo { case scheda, libera }

    // MARK: Stato mostrato dalle viste
    @Published var stato: Stato = .inAttesa
    @Published var workout: Workout?
    @Published var avanzamento: AvanzamentoAllenamento?
    /// Tempo di allenamento senza le pause.
    @Published var tempoTrascorso: TimeInterval = 0
    /// Vero quando la sessione HealthKit è in pausa (allineato allo stato reale nel delegate).
    @Published var inPausa = false
    @Published var recuperoRimanente = 0
    /// Metri nuotati nella ripetizione corrente, letti da HealthKit.
    @Published var metriNellaRipetizione = 0.0
    @Published var messaggioErrore: String?
    @Published var riepilogo: NuotataCompletata?
    @Published var modo: Modo = .scheda
    /// Vasca o acque libere (in modo `.scheda` è sempre vasca).
    @Published var ambiente: AmbienteNuoto = .vasca
    /// Metri totali nuotati nella sessione, letti da HealthKit (per la nuotata libera).
    @Published var metriTotali = 0.0
    /// Tempo obiettivo (secondi) per ogni ripetizione del piano, nello stesso ordine di `piano.passi`; nil = nessun obiettivo.
    /// È solo un riferimento da mostrare: non si confronta col tempo reale e non c'è giudizio.
    @Published var target: [Int?] = []

    /// Tempo obiettivo della ripetizione corrente, se c'è (nuotata guidata, iPhone che manda i target).
    var obiettivoCorrente: Int? {
        guard modo == .scheda, let av = avanzamento, target.indices.contains(av.indice),
              let secondi = target[av.indice], secondi > 0 else { return nil }
        return secondi
    }

    // MARK: HealthKit
    private let healthStore = HKHealthStore()
    private var sessione: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var vascaMetri = 25
    /// Lunghezza della vasca in uso (25 o 50 m), per mostrarla nella nuotata libera.
    var vascaMetriScelti: Int { vascaMetri }
    /// Vero dall'avvio fino a quando la sessione parte o fallisce: evita due sessioni con due tocchi ravvicinati.
    private var inAvvio = false

    /// Distanza totale nuotata secondo HealthKit e valore all'inizio della ripetizione corrente.
    private var distanzaTotale = 0.0
    private var distanzaInizioRipetizione = 0.0
    private var recuperoFine: Date?
    private var inizioAllenamento = Date()
    private var timer: Timer?

    // Tempo senza pause. Non ci fidiamo solo di `builder.elapsedTime` (non sono sicuro che escluda le pause in ogni caso)
    // né di `Date()` (le conterebbe): teniamo un accumulatore dei tratti già trascorsi in cui si nuotava
    // e la data di inizio del tratto in corso (nil quando si è in pausa).
    private var tempoAccumulato: TimeInterval = 0
    private var inizioTratto: Date?
    /// Secondi di recupero che mancavano quando si è premuto pausa (nil se non si era in recupero).
    private var recuperoMancanteInPausa: TimeInterval?
    /// Evita di chiudere due volte la sessione (per esempio ultimo "Fatto" e "Termina" quasi insieme).
    private var inChiusura = false

    private let link = PhoneLink()
    private static let chiaveUltimoAllenamento = "swimwave.watch.ultimoAllenamento"
    /// Tempi obiettivo dell'ultimo allenamento ricevuto (lista di interi, 0 = nessun obiettivo), salvati insieme a lui.
    private static let chiaveUltimoTarget = "swimwave.watch.ultimoTarget"

    override init() {
        super.init()
        link.onAllenamento = { [weak self] workout, target in
            self?.riceviAllenamento(workout, target: target)
        }
        link.attiva()
        // L'ultimo allenamento ricevuto resta disponibile anche senza iPhone, e anche dopo che l'app è stata chiusa:
        // al riavvio si torna a "Pronto" (la sessione di nuoto eventualmente interrotta non viene ripresa).
        if let w = WorkoutManager.caricaUltimoAllenamento() {
            prepara(w)
        }
    }

    private static func caricaUltimoAllenamento() -> Workout? {
        guard let data = UserDefaults.standard.data(forKey: chiaveUltimoAllenamento) else { return nil }
        return try? JSONDecoder().decode(Workout.self, from: data)
    }

    // MARK: Allenamento ricevuto

    /// Tempi obiettivo salvati con l'ultimo allenamento, validi solo se hanno un valore per ogni ripetizione.
    /// Se mancano (iPhone vecchio, nessun salvataggio) o la lunghezza non torna: nessun obiettivo.
    private static func caricaUltimoTarget(passi: Int) -> [Int?] {
        let nessuno = [Int?](repeating: nil, count: passi)
        guard let valori = UserDefaults.standard.array(forKey: chiaveUltimoTarget) as? [Int],
              valori.count == passi else { return nessuno }
        return valori.map { $0 > 0 ? $0 : nil }
    }

    private func riceviAllenamento(_ nuovo: Workout, target nuovoTarget: [Int?]) {
        // Il nuovo allenamento e i suoi tempi obiettivo si salvano sempre, così non si perdono.
        if let data = try? JSONEncoder().encode(nuovo) {
            UserDefaults.standard.set(data, forKey: WorkoutManager.chiaveUltimoAllenamento)
            UserDefaults.standard.set(nuovoTarget.map { $0 ?? 0 }, forKey: WorkoutManager.chiaveUltimoTarget)
        }
        // Ma non si cambia la schermata mentre si nuota o mentre si guarda il riepilogo: sarà caricato alla chiusura.
        guard stato == .inAttesa || stato == .pronto else { return }
        prepara(nuovo)
    }

    private func prepara(_ w: Workout) {
        workout = w
        let piano = PianoAllenamento(workout: w)
        avanzamento = AvanzamentoAllenamento(piano: piano)
        // Sempre gli obiettivi salvati: prepara() è chiamata solo con l'ultimo allenamento ricevuto.
        target = WorkoutManager.caricaUltimoTarget(passi: piano.passi.count)
        tempoTrascorso = 0
        tempoAccumulato = 0
        inizioTratto = nil
        recuperoMancanteInPausa = nil
        recuperoFine = nil
        inPausa = false
        inChiusura = false
        recuperoRimanente = 0
        metriNellaRipetizione = 0
        metriTotali = 0
        modo = .scheda
        ambiente = .vasca
        inAvvio = false
        riepilogo = nil
        messaggioErrore = nil
        stato = .pronto
    }

    // MARK: Nuotata libera: scelta dell'ambiente

    /// Dalla schermata iniziale (con o senza allenamento pronto) apre la scelta: vasca 25 m, vasca 50 m, acque libere.
    func apriSceltaLibera() {
        guard stato == .inAttesa || stato == .pronto else { return }
        messaggioErrore = nil
        stato = .sceltaLibera
    }

    /// Dalla scelta si torna alla schermata iniziale.
    func annullaSceltaLibera() {
        guard stato == .sceltaLibera, !inAvvio else { return }
        messaggioErrore = nil
        if let w = WorkoutManager.caricaUltimoAllenamento() ?? workout {
            prepara(w)
        } else {
            stato = .inAttesa
        }
    }

    // MARK: Avvio

    func inizia() {
        guard let w = workout, stato == .pronto, !inAvvio else { return }
        modo = .scheda
        ambiente = .vasca
        vascaMetri = w.vascaMetri
        richiediPermessiEAvvia()
    }

    /// Avvia la nuotata libera (dalla schermata di scelta): `.vasca` con la lunghezza scelta (25 o 50 m), oppure `.acqueLibere`.
    func iniziaLibera(in nuovoAmbiente: AmbienteNuoto, vascaMetri metri: Int = 25) {
        guard stato == .sceltaLibera, !inAvvio else { return }
        modo = .libera
        ambiente = nuovoAmbiente
        // Lunghezza della vasca: quella scelta dall'utente (in acque libere non serve e non si manda).
        vascaMetri = (metri == 25 || metri == 50) ? metri : 25
        // Nessuna scheda: l'avanzamento a serie e i tempi obiettivo non c'entrano.
        avanzamento = nil
        target = []
        richiediPermessiEAvvia()
    }

    private func richiediPermessiEAvvia() {
        guard HKHealthStore.isHealthDataAvailable() else {
            messaggioErrore = NSLocalizedString("watch.errore.salute", comment: "")
            return
        }
        inAvvio = true
        let daScrivere: Set<HKSampleType> = [HKObjectType.workoutType()]
        let daLeggere: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceSwimming),
            HKQuantityType(.swimmingStrokeCount),
        ]
        healthStore.requestAuthorization(toShare: daScrivere, read: daLeggere) { [weak self] riuscito, errore in
            DispatchQueue.main.async {
                guard let self else { return }
                if riuscito {
                    self.avviaSessione()
                } else {
                    self.inAvvio = false
                    self.messaggioErrore = NSLocalizedString("watch.errore.permessi", comment: "")
                }
            }
        }
    }

    private func avviaSessione() {
        let configurazione = HKWorkoutConfiguration()
        configurazione.activityType = .swimming
        switch ambiente {
        case .vasca:
            configurazione.swimmingLocationType = .pool
            // Lunghezza della vasca dal profilo (arriva dentro l'allenamento: vasca_metri; 25 m se non c'è).
            configurazione.lapLength = HKQuantity(unit: HKUnit.meter(), doubleValue: Double(vascaMetri))
        case .acqueLibere:
            // Nessun lapLength: i metri li stima il sistema (GPS/accelerometro) se la posizione è consentita.
            configurazione.swimmingLocationType = .openWater
        }

        do {
            let sessione = try HKWorkoutSession(healthStore: healthStore, configuration: configurazione)
            let builder = sessione.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configurazione)
            sessione.delegate = self
            builder.delegate = self
            self.sessione = sessione
            self.builder = builder

            let inizio = Date()
            inizioAllenamento = inizio
            distanzaTotale = 0
            metriTotali = 0
            distanzaInizioRipetizione = 0
            tempoAccumulato = 0
            inizioTratto = nil
            recuperoMancanteInPausa = nil
            inPausa = false
            inChiusura = false
            sessione.startActivity(with: inizio)
            builder.beginCollection(withStart: inizio) { [weak self] riuscito, errore in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.inAvvio = false
                    if riuscito {
                        self.inizioTratto = Date()
                        self.stato = .inCorso
                        self.avviaTimer()
                        WKInterfaceDevice.current().play(.start)
                        // Blocco Acqua: l'acqua sullo schermo non registra tocchi fantasma durante la bracciata.
                        // Si toglie girando la Digital Crown (per esempio per usare "Fatto" se l'avanzamento
                        // automatico non scatta). Da provare in piscina.
                        WKInterfaceDevice.current().enableWaterLock()
                    } else {
                        // La raccolta non è partita: si chiude la sessione già creata, così non blocca la prossima.
                        self.sessione?.end()
                        self.sessione = nil
                        self.builder = nil
                        self.messaggioErrore = NSLocalizedString("watch.errore.sessione", comment: "")
                    }
                }
            }
        } catch {
            inAvvio = false
            messaggioErrore = NSLocalizedString("watch.errore.sessione", comment: "")
        }
    }

    // MARK: Avanzamento

    /// Pulsante grande: "Fatto" durante la nuotata, "Vai" durante il recupero.
    /// È la riserva dell'avanzamento automatico, che usa i metri di HealthKit.
    func avanti() {
        // In pausa il pulsante non fa nulla (nella vista è anche disattivato).
        guard stato == .inCorso, modo == .scheda, !inPausa, let fase = avanzamento?.fase else { return }
        switch fase {
        case .nuoto: ripetizioneFinita()
        case .recupero: recuperoFinito()
        case .finito: break
        }
    }

    private func ripetizioneFinita() {
        guard var av = avanzamento else { return }
        av.completaPasso()
        avanzamento = av
        metriNellaRipetizione = 0
        switch av.fase {
        case .finito:
            terminaSessione()
        case .recupero(let secondi):
            recuperoRimanente = secondi
            recuperoFine = Date().addingTimeInterval(TimeInterval(secondi))
            WKInterfaceDevice.current().play(.success)
        case .nuoto:
            distanzaInizioRipetizione = distanzaTotale
            WKInterfaceDevice.current().play(.success)
        }
    }

    private func recuperoFinito() {
        guard var av = avanzamento else { return }
        av.finisciRecupero()
        avanzamento = av
        recuperoFine = nil
        recuperoRimanente = 0
        distanzaInizioRipetizione = distanzaTotale
        metriNellaRipetizione = 0
        WKInterfaceDevice.current().play(.start)
    }

    /// Avanzamento automatico: quando i metri della ripetizione sono quasi completi (tolleranza di mezza vasca,
    /// perché HealthKit aggiorna la distanza a ogni vasca) passa alla ripetizione seguente.
    private func controllaAvanzamentoAutomatico() {
        // In pausa l'avanzamento automatico è fermo.
        guard stato == .inCorso, modo == .scheda, !inPausa, let av = avanzamento, av.fase == .nuoto, let passo = av.passoCorrente else { return }
        let nuotati = max(0, distanzaTotale - distanzaInizioRipetizione)
        metriNellaRipetizione = nuotati
        if nuotati >= Double(passo.distanzaMetri) - Double(vascaMetri) / 2.0 {
            ripetizioneFinita()
        }
    }

    // MARK: Timer

    private func avviaTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        // In pausa né il cronometro né il recupero avanzano.
        guard !inPausa else { return }
        tempoTrascorso = tempoAttivo(Date())
        if modo == .scheda, let av = avanzamento, case .recupero = av.fase, let fine = recuperoFine {
            let resto = Int(ceil(fine.timeIntervalSinceNow))
            recuperoRimanente = max(0, resto)
            if resto <= 0 { recuperoFinito() }
        }
    }

    /// Tempo di allenamento escluse le pause, a questo istante.
    private func tempoAttivo(_ adesso: Date) -> TimeInterval {
        var totale = tempoAccumulato
        if let inizio = inizioTratto {
            totale += max(0, adesso.timeIntervalSince(inizio))
        }
        return totale
    }

    // MARK: Pausa e ripresa

    /// Mette in pausa la sessione di nuoto (pulsante nella pagina dei controlli).
    func pausa() {
        guard stato == .inCorso, !inPausa, !inChiusura else { return }
        sessione?.pause()
        // Fermiamo subito cronometro e recupero; il delegate conferma lo stato reale (vedi `workoutSession(_:didChangeTo:...)`).
        applicaPausa(true)
        WKInterfaceDevice.current().play(.stop)
    }

    func riprendi() {
        guard stato == .inCorso, inPausa, !inChiusura else { return }
        sessione?.resume()
        applicaPausa(false)
        WKInterfaceDevice.current().play(.start)
    }

    /// Allinea cronometro e recupero allo stato di pausa. Si può chiamare più volte con lo stesso valore (non fa nulla).
    /// Va chiamata sul thread principale.
    private func applicaPausa(_ inPausaNuovo: Bool) {
        guard stato == .inCorso, inPausaNuovo != inPausa else { return }
        let ora = Date()
        if inPausaNuovo {
            if let inizio = inizioTratto {
                tempoAccumulato += max(0, ora.timeIntervalSince(inizio))
            }
            inizioTratto = nil
            tempoTrascorso = tempoAccumulato
            if let fine = recuperoFine {
                recuperoMancanteInPausa = max(0, fine.timeIntervalSince(ora))
                recuperoFine = nil
            }
            inPausa = true
        } else {
            inizioTratto = ora
            if let mancante = recuperoMancanteInPausa {
                recuperoFine = ora.addingTimeInterval(mancante)
            }
            recuperoMancanteInPausa = nil
            inPausa = false
        }
    }

    // MARK: Fine

    /// Termina in anticipo (pagina dei controlli). Funziona anche in pausa.
    func termina() {
        guard stato == .inCorso, !inChiusura else { return }
        if modo == .scheda {
            var av = avanzamento
            av?.termina()
            avanzamento = av
        }
        terminaSessione()
    }

    private func terminaSessione() {
        guard !inChiusura else { return }
        inChiusura = true
        timer?.invalidate()
        timer = nil
        WKInterfaceDevice.current().play(.stop)
        // Durata senza pause (anche se si termina mentre si è in pausa: `inizioTratto` è nil e conta l'accumulatore).
        let durata = tempoAttivo(Date())
        tempoAccumulato = durata
        inizioTratto = nil
        // Nella nuotata libera non c'è un piano: se HealthKit non dà i metri restano 0.
        let metriPianificati = modo == .scheda ? (avanzamento?.metriCompletati ?? 0) : 0
        let titolo = modo == .libera
            ? NSLocalizedString("watch.libera.titolo", comment: "")
            : (workout?.titolo ?? "")
        let builderCorrente = builder

        sessione?.end()
        guard let builderCorrente else {
            // Non dovrebbe succedere: si chiude comunque, con i metri del piano.
            concludi(workout: nil, builder: nil, durata: durata, metriPianificati: metriPianificati, titolo: titolo)
            return
        }
        builderCorrente.endCollection(withEnd: Date()) { [weak self] _, _ in
            builderCorrente.finishWorkout { workout, _ in
                DispatchQueue.main.async {
                    self?.concludi(workout: workout, builder: builderCorrente, durata: durata,
                                   metriPianificati: metriPianificati, titolo: titolo)
                }
            }
        }
    }

    /// Ultimo passo: crea la nuotata da mandare all'iPhone. Sul thread principale.
    private func concludi(workout: HKWorkout?, builder: HKLiveWorkoutBuilder?, durata: TimeInterval,
                          metriPianificati: Int, titolo: String) {
        // Metri: la distanza di nuoto misurata da HealthKit; se manca (per esempio nel simulatore) quelli del piano.
        let misurati = builder?.statistics(for: HKQuantityType(.distanceSwimming))?
            .sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
        let metri = (misurati.isFinite && misurati > 0 && misurati < 1_000_000) ? Int(misurati.rounded()) : metriPianificati
        // Stesso id dell'allenamento salvato in Apple Salute: l'iPhone, leggendo Salute, non lo conta due volte.
        // Se il salvataggio non è riuscito (workout nil) si usa un id nuovo.
        // Dati in più, solo se il builder li ha (altrimenti nil e non si mostrano). Le vasche (`vasche`) le legge l'iPhone da Salute.
        let calorie = WorkoutManager.interoPositivo(
            builder?.statistics(for: HKQuantityType(.activeEnergyBurned))?
                .sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()))
        let battitiAlMinuto = HKUnit.count().unitDivided(by: HKUnit.minute())
        let frequenzaMedia = WorkoutManager.interoPositivo(
            builder?.statistics(for: HKQuantityType(.heartRate))?
                .averageQuantity()?.doubleValue(for: battitiAlMinuto))
        let bracciate = WorkoutManager.interoPositivo(
            builder?.statistics(for: HKQuantityType(.swimmingStrokeCount))?
                .sumQuantity()?.doubleValue(for: HKUnit.count()))
        let inVasca = ambiente == .vasca
        let nuotata = NuotataCompletata(id: workout?.uuid ?? UUID(), data: Date(), metri: metri,
                                        durataSecondi: Int(durata), titolo: titolo, origine: .watch,
                                        calorie: calorie, frequenzaCardiacaMedia: frequenzaMedia,
                                        bracciate: bracciate, vascaMetri: inVasca ? vascaMetri : nil,
                                        ambiente: ambiente)
        riepilogo = nuotata
        link.invia(nuotata: nuotata)
        inPausa = false
        stato = .finito
    }

    /// Arrotonda un valore di HealthKit a Int; nil se manca, non è finito o non è positivo.
    private static func interoPositivo(_ valore: Double?) -> Int? {
        guard let valore, valore.isFinite, valore > 0, valore < 1_000_000_000 else { return nil }
        return Int(valore.rounded())
    }

    /// Dal riepilogo si torna alla schermata iniziale.
    func chiudiRiepilogo() {
        sessione = nil
        builder = nil
        modo = .scheda
        ambiente = .vasca
        // Se durante l'allenamento è arrivato un allenamento più recente, si parte da quello.
        if let w = WorkoutManager.caricaUltimoAllenamento() ?? workout {
            prepara(w)
        } else {
            riepilogo = nil
            stato = .inAttesa
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        // L'avanzamento è guidato da noi; qui allineiamo solo la pausa allo stato reale della sessione
        // (la pausa può arrivare anche dal sistema, non solo dal nostro pulsante).
        // Il passaggio running -> running iniziale si ignora: "ripresa" solo se si veniva da paused.
        DispatchQueue.main.async { [weak self] in
            guard let self, workoutSession === self.sessione else { return }
            if toState == .paused {
                self.applicaPausa(true)
            } else if toState == .running && fromState == .paused {
                self.applicaPausa(false)
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.messaggioErrore = NSLocalizedString("watch.errore.sessione", comment: "")
            // Se un pause()/resume() non è riuscito, la pausa mostrata deve tornare a quella reale.
            if self.stato == .inCorso, let reale = self.sessione?.state {
                self.applicaPausa(reale == .paused)
            }
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let tipoDistanza = HKQuantityType(.distanceSwimming)
        guard collectedTypes.contains(tipoDistanza) else { return }
        let metri = workoutBuilder.statistics(for: tipoDistanza)?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.distanzaTotale = metri
            self.metriTotali = metri
            self.controllaAvanzamentoAutomatico()
        }
    }
}
