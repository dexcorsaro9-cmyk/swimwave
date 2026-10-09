import { readFileSync } from "node:fs";
import Ajv from "ajv";

const root = new URL("../../../", import.meta.url);
const schema = JSON.parse(readFileSync(new URL("docs/schema/workout.schema.json", root), "utf8"));
const ajv = new Ajv({ allErrors: true });
const checkSchema = ajv.compile(schema);

/** Legge un file JSON di content/. */
export function loadContent(nome) {
  return JSON.parse(readFileSync(new URL(`content/${nome}`, root), "utf8"));
}

/**
 * Id dei drill ammessi. Di default include le bozze (sviluppo e prova).
 * Nella versione per gli utenti usa `{ soloApprovati: true }`.
 */
export function loadDrills({ soloApprovati = false } = {}) {
  const file = loadContent("drills.json");
  return file.drill.filter((d) => !soloApprovati || d.stato === "approvato").map((d) => d.id);
}

/**
 * Controlla un allenamento: schema + regole che lo schema non esprime.
 * @returns {{ok: boolean, errors: string[]}}
 */
export function validateWorkout(workout, allowedDrills) {
  if (!checkSchema(workout)) {
    return {
      ok: false,
      errors: checkSchema.errors.map((e) => `${e.instancePath || "/"} ${e.message}`),
    };
  }
  const errors = [];
  for (const [i, blocco] of workout.blocchi.entries()) {
    for (const [j, serie] of blocco.serie.entries()) {
      const where = `blocchi[${i}].serie[${j}]`;
      if (serie.distanza_m % workout.vasca_metri !== 0) {
        errors.push(`${where}: distanza_m ${serie.distanza_m} non è multipla della vasca (${workout.vasca_metri} m)`);
      }
      if (serie.drill !== undefined && !allowedDrills.includes(serie.drill)) {
        errors.push(`${where}: drill "${serie.drill}" non è nella lista chiusa`);
      }
    }
  }
  return { ok: errors.length === 0, errors };
}
