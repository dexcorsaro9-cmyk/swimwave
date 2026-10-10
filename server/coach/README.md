# Servizio coach di Swimwave

Piccolo server Node (nessuna dipendenza oltre `ajv`) che genera l'allenamento del giorno e, a richiesta, un breve commento del coach sul mese. Se il modello non risponde o la risposta non è valida, per l'allenamento restituisce un allenamento fisso di riserva e per il commento restituisce `{ "testo": null }` (l'app usa allora una frase fissa).

## Avvio

```
cd server/coach
npm install
npm test
ANTHROPIC_API_KEY=... SWIMWAVE_AMBIENTE=produzione PORT=8787 npm start
```

- `ANTHROPIC_API_KEY`: chiave del fornitore del modello. Va solo nell'ambiente del server, mai nell'app né nel repository. Senza chiave il server risponde sempre con la riserva.
- `SWIMWAVE_AMBIENTE`: con `sviluppo` ammette anche i drill in bozza; con qualsiasi altro valore (o se manca) solo i drill approvati.
- `PORT`: porta di ascolto (predefinita 8787).
- `SWIMWAVE_MODEL`: facoltativa, nome del modello.

Endpoint:

- `POST /allenamento` risponde `{ "workout": {...}, "fonte": "coach" | "riserva" }`.
- `POST /commento` risponde `{ "testo": "..." }` oppure `{ "testo": null }` (vedi sotto).
- `GET /salute` risponde `{ "ok": true }`.

Il server parla HTTP semplice: va messo dietro un servizio che offre HTTPS. Il corpo di ogni richiesta può essere al massimo di 16 KB; oltre, o se il JSON è rotto, risponde 400.

## Collegare l'app

Dopo il deploy, scrivi l'URL https (senza `/allenamento` finale) in `app/project.yml`, nella chiave `SwimwaveCoachURL` del target Swimwave, poi rigenera il progetto con XcodeGen. Se la chiave è vuota o non è un URL https valido, l'app usa gli allenamenti fissi. L'app contatta il servizio solo se l'utente ha dato il consenso all'IA.

## Cosa viene inviato a `/allenamento`

Solo questi campi, e solo con questi valori (il resto viene scartato):

- `livello`: principiante, intermedio, avanzato
- `obiettivo`: tecnica, resistenza, dimagrimento. L'app invia quello scelto dall'utente per quell'allenamento, se lo ha scelto, altrimenti quello del profilo
- `durata_min`: 20, 30, 45 o 60 (durata scelta dall'utente per quell'allenamento; facoltativa). Il coach avvicina `durata_stimata_min` e i metri a questa durata, restando dentro i tetti del livello. La riserva fissa non la tiene in conto
- `tappa`: numero da 1 a 50 (l'app per ora non lo invia)
- `vasca_metri`: intero da 10 a 100 (16, 20, 25, 33 e 50 sono le misure del menu; il Profilo permette anche un'altra misura). Il server arrotonda ogni distanza al multiplo della vasca più vicino
- `ritmo`: libero, regolare, spronami
- `coach`: uomo o donna
- `riepilogo`: soltanto `ultimo allenamento: facile`, `giusta` o `dura` (il motivo di "dura" resta sul telefono e non viene inviato)

## Commento del coach sul mese: `POST /commento`

Corpo (JSON), solo questi campi:

- `nuotate`, `metri`, `minuti`, `metri_mese_precedente`, `settimane_di_fila`, `facili`, `giuste`, `dure`: tutti obbligatori, interi da 0 a 100000
- `coach`: `uomo` o `donna` (facoltativo; se manca il tono è neutro)

Qualsiasi altro campo viene scartato (non arriva al modello). Un campo mancante, non intero, fuori range o un `coach` diverso da `uomo` e `donna` fanno rispondere 400 e il modello non viene chiamato.

Con `ANTHROPIC_API_KEY` il server chiama l'API Messages (stessa chiave e stesso modello dell'allenamento) con le istruzioni di `prompts/commento-mese.md` più il tono del coach scelto. Il commento ha al massimo due frasi, usa solo i numeri ricevuti, non dà consigli, non colpevolizza. L'uscita viene ripulita: una riga, massimo 300 caratteri, niente markdown. Se è vuota, più lunga di 300 caratteri, ha link o indirizzi, la parola inglese che indica lo stile libero, più di due frasi o un numero diverso da quelli ricevuti, oppure se il modello va in errore o supera 8 secondi, la risposta è `{ "testo": null }`. Senza chiave la risposta è sempre `{ "testo": null }`. In codice: `creaServer({ model, modelloCommento })`, dove `modelloCommento` si crea con `creaModelloCommento({ apiKey })` (src/commento.js).

## Cosa non viene inviato

Il nome, l'email, identificativi, dati grezzi di Apple Salute (calorie, frequenza cardiaca, bracciate, tempi delle vasche, percorso), dolore o malessere, note scritte dall'utente. Per il commento del mese partono solo i conteggi elencati sopra, non le singole nuotate. Il server non scrive nei log il contenuto delle richieste né delle risposte. Il fornitore del modello riceve gli stessi campi (vedi `docs/legale/informativa-privacy.md`).
