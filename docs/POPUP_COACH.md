# Il coach nei popup

Niente mascotte: il coach scelto (Antonio o Pamela) è l'unico volto dell'app. Compare dentro i popup, con la testa in un avatar tondo accanto al messaggio. Le espressioni sono quelle delle sei immagini di `assets/coach/`; i ritagli sul volto sono in `assets/coach/avatar/` (512 × 512, da mascherare a cerchio nell'app).

## Anatomia del popup
- Avatar tondo del coach in alto o a sinistra, con il nome ("Antonio · coach virtuale").
- Messaggio breve, massimo due frasi, tono come in `content/tono.md`.
- Al massimo due pulsanti, mai colpevolizzanti ("Ci sono", "Più tardi").
- Si chiude con un tocco fuori o con "Più tardi". Non blocca mai l'uso dell'app.

## Quando compare e con quale espressione

| Momento | Espressione | Note |
|---|---|---|
| Scelta del coach all'avvio | benvenuto | Due schede affiancate, Antonio e Pamela, con la scritta che sono coach virtuali |
| Primo ingresso di ogni giornata | benvenuto | Solo se l'utente ha scelto un ritmo che prevede messaggi |
| Proposta di allenamento | incoraggiamento | Solo se l'utente ha scelto "Spronami" |
| Fine allenamento, chiede come è andata | incoraggiamento | Facile / giusta / dura |
| Risposta "dura" | dopo allenamento duro | Offre di alleggerire il prossimo |
| Tappa del percorso o obiettivo settimanale raggiunto | traguardo | Con il simbolo della tappa |
| Ritorno dopo una pausa | ripartenza | Nessun conteggio dei giorni saltati |
| L'utente segnala dolore | dolore | Suggerisce riposo, nessun pulsante di insistenza |

## Regole
- **Notifiche solo su richiesta.** Fuori dall'app il coach scrive soltanto se l'utente ha scelto "Spronami" (vedi `docs/EXPERIENCE.md`).
- **Un popup alla volta**, e non più di uno al giorno in modalità "Libero" e "Regolare".
- **Mai durante l'allenamento sull'Apple Watch**: lì solo numeri. Dopo l'allenamento, avatar piccolo e frase breve.
- **Sempre dichiarato**: il nome è seguito da "coach virtuale".
- **Accessibilità**: ogni avatar ha un'etichetta testuale (es. "Antonio, sorridente"); il messaggio non dipende dall'immagine.
- **Cambio coach**: dal Profilo, in qualsiasi momento, senza perdere lo storico.
