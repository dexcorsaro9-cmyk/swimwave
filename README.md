# Swimwave

Il tuo istruttore di nuoto in tasca. / Your swim coach in your pocket.

App per chi nuota da solo e non ha nessuno che lo segua: coach IA che crea allenamenti su misura, consigli tecnici scritti da un istruttore vero, allenamento guidato su Apple Watch e lettura delle nuotate da Apple Health.

## Stato

- Nome scelto: **Swimwave** (provvisorio fino alle verifiche, vedi sotto)
- Fase: progettazione, con le prime basi tecniche (schema, servizio coach, modello condiviso)
- Piattaforma della prima versione: iPhone + Apple Watch (SwiftUI, HealthKit, WatchKit)
- Distribuzione di prova: TestFlight (già disponibile)

## Codice

- `docs/schema/workout.schema.json`: schema del formato dell'allenamento (il contratto)
- `server/coach/`: servizio coach (Node). Genera l'allenamento, lo controlla con lo schema e usa una riserva fissa se qualcosa non va. Test: `cd server/coach && npm install && npm test` (verificati, 8 su 8)
- `Packages/SwimwaveCore/`: pacchetto Swift condiviso da iPhone e Watch (modello e validazione). **Non ancora compilato né testato**: scritto senza Swift a disposizione, da provare in Xcode con `swift test`
- `content/drills.json` e `fixtures/`: segnaposto da compilare con l'istruttore

## Da verificare sul nome

Le ricerche web non trovano app di nuoto con il nome "Swimwave", ma non sostituiscono i controlli ufficiali:

- [ ] Ricerca "Swimwave" su App Store e Google Play
- [ ] Domini swimwave.com e swimwave.app
- [ ] Marchio su EUIPO TMview (Europa) e USPTO (USA), classi software e sport

Nomi già scartati e perché: Swimly (esiste un'app di allenamenti con lo stesso nome), Swimmo (smartwatch per nuotatori), Swim2Go (troppo vicino a GoSwim, SwimGo, Swim Workouts To Go), Swim4All (slogan usato da iniziative pubbliche), Swimflow (esiste già un'app di nuoto), AquaCoach e Aquamate (filone "aqua" molto affollato, Aquach è quasi omofono).

## Documenti

- [docs/PRODUCT.md](docs/PRODUCT.md): visione, target, funzioni della prima versione, prezzo
- [docs/EXPERIENCE.md](docs/EXPERIENCE.md): esperienza dell'utente, ritmo scelto da lui, percorso a tappe
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): parti del sistema, coach IA, dati, decisioni
- [docs/ROADMAP.md](docs/ROADMAP.md): ordine di sviluppo
- [docs/WORKOUT_FORMAT.md](docs/WORKOUT_FORMAT.md): formato dell'allenamento condiviso tra coach IA, iPhone e Watch
- [docs/COMPETITORS.md](docs/COMPETITORS.md): cosa esiste già e dove c'è spazio
- [CLAUDE.md](CLAUDE.md): contesto per lavorare sul progetto con Claude Code
