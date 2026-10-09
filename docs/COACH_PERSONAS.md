# I due coach

All'avvio l'utente sceglie tra due coach virtuali: un uomo e una donna. Sono personaggi creati con un generatore di immagini e applicano il metodo dell'istruttore. La scelta è modificabile dal Profilo.

Principi:
- **Stessa competenza, stesso contenuto, stesso tono.** Cambiano nome, presentazione e immagine. Nessuno stereotipo: l'uomo non è "quello deciso" e la donna "quella dolce".
- **Persone inventate.** Niente somiglianza con persone reali, né con l'istruttore né con celebrità. I prompt non citano nomi di persone.
- **Trasparenza.** L'app dice chiaramente che sono coach virtuali e che il metodo è dell'istruttore. Per le regole europee sulla trasparenza dell'IA (AI Act) e per le linee guida degli store, da verificare prima del rilascio.

## Scheda dei personaggi

| | Coach uomo | Coach donna |
|---|---|---|
| Nome | Antonio | Pamela |
| Età apparente | 35-45 anni | 35-45 anni |
| Aspetto | Italiano, capelli corti castani, barba corta curata, occhi caldi | Italiana, capelli castani raccolti, occhi caldi |
| Abbigliamento | Maglia tecnica da piscina blu scuro, senza loghi | Maglia tecnica da piscina blu scuro, senza loghi |
| Impressione | Persona che ti ascolta, paziente, sicura | Persona che ti ascolta, paziente, sicura |

Il nome e l'aspetto sono modificabili. L'importante è che i due personaggi abbiano la stessa età apparente, lo stesso stile e lo stesso livello di cura, perché nessuno dei due sembri la scelta principale.

## Cosa rende un volto empatico

Le indicazioni dei prompt si basano su questi elementi:
- **Sorriso naturale** che coinvolge gli occhi, non posato.
- **Sguardo diretto**, morbido, leggermente rivolto verso l'osservatore.
- **Testa appena inclinata** e spalle rilassate: ascolto, non posa.
- **Luce calda e morbida**, senza ombre dure.
- **Pelle naturale**, con imperfezioni leggere, per evitare l'effetto artificiale.
- **Sfondo sfocato di una piscina**, con colori morbidi, senza distrazioni.
- **Nessun gesto teatrale.** Un coach credibile, non uno spot.

## Prompt principale

Da usare in qualunque generatore di immagini. Si scrive in inglese perché i generatori lo capiscono meglio.

**Coach uomo**

```
Photorealistic portrait of a friendly Italian male swim coach, about 40 years old, short brown hair, neatly trimmed short beard, warm brown eyes, natural genuine smile that reaches the eyes, head slightly tilted, relaxed shoulders, soft direct gaze toward the viewer. He wears a plain dark blue technical pool shirt with no logos. Blurred bright indoor swimming pool in the background with soft turquoise tones. Warm soft natural light, shallow depth of field, natural skin texture with subtle imperfections, calm and trustworthy presence, empathetic and attentive expression. Upper body framing, centered, 1:1 square, high detail.
```

**Coach donna**

```
Photorealistic portrait of a friendly Italian female swim coach, about 40 years old, brown hair tied back in a loose low ponytail, warm brown eyes, natural genuine smile that reaches the eyes, head slightly tilted, relaxed shoulders, soft direct gaze toward the viewer. She wears a plain dark blue technical pool shirt with no logos. Blurred bright indoor swimming pool in the background with soft turquoise tones. Warm soft natural light, shallow depth of field, natural skin texture with subtle imperfections, calm and trustworthy presence, empathetic and attentive expression. Upper body framing, centered, 1:1 square, high detail.
```

**Prompt negativo** (se il generatore lo supporta)

```
cartoon, 3d render, plastic skin, over-retouched, airbrushed, harsh shadows, stiff pose, forced grin, teeth too perfect, exaggerated expression, text, watermark, logo, extra fingers, deformed hands, celebrity likeness, uncanny valley, dark mood
```

## Variazioni di espressione

Le stesse persone, con espressioni diverse, servono nei momenti dell'app. Si ottengono dal prompt principale cambiando solo la riga dell'espressione.

| Momento | Espressione da aggiungere |
|---|---|
| Benvenuto e scelta | `warm welcoming smile, open and inviting, slight head tilt` |
| Incoraggiamento in allenamento | `confident encouraging smile, supportive look, slight nod` |
| Traguardo raggiunto | `proud joyful smile, bright eyes, one thumb up, genuine celebration` |
| Dopo un allenamento duro | `gentle understanding look, soft reassuring smile, calm eyes` |
| Ripartenza dopo una pausa | `friendly relaxed smile, welcoming, no judgement` |
| Se l'utente segnala dolore | `attentive caring expression, calm and serious but kind, no smile` |

## Come mantenere lo stesso volto

I generatori tendono a cambiare la persona a ogni immagine. Per averla coerente:
1. Genera diverse varianti del prompt principale e scegli la migliore.
2. Usala come **immagine di riferimento** (character reference) nelle generazioni successive, se lo strumento lo permette, oppure mantieni lo stesso seed.
3. Cambia solo la riga dell'espressione.
4. Controlla ogni immagine accanto alla scelta: stessa persona, stesso abbigliamento.

## Formati

- Ritratto quadrato 1:1, almeno 1024 × 1024 px, per scelta e riepiloghi.
- Versione ritagliata sul volto per l'avatar piccolo (Watch e notifiche).
- Se serve, versione con sfondo trasparente (PNG).
- File in `assets/coach/` con nomi del tipo `antonio-benvenuto.png`.

## Verifica con le persone

Le immagini vanno scelte guardandole con persone vere, non solo noi:
1. Mostra 3-5 varianti per coach a 10-15 persone del target.
2. Chiedi: "Quale ti ispira più fiducia? Quale ti fa sentire a tuo agio?"
3. Tieni la variante più scelta. Controlla anche che i due coach siano scelti in modo equilibrato.

## Punti aperti

1. I nomi sono decisi: Antonio e Pamela. Antonio coincide con il nome del fondatore: è una scelta voluta, ma l'immagine resta di un personaggio inventato e l'app deve dire in modo chiaro che è un coach virtuale, perché nessuno lo scambi per una persona reale.
2. L'abbigliamento: maglia da piscina o qualcosa di più informale?
3. La voce: serve una voce per ciascun coach? È un lavoro successivo e ha implicazioni di costo e di trasparenza.
