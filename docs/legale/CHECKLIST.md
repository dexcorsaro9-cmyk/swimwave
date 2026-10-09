> **BOZZA, da far rivedere a un avvocato prima della pubblicazione.**
> Chi l'ha scritta non è un avvocato. Ogni punto ha stato **da verificare**. Data di consultazione delle fonti: **2026-10-09**.

# Checklist di conformità di Swimwave

Come leggerla: per ogni punto c'è *cosa dice la fonte*, *come l'ho letta* (letta direttamente / solo da fonte secondaria / non letta) e *cosa decidere*. Dove non ho potuto leggere una fonte, lo scrivo e non indovino. Le frasi legali non verificate sono marcate "da verificare".

## 0. Stato delle fonti (cosa ho letto davvero)

| Fonte | Esito il 2026-10-09 |
|---|---|
| Linee guida App Store (developer.apple.com/app-store/review/guidelines/) | **Lette** (la pagina è lunga: lette tutte e due le parti). Riassunte con parole mie. |
| Apple, App Privacy Details (developer.apple.com/app-store/app-privacy-details/) | **Letta**. |
| AI Act, testo ufficiale su EUR-Lex (Reg. UE 2024/1689) | **Non letto**: la pagina ha restituito solo menu e metadati, senza il testo degli articoli. Un secondo tentativo sull'indirizzo ELI è stato bloccato dal permesso di accesso, e non l'ho aggirato. |
| Atto che modifica l'AI Act ("Digital Omnibus on AI", Reg. UE 2026/1744, secondo fonti) | Una ricerca limitata ai siti ufficiali europei restituisce le pagine EUR-Lex di questo regolamento e la versione consolidata del 2024/1689 al 2026-07-27, quindi **l'atto esiste**. Ma **non ho potuto aprirle**: il contenuto (date, periodo transitorio) viene da **una fonte secondaria** (cpduk.co.uk). Da confermare sul testo ufficiale. |
| Commissione europea, pagina sul quadro normativo dell'IA (digital-strategy.ec.europa.eu) | **Non letta**: richiesta di accesso non autorizzata/scaduta. |
| GDPR, Garante privacy, EDPB, Codice del consumo, Direttiva sull'accessibilità, norme sui dispositivi medici | **Non consultati** in questa sessione. Quello che scrivo viene dalla conoscenza generale di chi ha redatto la bozza e va **tutto verificato**. Dove metto un link, è l'indirizzo del portale ufficiale **non aperto**. |

Altre limitazioni: ho letto il codice del servizio coach solo in parte (`server/coach/src/coach.js`): conferma che nella richiesta il servizio usa il coach scelto e non il nome dell'utente, ma non c'è ancora un fornitore di IA, un hosting né un registro dei log.

---

## A. GDPR

### A1. Basi giuridiche e informativa (art. 6, 9, 13)
- **Fonte:** GDPR, [eur-lex.europa.eu/eli/reg/2016/679/oj](https://eur-lex.europa.eu/eli/reg/2016/679/oj) (link non aperto, 2026-10-09). Gli articoli 6 e 9 chiedono una base giuridica per ogni finalità e, per i dati sulla salute, una condizione in più (di norma il consenso esplicito). L'art. 13 elenca cosa dire all'interessato. **Non letto: da verificare.**
- **Stato bozza:** `informativa-privacy.md` assegna una base a ogni finalità.
- **Da decidere:**
  - [ ] Conferma delle basi (contratto per allenamento e coach; consenso per Apple Salute e notifiche; legittimo interesse per sicurezza/log).
  - [ ] Se esistono statistiche o rapporti sugli arresti: quale strumento, quali dati, quale base. Oggi non è deciso.
  - [ ] Dove si trova il link all'informativa (l'app e App Store Connect: vedi C1).

