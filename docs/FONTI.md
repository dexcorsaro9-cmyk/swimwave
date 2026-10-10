# Fonti dei contenuti tecnici

I drill, gli errori comuni e le tappe del percorso sono stati scritti confrontandoli con fonti di federazioni, enti e testi accademici, consultate il 9 ottobre 2026. I contenuti sono riassunti con parole nostre. L'elenco completo, con i link, è in `content/fonti.json`.

Ogni voce dei file in `content/` ha:
- `stato`: `bozza` finché l'istruttore non l'ha controllata, poi `approvato`. Nella versione per gli utenti vanno solo le voci approvate.
- `fonti`: gli id delle fonti che la sostengono. Se è vuoto c'è una `nota_fonti` che spiega perché.

## Fonti usate

| Fonte | Ente | Per cosa |
|---|---|---|
| Linee guida su attività fisica | Organizzazione Mondiale della Sanità (2020) | Partire con piccole quantità e aumentare gradualmente |
| Learn to Swim, 7 fasi | Swim England | Ordine delle abilità e distanze di riferimento (per bambini) |
| Learn-to-Swim, livelli 1-6 | Scheda con struttura simile alla Croce Rossa americana, organizzazione non dichiarata | Prove di galleggiamento e respirazione, distanze |
| Dispensa Sport natatori | Francesco Ravenna, Università di Ferrara | Didattica italiana, respirazione bilaterale, ordine degli stili |
| Drill Progression Framework (stile libero, dorso, rana, delfino) | Swim Wales | Descrizione dei drill |
| Coaches Cards Freestyle, MERC 4 Breaststroke Kick | Special Olympics | Catch-up, un braccio, gambata di rana |
| 10 Common Freestyle Swim Mistakes | USA Triathlon | Errori comuni e correzioni |
| Fingertip Drag Catch-Up | Swimming World Magazine | Drill con le dita sull'acqua |
| 6-Kick Switch | FORM (azienda) | Solo conferma del drill |
| Swimming Fitness Training Plan (20 sedute) | Swim England (sito ufficiale swimming.org) | Struttura della seduta e crescita graduale del volume (300 m alla seduta 1, 950 m alla seduta 10) |
| Pool Training Session 1 | Swim England (sito ufficiale swimming.org) | Esempio di seduta per chi parte: 20-30 secondi di pausa, riscaldamento e defaticamento di 2 vasche |
| Session Planning Guide for Coaches | Swim Wales | Ordine dei blocchi di una seduta (per allenatori agonisti, usata solo per l'ordine) |
| A Simple Method for Determining Critical Speed... (1992) | Wakayoshi e altri, Int J Sports Med | Definizione e calcolo della velocità critica (agonisti) |
| Physiological Responses... Critical Stroke Rate (2022) | Funai e altri, Sports | Velocità critica da prove di 200 m e 400 m |
| Stroke-Specific Swimming Critical Speed Testing (2024) | Scott, Burden, Dekerle, J Hum Kinet | Velocità critica da prove di 200 m e 400 m, uso per personalizzare le intensità |
| Modeling... distance above critical speed (2022) | Raimundo e altri, Frontiers in Physiology | Velocità critica come confine tra sforzo sostenibile e non |
| How to Train With Critical Swim Speed Intervals | Botyarov, U.S. Masters Swimming | Test 400 + 200 per master; sforzo sostenibile, non a tutta |
| 4 Swimming Dryland Exercises to Save Your Shoulders (2025) | Bo Hickey, U.S. Masters Swimming | Rotazione interna con elastico; frequenza 2-3 volte a settimana |
| Rotator Cuff and Shoulder Conditioning Program | OrthoInfo, AAOS | Tecnica degli esercizi con elastico per la spalla e stretching del braccio (pensato per la riabilitazione) |
| Kabat D2 elastic bands in swimmers (2023) | Della Tommasina e altri, Frontiers in Physiology | Esercizio con elastico per nuotatori; risultato non significativo |
| Update on Rehabilitation Strategies for Swimmers' Shoulder (2024) | Rivista Thieme, revisione narrativa | Importanza di core e rotatori esterni; programmi con pochi esercizi |
| From dry-land to the water (2024) | Raineteau e altri, Frontiers in Sports and Active Living | Contesto: il core è molto allenato dai preparatori di sprinter d'élite |
| Bird dog exercise for your core | Harvard Health Publishing | Bird dog: esecuzione, 10 ripetizioni, errori |
| Basic Core and Pelvic Stability | UC Davis Health, Sports Medicine | Bird dog, plank laterale, dead bug |
| Unlock Your Spine with Flexibility and Strengthening Exercises (2025) | Orlando Health, M. Curda DPT | Libro aperto, ponte, bird dog |
| Strength exercises / Flexibility exercises | NHS | Mini-squat e stretching del polpaccio |
| Why the Glute Bridge Belongs in Almost Every Client Program | NASM | Esecuzione del ponte per i glutei |

## Cosa è cambiato rispetto alla prima bozza

- Il drill "Sei colpi e tre bracciate" non era come l'avevo descritto: il drill documentato prevede sei colpi su un fianco e una bracciata per cambiare lato. È diventato "Sei colpi e cambio".
- "Battuta di fianco" è diventata "Battuta con un braccio teso": le fonti indicano una rotazione di circa 45 gradi, non il corpo disteso su un fianco.
- Le distanze dei test erano troppo ambiziose rispetto ai quadri ufficiali: ad esempio 50 m di dorso e rana sono diventati 25 m, e 200 m continui sono diventati 100 m.
- L'onda del delfino parte dal petto e non è più descritta sulla schiena o di fianco.
- La gambata di rana ha ora i dettagli della fonte: piedi flessi e ruotati in fuori, ginocchia appena più larghe dei fianchi.

## Aggiunte del 9 ottobre 2026

- Allenamenti di riserva: ora 15. Le tre fonti nuove sostengono la struttura (riscaldamento, tecnica, serie principale, defaticamento) e la crescita graduale, registrate una volta sola in `content/allenamenti/indice.json`.
- Dorso, rana e delfino: 7 drill e 9 errori nuovi, ricavati dai quadri Swim Wales già nell'elenco (dorso, rana, delfino) e dalla scheda Special Olympics sulla gambata di rana. Non è stata aggiunta nessuna fonte nuova per questi: i quadri Swim Wales sono scritti per nuotatori agonisti o per l'allenatore, quindi l'adattamento all'adulto alle prime armi è da verificare. Dove il quadro non spiega perché un difetto sia un problema, la spiegazione è nostra e lo dice la `nota_fonti`.
- Il sito ufficiale di Swim England (swimming.org) è risultato leggibile per le pagine del piano di allenamento e della seduta 1. Le sedute dalla 2 in poi (solo per iscritti) mostrano solo titolo e metri, quindi non sono state usate. Le 7 fasi del Learn to Swim restano la copia dell'Università di Brighton: non ho riprovato a leggere la versione ufficiale.
- Non consultati in questo giro: World Aquatics, USA Swimming, Federazione Italiana Nuoto.

## Zone di ritmo (9 ottobre 2026)

`content/zone-ritmo.json`: le 5 fonti sopra sostengono il concetto di velocità critica e il test 200 m + 400 m, ma **nessuna dà le percentuali delle zone**. I limiti (70-110% della velocità critica) sono proposte nostre e prudenti, con `fonti` vuoto e una `nota_fonti`. Riscaldamento, riposo e partenza del test sono pure nostri. Non consultati: Swim England, British Swimming, USA Swimming, FIN, ACSM/NSCA (nessuna pagina utile trovata o leggibile).

## Limiti

- Le fasi di Swim England e i livelli Learn-to-Swim sono pensati per i bambini. Le usiamo per l'ordine di apprendimento, non come soglie per gli adulti.
- Le cifre di volumi, durate e recuperi degli allenamenti non hanno una fonte diretta: sono prudenti e vanno validate. Confronto solo parziale con Swim England (seduta 1: 300 m e 20-30 secondi di pausa; seduta 10: 950 m).
- Gli esercizi al bordo (galleggiamento a stella, respirazione al bordo, gambata di rana al bordo) non possono comparire negli allenamenti, che sono espressi in distanze: le tappe 1 e 2 non hanno allenamenti di riserva propri.
- Non abbiamo potuto leggere il programma della Federazione Italiana Nuoto (Scuola Nuoto Federale), né manuali come quelli di Counsilman, Maglischo o Laughlin. Vanno confrontati dall'istruttore.
- Le fonti in disaccordo sono segnalate: l'ordine di dorso, rana e delfino.

## Come si aggiunge una fonte

Si aggiunge una voce in `content/fonti.json` e il suo id nel campo `fonti` della voce che sostiene. I test controllano che ogni fonte citata esista e che ogni contenuto abbia fonti o una nota.
