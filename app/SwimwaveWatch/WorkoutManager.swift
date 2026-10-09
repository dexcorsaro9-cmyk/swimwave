import Combine
import Foundation
import HealthKit
import WatchKit
import SwimwaveCore

/// Guida l'allenamento sul Watch: sessione HealthKit di nuoto in vasca + avanzamento serie per serie.
///
/// NON TESTATO: scritto senza Xcode. Da provare su un Apple Watch vero, in piscina (il simulatore non produce
/// dati di nuoto). Cose da verificare sul campo:
///  - il rilevamento delle vasche (distanceSwimming arriva a ogni vasca? con che ritardo?);
///  - il blocco dello schermo in acqua (Water Lock) e il pulsante "Fatto" come riserva dell'avanzamento automatico;
///  - le vibrazioni (si distinguono in acqua?) e la durata della batteria;
///  - pausa e ripresa (HKWorkoutSession.pause()/resume()): il cronometro e il recupero si fermano davvero? l'avanzamento
///    automatico resta fermo? la distanza nuotata dopo la ripresa viene contata bene?
///  - cosa succede se l'app va in background o viene chiusa a metà: la sessione NON viene ripresa (scelta voluta, troppo
///    rischioso senza prove). Al riavvio si mostra "Pronto" con l'ultimo allenamento ricevuto. Da vedere in piscina se la
///    sessione rimasta aperta blocca l'avvio della successiva (in quel caso compare l'errore "Impossibile avviare").
final class WorkoutManager: NSObject, ObservableObject {
    enum Stato { case inAttesa, pronto, inCorso, finito }

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

    // MARK: HealthKit
    private let healthStore = HKHealthStore()
    private var sessione: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var vascaMetri = 25

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

    override init() {
        super.init()
        link.onAllenamento = { [weak self] workout in
            self?.riceviAllenamento(workout)
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

    private func riceviAllenamento(_ nuovo: Workout) {
        // Il nuovo allenamento si salva sempre, così non si perde.
        if let data = try? JSONEncoder().encode(nuovo) {
            UserDefaults.standard.set(data, forKey: WorkoutManager.chiaveUltimoAllenamento)
        }
        // Ma non si cambia la schermata mentre si nuota o mentre si guarda il riepilogo: sarà caricato alla chiusura.
        guard stato == .inAttesa || stato == .pronto else { return }
        prepara(nuovo)
    }

    private func prepara(_ w: Workout) {
        workout = w
        avanzamento = AvanzamentoAllenamento(piano: PianoAllenamento(workout: w))
        tempoTrascorso = 0
        tempoAccumulato = 0
        inizioTratto = nil
        recuperoMancanteInPausa = nil
        recuperoFine = nil
        inPausa = false
        inChiusura = false
        recuperoRimanente = 0
        metriNellaRipetizione = 0
        riepilogo = nil
        messaggioErrore = nil
        stato = .pronto
    }

    // MARK: Avvio

    func inizia() {
        guard let w = workout, stato == .pronto else { return }
        vascaMetri = w.vascaMetri
        guard HKHealthStore.isHealthDataAvailable() else {
            messaggioErrore = NSLocalizedString("watch.errore.salute", comment: "")
            return
        }
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
                    self.messaggioErrore = NSLocalizedString("watch.errore.permessi", comment: "")
                }
            }
        }
    }

    private func avviaSessione() {
        let configurazione = HKWorkoutConfiguration()
        configurazione.activityType = .swimming
        configurazione.swimmingLocationType = .pool
        // Lunghezza della vasca dal profilo (arriva dentro l'allenamento: vasca_metri).
        configurazione.lapLength = HKQuantity(unit: HKUnit.meter(), doubleValue: Double(vascaMetri))

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
                    if riuscito {
                        self.inizioTratto = Date()
                        self.stato = .inCorso
                        self.avviaTimer()
                        WKInterfaceDevice.current().play(.start)
                    } else {
                        self.messaggioErrore = NSLocalizedString("watch.errore.sessione", comment: "")
                    }
                }
            }
        } catch {
            messaggioErrore = NSLocalizedString("watch.errore.sessione", comment: "")
        }
    }

    // MARK: Avanzamento

    /// Pulsante grande: "Fatto" durante la nuotata, "Vai" durante il recupero.
    /// È la riserva dell'avanzamento automatico, che usa i metri di HealthKit.
    func avanti() {
        // In pausa il pulsante non fa nulla (nella vista è anche disattivato).
        guard stato == .inCorso, !inPausa, let fase = avanzamento?.fase else { return }
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
        guard stato == .inCorso, !inPausa, let av = avanzamento, av.fase == .nuoto, let passo = av.passoCorrente else { return }
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
        if let av = avanzamento, case .recupero = av.fase, let fine = recuperoFine {
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
        var av = avanzamento
        av?.termina()
        avanzamento = av
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
        let metriPianificati = avanzamento?.metriCompletati ?? 0
        let titolo = workout?.titolo ?? ""
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
        let metri = misurati > 0 ? Int(misurati.rounded()) : metriPianificati
        // Stesso id dell'allenamento salvato in Apple Salute: l'iPhone, leggendo Salute, non lo conta due volte.
        // Se il salvataggio non è riuscito (workout nil) si usa un id nuovo.
        let nuotata = NuotataCompletata(id: workout?.uuid ?? UUID(), data: Date(), metri: metri,
                                        durataSecondi: Int(durata), titolo: titolo, origine: .watch)
        riepilogo = nuotata
        link.invia(nuotata: nuotata)
        inPausa = false
        stato = .finito
    }

    /// Dal riepilogo si torna alla schermata iniziale.
    func chiudiRiepilogo() {
        sessione = nil
        builder = nil
        // Se durante l'allenamento è arrivato un allenamento più recente, si parte da quello.
        if let w = WorkoutManager.caricaUltimoAllenamento() ?? workout {
            prepara(w)
        } else {
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
            self.controllaAvanzamentoAutomatico()
        }
    }
}
