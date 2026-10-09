import { test } from "node:test";
import assert from "node:assert/strict";
import { validateWorkout, loadDrills, loadContent } from "../src/validate.js";
import { scegliRiserva, adattaVasca, loadFallback, loadInstructions, loadPersona } from "../src/coach.js";

const drills = loadDrills();
const drillCompleti = loadContent("drills.json").drill;
const errori = loadContent("errori-comuni.json").errori;
const tappe = loadContent("percorso.json").tappe;
const fonti = loadContent("fonti.json").fonti;
const indice = loadContent("allenamenti/indice.json").allenamenti;
const idFonti = new Set(fonti.map((f) => f.id));
const idDrill = new Set(drills);
const idErrori = new Set(errori.map((e) => e.id));

test("ogni allenamento di riserva è valido", () => {
  for (const voce of indice) {
    const w = loadContent(`allenamenti/${voce.file}`);
    const esito = validateWorkout(w, drills);
    assert.deepEqual(esito.errors, [], voce.file);
  }
});

test("gli allenamenti del principiante non usano intensità forte", () => {
  for (const voce of indice.filter((a) => a.livello === "principiante")) {
    const w = loadContent(`allenamenti/${voce.file}`);
    for (const b of w.blocchi) for (const s of b.serie) assert.notEqual(s.intensita, "forte", voce.file);
  }
});

test("ogni allenamento ha riscaldamento e defaticamento, e il principiante la tecnica", () => {
  for (const voce of indice) {
    const w = loadContent(`allenamenti/${voce.file}`);
    const tipi = w.blocchi.map((b) => b.tipo);
    assert.ok(tipi.includes("riscaldamento"), voce.file);
    assert.ok(tipi.includes("defaticamento"), voce.file);
    if (voce.livello === "principiante") assert.ok(tipi.includes("tecnica"), voce.file);
  }
});

test("i volumi del principiante e dell'intermedio restano nei limiti delle regole", () => {
  for (const voce of indice) {
    const w = loadContent(`allenamenti/${voce.file}`);
    const metri = w.blocchi.flatMap((b) => b.serie).reduce((t, s) => t + s.ripetizioni * s.distanza_m, 0);
    const [min, max] = voce.livello === "principiante" ? [250, 600] : [600, 1200];
    assert.ok(metri >= min && metri <= max, `${voce.file}: ${metri} m fuori da ${min}-${max}`);
  }
});

test("drill, errori e tappe si riferiscono solo a id esistenti", () => {
  for (const e of errori) for (const d of e.drill) assert.ok(idDrill.has(d), `errore ${e.id}: drill ${d}`);
  for (const t of tappe) {
    for (const d of t.drill) assert.ok(idDrill.has(d), `tappa ${t.id}: drill ${d}`);
    for (const e of t.errori) assert.ok(idErrori.has(e), `tappa ${t.id}: errore ${e}`);
  }
  for (const d of drillCompleti) assert.ok(d.tappa >= 1 && d.tappa <= tappe.length, `drill ${d.id}`);
});

test("ogni fonte citata esiste", () => {
  for (const voce of [...drillCompleti, ...errori, ...tappe]) {
    for (const f of voce.fonti ?? []) assert.ok(idFonti.has(f), `${voce.id ?? voce.nome}: fonte ${f}`);
  }
});

test("ogni contenuto tecnico ha stato e fonti, o una nota che spiega perché no", () => {
  for (const voce of [...drillCompleti, ...errori, ...tappe]) {
    assert.ok(["bozza", "approvato"].includes(voce.stato), `${voce.id}: stato`);
    assert.ok(Array.isArray(voce.fonti), `${voce.id}: fonti mancanti`);
    if (voce.fonti.length === 0) assert.ok(voce.nota_fonti, `${voce.id}: senza fonti e senza nota`);
  }
});

test("la riserva dipende dal livello e dall'obiettivo", () => {
  const p = scegliRiserva({ livello: "principiante", obiettivo: "resistenza" });
  assert.equal(p.titolo, "Costruire resistenza");
  const i = scegliRiserva({ livello: "intermedio", obiettivo: "resistenza" });
  assert.equal(i.titolo, "Resistenza intermedia");
  assert.equal(scegliRiserva({ livello: "avanzato", obiettivo: "resistenza" }).titolo, "Resistenza intermedia");
  assert.deepEqual(scegliRiserva({}), loadFallback());
});

test("senza un obiettivo noto usa gli allenamenti del livello", () => {
  const w = scegliRiserva({ livello: "principiante", obiettivo: "sconosciuto" });
  assert.equal(validateWorkout(w, drills).ok, true);
});

test("adatta gli allenamenti alla vasca da 50 m", () => {
  for (const voce of indice) {
    const w = adattaVasca(loadContent(`allenamenti/${voce.file}`), 50);
    assert.equal(w.vasca_metri, 50);
    const esito = validateWorkout(w, drills);
    assert.deepEqual(esito.errors, [], voce.file);
  }
});

test("il coach scelto cambia il tono ma non le regole", () => {
  const uomo = loadInstructions({ coach: "uomo" });
  const donna = loadInstructions({ coach: "donna" });
  const nessuno = loadInstructions({});
  assert.ok(uomo.includes("Marco") && !uomo.includes("Giulia"));
  assert.ok(donna.includes("Giulia") && !donna.includes("Marco"));
  assert.ok(!nessuno.includes("Tono del coach scelto"));
  for (const t of [uomo, donna, nessuno]) assert.ok(t.includes("Regole dell'istruttore"));
  assert.equal(loadPersona("sconosciuto"), null);
});
