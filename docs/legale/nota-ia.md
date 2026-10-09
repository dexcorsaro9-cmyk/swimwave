> **BOZZA, da far rivedere a un avvocato prima della pubblicazione.**
> Chi l'ha scritta non è un avvocato. Le parti tra parentesi quadre sono segnaposto o decisioni aperte.

# Nota sull'intelligenza artificiale

Tre testi, uno per ogni punto dell'app dove va mostrata l'informazione. Frasi brevi, adatte alla traduzione (le stringhe vanno nei file di localizzazione).

## Cosa deve restare vero (da controllare con lo sviluppo e l'istruttore)

- Le immagini di Antonio e Pamela sono generate con l'IA. I due sono personaggi inventati, non persone reali.
- L'allenamento è generato da un sistema di IA tramite un servizio nostro, entro regole scritte da un istruttore e con una lista chiusa di esercizi. Se qualcosa non va, l'app usa un allenamento fisso di riserva.
- I messaggi e i riepiloghi del coach [sono generati dall'IA / sono testi preparati: DA CONFERMARE]. Se sono generati, il testo del punto 2 resta com'è; se sono testi fissi, correggere la frase.
- Il metodo e i contenuti tecnici si basano su fonti autorevoli e sono controllati da un istruttore di nuoto. **Non scrivere "scritti dall'istruttore"** se i testi sono preparati con strumenti di IA e poi controllati da lui (CLAUDE.md dice questo; PRODUCT.md dice altro: vedi CHECKLIST, punto F2).

> NOTA PER L'AVVOCATO: la scelta di non ripetere l'etichetta "coach virtuale" in ogni schermata (POPUP_COACH.md) va valutata rispetto all'articolo 50 dell'AI Act e alle regole sulle pratiche commerciali scorrette. Vedi CHECKLIST, punti B1-B3. Una soluzione prudente e leggera, se il parere è negativo, è un'etichetta discreta ("Coach virtuale") sull'avatar nelle sole schermate in cui l'utente "parla" con il coach.

---

## 1. Testo breve: schermata di scelta del coach (una riga)

**Versione consigliata** (sotto le due schede):

> Antonio e Pamela sono coach virtuali creati con l'IA, non persone reali. Il metodo è di un istruttore di nuoto.

Alternativa più corta:

> Coach virtuali creati con l'IA. Il metodo è di un istruttore vero.

Collegamento accanto alla riga: **"Come funziona"**, che apre il testo esteso (punto 2).

> NOTA: "istruttore vero" va bene solo se in app si capisce che l'istruttore ha controllato i contenuti e non fa il coach in tempo reale. Preferire "Il metodo è controllato da un istruttore di nuoto".

---

## 2. Testo esteso: Profilo > Informazioni > "Intelligenza artificiale e coach virtuali"

**I coach sono virtuali**
Antonio e Pamela sono personaggi virtuali. Le loro immagini sono state create con un programma di intelligenza artificiale e non ritraggono persone reali. Il nome "Antonio" è un nome di fantasia, anche se coincide con quello del fondatore. [DECISIONE: tenere o togliere questa frase.] Non sono istruttori in carne e ossa e non ti vedono in acqua.

**Chi prepara il tuo allenamento**
Quando chiedi l'allenamento del giorno, il nostro servizio usa un sistema di intelligenza artificiale di un fornitore esterno ([FORNITORE DEL MODELLO IA]). Il sistema riceve soltanto ciò che serve: il tuo livello, l'obiettivo, la lunghezza della vasca, il ritmo scelto e un riepilogo degli ultimi allenamenti. Non riceve il tuo nome né i tuoi dati grezzi di Apple Salute. [DA CONFERMARE.]

**Le regole**
L'IA non inventa gli esercizi: sceglie da un elenco di esercizi fissi e segue regole scritte da un istruttore di nuoto. Ogni allenamento viene controllato dall'app prima di mostrartelo. Se qualcosa non va, o manca la connessione, ricevi un allenamento di riserva.

**I contenuti tecnici**
Consigli, esercizi e tappe del percorso si basano su fonti autorevoli (federazioni sportive, enti, testi accademici), sono riassunti con parole nostre e sono stati controllati da un istruttore di nuoto. [Preparati con l'aiuto di strumenti di IA: CONFERMARE se dichiararlo.]

**I limiti**
L'IA può sbagliare. Un allenamento può non essere adatto a te, anche se segue le regole. Non è una consulenza medica. Se un esercizio ti sembra troppo, salta; se senti dolore, fermati e senti un medico. Vedi l'Avvertenza sulla salute.

**Le tue scelte**
Puoi cambiare coach dal Profilo in qualsiasi momento, senza perdere lo storico. Dettagli su come usiamo i tuoi dati nell'Informativa sulla privacy.

**Domande o segnalazioni**
Scrivici a [EMAIL ASSISTENZA].

---

## 3. Testo per le Informazioni dell'App Store (scheda di prodotto)

Da aggiungere alla descrizione, in fondo, in italiano. Se la scheda è tradotta, tradurre.

> **Coach virtuali e intelligenza artificiale.** Swimwave usa l'intelligenza artificiale per creare gli allenamenti e per i messaggi dei coach. Antonio e Pamela sono personaggi virtuali, con immagini generate dall'IA, non persone reali. L'IA lavora con regole scritte da un istruttore di nuoto e una lista chiusa di esercizi; i contenuti tecnici si basano su fonti autorevoli e sono controllati da un istruttore. Può commettere errori. Swimwave non è un dispositivo medico e non sostituisce il parere del medico. Nuota sempre dove c'è un assistente bagnanti.

**Note per la revisione di Apple (campo "Note per la revisione")**, in inglese:

> The app is a swim-coaching app. Workouts are generated by a third-party AI model through our own server, restricted to a closed list of exercises and validated against a JSON schema, with a fixed fallback workout. The two coaches are fictional characters with AI-generated images; the app discloses this on the coach selection screen, in Profile > About, and in the privacy policy. The app does not diagnose or treat medical conditions and shows a health notice at first launch. Personal data sent to the AI provider is limited to level, goal, pool length, pace and workout summaries; the user's name is not sent. HealthKit data is used only to save and read swim workouts for the user and is not used for advertising or marketing. [CONFERMARE tutte le frasi con lo sviluppo.]

> NOTA: Apple chiede di descrivere i dati inviati a IA di terze parti e di avere il permesso esplicito dell'utente prima di condividerli (linea guida 5.1.2(i), letta il 2026-10-09). Serve quindi una schermata di consenso prima della prima richiesta al coach IA: vedi CHECKLIST, punto C3. Il testo qui sopra va aggiornato di conseguenza.
