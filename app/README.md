# App Swimwave (iPhone + Apple Watch)

Scheletro dell'app nativa in SwiftUI: iPhone (iOS 17) e Apple Watch (watchOS 10), con la logica condivisa in `../Packages/SwimwaveCore`.

**Stato: scritto senza Swift né Xcode a disposizione. Nulla è stato compilato né eseguito.** Il primo passo, aprendo il progetto, è compilare e correggere gli errori (probabili, ma piccoli).

## Come generare il progetto

```bash
brew install xcodegen
cd app
xcodegen            # crea Swimwave.xcodeproj e la cartella Config/ (Info.plist e entitlements)
open Swimwave.xcodeproj
```

Poi in Xcode:
1. Cambia il bundle id segnaposto `com.example.swimwave` in `project.yml` (anche `com.example.swimwave.watchkitapp` e `WKCompanionAppBundleIdentifier`) e rigenera con `xcodegen`.
2. Imposta il team in *Signing & Capabilities* (o `DEVELOPMENT_TEAM` in `project.yml`) per entrambi i target.
3. Scegli lo schema `Swimwave` e un iPhone. Il Watch si prova solo su un orologio vero (vedi sotto).

`Swimwave.xcodeproj/` e `Config/` sono generati e stanno in `app/.gitignore`.

## Pacchetto condiviso: come eseguire i test

```bash
cd Packages/SwimwaveCore
swift test
```

Serve un Mac con Xcode (il pacchetto usa solo Foundation, quindi in teoria gira anche su Linux con Swift 5.9+). Il test `testContenutiRealiDelRepository` legge i file veri di `content/` e controlla che tutti gli allenamenti di riserva passino la validazione.

Aggiunto al pacchetto (senza toccare le API esistenti):
- `Profilo` (+ `Livello`, `Obiettivo`, `Vasca`, `Ritmo`, `CoachID`) con validazione dei campi obbligatori;
- `Saluto` e `FasciaOraria` (mattina 5-12, pomeriggio 13-17, sera 18-4);
- `ObiettivoSettimanale` / `ProgressoSettimanale` (nuotate nella settimana, "ne manca una");
- `ContentStore` (legge `content/*.json`, mostra solo i contenuti `approvato`; in debug anche le bozze), `Riserva` (stessa logica di `scegliRiserva` del server, più `adattaVasca`);
- `PianoAllenamento` e `AvanzamentoAllenamento` (la logica serie per serie del Watch);
- `MessaggiWatch` e `NuotataCompletata` (chiavi e codifica dei messaggi iPhone <-> Watch).

## Cosa c'è

| Parte | File principali |
|---|---|
| App iPhone | `Swimwave/SwimwaveApp.swift`, `Swimwave/Schermate/` (Oggi, Percorso, Storico, Profilo, Informazioni), `Swimwave/Stato/StatoApp.swift` |
| Tema | `Swimwave/Tema/Tema.swift` (colori nominati, bottoni, carta, onda, menu a tendina), `Tema/Testi.swift` (etichette localizzate) |
| Coach | `Swimwave/Coach/CoachPopup.swift` (avatar tondo, sei espressioni, popup riusabile) |
| Primo avvio | `Swimwave/Onboarding/OnboardingView.swift` (scelta coach, lavagnetta a 5 passi con menu a tendina, scheda finale) |
| Risorse | `Swimwave/Assets.xcassets` (colori chiaro/scuro, 12 avatar), `Swimwave/Localizable.xcstrings`, `SwimwaveWatch/Localizable.xcstrings` |
| App Watch | `SwimwaveWatch/WorkoutManager.swift` (HKWorkoutSession), `PhoneLink.swift` (WatchConnectivity), `AllenamentoView.swift`, `ContentView.swift` |

