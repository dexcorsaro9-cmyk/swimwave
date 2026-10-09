import { readFileSync } from "node:fs";
import { loadPersona } from "./coach.js";

const root = new URL("../../../", import.meta.url);

/**
 * Commento del coach sul mese. Al modello arrivano SOLO questi conteggi (interi da 0 a 100000)
 * e, per il tono, il coach scelto. Mai il nome, mai testo libero. Vedi docs/legale/informativa-privacy.md.
 */
export const CAMPI_CONTEGGIO = [
  "nuotate",
  "metri",
  "minuti",
  "metri_mese_precedente",
  "settimane_di_fila",
  "facili",
  "giuste",
  "dure",
];
export const MASSIMO_CONTEGGIO = 100000;
export const MASSIMO_CARATTERI = 300;

const conteggioValido = (v) => Number.isInteger(v) && v >= 0 && v <= MASSIMO_CONTEGGIO;

/**
 * Validazione strettissima del corpo di POST /commento.
 * - Tutti gli 8 conteggi sono obbligatori e devono essere interi tra 0 e 100000.
 * - `coach`, se presente, deve essere "uomo" o "donna" (se manca, tono neutro).
 * - Qualsiasi altro campo viene scartato.
 * @returns {object | null} i soli campi ammessi, oppure null se il corpo non è valido (il server risponde 400).
 */
export function commentoMinimo(corpo) {
  if (corpo === null || typeof corpo !== "object" || Array.isArray(corpo)) return null;
  const dati = {};
  for (const campo of CAMPI_CONTEGGIO) {
    if (!Object.hasOwn(corpo, campo) || !conteggioValido(corpo[campo])) return null;
    dati[campo] = corpo[campo];
  }
  if (Object.hasOwn(corpo, "coach")) {
    if (corpo.coach !== "uomo" && corpo.coach !== "donna") return null;
    dati.coach = corpo.coach;
  }
  return dati;
}

/** Istruzioni di sistema del commento: il prompt fisso più il tono del coach scelto (se c'è). */
export function loadIstruzioniCommento(dati = {}) {
  const base = readFileSync(new URL("server/coach/prompts/commento-mese.md", root), "utf8");
  const persona = loadPersona(dati.coach);
  const tono = persona
    ? `\n## Tono del coach scelto\n\nTi chiami ${persona.nome}. ${persona.tono}\nIl contenuto non cambia con il coach: cambia solo il modo di parlare.\n`
    : "";
  return `${base}${tono}`;
}

/** I numeri che il commento può citare: quelli ricevuti. */
function numeriAmmessi(dati) {
  return new Set(CAMPI_CONTEGGIO.map((c) => dati[c]));
}

/**
 * Ripulisce l'uscita del modello. Restituisce il testo pulito, oppure null se non è utilizzabile:
 * non è una stringa, è vuota, supera 300 caratteri, contiene un URL, la parola "crawl", più di due frasi
 * o un numero che non è tra quelli ricevuti. Il markdown viene tolto e gli a capo diventano spazi (una riga).
 */
export function pulisciCommento(uscita, dati) {
  if (typeof uscita !== "string") return null;
  let testo = uscita
    .replace(/[\r\n\t]+/g, " ")
    .replace(/^\s*[-*•]\s+/, "")
    .replace(/[*_~`#>]/g, "")
    .replace(/\s+/g, " ")
    .trim();
  // virgolette attorno a tutta la frase
  testo = testo.replace(/^["“”«»']+/, "").replace(/["“”«»']+$/, "").trim();
  if (testo.length === 0 || testo.length > MASSIMO_CARATTERI) return null;
  if (/https?:|www\.|\b[\w-]+\.(it|com|org|net|io|app|eu)\b|@\w/i.test(testo)) return null;
  if (/\bcrawl\b/i.test(testo)) return null;
  if ((testo.match(/[.!?…]+(?=\s|$)/g) ?? []).length > 2) return null;
  const ammessi = numeriAmmessi(dati);
  for (const token of testo.match(/\d+(?:[.,]\d+)*/g) ?? []) {
    // "3.500" con il punto delle migliaia vale 3500; qualsiasi altro decimale non è tra i numeri ricevuti.
    const intero = /^\d{1,3}(\.\d{3})+$/.test(token) ? token.replace(/\./g, "") : token;
    if (!/^\d+$/.test(intero) || !ammessi.has(Number(intero))) return null;
  }
  return testo;
}

/**
 * Genera il commento. `model` è una funzione async ({ istruzioni, dati }) => stringa.
 * Se il modello fallisce o l'uscita non è valida, restituisce null (l'app usa allora una frase fissa).
 */
export async function generaCommento(dati, { model } = {}) {
  if (!model) return null;
  try {
    const uscita = await model({ istruzioni: loadIstruzioniCommento(dati), dati: soloConteggi(dati) });
    return pulisciCommento(uscita, dati);
  } catch {
    return null;
  }
}

function soloConteggi(dati) {
  return Object.fromEntries(CAMPI_CONTEGGIO.map((c) => [c, dati[c]]));
}

/**
 * Crea la funzione `model` del commento: stessa API Messages e stessa chiave dell'allenamento,
 * ma con un `system` dedicato (prompts/commento-mese.md) e senza strumenti: risposta in testo.
 * @param {{apiKey: string, modelId?: string, fetchImpl?: typeof fetch, url?: string, timeoutMs?: number}} opzioni
 */
export function creaModelloCommento({
  apiKey,
  modelId = process.env.SWIMWAVE_MODEL ?? "claude-sonnet-5-5",
  fetchImpl = fetch,
  url = "https://api.anthropic.com/v1/messages",
  timeoutMs = 8000,
} = {}) {
  if (!apiKey) throw new Error("manca la chiave del modello");
  return async ({ istruzioni, dati }) => {
    const risposta = await fetchImpl(url, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      signal: AbortSignal.timeout(timeoutMs),
      body: JSON.stringify({
        model: modelId,
        max_tokens: 300,
        system: istruzioni,
        messages: [{ role: "user", content: `Numeri del mese (JSON): ${JSON.stringify(soloConteggi(dati))}` }],
      }),
    });
    if (!risposta.ok) throw new Error(`il servizio del modello ha risposto ${risposta.status}`);
    const corpo = await risposta.json();
    const testo = (corpo.content ?? []).filter((b) => b.type === "text" && typeof b.text === "string").map((b) => b.text).join(" ");
    if (!testo.trim()) throw new Error("il modello non ha risposto con un testo");
    return testo;
  };
}
