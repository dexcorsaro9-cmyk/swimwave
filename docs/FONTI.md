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

## Cosa è cambiato rispetto alla prima bozza

- Il drill "Sei colpi e tre bracciate" non era come l'avevo descritto: il drill documentato prevede sei colpi su un fianco e una bracciata per cambiare lato. È diventato "Sei colpi e cambio".
- "Battuta di fianco" è diventata "Battuta con un braccio teso": le fonti indicano una rotazione di circa 45 gradi, non il corpo disteso su un fianco.
- Le distanze dei test erano troppo ambiziose rispetto ai quadri ufficiali: ad esempio 50 m di dorso e rana sono diventati 25 m, e 200 m continui sono diventati 100 m.
- L'onda del delfino parte dal petto e non è più descritta sulla schiena o di fianco.
- La gambata di rana ha ora i dettagli della fonte: piedi flessi e ruotati in fuori, ginocchia appena più larghe dei fianchi.

## Limiti

- Le fasi di Swim England e i livelli Learn-to-Swim sono pensati per i bambini. Le usiamo per l'ordine di apprendimento, non come soglie per gli adulti.
- Le cifre di volumi, durate e recuperi degli allenamenti non hanno una fonte diretta: sono prudenti e vanno validate.
- Non abbiamo potuto leggere il programma della Federazione Italiana Nuoto (Scuola Nuoto Federale), né manuali come quelli di Counsilman, Maglischo o Laughlin. Vanno confrontati dall'istruttore.
- Le fonti in disaccordo sono segnalate: l'ordine di dorso, rana e delfino.

## Come si aggiunge una fonte

Si aggiunge una voce in `content/fonti.json` e il suo id nel campo `fonti` della voce che sostiene. I test controllano che ogni fonte citata esista e che ogni contenuto abbia fonti o una nota.
