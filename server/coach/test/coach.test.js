import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { validateWorkout, loadDrills } from "../src/validate.js";
import { generateWorkout, loadFallback } from "../src/coach.js";

const fixture = () =>
  JSON.parse(readFileSync(new URL("../../../fixtures/workouts/resistenza-base.json", import.meta.url), "utf8"));
const drills = loadDrills();

test("l'esempio di WORKOUT_FORMAT.md è valido", () => {
  const esito = validateWorkout(fixture(), drills);
  assert.deepEqual(esito.errors, []);
  assert.equal(esito.ok, true);
});

test("rifiuta un drill fuori dalla lista chiusa", () => {
  const w = fixture();
  w.blocchi[1].serie[0].drill = "esercizio-inventato";
  const esito = validateWorkout(w, drills);
  assert.equal(esito.ok, false);
  assert.match(esito.errors[0], /lista chiusa/);
});

test("rifiuta distanze non multiple della vasca", () => {
  const w = fixture();
  w.blocchi[2].serie[0].distanza_m = 110;
  const esito = validateWorkout(w, drills);
  assert.equal(esito.ok, false);
  assert.match(esito.errors[0], /multipla della vasca/);
});

test("rifiuta campi fuori schema", () => {
  const w = fixture();
  w.blocchi[0].tipo = "sprint";
  assert.equal(validateWorkout(w, drills).ok, false);
  const w2 = fixture();
  w2.extra = 1;
  assert.equal(validateWorkout(w2, drills).ok, false);
});

test("il coach accetta una risposta valida", async () => {
  const esito = await generateWorkout({}, { model: async () => JSON.stringify(fixture()) });
  assert.equal(esito.fonte, "coach");
});

test("il coach riprova dopo una risposta non valida", async () => {
  let chiamate = 0;
  const model = async ({ erroriPrecedenti }) => {
    chiamate++;
    if (chiamate === 1) return "non è json";
    assert.ok(erroriPrecedenti.length > 0);
    return JSON.stringify(fixture());
  };
  const esito = await generateWorkout({}, { model });
  assert.equal(chiamate, 2);
  assert.equal(esito.fonte, "coach");
});

test("senza risposte valide usa l'allenamento di riserva", async () => {
  const bad = fixture();
  bad.blocchi[1].serie[0].drill = "inventato";
  const esito = await generateWorkout({}, { model: async () => JSON.stringify(bad) });
  assert.equal(esito.fonte, "riserva");
  assert.deepEqual(esito.workout, loadFallback());
  assert.ok(esito.errori.length > 0);
});

test("se il modello va in errore usa la riserva", async () => {
  const esito = await generateWorkout({}, {
    model: async () => {
      throw new Error("rete assente");
    },
  });
  assert.equal(esito.fonte, "riserva");
});
