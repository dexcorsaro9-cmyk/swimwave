# Personaggi acquatici di Swimwave

Oltre allo squalo (`assets/squalo/`) l'utente può scegliere altri personaggi, al primo avvio e poi dal Profilo.
Nessuno ha un nome: nell'app c'è solo la specie. Tutti sono animali che nuotano.

Regole comuni (le stesse dello squalo):
- stile 3D da film d'animazione, simpatico e morbido, occhi grandi e espressivi, nessuna scritta, nessun logo, nessun personaggio già esistente;
- vista laterale, rivolto a destra, fermo sul posto (non attraversa lo schermo);
- sfondo verde uniforme (chroma key), senza ombre sul fondo;
- immagini generate dall'IA: controllare i termini d'uso per l'uso commerciale prima della pubblicazione.

## I cinque personaggi proposti

Tutti si possono scegliere da chiunque: "per lui" e "per lei" indicano solo il carattere con cui sono stati pensati.

| # | Specie | Pensato per | Carattere | Colori |
|---|--------|-------------|-----------|--------|
| 1 | Delfino | lui | scattante, sempre di buon umore | grigio-azzurro, pancia chiara |
| 2 | Tartaruga marina | lui | calma, costante, non ha fretta | guscio verde oliva, pelle verde chiaro |
| 3 | Razza manta | lei | elegante, fluida, silenziosa | blu notte sopra, bianco sotto |
| 4 | Polpo | lei | curioso, ingegnoso, un po' buffo | viola corallo con ventose rosa |
| 5 | Pinguino | lei | tenace, veloce sott'acqua | nero e bianco, becco e zampe arancio |

## Come si producono (come per lo squalo)

1. **Immagine base con Gemini**, un prompt per specie: vedi "Prompt immagine" qui sotto.
2. **Cinque video con Flow**, uno per posa, partendo dall'immagine base. Ogni prompt = parte comune + parte della posa.
3. Mandarmi i video: li trasformo in fogli di fotogrammi (9 colonne, sfondo trasparente, ciclo chiuso) per iPhone e Watch,
   li aggiungo al catalogo immagini e il personaggio compare da solo nella scelta.

Fogli per ogni personaggio: `<id>-nuota-sheet`, `<id>-festa-sheet`, `<id>-stanco-sheet` (iPhone), più
`<id>-concentrato-sheet` e `<id>-attesa-sheet` (Watch). Gli id sono: `delfino`, `tartaruga`, `manta`, `polpo`, `pinguino`.

## Prompt immagine (uno per specie)

Parte comune da incollare sempre:

> Personaggio in stile 3D da film d'animazione, tenero e simpatico, occhi grandi e luminosi, forme morbide, materiali puliti.
> Vista laterale perfetta, rivolto verso destra, in posa neutra e rilassata. Sfondo verde chroma key uniforme (#00B140),
> nessuna ombra, nessun oggetto, nessuna scritta, nessun logo. Un solo personaggio, tutto il corpo visibile, nessun taglio.

Poi una riga per specie:

1. **Delfino:** «Un delfino giovane, grigio-azzurro con la pancia chiara, sorriso largo, espressione scattante e allegra.»
2. **Tartaruga marina:** «Una tartaruga marina adulta, guscio verde oliva con disegni morbidi, pelle verde chiaro, pinne grandi, sguardo calmo e sereno.»
3. **Razza manta:** «Una razza manta elegante, dorso blu notte con piccole macchie chiare, ventre bianco, ali ampie e morbide, sguardo dolce.»
4. **Polpo:** «Un polpo viola corallo con ventose rosa, testa tonda, otto tentacoli ordinati e ondulati, sguardo curioso e un po' buffo.»
5. **Pinguino:** «Un pinguino in immersione, nero e bianco, becco e zampe arancio, ali tese come pinne, espressione decisa e simpatica.»

## Prompt video (Flow): parte comune

> Dall'immagine allegata. Stesso identico personaggio, stesso stile, stessi colori. Telecamera ferma, inquadratura laterale fissa,
> il personaggio resta al centro sul posto, rivolto a destra. Sfondo verde chroma key uniforme invariato, nessuna ombra sul fondo,
> nessuna bolla né altri elementi (le bolle le aggiunge l'app). Movimento fluido e naturale. Il primo e l'ultimo fotogramma sono
> uguali, così il video si ripete senza stacchi. Nessuna scritta.

Poi la parte della posa (durate: circa 3,5 secondi, tranne dove indicato):

- **nuota:** «Nuota tranquillo sul posto con il movimento tipico della specie (coda del delfino, pinne della tartaruga, ali della manta, tentacoli del polpo, ali-pinne del pinguino), ritmo regolare e rilassato.»
- **festa:** «Esulta: un balzo allegro con un piccolo giro e un sorriso grande, poi torna alla posizione iniziale. Circa 3,5 secondi.»
- **concentrato:** «Nuota con sguardo deciso e movimenti più energici e precisi, sopracciglia in giù, ritmo più veloce. Circa 2,7 secondi.»
- **stanco:** «Stanco: sbadiglia, le spalle e le pinne si abbassano, dondola piano su e giù, occhi socchiusi.»
- **attesa:** «Aspetta curioso: respira piano, si guarda attorno con un leggero movimento della testa e degli occhi, galleggia con un piccolo dondolio. Circa 5 secondi, il movimento va avanti e poi torna indietro in modo fluido.»