### A2. Dati sulla salute e consenso esplicito (art. 9)
- **Fonte:** GDPR art. 9 (non letto). I dati "relativi alla salute" sono una categoria particolare; il trattamento è vietato salvo eccezioni, tra cui il consenso esplicito. Cosa conta come "dato sulla salute" è interpretato in modo ampio: **da verificare con l'avvocato.**
- **Situazione del prodotto (da ONBOARDING.md, ARCHITECTURE.md, EXPERIENCE.md):**
  - I "fastidi fisici" non si chiedono all'avvio: bene.
  - Ma ARCHITECTURE.md prevede la "risposta dell'utente" con **dolore sì/no**, e un "riassunto per il coach" con "ultime risposte". Se il dolore finisce nel riassunto, parte verso server e fornitore di IA: sarebbe un dato sulla salute inviato a terzi.
  - Gli allenamenti da Apple Salute (durata, distanza, frequenza) possono essere considerati dati sulla salute o sull'attività fisica: **da verificare**.
  - L'obiettivo "Dimagrire" suggerisce una condizione fisica: **da verificare** se vada trattato con prudenza.
- **Da decidere:**
  - [ ] Il dolore sì/no resta solo sul dispositivo (consigliato) o viaggia verso il server? Se viaggia: consenso esplicito separato e testo dell'informativa cambiato.
  - [ ] I riepiloghi derivati da HealthKit inviati al servizio: servono davvero? Se sì, consenso esplicito prima del primo invio (si collega a C3).
  - [ ] Se mai si raccogliesse un dato di salute facoltativo (per esempio i "fastidi" in una versione futura): consenso esplicito, separato, revocabile, e solo sul dispositivo se possibile.

### A3. DPIA (valutazione d'impatto, art. 35)
- **Fonte:** GDPR art. 35 e l'elenco dei trattamenti che richiedono la DPIA del Garante italiano (provvedimento n. 467/2018: **non letto, da verificare**); linee guida del gruppo di lavoro Art. 29 sulla DPIA. Una DPIA serve quando il rischio è elevato; tra i criteri compaiono uso di nuove tecnologie, dati sulla salute, trattamenti su larga scala.
- **Da decidere:**
  - [ ] Fare una DPIA, o scrivere una valutazione che spiega perché non serve. Consiglio: farne almeno una versione breve (uso di IA di terzi + dati forse sanitari + dati inviati fuori dal dispositivo).
  - [ ] Rifarla se cambia il fornitore o si aggiungono dati.

