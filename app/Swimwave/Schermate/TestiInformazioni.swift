import Foundation

// TESTO DA FAR VEDERE A UN AVVOCATO prima della pubblicazione (docs/legale/CHECKLIST.md).
//
// Scritto in italiano semplice a partire da docs/legale/ (nota-ia.md, informativa-privacy.md, avvertenza-salute.md).
// Sono costanti nel codice e non chiavi di Localizable.xcstrings: sono testi legali lunghi, che vanno rivisti e
// tradotti come un documento unico. Le parti tra parentesi quadre sono segnaposto da riempire (contatti, indirizzo web).
// Cose volutamente NON dette perché ancora da decidere o da verificare (vedi docs/legale/): nome del fornitore di IA,
// per quanto tempo il servizio e il fornitore conservano le richieste, uso dei dati per addestrare modelli,
// regioni geografiche dei server.

/// Una sezione della schermata Informazioni: un titolo e uno o più paragrafi.
struct SezioneInformazioni: Identifiable {
    let id: String
    let titolo: String
    let paragrafi: [String]
}

enum TestiInformazioni {
    static let contatto = "[email di contatto da inserire]"
    static let indirizzoInformativa = "[indirizzo web dell'informativa da inserire]"

    static let sezioni: [SezioneInformazioni] = [
        SezioneInformazioni(
            id: "coach",
            titolo: "I coach sono personaggi virtuali",
            paragrafi: [
                "Antonio e Pamela sono personaggi virtuali. Le loro immagini sono state create con un programma di intelligenza artificiale e non ritraggono persone reali. Non sono istruttori in carne e ossa e non ti vedono in acqua.",
                "Gli allenamenti sono preparati con l'aiuto dell'intelligenza artificiale. Il metodo e i contenuti tecnici si basano su fonti autorevoli, sono riassunti con parole nostre e sono controllati da un istruttore di nuoto.",
                "Puoi cambiare coach quando vuoi dal Profilo, senza perdere lo storico."
            ]
        ),
        SezioneInformazioni(
            id: "ia",
            titolo: "Come preparo i tuoi allenamenti",
            paragrafi: [
                "Se acconsenti, il nostro servizio usa un sistema di intelligenza artificiale di un fornitore esterno per preparare l'allenamento del giorno.",
                "Al servizio arrivano solo: il tuo livello, l'obiettivo, la lunghezza della vasca, il ritmo scelto, il coach scelto e come ti è sembrato l'ultimo allenamento (facile, giusto o duro).",
                "Non arrivano mai il tuo nome né i dati grezzi di Apple Salute.",
                "L'intelligenza artificiale non inventa gli esercizi: sceglie da un elenco di esercizi fissi e segue regole scritte da un istruttore di nuoto. L'app controlla ogni allenamento prima di mostrartelo. Se qualcosa non va, o manca la connessione, ricevi un allenamento fisso di riserva.",
                "Se preferisci di no, ricevi allenamenti fissi preparati dal nostro team. Puoi cambiare idea quando vuoi, in Profilo."
            ]
        ),
        SezioneInformazioni(
            id: "limiti",
            titolo: "I limiti",
            paragrafi: [
                "L'intelligenza artificiale può sbagliare. Un allenamento può non essere adatto a te, anche se segue le regole. Se un esercizio ti sembra troppo, accorcialo, rallenta o salta.",
                "I dati dell'orologio possono contenere errori. Distanze, calorie e altri numeri sono stime."
            ]
        ),
        SezioneInformazioni(
            id: "salute",
            titolo: "Salute e sicurezza",
            paragrafi: [
                "Swimwave non è un dispositivo medico e non sostituisce il tuo medico. Non fa diagnosi, non cura malattie e non dà consigli medici.",
                "Se hai dubbi sulla tua salute, parlane con il medico prima di nuotare. Vale anche se hai problemi di cuore, di respirazione, alle articolazioni, alla schiena o alle spalle, se sei in gravidanza o se non fai attività fisica da molto tempo.",
                "Gli allenamenti sono indicazioni, non obblighi. Se senti dolore, giramenti di testa, dolore al petto o mancanza di fiato anomala, fermati ed esci dall'acqua. Se il disturbo non passa, senti un medico. In caso di emergenza chiama il 112.",
                "Nuota sempre dove c'è un assistente bagnanti e rispetta il regolamento dell'impianto."
            ]
        ),
        SezioneInformazioni(
            id: "dati",
            titolo: "I tuoi dati, in breve",
            paragrafi: [
                "Ti chiediamo pochi dati: nome o soprannome, livello, obiettivo (facoltativo), lunghezza della vasca, ritmo e, se serve, quante volte a settimana vuoi nuotare. Non ti chiediamo sesso, peso, data di nascita né fastidi fisici.",
                "Servono per salutarti per nome, scegliere l'allenamento adatto a te e tenere il conto del tuo obiettivo della settimana.",
                "Non vendiamo i tuoi dati."
            ]
        ),
        SezioneInformazioni(
            id: "dove",
            titolo: "Dove restano i dati",
            paragrafi: [
                "Il tuo nome, il profilo, le nuotate e le risposte \"facile, giusta o dura\" restano sul tuo telefono.",
                "Solo se acconsenti all'intelligenza artificiale, il servizio riceve i dati elencati qui sopra per preparare l'allenamento.",
                "Apple Salute: solo se dai il permesso, l'app legge le tue nuotate (anche quelle di altre app e dell'orologio) per mostrartele, e salva gli allenamenti fatti con il Watch. I dati di Apple Salute non sono usati per pubblicità, marketing o profilazione, e non sono venduti. Puoi cambiare il permesso quando vuoi in Impostazioni, Salute, Accesso ai dati e dispositivi.",
                "Notifiche: solo se scegli il ritmo Spronami, un promemoria al giorno al massimo e solo se manca qualcosa al tuo obiettivo. Restano sul telefono e le puoi spegnere quando vuoi."
            ]
        ),
        SezioneInformazioni(
            id: "cancellare",
            titolo: "Come cancellare i tuoi dati",
            paragrafi: [
                "In Profilo, tocca \"Cancella i miei dati\": profilo, nuotate e scelte salvati dall'app vengono eliminati dal telefono. I dati in Apple Salute non vengono toccati: li gestisci da Salute.",
                "Per i diritti previsti dalla legge sulla privacy (sapere quali dati abbiamo, correggerli, cancellarli, riceverne una copia, opporti, revocare un consenso) scrivi a \(TestiInformazioni.contatto). Se pensi che i tuoi dati non siano trattati correttamente puoi anche fare reclamo al Garante per la protezione dei dati personali (garanteprivacy.it).",
                "L'informativa completa sulla privacy è qui: \(TestiInformazioni.indirizzoInformativa)."
            ]
        ),
        SezioneInformazioni(
            id: "adulti",
            titolo: "Solo per adulti",
            paragrafi: [
                "Per ora Swimwave è pensata per le persone maggiorenni. All'inizio ti abbiamo chiesto di confermare di avere almeno 18 anni."
            ]
        ),
        SezioneInformazioni(
            id: "contatti",
            titolo: "Domande o segnalazioni",
            paragrafi: [
                "Scrivici a \(TestiInformazioni.contatto)."
            ]
        )
    ]

    /// Versione dell'app, se disponibile (per esempio "0.1.0").
    static var versione: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
