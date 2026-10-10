# Revisione dell'istruttore

Tutti i contenuti rimasti sono stati approvati dall'istruttore il 10 ottobre 2026 (tolti: drill Delfino sei colpi, Dorso al rallentatore, esercizi a secco). Le note sotto restano come promemoria dei punti con fonte debole o numeri nostri, da riguardare con l'esperienza in acqua.

## 1. Da verificare per primi (senza fonte diretta o con fonte parziale)

- Drill **Respirazione laterale con tavoletta**: il principio è sostenuto dalle fonti, ma l'esecuzione come l'ho descritta no.
- Errore **Respiro trattenuto**: le fonti descrivono l'abilità, non l'errore.
- Errore **Gambe che pedalano**: la fonte parla di battuta dall'anca nel dorso. Per lo stile libero è un'estensione.
- Errore **Partenza troppo forte**: il criterio "ritmo che permette di parlare" è comune ma non l'ho trovato in una fonte.
- Errore **Collo e spalle rigidi**.
- Errore **Niente riscaldamento e recupero**.
- Nuovi drill (tappe 8-10), tutti da quadri Swim Wales scritti per nuotatori agonisti o per l'allenatore che osserva: controlla che siano adatti a un adulto alle prime armi. Il drill **Delfino: sei colpi, una bracciata** è stato tolto perché troppo avanzato (decisione dell'istruttore): l'errore **Piede che esce tutto dall'acqua nel delfino** ora non ha un drill collegato. Anche **Dorso al rallentatore** è stato tolto (la fonte lo pensa per chi osserva dal bordo, non per chi nuota da solo).
- Nuovi errori di dorso, rana e delfino: nelle fonti sono sostenuti il difetto e la correzione, mentre la spiegazione del "perché è un problema" è nostra. Per **Spalle verso la testa nel delfino** il drill della fonte non è nella nostra lista, quindi l'errore non ha un drill collegato.
- Fonte che manca: nessuna fonte di federazione (né Swim Wales né Swim England) descrive la rana o il delfino per adulti principianti. Per questo le tappe 9 e 10 restano le più fragili.

## 2. Numeri

- Volumi per allenamento: principiante 250-600 m, intermedio 600-1.200 m.
- Durate: principiante 20-35 min, intermedio 35-50 min.
- Recuperi: principiante 20-45 s, intermedio 15-30 s. Confronto parziale: la seduta 1 di Swim England usa 20-30 s di pausa per principianti.
- Crescita dei volumi: nel piano di Swim England si va da 300 m (seduta 1) a 950 m (seduta 10). Sostiene l'idea di partire da poco e crescere, ma non le soglie esatte né il limite di 600 m del principiante.
- Soglie dopo una pausa: fino a 2 settimane, da 2 a 6, oltre 6.
- "Almeno 3 allenamenti su una tappa prima di proporre il test."
- Livelli: principiante, intermedio (100 m continui di stile libero), avanzato.
- Distanze dei test delle tappe: 10 m di battuta, 25 m, 50 m, 100 m.

## 3. Struttura

