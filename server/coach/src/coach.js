import { readFileSync } from "node:fs";
import { validateWorkout, loadDrills } from "./validate.js";

const root = new URL("../../../", import.meta.url);

/** Allenamento fisso di riserva. Per ora uno solo, da ampliare con l'istruttore. */
export function loadFallback() {
  return JSON.parse(readFileSync(new URL("fixtures/workouts/resistenza-base.json", root), "utf8"));
}

export function loadInstructions() {
  return readFileSync(new URL("server/coach/prompts/istruzioni-coach.md", root), "utf8");
}

/**
 * Genera un allenamento.
 * `model` è una funzione async ({ istruzioni, richiesta, drill, erroriPrecedenti }) => stringa JSON.
 * Prova fino a `tentativi` volte; se nessuna risposta è valida, usa la riserva.
 * @returns {{workout: object, fonte: "coach" | "riserva", errori: string[]}}
 */
export async function generateWorkout(richiesta, { model, tentativi = 2, drills = loadDrills(), fallback = loadFallback() } = {}) {
  const istruzioni = loadInstructions();
  let erroriPrecedenti = [];
  for (let n = 0; n < tentativi; n++) {
    try {
      const raw = await model({ istruzioni, richiesta, drill: drills, erroriPrecedenti });
      const workout = JSON.parse(raw);
      const esito = validateWorkout(workout, drills);
      if (esito.ok) return { workout, fonte: "coach", errori: [] };
      erroriPrecedenti = esito.errors;
    } catch (e) {
      erroriPrecedenti = [`risposta non valida: ${e.message}`];
    }
  }
  return { workout: fallback, fonte: "riserva", errori: erroriPrecedenti };
}