Scelte da sapere:
- **Persistenza con UserDefaults** (un solo blocco JSON, `StatoApp`), non SwiftData: senza compilare, le macro di SwiftData sono un rischio inutile per pochi dati. Il motivo è anche nel commento di `StatoApp.swift`.
- **Coach come configurazione dell'app**, non da `content/coach.json`: quel file è in `bozza` (la scelta del coach sparirebbe in release) e la sua presentazione contiene "coach virtuale", che nelle schermate va evitato (una sola riga nella scelta e le Informazioni).
- **Stringhe**: tutte in `Localizable.xcstrings`, con chiavi come `oggi.titolo`. I testi che vengono da `content/` (titoli, drill, tappe) sono in italiano e non ancora traducibili.
- **I contenuti entrano nell'app come cartella `content/`** (folder reference in `project.yml`) e vengono letti a runtime.

## IMPORTANTE: oggi gli utenti non vedrebbero contenuti

Tutti i contenuti in `content/` sono `bozza`. Una build **Release** (che mostra solo `approvato`) ha Oggi senza allenamento e Percorso vuoto, con un messaggio onesto che spiega che sono in revisione. Le build **Debug** includono le bozze (e mostrano una riga di diagnostica nel Profilo). Quando l'istruttore approva i contenuti (`content/REVISIONE.md`) la build Release si riempie da sola.

## Scritto e NON testato

Tutto. In particolare, da guardare per primi:

- **Compilazione**: non c'era un compilatore. Punti a rischio: `@Bindable var stato = stato` in `ProfiloView`, la sintassi `#Preview`, i tipi dei `Picker` con selezione opzionale (`MenuScelta`), le firme dei delegati di HealthKit/WatchConnectivity.
- **XcodeGen**: la cartella `content` come `type: folder`, l'incorporamento dell'app Watch nell'app iPhone ("Embed Watch Content") e i file `Config/*.plist` generati. Se il Watch non viene incorporato, aggiungere la fase a mano.
- **Watch in acqua** (solo su orologio vero, in piscina): la sessione `HKWorkoutSession` per il nuoto in vasca, il rilevamento delle vasche (`distanceSwimming`) che fa avanzare le ripetizioni, il pulsante "Fatto" come riserva, il blocco dello schermo in acqua, le vibrazioni, la batteria.
- **WatchConnectivity**: invio dell'allenamento (`updateApplicationContext`) e ritorno della nuotata (`transferUserInfo`); il simulatore accoppiato non è affidabile.
- **Tema scuro**: i colori scuri in `Assets.xcassets` sono una proposta mia (docs/GRAFICA.md non li definisce) e il contrasto va verificato.
- **Localizzazione**: formati con `%ld` e `%@` letti con `NSLocalizedString`.

## Da fare

- Icona dell'app (iPhone e Watch): le due `AppIcon` sono vuote.
- Richieste di permesso spiegate dal coach nel momento giusto: Apple Salute e notifiche (solo Regolare/Spronami). Oggi l'autorizzazione di HealthKit si chiede sul Watch al primo "Inizia".
- Lettura delle nuotate da Apple Salute sull'iPhone (oggi lo Storico mostra solo le nuotate consegnate dal Watch).
- Servizio coach (`server/coach`): oggi l'allenamento di oggi è sempre una riserva fissa, scelta per giorno, livello, obiettivo e vasca.
- Domanda "Hai almeno 18 anni?" (docs/ONBOARDING.md, punto da verificare) e informazioni legali: il testo di *Profilo > Informazioni* è un segnaposto; `docs/legale/` non esiste ancora.
- Mapping livello -> tappa di partenza (`Livello.tappaDiPartenza`) e soglia di ripartenza (14 giorni, `StatoApp.giorniPerRipartenza`): valori provvisori, da confermare con l'istruttore.
- Percorso: segnare le tappe come completate in base ai test (oggi "completata" = tappa prima di quella attuale, che l'utente sposta a mano).
- Notifiche, promemoria e sfide per "Spronami"; riorganizzazione della settimana per "Regolare".
- Dopo l'allenamento: domanda facile / giusta / dura, popup "dopo allenamento duro" e "dolore" (le immagini ci sono, la logica no), riepilogo scritto.
- Watch: pausa, ripresa di una sessione interrotta, avatar piccolo con frase breve a fine allenamento, Digital Crown o Action Button per avanzare.
- Abbonamento (StoreKit 2), video dei drill, inglese e spagnolo, test automatici dell'app (oggi solo il pacchetto ha test), verifica di contrasto e VoiceOver.
