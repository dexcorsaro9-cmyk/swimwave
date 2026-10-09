# Esperienza dell'utente

Swimwave è il "Duolingo del nuoto": un percorso su misura, in cui l'utente si sente seguito. L'utente decide quanto e quando nuotare. L'app osserva come nuota davvero, si adatta, e spinge solo se l'utente lo chiede.

## Principi

1. **Decide l'utente.** La frequenza non è imposta. L'app non assegna allenamenti giornalieri e non punisce le pause.
2. **L'app si adatta.** Propone in base a quanto, quando e come l'utente nuota davvero, non a un calendario fisso.
3. **Spronare è una scelta.** Promemoria, sfide e tono più energico si attivano solo se l'utente lo chiede, e si disattivano quando vuole.
4. **Seguito, non sorvegliato.** L'app mostra di ricordare ciò che l'utente ha detto e fatto, e usa solo dati che può misurare davvero.
5. **Sicurezza prima del risultato.** Mai spingere oltre il carico sensato, mai incoraggiare a nuotare con dolore.

## Come vuoi nuotare (ritmo scelto dall'utente)

Si sceglie nell'onboarding e si cambia in qualsiasi momento dal Profilo.

| Modalità | Cosa fa l'app |
|---|---|
| **Libero** | Nessun obiettivo e nessuna notifica di sollecito. Quando l'utente apre l'app trova la proposta adatta a oggi. |
| **Regolare** | L'utente imposta un obiettivo settimanale (da 1 a 5 nuotate). L'app lo ricorda con discrezione e riorganizza la settimana se salta un giorno. |
| **Spronami** | Come Regolare, più promemoria, piccole sfide e un tono più incalzante. Solo se l'utente lo attiva. |

## Cosa osserva l'app

- giorni e orari in cui nuota davvero
- frequenza reale rispetto a quella desiderata
- durata, distanza e passo delle nuotate (da Apple Health)
- come è andata, con un tocco dopo ogni nuotata: facile / giusta / dura
- allenamenti interrotti a metà
- tempo dall'ultima nuotata

## Come risponde

| Segnale | Risposta |
|---|---|
| Nuota più spesso del previsto | Lo riconosce, propone di alzare l'obiettivo se lo vuole, ricorda l'importanza del recupero |
| Nuota meno del previsto (Regolare o Spronami) | Messaggio gentile e proposta di un allenamento più corto per ripartire |
| Non nuota da tempo (modalità Libero) | Nessun messaggio. Alla riapertura propone una ripresa morbida |
| Sempre "dura" | Alleggerisce i volumi e le intensità |
| Sempre "facile" | Propone di salire di livello o di fare il test della tappa |
| Interrompe a metà più volte | Propone allenamenti più brevi e chiede cosa è successo |
| Segnala dolore o malessere | Consiglia di fermarsi e, se persiste, di sentire un professionista. Nessuna diagnosi |

## Il ciclo di ogni nuotata

1. **Prima.** L'app propone l'allenamento di oggi e spiega perché ("oggi lavoriamo sulla respirazione perché l'ultima volta l'hai trovata dura").
2. **Durante.** Il Watch guida serie per serie, con vibrazione e frasi brevi. Nessun tocco sullo schermo.
3. **Dopo.** Riepilogo scritto con la voce dell'istruttore: una cosa fatta bene e una sola da migliorare. Poi il tocco facile / giusta / dura che regola la volta successiva.
4. **Nel percorso.** Ogni nuotata fa avanzare l'utente nella tappa in cui si trova.

## Il percorso a tappe (bozza da confermare dall'istruttore)

Percorso per l'adulto che ha iniziato da poco. I nomi sono una proposta di struttura. Criteri, drill, errori tipici e test sono in `content/percorso.json`, in bozza e con le fonti (vedi docs/FONTI.md), da controllare con l'istruttore.

| # | Tappa | Test per completarla |
|---|---|---|
| 1 | Confidenza in acqua e galleggiamento | vedi content/percorso.json |
| 2 | Respirazione | vedi content/percorso.json |
| 3 | Posizione del corpo e scivolamento | vedi content/percorso.json |
| 4 | Battuta di gambe | vedi content/percorso.json |
| 5 | Bracciata a stile libero | vedi content/percorso.json |
| 6 | Coordinazione e respirazione laterale | vedi content/percorso.json |
| 7 | Nuotare in continuità (resistenza di base) | vedi content/percorso.json |
| 8 | Dorso | vedi content/percorso.json |
| 9 | Rana | vedi content/percorso.json |
| 10 | Delfino | vedi content/percorso.json |

Regole del percorso:
- Le tappe guidano ma non bloccano: l'utente può saltare avanti o tornare indietro.
- Gli obiettivi (resistenza, dimagrimento, tecnica) cambiano il contenuto degli allenamenti, non l'ordine delle tappe.
- Per ogni tappa: spiegazione breve, drill, errori tipici, test. Tutto scritto dall'istruttore.

## Motivazione senza pressione

- Traguardi per tappe completate e riepilogo settimanale.
- Nessuna serie giornaliera. Al suo posto, "settimane attive" con una pausa dichiarata dall'utente che non azzera nulla.
- Il tono è quello di un istruttore: caldo, concreto, mai colpevolizzante.

## Dati e privacy

I dati di salute di Apple Health restano il più possibile sul dispositivo. Al coach IA arrivano riassunti (frequenza, durata, giudizio facile / giusta / dura), non i dati grezzi. L'utente può vedere e cancellare ciò che l'app ha memorizzato. Da verificare con la normativa europea (GDPR) prima del rilascio.

## Punti aperti per l'istruttore

1. Conferma o modifica l'elenco e l'ordine delle tappe.
2. Test di completamento per ogni tappa.
3. I 10 errori più comuni dei principianti, collegati alle tappe.
4. Soglie per dire "troppo poco recupero" o "carico troppo alto", con valori tuoi.
5. Frasi tipo del coach per i momenti chiave (riepilogo, ripartenza dopo una pausa, traguardo).
