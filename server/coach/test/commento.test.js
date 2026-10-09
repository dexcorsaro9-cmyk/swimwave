import { test } from "node:test";
import assert from "node:assert/strict";
import { richiestaMinima, creaModello } from "../src/modello.js";
import { creaServer } from "../src/server.js";
import { loadInstructions, scegliRiserva } from "../src/coach.js";
import { loadDrills } from "../src/validate.js";
import {
  commentoMinimo,
  pulisciCommento,
  loadIstruzioniCommento,
  creaModelloCommento,
  CAMPI_CONTEGGIO,
} from "../src/commento.js";

const base = { livello: "intermedio", obiettivo: "resistenza", vasca_metri: 25, ritmo: "regolare", coach: "donna" };
const mese = {
  nuotate: 12,
  metri: 14500,
  minuti: 540,
  metri_mese_precedente: 9000,
  settimane_di_fila: 3,
  facili: 2,
  giuste: 8,
  dure: 2,
  coach: "uomo",
};

async function chiedi(server, percorso, corpo, metodo = "POST") {
  await new Promise((r) => server.listen(0, r));
  const { port } = server.address();
  try {
    const r = await fetch(`http://127.0.0.1:${port}${percorso}`, {
      method: metodo,
      body: typeof corpo === "string" ? corpo : JSON.stringify(corpo),
    });
    return { stato: r.status, json: await r.json() };
  } finally {
    await new Promise((r) => server.close(r));
  }
}

// ---------- /allenamento: durata e obiettivo ----------

test("durata_min è ammessa solo se vale 20, 30, 45 o 60", () => {
  for (const d of [20, 30, 45, 60]) assert.equal(richiestaMinima({ ...base, durata_min: d }).durata_min, d);
  for (const d of [0, 10, 25, 59, 61, 90, -30, 30.5, "30", "45 minuti", null, true, [30], { a: 30 }, NaN, Infinity]) {
    assert.ok(!("durata_min" in richiestaMinima({ ...base, durata_min: d })), `scartato: ${JSON.stringify(d)}`);
  }
});

test("obiettivo è ammesso solo se tecnica, resistenza o dimagrimento", () => {
  for (const o of ["tecnica", "resistenza", "dimagrimento"]) assert.equal(richiestaMinima({ ...base, obiettivo: o }).obiettivo, o);
  for (const o of ["stareBene", "Tecnica", "velocità", "", 1, null, ["tecnica"]]) {
    assert.ok(!("obiettivo" in richiestaMinima({ ...base, obiettivo: o })), `scartato: ${JSON.stringify(o)}`);
  }
});

test("la durata valida arriva al modello dell'allenamento, quella non valida no", async () => {
  let messaggio;
  const fetchFinto = async (_url, opzioni) => {
    messaggio = JSON.parse(opzioni.body).messages[0].content;
    return { ok: true, json: async () => ({ content: [{ type: "tool_use", name: "proponi_allenamento", input: scegliRiserva(base) }] }) };
  };
  const model = creaModello({ apiKey: "k", fetchImpl: fetchFinto });
  await model({ istruzioni: "", richiesta: { ...base, durata_min: 45 }, drill: loadDrills() });
  assert.ok(messaggio.includes('"durata_min":45'));
  await model({ istruzioni: "", richiesta: { ...base, durata_min: 47 }, drill: loadDrills() });
  assert.ok(!messaggio.includes("durata_min"));
});

test("le istruzioni dell'allenamento spiegano come usare la durata richiesta", () => {
  const testo = loadInstructions({ coach: "uomo" });
  assert.match(testo, /durata_min/);
  assert.match(testo, /durata_stimata_min/);
  assert.match(testo, /tetti del livello/);
});

test("il server accetta durata e obiettivo scelti e passa al modello solo valori ammessi", async () => {
  let ricevuta;
  const server = creaServer({
    soloApprovati: false,
    model: async ({ richiesta }) => {
      ricevuta = richiesta;
      return JSON.stringify(scegliRiserva(base));
    },
  });
  const { stato, json } = await chiedi(server, "/allenamento", { ...base, durata_min: 30, obiettivo: "tecnica", nome: "Luca" });
  assert.equal(stato, 200);
  assert.equal(json.fonte, "coach");
  assert.equal(ricevuta.durata_min, 30);
  assert.equal(ricevuta.obiettivo, "tecnica");
  assert.ok(!("nome" in ricevuta));
});

// ---------- commentoMinimo ----------

test("commentoMinimo tiene solo i nove campi ammessi", () => {
  const r = commentoMinimo({ ...mese, nome: "Luca", email: "x@y.it", id: "abc", note: "ciao", riepilogo: "ultimo allenamento: dura" });
  assert.deepEqual(Object.keys(r).sort(), [...CAMPI_CONTEGGIO, "coach"].sort());
  assert.deepEqual(r, mese);
});

