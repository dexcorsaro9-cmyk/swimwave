import { readFileSync } from "node:fs";

const root = new URL("../../../", import.meta.url);
const NOME_STRUMENTO = "proponi_allenamento";

/**
 * Dati che possono arrivare al modello. Tutto il resto viene scartato:
 * niente nome, niente identificativi. Vedi docs/legale/informativa-privacy.md.
 */
const CAMPI_AMMESSI = ["livello", "obiettivo", "tappa", "vasca_metri", "ritmo", "coach", "riepilogo"];

export function richiestaMinima(richiesta = {}) {
  return Object.fromEntries(CAMPI_AMMESSI.filter((c) => richiesta[c] !== undefined).map((c) => [c, richiesta[c]]));
}

function schemaPerIlModello() {
  const schema = JSON.parse(readFileSync(new URL("docs/schema/workout.schema.json", root), "utf8"));
  const { $schema, $id, ...resto } = schema;
  return resto;
}

/**
 * Crea la funzione `model` per `generateWorkout`, che chiama l'API Messages di Anthropic.
 * Il modello è costretto a rispondere con lo strumento `proponi_allenamento`, il cui
 * schema è quello dell'allenamento: l'uscita è già JSON strutturato. Il controllo
 * vero resta in `validateWorkout`.
 * @param {{apiKey: string, modelId?: string, fetchImpl?: typeof fetch, url?: string}} opzioni
 */
export function creaModello({
  apiKey,
  modelId = process.env.SWIMWAVE_MODEL ?? "claude-sonnet-5-5",
  fetchImpl = fetch,
  url = "https://api.anthropic.com/v1/messages",
} = {}) {
  if (!apiKey) throw new Error("manca la chiave del modello");
  const inputSchema = schemaPerIlModello();
  return async ({ istruzioni, richiesta, drill, erroriPrecedenti = [] }) => {
    const parti = [
      "Proponi l'allenamento di oggi per questo utente.",
      `Dati dell'utente (JSON): ${JSON.stringify(richiestaMinima(richiesta))}`,
      `Drill ammessi (lista chiusa, usa solo questi id): ${JSON.stringify(drill)}`,
    ];
    if (erroriPrecedenti.length > 0) {
      parti.push(`Il tentativo precedente non era valido. Correggi questi errori: ${JSON.stringify(erroriPrecedenti)}`);
    }
    const risposta = await fetchImpl(url, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: modelId,
        max_tokens: 2000,
        system: istruzioni,
        messages: [{ role: "user", content: parti.join("\n\n") }],
        tools: [
          {
            name: NOME_STRUMENTO,
            description: "Restituisce l'allenamento nel formato Swimwave.",
            input_schema: inputSchema,
          },
        ],
        tool_choice: { type: "tool", name: NOME_STRUMENTO },
      }),
    });
    if (!risposta.ok) throw new Error(`il servizio del modello ha risposto ${risposta.status}`);
    const corpo = await risposta.json();
    const blocco = (corpo.content ?? []).find((b) => b.type === "tool_use" && b.name === NOME_STRUMENTO);
    if (!blocco) throw new Error("il modello non ha usato lo strumento richiesto");
    return JSON.stringify(blocco.input);
  };
}
