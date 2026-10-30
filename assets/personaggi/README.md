# Personaggi acquatici di Swimwave

Oltre allo squalo (`assets/squalo/`) l'utente può scegliere altri personaggi, al primo avvio e poi dal Profilo.
Nessuno ha un nome: nell'app c'è solo la specie. Tutti sono animali che nuotano.

Stile: 3D da film d'animazione, simpatico e morbido, occhi grandi ed espressivi, nessuna scritta, nessun logo, nessun personaggio già esistente.
Immagini e video generati dall'IA: controllare i termini d'uso per l'uso commerciale prima della pubblicazione.

## I cinque personaggi proposti

Tutti si possono scegliere da chiunque: "per lui" e "per lei" indicano solo il carattere con cui sono stati pensati.

| # | Specie | Pensato per | Carattere | Colori |
|---|--------|-------------|-----------|--------|
| 1 | Delfino | lui | scattante, sempre di buon umore | grigio-azzurro, pancia chiara |
| 2 | Tartaruga marina | lui | calma, costante, non ha fretta | guscio verde oliva, pelle verde chiaro |
| 3 | Razza manta | lei | elegante, fluida, silenziosa | blu notte sopra, bianco sotto |
| 4 | Polpo | lei | curioso, ingegnoso, un po' buffo | viola corallo con ventose rosa |
| 5 | Pinguino | lei | tenace, veloce sott'acqua | nero e bianco, becco e zampe arancio |

## Stato

- **Delfino**, **tartaruga marina**, **razza manta** e **polpo:** fatti. Fogli in `assets/personaggi/<id>/`, già nell'app (iPhone e Watch).
- Pinguino: in attesa dei video.

## Come si producono (come per lo squalo)

1. **Immagine base con Gemini**: un prompt per specie, completo.
2. **Cinque video con Flow** partendo da quell'immagine: un prompt per posa, ciascuno completo (nessuna parte da aggiungere).
3. Mandarmi i video: `tools/crea_fogli_personaggio.py` li trasforma in fogli di fotogrammi (9 colonne, sfondo trasparente, ciclo chiuso)
   per iPhone e Watch; poi si registra il personaggio in `Personaggio.swift` (iPhone) e `Squalo.swift` (Watch) e compare nella scelta.

Fogli per ogni personaggio: `<id>-nuota-sheet`, `<id>-festa-sheet`, `<id>-stanco-sheet` (iPhone), più
`<id>-concentrato-sheet` e `<id>-attesa-sheet` (Watch). Per cominciare in piccolo bastano nuota, festa e stanco.

Ogni blocco qui sotto è un prompt completo: si copia così com'è.

---

## 1. Delfino (id `delfino`)

### Immagine base (Gemini)

```
Personaggio in stile 3D da film d'animazione, tenero e simpatico, occhi grandi e luminosi, forme morbide, materiali puliti. Un delfino giovane, grigio-azzurro con la pancia chiara, sorriso largo, espressione scattante e allegra. Vista laterale perfetta, rivolto verso destra, in posa neutra e rilassata. Sfondo verde chroma key uniforme (#00B140), nessuna ombra, nessun oggetto, nessuna scritta, nessun logo. Un solo personaggio, tutto il corpo visibile, nessun taglio.
```

