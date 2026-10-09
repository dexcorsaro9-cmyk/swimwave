# Servizio coach di Swimwave

Piccolo server Node (nessuna dipendenza oltre `ajv`) che genera l'allenamento del giorno. Se il modello non risponde o la risposta non è valida, restituisce un allenamento fisso di riserva.

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

Endpoint: `POST /allenamento` risponde `{ "workout": {...}, "fonte": "coach" | "riserva" }`; `GET /salute` risponde `{ "ok": true }`. Il server parla HTTP semplice: va messo dietro un servizio che offre HTTPS.

## Collegare l'app

Dopo il deploy, scrivi l'URL https (senza `/allenamento` finale) in `app/project.yml`, nella chiave `SwimwaveCoachURL` del target Swimwave, poi rigenera il progetto con XcodeGen. Se la chiave è vuota o non è un URL https valido, l'app usa gli allenamenti fissi. L'app contatta il servizio solo se l'utente ha dato il consenso all'IA.

## Cosa viene inviato

Solo questi campi, e solo con questi valori (il resto viene scartato):

- `livello`: principiante, intermedio, avanzato
- `obiettivo`: tecnica, resistenza, dimagrimento
- `tappa`: numero da 1 a 50 (l'app per ora non lo invia)
- `vasca_metri`: 25 o 50
- `ritmo`: libero, regolare, spronami
- `coach`: uomo o donna
- `riepilogo`: soltanto `ultimo allenamento: facile`, `giusta` o `dura`

## Cosa non viene inviato

Il nome, l'email, identificativi, dati grezzi di Apple Salute, dolore o malessere. Il server non scrive nei log il contenuto delle richieste. Il fornitore del modello riceve gli stessi campi (vedi `docs/legale/informativa-privacy.md`).
