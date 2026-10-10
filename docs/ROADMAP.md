# Roadmap

## Fatto (bozze, da verificare)

- Formato dell'allenamento e schema (`docs/WORKOUT_FORMAT.md`, `docs/schema/`)
- Servizio coach con client del modello, validazione e riserva (`server/coach/`, test verdi)
- Contenuti tecnici in bozza con fonti: drill, errori, percorso a 10 tappe, 15 allenamenti di riserva (`content/`)
- Due coach con immagini, espressioni e avatar (`assets/coach/`)
- Specifiche: esperienza, primo avvio, popup, grafica (`docs/`)
- Mockup dell'interfaccia (canvas dei mockup)
- App SwiftUI iPhone + Watch e pacchetto condiviso (`app/`, `Packages/`), **scritta per intero ma mai compilata**: 18+, consenso IA, permessi, allenamento guidato su iPhone e Watch (pausa/ripresa, nuoto libero, acque libere), domanda facile/giusta/dura, storico con dettaglio, calendario e confronto, andamento, riepiloghi, record e migliori tempi, traguardi, il tuo anno, obiettivo mensile, serie di settimane, test del ritmo con zone, libreria di allenamenti, richiesta al coach, Spronami, tema scuro, icona (bracciata-onda), scorciatoia Siri, complicazione del Watch, interfaccia in italiano, inglese e spagnolo (i contenuti tecnici restano in italiano)
- Bozze legali e checklist di conformità (`docs/legale/`)

## Prossimi passi (versione 1: iPhone + Apple Watch)

1. **Revisione dei contenuti** da parte dell'istruttore e passaggio ad `approvato` (senza contenuti approvati l'app in Release non mostra allenamenti).
2. **Compilare e provare l'app** con Codemagic (`codemagic.yaml`, vedi `app/README.md`): prima il workflow `test`, poi `ios-testflight`; correggere gli errori di compilazione.
3. **Collegare l'app al servizio coach**: hosting, chiave del modello, schermata di consenso prima della prima richiesta all'IA.
4. ~~Completare l'app~~ fatto nel codice (vedi sopra); resta da provarlo: tutto è nella versione 1, non c'è una seconda versione per queste funzioni.
5. **Watch in acqua**: prova con l'orologio fisico per 2-3 settimane via TestFlight, annotando cosa non funziona.
6. **Parere legale** su AI Act, privacy, regole di Apple; poi pubblicare informativa e termini.
7. **Abbonamento** con StoreKit 2, dopo il foglio ricavi/costi.
8. **Prova con 10-15 persone** della piscina; verifica delle immagini dei coach.

Note tecniche:
- Il simulatore non basta: per il nuoto serve l'orologio fisico.
- In acqua il touchscreen non è affidabile: pochi pulsanti e avanzamento automatico.
- Il rilevamento di vasche e stile dell'orologio ha limiti: da misurare allenandosi.

## Versione 2

- Analisi video con IA (dopo la prova su video reali)
- Android con Health Connect
- Contenuti tecnici e testi legali in inglese e spagnolo (l'interfaccia c'è già)
- Voce dei coach (costi e trasparenza da valutare)

## Più avanti

Wear OS e Garmin, solo se richiesti dagli utenti. Strava, acque libere, dryland, community.

## Tolto dalla versione 1

Esercizi a secco (decisione dell'istruttore, ottobre 2026): file, schermata e fonti rimossi; si può riprendere in seguito dalla cronologia di git.

## Cose da non fare

Copiare altre app: contenuti, nomi dei piani e grafica sono loro. Si riproducono idee e funzioni, non materiali. Inventare contenuti tecnici: ogni contenuto ha una fonte o dichiara di non averla.
