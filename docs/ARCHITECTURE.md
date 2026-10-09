# Architettura

Bozza di partenza, da rivedere. Le scelte sono motivate perché si possano contestare. Vedi anche EXPERIENCE.md (cosa vive l'utente) e WORKOUT_FORMAT.md (il contratto dell'allenamento).

## Decisioni prese

| Questione | Scelta | Perché |
|---|---|---|
| Coach IA nella v1 | Sì, ma dentro regole rigide, con allenamenti fissi di riserva | È il cuore dell'idea "su misura". Le regole e la lista chiusa dei drill evitano consigli tecnici inventati |
| Dove gira il coach | Piccolo servizio server che fa da intermediario | La chiave API non può stare nell'app. Si può cambiare modello senza rilasciare l'app |
| Account | Nessuno nella v1, identificativo anonimo del dispositivo | Meno attrito, meno dati personali. Il Sign in with Apple si aggiunge con l'abbonamento multi-dispositivo |
| Dati sul dispositivo | SwiftData | Nativo, sufficiente per allenamenti, tappe, risposte dell'utente |
| iPhone ↔ Watch | WatchConnectivity | Standard per passare l'allenamento prima di entrare in acqua |
| Contenuti tecnici | File JSON nell'app, video su hosting esterno | Testi aggiornabili e video senza gonfiare l'app |
| Abbonamento | StoreKit 2, prezzo a gradini | Il prezzo che scende ogni mese potrebbe non essere supportato dagli store |

## Parti del sistema

```
iPhone app  <--WatchConnectivity-->  Watch app
    |                                    |
    |                                    +-- HKWorkoutSession (nuoto in piscina)
    |
    +-- HealthKit (lettura nuotate)
    +-- SwiftData (profilo, percorso, storico, risposte)
    +-- StoreKit 2 (abbonamento)
    |
    v
Servizio coach (server)  -->  modello IA
    - riceve: profilo + riassunto dello storico + tappa attuale
    - applica: regole dell'istruttore, lista chiusa dei drill
    - restituisce: allenamento nel formato di WORKOUT_FORMAT.md
```

### App iPhone (SwiftUI)
Cinque tab: Oggi, Piano, Tecnica, Progressi, Profilo. Onboarding con livello, obiettivo, vasca, e ritmo scelto (Libero, Regolare, Spronami).

### App Watch
Autonoma in acqua: riceve l'allenamento prima, lo percorre senza iPhone, salva la sessione su Apple Health. Avanzamento automatico, un solo pulsante grande, vibrazioni per il recupero. Solo l'orologio fisico dà risultati affidabili: il simulatore non basta.

### Pacchetto condiviso (SwimwaveCore)
Usato da iPhone e Watch. Contiene il modello dell'allenamento, la validazione, il modello del percorso e le stringhe. Così il contratto è scritto una volta sola.

### Servizio coach
Funzione leggera (serverless). Non conserva i dati dell'utente oltre la richiesta. Riceve riassunti, non dati grezzi di salute.

## Il coach: come si evitano gli errori

1. **Regole in ingresso.** Il testo di istruzioni contiene solo regole scritte dall'istruttore.
2. **Uscita vincolata.** Il modello deve rispondere in JSON secondo `docs/schema/workout.schema.json`.
3. **Controllo nel server.** Se il JSON non rispetta lo schema o usa un drill fuori lista, si riprova una volta, poi si scarta.
4. **Controllo nell'app.** Lo stesso schema viene verificato sul dispositivo prima di mostrare l'allenamento.
5. **Riserva.** Se tutto fallisce o manca la rete, l'app usa un allenamento fisso adatto a livello e tappa.

## Modelli di dati

- **Profilo**: livello, obiettivo, lunghezza vasca, ritmo scelto, obiettivo settimanale (se Regolare o Spronami).
- **Percorso**: tappe (id, nome, test), tappa attuale, tappe completate.
- **Allenamento**: come in WORKOUT_FORMAT.md, più stato (proposto, in corso, completato, interrotto).
- **Risposta dell'utente**: facile / giusta / dura, dolore sì/no, data.
- **Riassunto per il coach**: frequenza reale, durata media, ultime risposte, tempo dall'ultima nuotata.

## Dati sensibili

I dati di Apple Health restano sul dispositivo. Al server vanno solo i riassunti sopra. L'utente può vedere e cancellare tutto. Da verificare con le regole europee (GDPR) e le linee guida di Apple su HealthKit prima del rilascio.

## Rischi tecnici da misurare

- Rilevamento di vasche e stile dell'orologio: ha limiti, da misurare allenandosi.
- Il touchscreen in acqua non è affidabile.
- Costo del coach per utente contro il ricavo (vedi PRODUCT.md, foglio ricavi/costi).
- Compatibilità del prezzo a scalare con gli store.

## Ordine di lavoro suggerito

1. Schema del formato e modello condiviso (fatto: schema in `docs/schema`, modelli in `Packages/SwimwaveCore`)
2. Allenamenti fissi di riserva e regole del coach, con l'istruttore
3. Watch: percorrere un allenamento fisso in acqua, test personale
4. iPhone: scheda di Oggi, onboarding, ritmo scelto
5. Servizio coach e controllo dell'uscita
6. Percorso a tappe e riepiloghi
7. Abbonamento
