# Roadmap

## Versione 1 (iPhone + Apple Watch)

1. Definire il formato dell'allenamento (vedi WORKOUT_FORMAT.md)
2. Scrivere le istruzioni del coach IA per livello e obiettivo, con le regole dell'istruttore
3. App iPhone (SwiftUI): scheda dell'allenamento del giorno, piano, drill con testi e video, abbonamento con prova gratuita
4. Lettura delle nuotate da Apple Health (HealthKit)
5. App Apple Watch minima: serie in corso, timer del recupero con vibrazione, pulsante grande per avanzare, sessione di nuoto in piscina salvata su Apple Health
6. Test personale in acqua con TestFlight per 2-3 settimane, annotando cosa non funziona
7. Prova con 10-15 persone della piscina

Note tecniche da tenere presenti:
- Il simulatore non basta: per il nuoto serve l'orologio fisico.
- In acqua il touchscreen non è affidabile: pochi pulsanti fisici e avanzamento automatico.
- Il rilevamento di vasche e stile dell'orologio ha limiti: da misurare allenandosi.

## Versione 2

- Analisi video con IA (dopo la prova sui video reali)
- Analisi dettagliata dei dati (bracciate, passo, split) da Apple Health
- Android con Health Connect
- Lingue: inglese e spagnolo

## Più avanti

Wear OS e Garmin, solo se richiesti dagli utenti. Strava, acque libere, dryland, community.

## Cose da non fare

Copiare MySwimPro: contenuti, nomi dei piani e grafica sono loro. Si riproducono idee e funzioni, non materiali.