test("commentoMinimo: il coach è facoltativo ma, se c'è, deve essere uomo o donna", () => {
  const { coach, ...senza } = mese;
  assert.deepEqual(commentoMinimo(senza), senza);
  assert.equal(commentoMinimo({ ...mese, coach: "donna" }).coach, "donna");
  for (const c of ["robot", "Uomo", "", null, 1, ["uomo"]]) assert.equal(commentoMinimo({ ...mese, coach: c }), null, JSON.stringify(c));
});

test("commentoMinimo rifiuta valori fuori range, non interi o mancanti", () => {
  assert.ok(commentoMinimo({ ...mese, metri: 0 }));
  assert.ok(commentoMinimo({ ...mese, metri: 100000 }));
  for (const campo of CAMPI_CONTEGGIO) {
    for (const v of [-1, 100001, 1.5, "12", null, undefined, NaN, Infinity, true, [1], {}]) {
      assert.equal(commentoMinimo({ ...mese, [campo]: v }), null, `${campo}=${JSON.stringify(v)}`);
    }
    const { [campo]: _tolto, ...mancante } = mese;
    assert.equal(commentoMinimo(mancante), null, `manca ${campo}`);
  }
  for (const corpo of [null, [], "testo", 42, undefined]) assert.equal(commentoMinimo(corpo), null);
});

// ---------- istruzioni e uscita ----------

test("le istruzioni del commento seguono le regole di tono", () => {
  const testo = loadIstruzioniCommento({ coach: "donna" });
  assert.match(testo, /stile libero/);
  assert.match(testo, /Al massimo due frasi/);
  assert.match(testo, /Non colpevolizzare mai/);
  assert.match(testo, /Pamela/);
  assert.match(loadIstruzioniCommento({ coach: "uomo" }), /Antonio/);
  assert.ok(!/Tono del coach scelto/.test(loadIstruzioniCommento({})));
});

test("pulisciCommento toglie markdown e a capo, e accetta i numeri ricevuti", () => {
  const t = pulisciCommento("**Bel mese!**\n\nHai nuotato 12 volte, 14.500 metri in tutto.\n", mese);
  assert.equal(t, "Bel mese! Hai nuotato 12 volte, 14.500 metri in tutto.");
  assert.equal(pulisciCommento('"Bel lavoro, continua con calma."', mese), "Bel lavoro, continua con calma.");
  assert.equal(pulisciCommento("- Un mese tranquillo e costante.", mese), "Un mese tranquillo e costante.");
});

test("pulisciCommento scarta testi non validi", () => {
  const cattivi = [
    "x".repeat(301),
    "",
    "   \n  ",
    42,
    null,
    "Guarda su https://example.com per altro.",
    "Vai su www.esempio.it ora.",
    "Scrivimi a coach@esempio.it.",
    "Bel mese, il tuo crawl migliora.",
    "Uno. Due. Tre.",
    "Hai nuotato 13 volte questo mese.",
    "Quasi 14,5 chilometri in tutto.",
  ];
  for (const c of cattivi) assert.equal(pulisciCommento(c, mese), null, JSON.stringify(c).slice(0, 40));
});

// ---------- POST /commento ----------

test("/commento valido: il modello riceve solo i conteggi e il tono del coach, e la risposta è ripulita", async () => {
  let chiamata;
  const server = creaServer({
    modelloCommento: async (c) => {
      chiamata = c;
      return "Un mese solido: 12 nuotate, e si sente. Continua con calma.";
    },
  });
  const { stato, json } = await chiedi(server, "/commento", mese);
  assert.equal(stato, 200);
  assert.deepEqual(json, { testo: "Un mese solido: 12 nuotate, e si sente. Continua con calma." });
  assert.deepEqual(Object.keys(chiamata.dati).sort(), [...CAMPI_CONTEGGIO].sort());
  assert.equal(chiamata.dati.metri, 14500);
  assert.match(chiamata.istruzioni, /Antonio/);
});

test("/commento con campi extra: vengono scartati e non arrivano al modello", async () => {
  let chiamata;
  const server = creaServer({
    modelloCommento: async (c) => {
      chiamata = c;
      return "Bel mese, continua così.";
    },
  });
  const { stato, json } = await chiedi(server, "/commento", {
    ...mese,
    nome: "Luca Rossi",
    email: "luca@esempio.it",
    riepilogo: "ultimo allenamento: dura",
    livello: "avanzato",
  });
  assert.equal(stato, 200);
  assert.equal(json.testo, "Bel mese, continua così.");
  const visto = JSON.stringify(chiamata.dati);
  for (const vietato of ["Luca", "esempio.it", "riepilogo", "livello", "avanzato", "nome", "email"]) {
    assert.ok(!visto.includes(vietato), `non deve arrivare al modello: ${vietato}`);
  }
  assert.ok(!chiamata.istruzioni.includes("Luca"));
});

