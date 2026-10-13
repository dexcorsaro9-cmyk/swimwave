# Swimwave

Il tuo istruttore di nuoto in tasca. / Your swim coach in your pocket.

App per chi nuota da solo e non ha nessuno che lo segua: coach IA che crea allenamenti su misura, consigli tecnici scritti da un istruttore vero, allenamento guidato su Apple Watch e lettura delle nuotate da Apple Health.

## Stato

- Nome scelto: **Swimwave** (provvisorio fino alle verifiche, vedi sotto)
- Fase: progettazione avanzata. I contenuti tecnici sono **approvati dall'istruttore** (10 ottobre 2026), con note sulle fonti più deboli in `content/REVISIONE.md`; l'app è completa nel codice ma **non ancora compilata**
- Piattaforma della prima versione: iPhone + Apple Watch (SwiftUI, HealthKit, WatchKit)
- Distribuzione di prova: TestFlight (già disponibile)

## Codice

- `docs/schema/workout.schema.json`: schema del formato dell'allenamento (il contratto)
- `server/coach/`: servizio coach (Node). Genera l'allenamento con il modello, lo controlla con lo schema e usa una riserva fissa se qualcosa non va. Test: `cd server/coach && npm install && npm test` (31 test, verificati). Avvio: `npm start` (con `ANTHROPIC_API_KEY`; senza chiave risponde solo con la riserva)
- `codemagic.yaml`: build e test su Codemagic (nessun Xcode locale necessario) e pubblicazione su TestFlight
- `app/`: scheletro dell'app SwiftUI per iPhone e Watch, generato con XcodeGen. **Non compilato né testato**: vedi `app/README.md`
- `Packages/SwimwaveCore/`: pacchetto Swift condiviso (modello, validazione, profilo, saluti, contenuti). **Non ancora compilato né testato**: lo prova Codemagic (workflow `test`, `swift test`)
- `content/`: contenuti tecnici in bozza, con le fonti: drill, errori comuni, percorso a tappe, allenamenti di riserva, tono, coach. Da controllare con `content/REVISIONE.md`
- `assets/coach/`: immagini dei due coach (bozze) e avatar
- `fixtures/`: esempi per i test

## Da verificare sul nome

Le ricerche web non trovano app di nuoto con il nome "Swimwave", ma non sostituiscono i controlli ufficiali:

- [ ] Ricerca "Swimwave" su App Store e Google Play
- [ ] Domini swimwave.com e swimwave.app
- [ ] Marchio su EUIPO TMview (Europa) e USPTO (USA), classi software e sport

Nomi già scartati e perché: Swimly (esiste un'app di allenamenti con lo stesso nome), Swimmo (smartwatch per nuotatori), Swim2Go (troppo vicino a GoSwim, SwimGo, Swim Workouts To Go), Swim4All (slogan usato da iniziative pubbliche), Swimflow (esiste già un'app di nuoto), AquaCoach e Aquamate (filone "aqua" molto affollato, Aquach è quasi omofono).

## Documenti

- [docs/PRODUCT.md](docs/PRODUCT.md): visione, target, funzioni della prima versione, prezzo, decisioni
- [docs/EXPERIENCE.md](docs/EXPERIENCE.md): esperienza dell'utente, ritmo scelto da lui, percorso a tappe
- [docs/ONBOARDING.md](docs/ONBOARDING.md): primo avvio e lavagnetta del coach
- [docs/POPUP_COACH.md](docs/POPUP_COACH.md): il coach nei popup
- [docs/GRAFICA.md](docs/GRAFICA.md): direzione grafica
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): parti del sistema, coach IA, dati
- [docs/FONTI.md](docs/FONTI.md): da dove vengono i contenuti tecnici
- [docs/COACH_PERSONAS.md](docs/COACH_PERSONAS.md) e [docs/COACH_PROMPTS.md](docs/COACH_PROMPTS.md): i due coach e i prompt delle immagini
- [docs/legale/](docs/legale/): bozze di informativa, termini, nota IA, avvertenza salute e checklist (da far rivedere a un avvocato)
- [docs/ROADMAP.md](docs/ROADMAP.md): cosa è fatto e cosa viene dopo
- [docs/WORKOUT_FORMAT.md](docs/WORKOUT_FORMAT.md): formato dell'allenamento condiviso tra coach IA, iPhone e Watch
- [docs/COMPETITORS.md](docs/COMPETITORS.md): concorrenti