### Video «Nuota» (Flow) — `delfino-nuota-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il delfino), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Nuota tranquillo sul posto con un'ondulazione morbida del corpo e della coda, pinne pettorali rilassate, ritmo regolare e rilassato.
```

### Video «Festa» (Flow) — `delfino-festa-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il delfino), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Esulta con un balzo allegro e un piccolo giro su se stesso, sorriso grande, poi ricade e torna alla posizione iniziale. Durata circa 3,5 secondi.
```

### Video «Concentrato» (Flow) — `delfino-concentrato-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il delfino), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Nuota con sguardo deciso e sopracciglia abbassate, con colpi di coda più energici e precisi e un ritmo più veloce. Durata circa 2,7 secondi.
```

### Video «Stanco» (Flow) — `delfino-stanco-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il delfino), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. È stanco: sbadiglia a bocca aperta, pinne e coda si abbassano, dondola piano su e giù con gli occhi socchiusi. Durata circa 3,7 secondi.
```

### Video «Attesa» (Flow) — `delfino-attesa-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il delfino), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Aspetta curioso: respira piano, si guarda attorno con un leggero movimento della testa e degli occhi, galleggia con un piccolo dondolio. Durata circa 5 secondi: il movimento va avanti e poi torna indietro in modo fluido.
```

---

## 2. Tartaruga marina (id `tartaruga`)

### Immagine base (Gemini)

```
Personaggio in stile 3D da film d'animazione, tenero e simpatico, occhi grandi e luminosi, forme morbide, materiali puliti. Una tartaruga marina adulta, guscio verde oliva con disegni morbidi, pelle verde chiaro, pinne grandi, sguardo calmo e sereno. Vista laterale perfetta, rivolto verso destra, in posa neutra e rilassata. Sfondo verde chroma key uniforme (#00B140), nessuna ombra, nessun oggetto, nessuna scritta, nessun logo. Un solo personaggio, tutto il corpo visibile, nessun taglio.
```

### Video «Nuota» (Flow) — `tartaruga-nuota-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (la tartaruga marina), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Nuota tranquilla sul posto con il battito lento e ampio delle pinne anteriori, la testa alta e rilassata, ritmo regolare e sereno.
```

### Video «Festa» (Flow) — `tartaruga-festa-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (la tartaruga marina), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Esulta con un piccolo balzo allegro e un giro lento su se stessa, sorriso grande e pinne aperte, poi torna alla posizione iniziale. Durata circa 3,5 secondi.
```

### Video «Concentrato» (Flow) — `tartaruga-concentrato-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (la tartaruga marina), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Nuota con sguardo deciso e sopracciglia abbassate, con battiti di pinne più energici e precisi e un ritmo più veloce del solito. Durata circa 2,7 secondi.
```

### Video «Stanco» (Flow) — `tartaruga-stanco-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (la tartaruga marina), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. È stanca: sbadiglia lentamente, la testa e le pinne si abbassano, dondola piano su e giù con gli occhi socchiusi. Durata circa 3,7 secondi.
```

### Video «Attesa» (Flow) — `tartaruga-attesa-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (la tartaruga marina), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Aspetta curiosa: respira piano, si guarda attorno con un leggero movimento della testa e degli occhi, galleggia con un piccolo dondolio. Durata circa 5 secondi: il movimento va avanti e poi torna indietro in modo fluido.
```

---

## 3. Razza manta (id `manta`)

### Immagine base (Gemini)

```
Personaggio in stile 3D da film d'animazione, tenero e simpatico, occhi grandi e luminosi, forme morbide, materiali puliti. Una razza manta elegante, dorso blu notte con piccole macchie chiare, ventre bianco, ali ampie e morbide, sguardo dolce. Vista laterale perfetta, rivolto verso destra, in posa neutra e rilassata. Sfondo verde chroma key uniforme (#00B140), nessuna ombra, nessun oggetto, nessuna scritta, nessun logo. Un solo personaggio, tutto il corpo visibile, nessun taglio.
```

### Video «Nuota» (Flow) — `manta-nuota-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (la razza manta), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Nuota tranquilla sul posto con ondulazioni lente e fluide delle ali, come se volasse nell'acqua, ritmo regolare e rilassato.
```

### Video «Festa» (Flow) — `manta-festa-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (la razza manta), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Esulta con un balzo allegro e un giro elegante con le ali spalancate, sorriso grande, poi torna alla posizione iniziale. Durata circa 3,5 secondi.
```

### Video «Concentrato» (Flow) — `manta-concentrato-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (la razza manta), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Nuota con sguardo deciso e sopracciglia abbassate, con battiti d'ala più energici e precisi e un ritmo più veloce. Durata circa 2,7 secondi.
```

### Video «Stanco» (Flow) — `manta-stanco-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (la razza manta), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. È stanca: sbadiglia, le ali si abbassano e si afflosciano, dondola piano su e giù con gli occhi socchiusi. Durata circa 3,7 secondi.
```

### Video «Attesa» (Flow) — `manta-attesa-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (la razza manta), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Aspetta curiosa: respira piano, si guarda attorno con un leggero movimento della testa e degli occhi, galleggia con un piccolo dondolio delle ali. Durata circa 5 secondi: il movimento va avanti e poi torna indietro in modo fluido.
```

---

## 4. Polpo (id `polpo`)

### Immagine base (Gemini)

```
Personaggio in stile 3D da film d'animazione, tenero e simpatico, occhi grandi e luminosi, forme morbide, materiali puliti. Un polpo viola corallo con ventose rosa, testa tonda, otto tentacoli ordinati e ondulati, sguardo curioso e un po' buffo. Vista laterale perfetta, rivolto verso destra, in posa neutra e rilassata. Sfondo verde chroma key uniforme (#00B140), nessuna ombra, nessun oggetto, nessuna scritta, nessun logo. Un solo personaggio, tutto il corpo visibile, nessun taglio.
```

### Video «Nuota» (Flow) — `polpo-nuota-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il polpo), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Nuota tranquillo sul posto con ondulazioni ritmiche e ordinate dei tentacoli e piccole spinte della testa, ritmo regolare e rilassato.
```

### Video «Festa» (Flow) — `polpo-festa-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il polpo), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Esulta con un balzo allegro, i tentacoli spalancati a ventaglio e un piccolo giro su se stesso, sorriso grande, poi torna alla posizione iniziale. Durata circa 3,5 secondi.
```

### Video «Concentrato» (Flow) — `polpo-concentrato-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il polpo), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Nuota con sguardo deciso e sopracciglia abbassate, con i tentacoli che battono più energici e precisi e un ritmo più veloce. Durata circa 2,7 secondi.
```

### Video «Stanco» (Flow) — `polpo-stanco-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il polpo), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. È stanco: sbadiglia, la testa e i tentacoli si afflosciano, dondola piano su e giù con gli occhi socchiusi. Durata circa 3,7 secondi.
```

### Video «Attesa» (Flow) — `polpo-attesa-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il polpo), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Aspetta curioso: respira piano, si guarda attorno con un leggero movimento della testa e degli occhi, i tentacoli ondeggiano appena, galleggia con un piccolo dondolio. Durata circa 5 secondi: il movimento va avanti e poi torna indietro in modo fluido.
```

---

## 5. Pinguino (id `pinguino`)

### Immagine base (Gemini)

```
Personaggio in stile 3D da film d'animazione, tenero e simpatico, occhi grandi e luminosi, forme morbide, materiali puliti. Un pinguino in immersione, nero e bianco, becco e zampe arancio, ali tese come pinne, espressione decisa e simpatica. Vista laterale perfetta, rivolto verso destra, in posa neutra e rilassata. Sfondo verde chroma key uniforme (#00B140), nessuna ombra, nessun oggetto, nessuna scritta, nessun logo. Un solo personaggio, tutto il corpo visibile, nessun taglio.
```

### Video «Nuota» (Flow) — `pinguino-nuota-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il pinguino), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Nuota tranquillo sul posto con colpi d'ala ampi e regolari come pinne e le zampe che seguono il corpo, ritmo regolare e rilassato.
```

### Video «Festa» (Flow) — `pinguino-festa-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il pinguino), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Esulta con un balzo allegro e un piccolo giro su se stesso, le ali aperte, sorriso grande, poi torna alla posizione iniziale. Durata circa 3,5 secondi.
```

### Video «Concentrato» (Flow) — `pinguino-concentrato-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il pinguino), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Nuota con sguardo deciso e sopracciglia abbassate, con colpi d'ala più energici e precisi e un ritmo più veloce. Durata circa 2,7 secondi.
```

### Video «Stanco» (Flow) — `pinguino-stanco-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il pinguino), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. È stanco: sbadiglia a becco aperto, le ali si abbassano, dondola piano su e giù con gli occhi socchiusi. Durata circa 3,7 secondi.
```

### Video «Attesa» (Flow) — `pinguino-attesa-sheet`

```
Dall'immagine allegata. Stesso identico personaggio (il pinguino), stesso stile 3D da film d'animazione, stessi colori e stesse proporzioni. Telecamera ferma, inquadratura laterale fissa, il personaggio resta al centro sul posto, rivolto verso destra. Sfondo verde chroma key uniforme (#00B140) invariato, nessuna ombra sul fondo, nessuna bolla né altri elementi: le bolle le aggiunge l'app. Movimento fluido e naturale, senza scatti. Il primo e l'ultimo fotogramma sono uguali, così il video si ripete senza stacchi. Nessuna scritta, nessun logo. Aspetta curioso: respira piano, si guarda attorno con un leggero movimento della testa e degli occhi, galleggia con un piccolo dondolio. Durata circa 5 secondi: il movimento va avanti e poi torna indietro in modo fluido.
```