test("/commento con valori fuori range, campi mancanti o corpo rotto risponde 400 e non chiama il modello", async () => {
  let chiamate = 0;
  const mk = () => creaServer({ modelloCommento: async () => (chiamate++, "Bel mese.") });
  const casi = [
    { ...mese, nuotate: -1 },
    { ...mese, metri: 100001 },
    { ...mese, minuti: 1.5 },
    { ...mese, dure: "2" },
    { ...mese, coach: "robot" },
    (({ facili, ...resto }) => resto)(mese),
    {},
    [],
    "{rotto",
    "null",
    JSON.stringify({ ...mese, nome: "x".repeat(20 * 1024) }),
  ];
  for (const corpo of casi) {
    const { stato } = await chiedi(mk(), "/commento", corpo);
    assert.equal(stato, 400, JSON.stringify(corpo).slice(0, 60));
  }
  assert.equal(chiamate, 0);
});

test("/commento: uscita del modello troppo lunga o con URL dà testo null", async () => {
  const lungo = creaServer({ modelloCommento: async () => "Bel mese ".repeat(60) });
  assert.deepEqual((await chiedi(lungo, "/commento", mese)).json, { testo: null });
  const conUrl = creaServer({ modelloCommento: async () => "Bel mese, leggi di più su https://esempio.it/mese." });
  assert.deepEqual((await chiedi(conUrl, "/commento", mese)).json, { testo: null });
  const conNumeroNuovo = creaServer({ modelloCommento: async () => "Hai nuotato 5500 metri più del mese scorso." });
  assert.deepEqual((await chiedi(conNumeroNuovo, "/commento", mese)).json, { testo: null });
});

test("/commento: se il modello va in errore o non risponde con testo dà testo null", async () => {
  const errore = creaServer({
    modelloCommento: async () => {
      throw new Error("rete assente");
    },
  });
  const r = await chiedi(errore, "/commento", mese);
  assert.equal(r.stato, 200);
  assert.deepEqual(r.json, { testo: null });
  const vuoto = creaServer({ modelloCommento: async () => "   " });
  assert.deepEqual((await chiedi(vuoto, "/commento", mese)).json, { testo: null });
});

test("/commento senza modello risponde testo null", async () => {
  const r = await chiedi(creaServer(), "/commento", mese);
  assert.equal(r.stato, 200);
  assert.deepEqual(r.json, { testo: null });
  const soloAllenamento = creaServer({ model: async () => "{}" });
  assert.deepEqual((await chiedi(soloAllenamento, "/commento", mese)).json, { testo: null });
});

test("/commento accetta solo POST", async () => {
  assert.equal((await chiedi(creaServer(), "/commento", undefined, "GET")).stato, 404);
});

// ---------- creaModelloCommento ----------

test("creaModelloCommento senza chiave dà errore", () => {
  assert.throws(() => creaModelloCommento({}), /chiave/);
});

test("creaModelloCommento chiama l'API Messages con un system dedicato, senza strumenti e senza nome", async () => {
  let chiamata;
  const fetchFinto = async (url, opzioni) => {
    chiamata = { url, opzioni, corpo: JSON.parse(opzioni.body) };
    return { ok: true, json: async () => ({ content: [{ type: "text", text: "Bel mese." }] }) };
  };
  const model = creaModelloCommento({ apiKey: "chiave-finta", modelId: "modello-finto", fetchImpl: fetchFinto });
  const testo = await model({ istruzioni: "ISTRUZIONI DEL COMMENTO", dati: { ...mese, nome: "Luca" } });
  assert.equal(testo, "Bel mese.");
  assert.equal(chiamata.opzioni.headers["x-api-key"], "chiave-finta");
  assert.equal(chiamata.corpo.model, "modello-finto");
  assert.equal(chiamata.corpo.system, "ISTRUZIONI DEL COMMENTO");
  assert.ok(!("tools" in chiamata.corpo));
  const messaggio = chiamata.corpo.messages[0].content;
  assert.ok(!messaggio.includes("Luca"));
  assert.ok(!messaggio.includes("coach"));
  assert.ok(messaggio.includes('"metri":14500'));
});

test("creaModelloCommento segnala risposte d'errore e risposte senza testo", async () => {
  const errore = creaModelloCommento({ apiKey: "k", fetchImpl: async () => ({ ok: false, status: 529 }) });
  await assert.rejects(errore({ istruzioni: "", dati: mese }), /529/);
  const senza = creaModelloCommento({ apiKey: "k", fetchImpl: async () => ({ ok: true, json: async () => ({ content: [] }) }) });
  await assert.rejects(senza({ istruzioni: "", dati: mese }), /testo/);
});
