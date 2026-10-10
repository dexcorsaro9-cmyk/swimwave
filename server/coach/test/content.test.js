import { readdirSync } from "node:fs";
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

test("gli attrezzi dei drill sono nella lista chiusa", () => {
  const ammessi = new Set(["tavoletta", "pull_buoy", "pinne", "snorkel"]);
  for (const d of drillCompleti) {
    for (const campo of ["attrezzi", "attrezzi_facoltativi"]) {
      for (const a of d[campo] ?? []) assert.ok(ammessi.has(a), `${d.id}: ${a}`);
    }
  }
});

test("adatta gli allenamenti a ogni vasca ammessa", () => {
  for (const vasca of [16, 20, 33, 50]) {
    for (const voce of indice) {
      const w = adattaVasca(loadContent(`allenamenti/${voce.file}`), vasca);
      assert.equal(w.vasca_metri, vasca);
      const esito = validateWorkout(w, drills);
      assert.deepEqual(esito.errors, [], `${voce.file} @${vasca}`);
    }
  }
});

test("l'adattamento arrotonda al multiplo della vasca e non supera 2000 m", () => {
  const w = { vasca_metri: 25, blocchi: [{ serie: [{ distanza_m: 25 }, { distanza_m: 100 }, { distanza_m: 2000 }] }] };
  const a = adattaVasca(w, 33);
  assert.deepEqual(a.blocchi[0].serie.map((s) => s.distanza_m), [33, 99, 1980]);
  assert.equal(adattaVasca(w, 25), w);
});

test("il coach scelto cambia il tono ma non le regole", () => {
  const uomo = loadInstructions({ coach: "uomo" });
  const donna = loadInstructions({ coach: "donna" });
  const nessuno = loadInstructions({});
  assert.ok(uomo.includes("Antonio") && !uomo.includes("Pamela"));
  assert.ok(donna.includes("Pamela") && !donna.includes("Antonio"));
  assert.ok(!nessuno.includes("Tono del coach scelto"));
  for (const t of [uomo, donna, nessuno]) assert.ok(t.includes("Regole dell'istruttore"));
  assert.equal(loadPersona("sconosciuto"), null);
});

test("l'indice degli allenamenti elenca tutti i file, con fonti esistenti e dati coerenti", () => {
  const radice = loadContent("allenamenti/indice.json");
  const file = readdirSync(new URL("content/allenamenti/", new URL("../../../", import.meta.url))).filter((f) => f !== "indice.json");
  assert.deepEqual(indice.map((v) => v.file).sort(), file.sort());
  assert.ok(radice.fonti.length > 0 || radice.nota_fonti, "indice: senza fonti e senza nota");
  for (const f of radice.fonti) assert.ok(idFonti.has(f), `indice: fonte ${f}`);
  for (const voce of indice) {
    assert.ok(["bozza", "approvato"].includes(voce.stato), `${voce.file}: stato`);
    assert.ok(["principiante", "intermedio"].includes(voce.livello), `${voce.file}: livello`);
    assert.ok(voce.obiettivi.length > 0 && voce.obiettivi.every((o) => ["tecnica", "resistenza", "dimagrimento"].includes(o)), `${voce.file}: obiettivi`);
    assert.ok(voce.tappe.length > 0 && voce.tappe.every((t) => tappe.some((x) => x.id === t)), `${voce.file}: tappe`);
  }
});

test("ogni livello e obiettivo ha almeno due allenamenti di riserva", () => {
  for (const livello of ["principiante", "intermedio"]) {
    for (const obiettivo of ["tecnica", "resistenza", "dimagrimento"]) {
      const n = indice.filter((a) => a.livello === livello && a.obiettivi.includes(obiettivo)).length;
      assert.ok(n >= 2, `${livello}/${obiettivo}: solo ${n}`);
    }
  }
});

test("serie e recuperi rispettano le regole dell'istruttore", () => {
  for (const voce of indice) {
    const w = loadContent(`allenamenti/${voce.file}`);
    const [recMin, recMax] = voce.livello === "principiante" ? [20, 45] : [15, 30];
    for (const b of w.blocchi) {
      for (const s of b.serie) {
        if (voce.livello === "principiante") {
          const max = b.tipo === "riscaldamento" ? 100 : 50;
          assert.ok(s.distanza_m <= max, `${voce.file}: serie di ${s.distanza_m} m nel blocco ${b.tipo}`);
        }
        if (s.recupero_s !== undefined) {
          assert.ok(s.recupero_s >= recMin && s.recupero_s <= recMax, `${voce.file}: recupero ${s.recupero_s} s`);
        }
        if (b.tipo === "riscaldamento" || b.tipo === "defaticamento") {
          assert.ok(s.intensita === "facile", `${voce.file}: ${b.tipo} non facile`);
        }
      }
    }
  }
});

test("le tappe 8, 9 e 10 hanno almeno due drill e un errore", () => {
  for (const id of [8, 9, 10]) {
    const t = tappe.find((x) => x.id === id);
    assert.ok(t.drill.length >= 2, `tappa ${id}: drill`);
    assert.ok(t.errori.length >= 1, `tappa ${id}: errori`);
  }
});

test("nei testi non compare 'crawl'", () => {
  // gli id delle fonti (es. swim-wales-crawl) non si rinominano e non sono visibili all'utente
  const senzaFonti = ({ fonti, ...resto }) => resto;
  const testi = JSON.stringify([drillCompleti.map(senzaFonti), errori.map(senzaFonti), tappe.map(senzaFonti)]);
  assert.ok(!/crawl/i.test(testi));
  for (const voce of indice) assert.ok(!/crawl/i.test(JSON.stringify(loadContent(`allenamenti/${voce.file}`))), voce.file);
});
