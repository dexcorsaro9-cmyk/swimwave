# Formato dell'allenamento

Struttura condivisa: il coach IA produce sempre questo formato, l'iPhone lo mostra come scheda, l'Apple Watch lo percorre serie dopo serie.

```json
{
  "titolo": "Resistenza base",
  "vasca_metri": 25,
  "durata_stimata_min": 45,
  "blocchi": [
    { "tipo": "riscaldamento", "serie": [
      { "ripetizioni": 1, "distanza_m": 200, "stile": "libero", "intensita": "facile" } ] },
    { "tipo": "tecnica", "serie": [
      { "ripetizioni": 4, "distanza_m": 50, "stile": "libero", "drill": "catch-up", "recupero_s": 15 } ] },
    { "tipo": "principale", "serie": [
      { "ripetizioni": 4, "distanza_m": 100, "stile": "libero", "intensita": "media", "recupero_s": 20 } ] },
    { "tipo": "defaticamento", "serie": [
      { "ripetizioni": 1, "distanza_m": 100, "stile": "misto", "intensita": "facile" } ] }
  ]
}
```

## Campi

- `tipo` del blocco: riscaldamento, tecnica, principale, defaticamento
- `stile`: libero, dorso, rana, delfino, misto
- `intensita`: facile, media, forte (da confermare: scala a parole o numerica)
- `drill`: voce di una lista chiusa di esercizi scelti dall'istruttore (lista da compilare)
- `recupero_s`: secondi di recupero tra una ripetizione e la successiva

## Punti aperti

Intensità, lista dei drill e numero di livelli vanno chiusi con l'istruttore (vedi PRODUCT.md).
