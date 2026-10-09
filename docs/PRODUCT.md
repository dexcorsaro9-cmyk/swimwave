# Prodotto

## Visione

La migliore app di nuoto: il "Duolingo del nuoto". Dare a chi nuota da solo ciò che oggi ha solo chi può pagare un istruttore: un allenamento adatto a lui, correzioni tecniche chiare e qualcuno che lo segue.

Tre idee guidano ogni scelta:
1. **Su misura.** L'utente decide la frequenza e il modo in cui vuole essere seguito (ritmo Libero, Regolare o Spronami). L'app non impone allenamenti giornalieri: si adatta ai suoi tempi e propone, e spinge solo se l'utente lo chiede.
2. **Coccolato e monitorato.** Un coach scelto all'avvio (Antonio o Pamela) lo chiama per nome, commenta ogni allenamento, riparte con lui dopo una pausa e lo ferma se sente dolore.
3. **Contenuti affidabili.** Ogni esercizio, errore, tappa e allenamento nasce da fonti autorevoli (federazioni, enti, testi accademici), è registrato in `content/fonti.json`, riassunto con parole nostre e controllato da un istruttore prima di arrivare all'utente.

Posizionamento: "il tuo istruttore in tasca", in italiano e con un prezzo accessibile. Il fondatore è un istruttore di nuoto: supervisiona i contenuti, che scrive Claude; non li inserisce a mano.

## Target

Chi nuota senza un istruttore:
- adulti che hanno iniziato da poco
- chi nuota per tenersi in forma o dimagrire
- chi vuole migliorare la tecnica senza pagare lezioni private

Prima versione solo per adulti (da confermare con la verifica dei 18 anni). Non è il target iniziale: agonisti, triatleti, scuole nuoto, acque libere.

## Funzioni della prima versione

| Funzione | Note |
|---|---|
| Primo avvio con la lavagnetta del coach | Scelta del coach, poi al massimo 5 domande (nome, livello, obiettivo, vasca, ritmo) con menu a tendina. Vedi `docs/ONBOARDING.md` |
| Coach scelto nei popup | Avatar tondo con espressioni diverse nei momenti chiave. Nessuna mascotte. Vedi `docs/POPUP_COACH.md` |
| Allenamento del giorno | Generato dal coach IA nel formato di `docs/WORKOUT_FORMAT.md`, con riserva fissa |
| Percorso a 10 tappe | Dalla confidenza in acqua al delfino, con test semplici per ogni tappa |
| Obiettivo settimanale | Al posto della serie giornaliera: nessuna colpa se si salta un giorno |
| Domanda a fine nuotata | Facile, giusta o dura: l'allenamento seguente si adatta |
| Drill e consigli tecnici per i 4 stili | Lista chiusa, con fonti |
| Lettura nuotate da Apple Salute | Sostituisce il diario manuale |
| App Apple Watch | Autonoma in acqua: numeri grandi, serie, recupero con vibrazione, sessione di nuoto in vasca salvata su Apple Salute |
| Italiano | Stringhe pronte per la traduzione (inglese e spagnolo poi) |
| Abbonamento con prova gratuita | Vedi prezzo |

## Contenuti: chi fa cosa

- **Claude** scrive tutti i contenuti tecnici partendo da fonti autorevoli, li registra in `content/fonti.json` e li marca `bozza`. Dove non trova una fonte lo dichiara.
- **Il fondatore, istruttore** li rivede con `content/REVISIONE.md` e li fa passare ad `approvato`. Gli utenti vedono solo contenuti approvati.
- **I coach IA** non inventano esercizi: scelgono da una lista chiusa e le loro risposte sono validate (schema, distanze, regole) prima di arrivare all'utente.

## Funzione differenziante (da validare)

Analisi dei video di nuoto dell'utente con IA, con i consigli che darebbe un istruttore da bordo vasca. È la parte più rischiosa: va provata su 5-10 video reali prima di promettere qualcosa. Riprese in piscina, riflessi e angoli sono difficili. Resta fuori dalla versione 1.

## Fuori dalla prima versione

Analisi video, analisi dettagliata (SWOLF, split), Strava, acque libere, dryland, Android, Wear OS, Garmin, community, chat con lo staff, voce dei coach.

## Prezzo (ipotesi da validare)

Abbonamento mensile a scalare: 12,99 € il primo mese, in discesa fino a 1 € al dodicesimo, circa 1,09 € in meno ogni mese. Spesa totale in 12 mesi: circa 84 €, media circa 7 € al mese.

Punti aperti:
- Cosa succede dopo il dodicesimo mese?
- Gli store applicano di norma prezzi fissi per piano: un prezzo diverso ogni mese potrebbe non essere supportato. Alternativa: gradini (per esempio 12,99, 9,99, 6,99, 3,99).
- I costi (IA, video, server) restano costanti mentre i ricavi per utente scendono: serve un foglio ricavi/costi per utente su 12 mesi prima di fissare il prezzo.
- Gli store trattengono una commissione.
- Un concorrente piccolo (Swimly) costa 0,99 € al mese: il prezzo va giustificato con la tecnica e il coach.

## Decisioni prese (per non riaprirle)

- Livelli: principiante e intermedio (l'avanzato usa i contenuti intermedi), definiti da cosa riesce a nuotare di fila.
- Intensità a parole: facile, media, forte (mai "forte" per i principianti).
- Drill: lista chiusa.
- Coach: due personaggi virtuali, stessa competenza e stesso tono, nessuna etichetta "coach virtuale" nelle schermate; la nota sull'IA sta alla scelta del coach, nel Profilo e nel disclaimer (da far verificare: `docs/legale/CHECKLIST.md`).

## Punti aperti

1. Revisione dei contenuti da parte dell'istruttore (`content/REVISIONE.md`).
2. Obiettivo "Dimagrire": formulazione e tono.
3. Solo adulti: verifica dei 18 anni.
4. Parere legale su AI Act, privacy e regole dell'App Store.
5. Nome: controlli su store, domini e marchio (vedi README).

## Validazione

Prova con 10-15 persone della piscina dell'istruttore, con lista d'attesa a prezzo basso, prima di costruire tutto. Le immagini dei coach vanno mostrate a 10-15 persone del target. Il fondatore usa l'app in prima persona con l'Apple Watch per 2-3 settimane.
