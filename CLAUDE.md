# Contesto per Claude Code

Progetto: Swimwave, app di coaching di nuoto per iPhone e Apple Watch (SwiftUI, HealthKit). Lingua del progetto e dell'interfaccia di partenza: italiano, con stringhe pronte per la traduzione.

Regole di lavoro:
- Il fondatore è un istruttore di nuoto ma non ha tempo di inserire i contenuti: li scrive Claude. Ogni contenuto tecnico (drill, errori, tappe, regole, allenamenti) si basa solo su fonti autorevoli (federazioni, enti, testi accademici), registrate in content/fonti.json e riassunte con parole nostre. Non inventare: se una fonte non si trova, lascia il campo `fonti` vuoto con una `nota_fonti` che lo dice.
- Nessuna revisione obbligatoria (decisione dell'istruttore, 26 ottobre 2026): i contenuti nascono `approvato` e l'app li propone in automatico. Restano le regole di sicurezza (nessuna intensità forte per il principiante, validazione dello schema, lista chiusa di drill) e le fonti dichiarate. Le note sulle fonti deboli sono in content/REVISIONE.md come promemoria, non come passaggio da superare.
- I due coach virtuali (uomo e donna) hanno stessa competenza e tono: vedi docs/COACH_PERSONAS.md. L'app dice che sono virtuali.
- Il formato dell'allenamento in docs/WORKOUT_FORMAT.md è il contratto tra coach IA, iPhone e Watch.
- Prima versione: iPhone + Apple Watch minimo. Android, Garmin, Wear OS e analisi video sono dopo.
- Non copiare contenuti, nomi dei piani o grafica di altre app.
- Il fondatore ha già pubblicato altre app native iOS e Android e ha TestFlight.
- Leggi README.md, docs/PRODUCT.md e docs/ROADMAP.md prima di iniziare.
