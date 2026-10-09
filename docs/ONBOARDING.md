# Primo avvio: la lavagnetta del coach

Subito dopo la scelta del coach, il coach compila con l'utente una **lavagnetta** (come quelle dei coach a bordo vasca) con il suo profilo. Una domanda alla volta, una riga che si riempie a ogni risposta, e alla fine la lavagnetta è la scheda dell'utente. Ogni risposta è modificabile dal Profilo.

Regole:
- **Poche domande, un tocco ciascuna.** Solo ciò che cambia davvero l'allenamento o il tono. Il resto si impara dall'uso.
- **Quasi tutto è saltabile**, con un valore di partenza prudente. Obbligatori solo i campi segnati "sì" nella tabella: nome, livello, vasca e ritmo (la frequenza solo se il ritmo è Regolare o Spronami). Tutte le altre domande hanno il pulsante "Salta" e partono con un valore prudente.
- **Domande sul fare, non sull'etichetta.** Il livello si ricava da cosa riesce a nuotare, con le soglie delle regole dell'istruttore (`server/coach/prompts/regole-istruttore.md`), non da "sono principiante".
- **Risposte guidate.** Le domande con più opzioni (livello, obiettivo, vasca, ritmo, frequenza, durata, attrezzi, orario, fastidi) si risolvono con un **menu a tendina**, con un valore alla volta e l'opzione scelta evidenziata. L'unico campo di testo libero è il nome. Così i dati sono puliti e il coach li usa senza interpretarli.
- **Niente dati che non servono.** Niente sesso, peso o data di nascita nella prima versione.

## Le domande

| # | Dato | Domanda del coach | Risposte | Obbligatorio | Cosa cambia |
|---|---|---|---|---|---|
| 1 | Nome | "Come ti chiamo?" | testo libero, anche solo il nome | sì | Saluti e messaggi: "Buongiorno, Luca", "Buonasera, Paola" |
| 2 | Livello | "Quanto riesci a nuotare di fila a stile libero?" | Non ancora 25 m · Meno di 100 m · 100 m senza fermarmi · Di più | sì | Livello (principiante / intermedio) e tappa di partenza del percorso |
| 3 | Obiettivo | "Cosa vuoi dal nuoto?" | Imparare e migliorare la tecnica · Resistere di più · Dimagrire · Stare bene | no (default: tecnica) | Tipo di allenamento |
| 4 | Vasca | "In che vasca nuoti?" | 25 m · 50 m · Non lo so ancora | sì (default: 25 m) | Distanze degli allenamenti |
| 5 | Ritmo | "Come vuoi che ti segua?" | Libero · Regolare · Spronami | sì (default: Libero) | Obiettivo settimanale e notifiche (vedi `docs/EXPERIENCE.md`) |
| 6 | Frequenza | "Quante volte a settimana vorresti nuotare?" | 1 · 2 · 3 · 4 · 5 | solo se Regolare o Spronami | Obiettivo settimanale |
| 7 | Durata | "Quanto tempo hai di solito in acqua?" | 20 · 30 · 45 · 60 min | no (default: 30) | Durata degli allenamenti |
| 8 | Attrezzi | "Cosa trovi in piscina?" | Tavoletta · Pull buoy · Tavoletta e pull buoy · Nessuno | no (default: nessuno) | Esercizi proposti (alcuni drill richiedono la tavoletta o il pull buoy) |
| 9 | Orario | "Quando preferisci nuotare?" | Mattina · Pausa pranzo · Sera · Dipende | no | Momento dei messaggi del coach, se ha scelto Regolare o Spronami |
| 10 | Fastidi | "C'è qualcosa di cui devo tenere conto?" | Nessuno · Spalla · Schiena · Altro (scelta tra voci prestabilite, nessun testo libero) | no | Evita esercizi mirati su quella zona; consiglia di sentire un medico |

## Prima versione: solo l'essenziale
All'avvio si chiedono solo **nome, livello, vasca e ritmo** (più la frequenza, se il ritmo è Regolare o Spronami). L'obiettivo (domanda 3) resta come unica domanda facoltativa, perché sceglie il tipo di allenamento; senza risposta vale "tecnica".

Le altre domande non si fanno all'avvio:
- **Durata, attrezzi, orario**: si impostano dal Profilo, e il coach le chiede nel momento in cui servono (per esempio gli attrezzi quando un esercizio ne richiede uno).
- **Fastidi fisici**: non si chiedono all'avvio. Il coach ne parla solo se l'utente segnala dolore, con il flusso già previsto (riposo e consiglio di sentire un medico). Così evitiamo di raccogliere dati sulla salute in anticipo.

Con questa scelta la lavagnetta ha 5 domande al massimo, non 7.

Dopo le domande, due richieste di permesso **spiegate dal coach nel momento giusto**, non all'avvio dell'app:
- **Apple Salute** (HealthKit), per salvare gli allenamenti.
- **Notifiche**, solo se ha scelto Regolare o Spronami.

## Il nome
- Si usa nei saluti e nei messaggi del coach: "Buongiorno, Luca", "Buonasera, Paola". Il saluto cambia con l'ora: mattina, pomeriggio, sera.
- Il testo del coach resta **neutro rispetto al genere** (frasi come "sei pronto/pronta" si evitano o si riformulano), perché non chiediamo il sesso.
- Il nome si salva sul dispositivo e si può cambiare dal Profilo. Si usa un nome o un soprannome: non serve il cognome.

## Da verificare
1. **Fastidi fisici = dato sulla salute**: per il GDPR è una categoria particolare. Va chiesto con consenso esplicito e in forma facoltativa, oppure tolto dalla prima versione. Proposta: tenerlo, facoltativo, salvato solo sul dispositivo.
2. **Minori**: chiedere solo "Hai almeno 18 anni?" prima di cominciare, o decidere che l'app è per adulti nella prima versione.
3. **Soglie del livello** (domanda 2): confermate dall'istruttore in `content/REVISIONE.md`.
4. **Obiettivo "Dimagrire"**: formulazione e tono da rivedere, per non spingere verso pratiche poco sane.
5. **Come arrivano i dati al coach IA**: del nome serve solo il tono; non passa al servizio altro che il necessario (vedi `docs/ARCHITECTURE.md`).