### A4. Registro dei trattamenti (art. 30)
- **Fonte:** GDPR art. 30 (non letto). Il registro è obbligatorio per le piccole imprese solo in certi casi (trattamento non occasionale o con dati particolari): **da verificare**.
- **Da decidere:**
  - [ ] Tenerlo comunque (facile da fare a partire dalle sezioni 2-7 dell'informativa).

### A5. Fornitori, contratti (DPA, art. 28) e trasferimenti (cap. V)
- **Fonte:** GDPR art. 28 e artt. 44-49 (non letti). Chi tratta dati per te deve essere vincolato da un contratto; per il trasferimento fuori UE servono garanzie (decisione di adeguatezza, clausole contrattuali tipo...). **Stato attuale del Data Privacy Framework e della sua validità: da verificare con fonti ufficiali; non l'ho controllato.**
- **Da decidere:** fornitori ancora da scegliere nel repository:
  - [ ] Fornitore del modello IA: DPA firmato? Dati usati per addestrare? Conservazione? Area geografica? Funzione "zero data retention"?
  - [ ] Hosting del servizio coach (e log).
  - [ ] Hosting dei video.
  - [ ] Eventuali strumenti di statistiche/arresti.
  - [ ] Email/assistenza.
  - [ ] Elenco dei responsabili da aggiornare nell'informativa (sezione 5).

### A6. Identificativo anonimo del dispositivo
- **Situazione:** ARCHITECTURE.md prevede un "identificativo anonimo del dispositivo". Un identificativo persistente associato a richieste e riepiloghi è, di norma, un dato personale (pseudonimo): **da verificare**.
- **Da decidere:**
  - [ ] A cosa serve esattamente (limite di richieste? abbonamento?).
  - [ ] Come l'utente lo cancella (diritto alla cancellazione senza account).
  - [ ] Se serve per cancellare i dati lato server.

### A7. Altri punti GDPR
- [ ] Diritti degli interessati (artt. 15-22): procedura interna e tempi (di norma un mese).
- [ ] Violazione dei dati (artt. 33-34): procedura di notifica entro 72 ore al Garante.
- [ ] Decisioni automatizzate (art. 22): valutazione che l'allenamento generato dall'IA non produce effetti giuridici o significativi analoghi. **Da verificare.**
- [ ] DPO (art. 37): serve? **Da verificare.**
- [ ] Notifiche e permessi di sistema: se nel tempo si aggiungono strumenti di misurazione, regole ePrivacy (art. 5.3 direttiva 2002/58, in Italia art. 122 del Codice privacy): **da verificare**.
- [ ] Nome dell'utente: la bozza dice che resta sul dispositivo. **Confermare con lo sviluppo.**

---

## B. AI Act (Regolamento UE 2024/1689)

### B1. Obbligo di dire che si interagisce con un'IA (art. 50, par. 1)
- **Cosa dice la fonte (conoscenza generale, testo ufficiale non letto: da verificare):** i fornitori di sistemi di IA destinati a interagire direttamente con persone devono progettarli in modo che le persone siano informate che stanno interagendo con un'IA, salvo che sia ovvio per una persona normalmente informata e attenta.
- **Collegamento col prodotto:**
  - I coach sono due personaggi con volto fotorealistico e nome proprio. POPUP_COACH.md decide di **non** mettere l'etichetta "coach virtuale" nelle schermate e nei popup: l'informazione compare alla scelta, in Profilo > Informazioni e nell'informativa.
  - Se i messaggi del coach sono generati dall'IA (da confermare, vedi nota-ia.md), la persona "parla" con un sistema di IA ogni volta che legge un messaggio. Il fatto che sia un'IA non è per forza "ovvio" quando l'avatar è fotorealistico e ha un nome come quello del fondatore.
- **Da decidere:**
  - [ ] Parere dell'avvocato: la disclosure "una volta alla scelta, più Informazioni" basta per l'art. 50(1)? Basta per le regole sulle pratiche commerciali scorrette (vedi F1)?
  - [ ] Alternativa a basso costo se il parere è negativo: etichetta discreta "Coach virtuale" accanto al nome, o icona "IA" sull'avatar, almeno dove c'è una conversazione/un messaggio generato.
  - [ ] Quali messaggi sono davvero generati dall'IA e quali sono testi fissi.

### B2. Contenuti sintetici: marcatura (art. 50, par. 2) e contenuti manipolati (par. 4)
- **Cosa dice la fonte (conoscenza generale, non letto ufficialmente: da verificare):** i fornitori di sistemi che generano audio, immagini, video o testo sintetici devono marcare gli output in formato leggibile da macchina. Chi usa (deployer) un sistema che crea o manipola immagini/video/audio che costituiscono un "deep fake", cioè che assomigliano a persone, luoghi o eventi esistenti e potrebbero sembrare autentici, deve dichiararlo.
- **Collegamento col prodotto:**
  - Le immagini dei coach: personaggi inventati, che non assomigliano a persone reali (COACH_PERSONAS.md): il par. 4 sui deep fake sembra non applicabile in senso stretto, ma **va confermato**. Il par. 2 pesa sul fornitore del generatore di immagini, non su di noi (se usiamo uno strumento terzo): **da verificare**.
  - L'allenamento generato è testo/dati strutturati (JSON): **da verificare** se rientra nel par. 2 (ci sono eccezioni per funzioni di mero supporto o che non alterano in modo sostanziale gli input; non l'ho letto).
- **Da decidere:**
  - [ ] Ruolo dell'azienda nel sistema (fornitore di un sistema di IA che incorpora un modello di terzi? deployer?). Cambia gli obblighi.
  - [ ] Conservare i metadati/marcatura delle immagini dei coach se il generatore li aggiunge.
  - [ ] Chiedere al fornitore del modello come soddisfa il par. 2 per il testo.

