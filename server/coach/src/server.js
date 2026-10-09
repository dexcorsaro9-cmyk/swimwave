import { createServer } from "node:http";
import { generateWorkout, scegliRiserva, adattaVasca } from "./coach.js";
import { loadDrills } from "./validate.js";
import { creaModello, richiestaMinima } from "./modello.js";
import { commentoMinimo, generaCommento, creaModelloCommento } from "./commento.js";

const LIMITE_CORPO = 16 * 1024;

function leggiCorpo(req) {
  return new Promise((resolve, reject) => {
    let dimensione = 0;
    const pezzi = [];
    req.on("data", (p) => {
      dimensione += p.length;
      if (dimensione > LIMITE_CORPO) {
        // Non si interrompe la connessione: il 400 deve arrivare. Il resto del corpo si scarta e la connessione si chiude dopo la risposta.
        pezzi.length = 0;
        reject(new Error("corpo troppo grande"));
        req.removeAllListeners("data");
        req.resume();
        return;
      }
      pezzi.push(p);
    });
    req.on("end", () => resolve(Buffer.concat(pezzi).toString("utf8")));
    req.on("error", reject);
  });
}

function rispondi(res, stato, oggetto) {
  const intestazioni = { "content-type": "application/json; charset=utf-8" };
  if (stato === 400) intestazioni.connection = "close";
  res.writeHead(stato, intestazioni);
  res.end(JSON.stringify(oggetto));
}

/**
 * Server HTTP minimo del coach. Non scrive nei log il contenuto delle richieste.
 * POST /allenamento  { livello, obiettivo, vasca_metri, ritmo, coach, durata_min, ... } -> { workout, fonte }
 * Senza `model` (nessuna chiave) risponde sempre con l'allenamento di riserva.
 * POST /commento  { nuotate, metri, minuti, metri_mese_precedente, settimane_di_fila, facili, giuste, dure, coach? } -> { testo }
 * `testo` è null se manca `modelloCommento` (nessuna chiave), se il modello fallisce o se l'uscita non è valida.
 * Un corpo non valido (campo mancante, fuori range, JSON rotto, troppo grande) riceve 400.
 * Gli utenti vedono solo drill approvati (`soloApprovati`), in sviluppo si usano anche le bozze.
 */
export function creaServer({ model, modelloCommento, soloApprovati = true } = {}) {
  return createServer(async (req, res) => {
    if (req.method === "GET" && req.url === "/salute") return rispondi(res, 200, { ok: true });
    if (req.method === "POST" && req.url === "/commento") {
      let dati;
      try {
        dati = commentoMinimo(JSON.parse(await leggiCorpo(req)));
      } catch {
        return rispondi(res, 400, { errore: "richiesta non valida" });
      }
      if (!dati) return rispondi(res, 400, { errore: "richiesta non valida" });
      const testo = await generaCommento(dati, { model: modelloCommento });
      return rispondi(res, 200, { testo });
    }
    if (req.method !== "POST" || req.url !== "/allenamento") return rispondi(res, 404, { errore: "non trovato" });
    let richiesta;
    try {
      richiesta = richiestaMinima(JSON.parse(await leggiCorpo(req)));
    } catch {
      return rispondi(res, 400, { errore: "richiesta non valida" });
    }
    const drills = loadDrills({ soloApprovati });
    if (!model) {
      return rispondi(res, 200, { workout: scegliRiserva(richiesta), fonte: "riserva" });
    }
    const { workout, fonte } = await generateWorkout(richiesta, { model, drills, fallback: scegliRiserva(richiesta) });
    return rispondi(res, 200, { workout: adattaVasca(workout, richiesta.vasca_metri), fonte });
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  const model = apiKey ? creaModello({ apiKey }) : undefined;
  const modelloCommento = apiKey ? creaModelloCommento({ apiKey }) : undefined;
  const soloApprovati = process.env.SWIMWAVE_AMBIENTE !== "sviluppo";
  const porta = Number(process.env.PORT ?? 8787);
  creaServer({ model, modelloCommento, soloApprovati }).listen(porta, () => {
    console.log(`Coach in ascolto sulla porta ${porta}${model ? "" : " (senza modello: solo riserva)"}`);
  });
}
