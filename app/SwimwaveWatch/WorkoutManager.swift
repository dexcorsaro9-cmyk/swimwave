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
///  - cosa succede se l'app va in background o viene chiusa a metà (la sessione non viene ripresa: da fare).
final class WorkoutManager: NSObject, ObservableObject {
    enum Stato { case inAttesa, pronto, inCorso, finito }

    // MARK: Stato mostrato dalle viste
    @Published var stato: Stato = .inAttesa
    @Published var workout: Workout?
    @Published var avanzamento: AvanzamentoAllenamento?
    @Published var tempoTrascorso: TimeInterval = 0
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

    private let link = PhoneLink()
    private static let chiaveUltimoAllenamento = "swimwave.watch.ultimoAllenamento"

    override init() {
        super.init()
        link.onAllenamento = { [weak self] workout in
            self?.riceviAllenamento(workout)
        }
        link.attiva()
        // L'ultimo allenamento ricevuto resta disponibile anche senza iPhone.
        if let data = UserDefaults.standard.data(forKey: WorkoutManager.chiaveUltimoAllenamento),
           let w = try? JSONDecoder().decode(Workout.self, from: data) {
            prepara(w)
        }
    }

    // MARK: Allenamento ricevuto

    private func riceviAllenamento(_ nuovo: Workout) {
        // Non si cambia l'allenamento mentre si nuota.
        guard stato != .inCorso else { return }
        if let data = try? JSONEncoder().encode(nuovo) {
            UserDefaults.standard.set(data, forKey: WorkoutManager.chiaveUltimoAllenamento)
        }
        prepara(nuovo)
    }

    private func prepara(_ w: Workout) {
        workout = w
        avanzamento = AvanzamentoAllenamento(piano: PianoAllenamento(workout: w))
        tempoTrascorso = 0
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
            sessione.startActivity(with: inizio)
            builder.beginCollection(withStart: inizio) { [weak self] riuscito, errore in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if riuscito {
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
        guard stato == .inCorso, let fase = avanzamento?.fase else { return }
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
        guard stato == .inCorso, let av = avanzamento, av.fase == .nuoto, let passo = av.passoCorrente else { return }
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
        tempoTrascorso = builder?.elapsedTime ?? Date().timeIntervalSince(inizioAllenamento)
        if let av = avanzamento, case .recupero = av.fase, let fine = recuperoFine {
            let resto = Int(ceil(fine.timeIntervalSinceNow))
            recuperoRimanente = max(0, resto)
            if resto <= 0 { recuperoFinito() }
        }
    }

    // MARK: Fine

    /// Termina in anticipo (pagina dei controlli).
    func termina() {
        guard stato == .inCorso else { return }
        var av = avanzamento
        av?.termina()
        avanzamento = av
        terminaSessione()
    }

    private func terminaSessione() {
        timer?.invalidate()
        timer = nil
        WKInterfaceDevice.current().play(.stop)
        let durata = builder?.elapsedTime ?? Date().timeIntervalSince(inizioAllenamento)
        let metriPianificati = avanzamento?.metriCompletati ?? 0
        // Se HealthKit non ha dato distanza (per esempio nel simulatore) si usano i metri del piano completati.
        let metri = distanzaTotale > 0 ? Int(distanzaTotale.rounded()) : metriPianificati
        let titolo = workout?.titolo ?? ""

        sessione?.end()
        builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            self?.builder?.finishWorkout { _, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    let nuotata = NuotataCompletata(data: Date(), metri: metri, durataSecondi: Int(durata), titolo: titolo)
                    self.riepilogo = nuotata
                    self.link.invia(nuotata: nuotata)
                    self.stato = .finito
                }
            }
        }
    }

    /// Dal riepilogo si torna alla schermata iniziale.
    func chiudiRiepilogo() {
        sessione = nil
        builder = nil
        if let w = workout {
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
        // Lo stato dell'allenamento è guidato da noi (avanzamento); qui non serve altro per ora.
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.messaggioErrore = NSLocalizedString("watch.errore.sessione", comment: "")
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