- Le 10 tappe e il loro ordine, in particolare dorso, rana e delfino (le fonti non sono d'accordo).
- I 10 errori scelti sono i giusti? Ora ce ne sono 19: 10 di base più 9 di dorso, rana e delfino.
- La lista dei 22 drill (17 più 5 nuovi per le tappe 8-10): manca qualcosa di importante?
- Esercizi al bordo come **Gambata di rana al bordo** e **Respirazione al bordo** non si possono mettere in un allenamento, che ragiona per distanze. Vanno proposti come consigli a parte? Oppure il formato deve prevedere serie a tempo?
- Le tappe 1 (galleggiamento) e 2 (respirazione) non hanno allenamenti dedicati per lo stesso motivo.

## 4. Allenamenti di riserva

I 15 allenamenti in `content/allenamenti/` sono prudenti e per vasca da 25 m. Controlla che abbiano senso per un adulto di quel livello. Gli 8 nuovi sono (tutti in `bozza`):

| File | Livello | Obiettivo | Tappa | Metri |
|---|---|---|---|---|
| `principiante-05-bracciata-lunga` | principiante | tecnica | 5 | 350 |
| `principiante-06-respiro-di-lato` | principiante | tecnica | 6 | 400 |
| `principiante-07-continuita-con-pull-buoy` | principiante | resistenza, dimagrimento | 6-7 | 500 |
| `principiante-08-rana-con-scivolo` | principiante | tecnica | 9 | 400 |
| `intermedio-04-costanza-in-vasca` | intermedio | dimagrimento, resistenza | 7 | 900 |
| `intermedio-05-resistenza-con-pull-buoy` | intermedio | resistenza | 7 | 900 |
| `intermedio-06-delfino-onda-dal-petto` | intermedio | tecnica | 10 | 800 |
| `intermedio-07-rana-due-gambate` | intermedio | tecnica | 9 | 750 |

Da guardare con attenzione:
- Le fonti (Swim England, Swim Wales) sostengono solo l'ordine dei blocchi e la crescita graduale. **Metri, recuperi, intensità e durate stimate sono nostre proposte**, come negli altri sette.
- **Intermedio 05**: due serie continue da 200 m a ritmo medio con 30 s di pausa. Non è troppo per chi ha appena superato i 100 m?
- **Intermedio 06**: delfino a 25 m per 8 ripetizioni. L'allenamento è per chi ha già fatto le tappe precedenti: è realistico per un intermedio?
- **Principiante 08**: rana 25 m per 10 ripetizioni in tutto, senza esercizio al bordo (vedi sopra).
- I "dimagrimento" non promettono perdita di peso: sono solo volumi regolari a ritmo facile o medio, come da regole.
- Le durate stimate sono state ricavate per confronto con i sette allenamenti esistenti, non misurate.

## 5. Tono e personaggi

- Frasi tipo in `content/tono.md`.
- I due coach virtuali in `content/coach.json` e `docs/COACH_PERSONAS.md`.

## 6. Confronto con le tue fonti

Non ho potuto leggere il programma della Federazione Italiana Nuoto né i manuali di riferimento. Se segui un metodo preciso, dimmelo e allineo i contenuti.

## 7. Zone di ritmo (`content/zone-ritmo.json`)

> **Decisione dell'istruttore (11 ottobre 2026): il test dei 400 m non si propone agli adulti; il test del ritmo si fa solo sui 200 m.** Il ritmo di riferimento è il tempo dei 200 m diviso 2. Le zone sono percentuali della velocità sui 200 m (facile 55-65, regolare 65-75, sostenuto 75-85, impegnativo 85-92, veloce 92-100). **Sono numeri nostri, senza fonte**: gli studi trovati usano due distanze e nuotatori agonisti. Vanno confermati o sostituiti con il tuo metodo.

Le zone dicono a che ritmo nuotare, in base a una prova a tutta sui 200 m di stile libero. È la parte con meno appoggio nelle fonti, quindi guardala con attenzione.

- **Percentuali**: le 5 zone vanno da 70% a 110% della velocità critica (vecchie percentuali sulla velocità critica, non più usate). **Sono numeri nostri e prudenti, senza fonte**: non ho trovato una federazione, un ente o un articolo scientifico che li dia. Le fonti sostengono solo il concetto di velocità critica e il suo calcolo. Ti sembrano giusti? Vuoi usare quelli del tuo metodo?
- **Zona "veloce"**: va proposta a chi non è agonista? Forse va tolta o nascosta ai livelli bassi.
- **Istruzioni del test**: riscaldamento, riposo di circa 20 minuti (o prove in giorni diversi), partenza dal bordo, stessa vasca per le due prove sono proposte nostre. Gli studi parlano di nuotatori agonisti e di prove in giorni diversi. Il riposo giusto è corretto?
- **Differenza tra le fonti**: un articolo per nuotatori master (USMS) propone sforzo sostenibile e non a tutta. Noi chiediamo il massimo: preferisci così?
- **Adatto agli adulti principianti?** Il test è consigliato dal livello intermedio in su, con un avvertimento sul medico. Due prove a tutta sono adatte a un adulto di quel livello? Serve una condizione più precisa (per esempio 200 m continui senza fermarsi)?
- **Descrizioni**: controlla tono e parole ("ritmo critico" è comprensibile?).
- Il tempo dei 200 m è accettato tra 1:30 e 15:00; fuori da questo intervallo l'app chiede di ricontrollarlo.

## 8. Attrezzi dei drill e adattamento dopo "dura"

- **Attrezzi** (`attrezzi` e `attrezzi_facoltativi` in `content/drills.json`): l'app mostra "Porta a bordo vasca" in base a questi campi. Li ho ricavati dal testo dei drill. Necessari: tavoletta (Respirazione laterale con tavoletta), pull buoy (Nuotata con pull buoy). Facoltativi: tavoletta (Battuta con tavoletta), pinne (Sei colpi e cambio, Dorso: battuta con rotazione, Delfino: sei colpi una bracciata, Onda del delfino), snorkel (Onda del delfino). Controlla che siano giusti e se ne manca qualcuno.
- **Dopo "dura", cosa non andava?** Percentuali nostre, provvisorie: mancava il fiato = recuperi +50% (almeno +5 s); braccia o gambe stanche = un quarto di ripetizioni in meno nelle serie principali; esercizio troppo difficile = si sceglie tra la metà di allenamenti con le tappe più basse. Va bene così o preferisci altri valori?
- **Vasche da 16, 20, 33 m e altre misure**: le distanze degli allenamenti, scritte per 25 m, si arrotondano al multiplo della vasca più vicino (per esempio 50 m diventano 40 m in vasca da 20). Controlla che il risultato abbia senso per i principianti (nelle vasche da 33 m una vasca singola è già lunga).

## 9. Medaglie, traversate ed efficienza

- **Traversate** (`Medaglie.traversate`): Stretto di Messina 3.100 m, Bonifacio 11.000 m, Gibilterra 14.200 m, Manica 34.000 m. Sono distanze indicative della traversata a nuoto, verificate su fonti pubbliche (Wikipedia); le medaglie contano i metri nuotati in totale nell'app, non sono traversate vere. Sono i numeri giusti per l'istruttore, o preferisci altre tappe?
- **Fedele alla vasca**: 2 nuotate a settimana per 3 settimane di fila. **Cento di fila**: 100 m senza fermarsi. Soglie nostre, provvisorie.
- **Efficienza (SWOLF)**: l'app confronta le bracciate per vasca con la nuotata precedente e dice "meno / simile / più" se la differenza è almeno 1,0 bracciata. La soglia di 1,0 è provvisoria: dimmi se ti sembra giusta.
- **Avviso a 5 secondi dalla fine del recupero**: una vibrazione, sia sul Watch che sull'iPhone guidato. Da provare in acqua con il Watch vero.