### B3. Data di applicazione e modifiche recenti (da verificare)
- **Cosa dice la fonte:**
  - Fonte secondaria letta il 2026-10-09 ([cpduk.co.uk](https://www.cpduk.co.uk/news/deadline-moved-and-duty-did-not-ai-act-transparency-obligations-after-digital-omnibus), **non ufficiale**): il "Digital Omnibus on AI" è il **Regolamento (UE) 2026/1744**, datato 8 luglio 2026, pubblicato nella Gazzetta ufficiale UE il 24 luglio 2026, in vigore dal 27 luglio 2026. Per l'art. 50 **non cambia la data generale**: gli obblighi di trasparenza si applicano **dal 2 agosto 2026**. Un periodo transitorio nuovo (art. 111, par. 4) porta al **2 dicembre 2026** l'obbligo di marcatura del par. 2 **solo** per i sistemi di IA generativa già sul mercato prima del 2 agosto 2026. Le norme sui sistemi ad alto rischio slittano al 2 dicembre 2027 e al 2 agosto 2028. La fonte cita anche il Codice di condotta sulla trasparenza dei contenuti generati dall'IA (versione finale 10 giugno 2026) e le linee guida della Commissione sull'art. 50 (20 luglio 2026).
  - Riscontro ufficiale: una ricerca limitata a siti ufficiali europei ha restituito la pagina EUR-Lex del [Reg. 2026/1744](https://eur-lex.europa.eu/eli/reg/2026/1744/oj/eng) e la versione consolidata dell'[AI Act al 2026-07-27](https://eur-lex.europa.eu/eli/reg/2024/1689/2026-07-27/eng) (solo titoli/indirizzi, **non aperte**). Quindi l'esistenza dell'atto è confermata, il contenuto no.
  - Altri titoli trovati dalla ricerca generale sono in tensione tra loro (alcuni parlano di "scadenza spostata", altri di "non rinviata"): la ricerca non basta.
- **Conclusione provvisoria (da verificare):** se la lettura è giusta, l'art. 50 si applica già al lancio di Swimwave (oggi 2026-10-09, quindi dopo il 2 agosto 2026). Il periodo transitorio del par. 2 non dovrebbe riguardare Swimwave, che è un prodotto nuovo.
- **Da decidere:**
  - [ ] L'avvocato (o un tecnico) legge il testo ufficiale del Reg. 2026/1744, l'art. 50 e l'art. 111, e le linee guida della Commissione del 20 luglio 2026.
  - [ ] Controlla se altri atti (italiani) toccano questo tema (per esempio la legge italiana sull'IA, L. 132/2025: **non verificata**).

### B4. Altri obblighi AI Act da guardare
- [ ] Alfabetizzazione in materia di IA (art. 4): stato attuale dopo l'omnibus **da verificare**.
- [ ] Pratiche vietate (art. 5), per esempio manipolazione o sfruttamento di vulnerabilità: i toni "Spronami" e i messaggi motivazionali non devono manipolare. **Da verificare con l'avvocato.**
- [ ] Alto rischio: da escludere formalmente (app di allenamento, non medica, non decide su persone). **Da verificare.**

---

## C. Linee guida App Store di Apple (lette il 2026-10-09)

Fonte: [developer.apple.com/app-store/review/guidelines/](https://developer.apple.com/app-store/review/guidelines/). I numeri delle sezioni sono quelli visti nella pagina.

### C1. Informativa e raccolta dati (5.1.1)
- **Cosa dice:** informativa collegata in App Store Connect e dentro l'app, con dati raccolti, usi, conservazione, cancellazione e revoca del consenso. Consenso prima di raccogliere dati, anche anonimi. Raccogliere solo i dati necessari alle funzioni principali.
- **Da decidere:**
  - [ ] URL pubblico dell'informativa e collegamento nel Profilo.
  - [ ] Dove si chiede il consenso per i dati inviati al server (vedi C3).
  - [ ] Come l'utente chiede la cancellazione dei dati lato server senza account.

### C2. Eliminazione dell'account (5.1.1(v))
- **Cosa dice:** se l'app permette di creare un account, deve permettere di eliminarlo dall'app.
- **Situazione:** la v1 non ha account (ARCHITECTURE.md). L'introduzione di Sign in with Apple con l'abbonamento multi-dispositivo cambierà la regola.
- **Da decidere:**
  - [ ] Prevedere già ora un "Elimina i miei dati" nel Profilo che cancella locale e server (identificativo anonimo).
  - [ ] Quando si aggiunge un account: eliminazione nell'app, non solo per email.

### C3. Condivisione con IA di terzi (5.1.2(i)) e uso dei dati (5.1.2)
- **Cosa dice:** non usare, trasmettere o condividere dati personali senza permesso; la condivisione con terzi, **compresa l'IA di terze parti**, va dichiarata chiaramente e va chiesto il permesso esplicito prima. I dati raccolti per uno scopo non si riusano per un altro senza nuovo consenso.
- **Situazione:** il servizio coach manda dati a un modello di terzi.
- **Da decidere:**
  - [ ] Schermata di consenso prima della prima richiesta al coach IA, con elenco dei dati e del fornitore.
  - [ ] Se rifiuta: l'app funziona con gli allenamenti di riserva (il consenso non può essere una condizione per usare l'app se non serve alla funzione: **da verificare con l'avvocato e con la revisione Apple**).

### C4. Salute e HealthKit (5.1.3)
- **Cosa dice:** i dati di salute e fitness non si usano né si comunicano a terzi per pubblicità, marketing o data mining (eccezioni limitate); bisogna dichiarare quali dati di salute si raccolgono; non scrivere dati falsi o inesatti in HealthKit; non conservare informazioni sanitarie personali in iCloud. Per i dati HealthKit vale anche il divieto di usarli per marketing/data mining (5.1.2(vi)).
- **Da decidere:**
  - [ ] SwiftData con sincronizzazione iCloud/CloudKit è un'opzione futura? Se contiene dati sanitari, è in conflitto con 5.1.3(ii): non attivare la sincronizzazione senza valutarlo.
  - [ ] Cosa dei dati HealthKit finisce nei riepiloghi per il fornitore di IA (3 righe nell'informativa e nel testo di revisione).
  - [ ] Testi dei permessi HealthKit (spiegano a cosa serve ogni permesso).
  - [ ] Essere certi che il fornitore di IA non usi i dati per scopi propri (vedi A5).

### C5. App di salute (1.4.1)
- **Cosa dice:** le app mediche che potrebbero dare informazioni inesatte o essere usate per diagnosi/cura sono guardate con più attenzione; non si possono dichiarare misure che non si possono validare; le app devono ricordare di consultare un medico e di non fidarsi solo dell'app.
- **Da decidere:**
  - [ ] Mostrare l'avvertenza di `avvertenza-salute.md` e non fare affermazioni di accuratezza sui dati dell'orologio.
  - [ ] Evitare la promessa di risultati sanitari.

### C6. Contenuti generati dall'IA
- **Cosa dice:** nella parte visibile della pagina non ho trovato una regola specifica sui contenuti generati dall'IA oltre alla 5.1.2(i). La pagina è stata letta tutta, ma Apple può cambiare le regole: **ricontrollare al momento dell'invio**. Il resto è: precisione dei metadati, nessuna ingannevolezza.
- **Da decidere:**
  - [ ] Descrivere nelle note per la revisione che i coach sono virtuali e come funziona l'IA (bozza in `nota-ia.md`).
  - [ ] Controllare se l'App Store Connect chiede una dichiarazione sull'IA o una classificazione per età legata all'IA (non verificato).

### C7. Etichette di privacy "App Privacy"
- **Cosa dice (letta il 2026-10-09, [app-privacy-details](https://developer.apple.com/app-store/app-privacy-details/)):** vanno dichiarati i dati raccolti da te **e dai partner** (SDK, strumenti, fornitori). "Raccolti" = inviati fuori dal dispositivo e accessibili a te o ai partner più a lungo di quanto serve per rispondere alla richiesta; i dati trattati solo sul dispositivo non sono "raccolti". I dati restano "collegati" all'utente salvo che siano de-identificati prima della raccolta. Categorie, tra cui Salute, Fitness, Identificativi (ID dispositivo/utente), Dati d'uso. La pagina non nomina i servizi di IA, ma un fornitore di IA è un partner esterno.
- **Da decidere:** compilare l'etichetta solo dopo aver deciso A2, A6 e C3. Bozza di partenza, da confermare:
  - [ ] Identificativi: Device ID/User ID (identificativo anonimo) se lo teniamo sul server.
  - [ ] Salute e Fitness: se i riepiloghi (frequenza, durata, giudizio, eventuale dolore) vengono inviati e conservati. Collegati all'utente? Usati per funzioni dell'app.
  - [ ] Tracciamento: nessuno (confermare che non ci siano SDK pubblicitari).
  - [ ] Dati inseriti: livello, obiettivo, vasca, ritmo: se inviati e conservati, "Contenuti dell'utente"/"Altri dati" (categoria esatta da scegliere nella tabella di Apple).
  - [ ] Aggiornare le etichette quando cambia il fornitore.

### C8. Abbonamenti (3.1.2) e prezzo
- **Cosa dice:** periodo minimo di 7 giorni, funzionare su tutti i dispositivi dell'utente, descrivere con chiarezza ciò che si ottiene e il prezzo prima di chiedere di abbonarsi; le prove gratuite si configurano in App Store Connect.
- **Da decidere:**
  - [ ] Il prezzo che scende ogni mese (PRODUCT.md) è compatibile? Apple definisce prezzi per piano: **da verificare** (PRODUCT.md lo segnala già).
  - [ ] Il testo di `termini-di-uso.md` sezione 8.

### C9. Nome, marchio e contenuti altrui (5.2)
- **Cosa dice:** usare solo contenuti propri o con licenza; niente nomi o metadati ingannevoli.
- **Da decidere:**
  - [ ] Verifica del nome "Swimwave" (README.md già segnala EUIPO TMview, USPTO, App Store).
  - [ ] Licenza d'uso del generatore di immagini per scopi commerciali.

---

## D. Minori e verifica "almeno 18 anni"

### D1. Età del consenso e dati dei minori
- **Fonte:** GDPR art. 8 (consenso dei minori per i servizi della società dell'informazione) e la scelta italiana dell'età (in Italia, 14 anni, nel Codice privacy art. 2-quinquies: **non letto, da verificare**).
- **Situazione:** la v1 è pensata per adulti. ONBOARDING.md lascia da decidere se chiedere "Hai almeno 18 anni?".
- **Da decidere:**
  - [ ] Conferma "18+" all'avvio, con un tocco: è una dichiarazione, non una verifica. Basta per l'avvocato?
  - [ ] Classificazione per età su App Store Connect coerente (non verificata).
  - [ ] Cosa succede se qualcuno dichiara meno di 18 anni: l'app si ferma o prosegue senza invio di dati al server?
  - [ ] Contratti con minori e abbonamento: validità. **Da verificare.**
  - [ ] Marketing che non attiri i minori.

---

## E. Accessibilità

### E1. Obblighi di legge
- **Fonte:** Direttiva (UE) 2019/882 (European Accessibility Act), applicata in Italia con D.Lgs. 82/2022, con applicazione dal 28 giugno 2025 per molti prodotti e servizi; esiste un'esenzione per le microimprese per i servizi (**non letta, da verificare** le soglie e se vale per l'azienda e per un'app venduta ai consumatori).
- **Da decidere:**
  - [ ] L'esenzione microimprese si applica? Con quali condizioni?
  - [ ] Anche se esente, rispettare le buone pratiche: VoiceOver, Dynamic Type, contrasto, alternative testuali.

### E2. Pratica nel progetto
- POPUP_COACH.md prevede etichette testuali per gli avatar. Da estendere a:
  - [ ] Testi dell'avvertenza sulla salute e della nota IA leggibili con VoiceOver e con testo grande.
  - [ ] Apple Watch: vibrazioni e testi, senza dipendere solo dall'immagine.
  - [ ] Video con sottotitoli.
  - [ ] Verificare se App Store Connect offre/richiede una dichiarazione di accessibilità (non verificato in questa sessione).

---

## F. Altri punti che l'avvocato dovrebbe vedere

### F1. Pratiche commerciali scorrette e trasparenza sul coach
- **Fonte:** Codice del consumo (D.Lgs. 206/2005) e direttiva 2005/29/CE sulle pratiche commerciali (**non letti, da verificare**). Un messaggio ingannevole sul fatto che si parli con una persona reale, o sul chi ha scritto i contenuti, può essere scorretto.
- **Da decidere:**
  - [ ] Nome "Antonio" uguale al nome del fondatore: rischio di far credere che sia lui. La bozza di `nota-ia.md` lo dice chiaramente: tenere?
  - [ ] Parlare di "il tuo istruttore in tasca" (README.md): accettabile se resta chiaro che è virtuale.

### F2. Dire la verità su chi scrive i contenuti
- **Contraddizione trovata nei documenti del progetto:** PRODUCT.md dice "testi scritti dall'istruttore"; CLAUDE.md dice che i contenuti li scrive Claude e l'istruttore li controlla; README.md dice "consigli tecnici scritti da un istruttore vero".
- **Da decidere:**
  - [ ] Usare ovunque la formula vera: "preparati con strumenti di IA, basati su fonti autorevoli e controllati da un istruttore di nuoto".
  - [ ] Cambiare README/PRODUCT e la scheda App Store se serve.

### F3. Videolezioni
- PRODUCT.md prevede video girati dall'istruttore. Liberatorie per l'immagine di chi appare, musiche, hosting.
- [ ] Liberatorie e licenze.

### F4. Dispositivo medico e promesse sulla salute
- **Fonte:** Regolamento (UE) 2017/745 sui dispositivi medici (**non letto, da verificare**): un software con finalità mediche (diagnosi, cura) può essere un dispositivo medico.
- **Situazione:** l'app non ha scopo medico e non diagnostica; l'obiettivo "Dimagrire" e il messaggio sul dolore sono punti da guardare.
- **Da decidere:**
  - [ ] Conferma che l'app, come descritta, non è un dispositivo medico.
  - [ ] Parole da evitare nei testi (terapia, cura, riabilitazione).
  - [ ] Formulazione dell'obiettivo "Dimagrire" (già segnalato in ONBOARDING.md).

### F5. Responsabilità e termini
- [ ] Clausole di esonero della responsabilità verso consumatori e per lesioni alla persona: limiti forti. **Da riscrivere con l'avvocato** (sezione 10 di `termini-di-uso.md`).
- [ ] Assicurazione di responsabilità civile.

### F6. Diritto di recesso, informazioni precontrattuali
- [ ] Servizio digitale in abbonamento: recesso, prova gratuita, rinnovo automatico, ODR. **Da verificare** con l'avvocato (non letto).

---

## G. Prima di pubblicare

- [ ] Sostituire tutti i segnaposto: [TITOLARE DEL TRATTAMENTO], [INDIRIZZO], [EMAIL PRIVACY], [P.IVA], [FORNITORE DEL MODELLO IA], [HOSTING...].
- [ ] Togliere le "NOTA PER L'AVVOCATO" e le frasi "DA VERIFICARE".
- [ ] Mettere i testi in `docs/legale` nei file di localizzazione dell'app.
- [ ] Ripetere la lettura delle fonti il giorno dell'invio ad Apple e prima del lancio (le regole cambiano; la data qui è 2026-10-09).
- [ ] Salvare la data in cui l'utente ha letto/accettato avvertenza, termini e consenso al coach IA.
