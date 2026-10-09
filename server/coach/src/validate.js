import { readFileSync } from "node:fs";
import Ajv from "ajv";

const root = new URL("../../../", import.meta.url);
const schema = JSON.parse(readFileSync(new URL("docs/schema/workout.schema.json", root), "utf8"));
const ajv = new Ajv({ allErrors: true });
const checkSchema = ajv.compile(schema);

export function loadDrills() {
  const file = JSON.parse(readFileSync(new URL("content/drills.json", root), "utf8"));
  return file.drill;
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
