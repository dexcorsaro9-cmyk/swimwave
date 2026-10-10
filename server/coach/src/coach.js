import { readFileSync } from "node:fs";
import { validateWorkout, loadDrills, loadContent } from "./validate.js";

const root = new URL("../../../", import.meta.url);

/** Allenamento fisso usato quando la richiesta non indica un livello. */
export function loadFallback() {
  return JSON.parse(readFileSync(new URL("fixtures/workouts/resistenza-base.json", root), "utf8"));
}

/** Persona del coach scelto ("uomo" o "donna"). Se manca o è sconosciuta, nessuna persona. */
export function loadPersona(id) {
  return loadContent("coach.json").coach.find((c) => c.id === id) ?? null;
}

export function loadInstructions(richiesta = {}) {
  const base = readFileSync(new URL("server/coach/prompts/istruzioni-coach.md", root), "utf8");
  const regole = readFileSync(new URL("server/coach/prompts/regole-istruttore.md", root), "utf8");
  const persona = loadPersona(richiesta.coach);
  const tono = persona
    ? `\n\n## Tono del coach scelto\n\nTi chiami ${persona.nome}. ${persona.tono}\nIl contenuto tecnico non cambia con il coach: cambia solo il modo di parlare.\n`
    : "";
  return `${base}\n${regole}${tono}`;
}

/**
 * Adatta un allenamento alla vasca dell'utente (16, 20, 25, 33, 50 m o altra misura) arrotondando
 * ogni distanza al multiplo della vasca più vicino (minimo una vasca, massimo 2000 m).
 */
export function adattaVasca(workout, vascaMetri) {
  if (!Number.isInteger(vascaMetri) || vascaMetri <= 0 || workout.vasca_metri === vascaMetri) return workout;
  return {
    ...workout,
    vasca_metri: vascaMetri,
    blocchi: workout.blocchi.map((b) => ({
      ...b,
      serie: b.serie.map((s) => {
        let multipli = Math.max(1, Math.round(s.distanza_m / vascaMetri));
        if (multipli * vascaMetri > 2000) multipli = Math.floor(2000 / vascaMetri);
        return { ...s, distanza_m: multipli * vascaMetri };
      }),
    })),
  };
}

/**
 * Sceglie un allenamento di riserva in base a livello e obiettivo.
 * Senza livello restituisce l'esempio di WORKOUT_FORMAT.md.
 * `scelta` (facoltativo) è un numero usato per variare tra gli allenamenti adatti.
 */
export function scegliRiserva({ livello, obiettivo, vasca_metri } = {}, scelta = 0) {
  if (!livello) return loadFallback();
  const indice = loadContent("allenamenti/indice.json").allenamenti;
  const gruppo = livello === "principiante" ? "principiante" : "intermedio";
  const delLivello = indice.filter((a) => a.livello === gruppo);
  const perObiettivo = delLivello.filter((a) => a.obiettivi.includes(obiettivo));
  const candidati = perObiettivo.length > 0 ? perObiettivo : delLivello;
  const voce = candidati[((scelta % candidati.length) + candidati.length) % candidati.length];
  const workout = loadContent(`allenamenti/${voce.file}`);
  return adattaVasca(workout, vasca_metri);
}

/**
 * Genera un allenamento.
 * `model` è una funzione async ({ istruzioni, richiesta, drill, erroriPrecedenti }) => stringa JSON.
 * Prova fino a `tentativi` volte; se nessuna risposta è valida, usa la riserva.
 * @returns {{workout: object, fonte: "coach" | "riserva", errori: string[]}}
 */
export async function generateWorkout(richiesta, { model, tentativi = 2, drills = loadDrills(), fallback } = {}) {
  const istruzioni = loadInstructions(richiesta);
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
  return { workout: fallback ?? scegliRiserva(richiesta), fonte: "riserva", errori: erroriPrecedenti };
}
