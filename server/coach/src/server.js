import { createServer } from "node:http";
import { generateWorkout, scegliRiserva, adattaVasca } from "./coach.js";
import { loadDrills } from "./validate.js";
import { creaModello, richiestaMinima } from "./modello.js";

const LIMITE_CORPO = 16 * 1024;

function leggiCorpo(req) {
  return new Promise((resolve, reject) => {
    let dimensione = 0;
    const pezzi = [];
    req.on("data", (p) => {
      dimensione += p.length;
      if (dimensione > LIMITE_CORPO) {
        reject(new Error("corpo troppo grande"));
        req.destroy();
        return;
      }
      pezzi.push(p);
    });
    req.on("end", () => resolve(Buffer.concat(pezzi).toString("utf8")));
    req.on("error", reject);
  });
}

function rispondi(res, stato, oggetto) {
  res.writeHead(stato, { "content-type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(oggetto));
}

/**
 * Server HTTP minimo del coach. Non scrive nei log il contenuto delle richieste.
 * POST /allenamento  { livello, obiettivo, vasca_metri, ritmo, coach, ... } -> { workout, fonte }
 * Senza `model` (nessuna chiave) risponde sempre con l'allenamento di riserva.
 * Gli utenti vedono solo drill approvati (`soloApprovati`), in sviluppo si usano anche le bozze.
 */
export function creaServer({ model, soloApprovati = true } = {}) {
  return createServer(async (req, res) => {
    if (req.method === "GET" && req.url === "/salute") return rispondi(res, 200, { ok: true });
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
  const soloApprovati = process.env.SWIMWAVE_AMBIENTE !== "sviluppo";
  const porta = Number(process.env.PORT ?? 8787);
  creaServer({ model, soloApprovati }).listen(porta, () => {
    console.log(`Coach in ascolto sulla porta ${porta}${model ? "" : " (senza modello: solo riserva)"}`);
  });
}
