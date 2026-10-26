#!/usr/bin/env python3
"""Genera gli allenamenti di riserva (content/allenamenti/*-gNN.json) a partire da modelli per livello e tipologia.

Le regole sono quelle dell'istruttore già nei test (server/coach/test/content.test.js):
- principiante: serie da 25-50 m (riscaldamento fino a 100 m), recuperi 20-45 s, solo intensità facile e media, tipologie A1 e A2, 250-600 m;
- intermedio: recuperi 15-30 s (30-60 s nella serie principale di B2 e C1), 'forte' solo in B2 e C1, 600-1200 m;
- riscaldamento e defaticamento sempre 'facile'; distanze multiple di 25 m; solo drill approvati e fatti per le distanze (niente esercizi al bordo).
Volumi, recuperi e durate sono nostre proposte prudenti senza fonte diretta (vedi content/allenamenti/indice.json).
I file già scritti a mano (senza '-g') non vengono toccati. Rilanciare lo script rigenera sempre gli stessi file (seme fisso).
Uso: python3 tools/genera_allenamenti.py
"""
import json, os, random, glob, re

RADICE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CARTELLA = os.path.join(RADICE, "content", "allenamenti")

drills = {d["id"]: d for d in json.load(open(os.path.join(RADICE, "content", "drills.json")))["drill"]}
NOMI = {k: v["nome"] for k, v in drills.items()}
TAPPA = {k: v["tappa"] for k, v in drills.items()}

# drill che si possono fare nuotando una distanza, con lo stile giusto (esclusi quelli al bordo e "sul dorso" della rana)
STILE = {
    "scivolamento-a-freccia": "libero", "battuta-con-tavoletta": "libero", "battuta-con-un-braccio-teso": "libero",
    "catch-up": "libero", "un-braccio-solo": "libero", "dita-sull-acqua": "libero",
    "respirazione-laterale-con-tavoletta": "libero", "sei-colpi-e-cambio": "libero", "nuotata-con-pull-buoy": "libero",
    "battuta-sul-dorso": "dorso", "dorso-un-braccio-alla-volta": "dorso", "dorso-battuta-con-rotazione": "dorso",
    "rana-con-scivolo": "rana", "rana-due-gambate-una-bracciata": "rana", "rana-corpo-verso-le-mani": "rana",
    "onda-del-delfino": "delfino", "delfino-un-braccio-alla-volta": "delfino",
}
STILE = {k: v for k, v in STILE.items() if k in drills}

RITMO = {  # secondi ogni 100 m
    "principiante": {"facile": 200, "media": 175},
    "intermedio": {"facile": 150, "media": 130, "forte": 112},
}
LIMITI = {  # (metri min, metri max, minuti min, minuti max)
    "principiante": (300, 600, 20, 35),
    "intermedio": (700, 1200, 30, 55),
}

def serie(r, d, stile="libero", i=None, rec=None, drill=None):
    s = {"ripetizioni": r, "distanza_m": d, "stile": stile}
    if i: s["intensita"] = i
    if drill: s["drill"] = drill
    if rec is not None: s["recupero_s"] = rec
    return s

def metri(blocchi):
    return sum(s["ripetizioni"] * s["distanza_m"] for b in blocchi for s in b["serie"])

def durata(liv, blocchi):
    nuoto = rec = 0
    for b in blocchi:
        for s in b["serie"]:
            nuoto += s["ripetizioni"] * s["distanza_m"] / 100 * RITMO[liv][s.get("intensita", "facile")]
            rec += s["ripetizioni"] * s.get("recupero_s", 0)
    return round((nuoto + rec) * 1.15 / 60 + 6)

def scelte_drill(rng, liv, tappa):
    if liv == "principiante":
        pool = [k for k in STILE if STILE[k] == "libero" and max(3, tappa - 3) <= TAPPA[k] <= tappa + 1 and k != "nuotata-con-pull-buoy"]
        if tappa >= 7: pool += ["nuotata-con-pull-buoy"]
    else:
        pool = [k for k in STILE if TAPPA[k] >= 4]
    return rng.sample(pool, 2) if len(pool) >= 2 else pool

# ----------------------------------------------------------------------------- principiante
def principiante(rng, tip):
    tappa = rng.choice([3, 4, 5, 5, 6, 6, 7])
    wu = rng.choice([[serie(2, 50, i="facile", rec=rng.choice([20, 25]))], [serie(1, 100, i="facile")], [serie(4, 25, i="facile", rec=20)]])
    cd = rng.choice([[serie(1, 50, i="facile")], [serie(2, 25, i="facile", rec=20)], [serie(1, 25, i="facile")]])
    d1, d2 = scelte_drill(rng, "principiante", tappa)
    tec = [serie(rng.choice([4, 4, 6]), 25, STILE[d1], drill=d1, rec=rng.choice([20, 25, 30]))]
    if rng.random() < 0.5:
        tec.append(serie(rng.choice([2, 4]), 25, STILE[d2], drill=d2, rec=rng.choice([20, 25, 30])))
    if tip == "a1":
        princ = rng.choice([
            [serie(rng.choice([6, 8, 10]), 25, i="facile", rec=rng.choice([25, 30, 35]))],
            [serie(rng.choice([4, 5, 6]), 50, i="facile", rec=rng.choice([30, 35, 40]))],
            [serie(4, 50, i="facile", rec=35), serie(rng.choice([4, 6]), 25, i="facile", rec=25)],
        ])
        titolo = f"Tecnica: {NOMI[d1].lower()}" + (f" e {NOMI[d2].lower()}" if len(tec) == 2 else "")
        obiettivi = ["tecnica"]
    else:
        princ = rng.choice([
            [serie(rng.choice([5, 6, 7, 8]), 50, i="media", rec=rng.choice([25, 30, 35]))],
            [serie(rng.choice([8, 10, 12]), 25, i="media", rec=rng.choice([20, 25]))],
            [serie(4, 50, i="media", rec=30), serie(rng.choice([4, 6]), 25, i="facile", rec=25)],
            [serie(rng.choice([3, 4]), 50, i="facile", rec=30), serie(rng.choice([3, 4]), 50, i="media", rec=35)],
        ])
        titolo = "Fondo facile: " + " + ".join(f"{s['ripetizioni']} × {s['distanza_m']} m" for s in princ)
        obiettivi = ["resistenza", "dimagrimento"]
    blocchi = [{"tipo": "riscaldamento", "serie": wu}, {"tipo": "tecnica", "serie": tec},
               {"tipo": "principale", "serie": princ}, {"tipo": "defaticamento", "serie": cd}]
    return titolo, blocchi, obiettivi, [tappa]

# ----------------------------------------------------------------------------- intermedio
def intermedio(rng, tip):
    wu = rng.choice([[serie(1, 200, i="facile")], [serie(4, 50, i="facile", rec=15)], [serie(2, 100, i="facile", rec=15)],
                     [serie(6, 50, i="facile", rec=rng.choice([15, 20]))], [serie(1, 300, i="facile")]])
    cd = rng.choice([[serie(1, 100, i="facile")], [serie(1, 200, i="facile")], [serie(2, 50, i="facile", rec=15)], [serie(2, 100, i="facile", rec=15)]])
    d1, d2 = scelte_drill(rng, "intermedio", 8)
    tec = [serie(rng.choice([4, 6]), rng.choice([25, 50]), STILE[d1], drill=d1, rec=rng.choice([15, 20, 25]))]
    if rng.random() < 0.55:
        tec.append(serie(rng.choice([4, 6]), 25, STILE[d2], drill=d2, rec=rng.choice([15, 20, 25])))
    if tip == "a1":
        princ = rng.choice([
            [serie(rng.choice([6, 8, 10]), 50, i="facile", rec=rng.choice([15, 20]))],
            [serie(rng.choice([4, 5, 6]), 100, i="facile", rec=rng.choice([15, 20, 25]))],
            [serie(rng.choice([3, 4]), 150, i="facile", rec=20)],
            [serie(4, 100, "misto", i="facile", rec=20)],
        ])
        titolo = f"Tecnica: {NOMI[d1].lower()}" + (f" e {NOMI[d2].lower()}" if len(tec) == 2 else "")
        obiettivi = ["tecnica"]
    elif tip == "a2":
        princ = rng.choice([
            [serie(3, 200, i="media", rec=rng.choice([20, 25, 30]))], [serie(4, 150, i="media", rec=rng.choice([20, 25]))],
            [serie(2, 300, i="media", rec=rng.choice([25, 30]))], [serie(rng.choice([6, 8]), 100, i="media", rec=rng.choice([15, 20]))],
            [serie(4, 100, "misto", i="media", rec=20), serie(2, 200, i="media", rec=25)],
            [serie(1, 400, i="media"), serie(2, 100, i="media", rec=20)],
        ])
        titolo = "Fondo: " + " + ".join(f"{s['ripetizioni']} × {s['distanza_m']} m" for s in princ)
        obiettivi = ["resistenza", "dimagrimento"]
    elif tip == "b1":
        princ = rng.choice([
            [serie(rng.choice([5, 6, 8]), 100, i="media", rec=rng.choice([15, 20]))], [serie(4, 200, i="media", rec=rng.choice([20, 25]))],
            [serie(3, 300, i="media", rec=rng.choice([25, 30]))], [serie(rng.choice([8, 10]), 50, i="media", rec=15)],
            [serie(3, 150, i="media", rec=20), serie(3, 100, i="media", rec=15)],
            [serie(2, 200, i="media", rec=20), serie(4, 100, i="media", rec=15)],
        ])
        titolo = "Soglia: " + " + ".join(f"{s['ripetizioni']} × {s['distanza_m']} m" for s in princ)
        obiettivi = ["resistenza", "dimagrimento"]
    elif tip == "b2":
        princ = rng.choice([
            [serie(rng.choice([6, 8]), 100, i="forte", rec=rng.choice([40, 45, 50, 60]))],
            [serie(rng.choice([10, 12]), 50, i="forte", rec=rng.choice([30, 35, 40]))],
            [serie(rng.choice([6, 8]), 75, i="forte", rec=rng.choice([40, 45]))],
            [serie(5, 150, i="forte", rec=60)],
            [serie(4, 100, i="forte", rec=45), serie(6, 50, i="forte", rec=30)],
        ])
        titolo = "Ritmo alto: " + " + ".join(f"{s['ripetizioni']} × {s['distanza_m']} m" for s in princ)
        obiettivi = ["resistenza"]
    else:  # c1
        princ = rng.choice([
            [serie(4, 100, i="forte", rec=60)], [serie(rng.choice([6, 8]), 50, i="forte", rec=rng.choice([40, 45, 50]))],
            [serie(6, 50, i="forte", rec=40), serie(2, 100, i="forte", rec=60)], [serie(3, 150, i="forte", rec=60)],
            [serie(4, 75, i="forte", rec=60)], [serie(2, 100, i="forte", rec=60), serie(4, 50, i="forte", rec=45)],
        ])
        titolo = "Tolleranza: " + " + ".join(f"{s['ripetizioni']} × {s['distanza_m']} m" for s in princ)
        obiettivi = ["resistenza"]
    blocchi = [{"tipo": "riscaldamento", "serie": wu}, {"tipo": "tecnica", "serie": tec},
               {"tipo": "principale", "serie": princ}, {"tipo": "defaticamento", "serie": cd}]
    usati = [s["drill"] for s in tec]
    tappe = sorted({TAPPA[d] for d in usati}) if tip == "a1" else [7]
    return titolo, blocchi, obiettivi, tappe

def valido(liv, tip, blocchi):
    m = metri(blocchi); mn, mx, tmin, tmax = LIMITI[liv]
    if not (mn <= m <= mx): return False
    if not (tmin <= durata(liv, blocchi) <= tmax): return False
    alta = tip in ("b2", "c1")
    for b in blocchi:
        for s in b["serie"]:
            if liv == "principiante":
                if s["distanza_m"] > (100 if b["tipo"] == "riscaldamento" else 50): return False
                if "recupero_s" in s and not (20 <= s["recupero_s"] <= 45): return False
                if s.get("intensita") == "forte": return False
            else:
                lo, hi = (30, 60) if alta and b["tipo"] == "principale" else (15, 30)
                if "recupero_s" in s and not (lo <= s["recupero_s"] <= hi): return False
                if s.get("intensita") == "forte" and not (alta and b["tipo"] == "principale"): return False
            if b["tipo"] in ("riscaldamento", "defaticamento") and s.get("intensita") != "facile": return False
            if s["distanza_m"] % 25: return False
    if alta and not any(s.get("intensita") == "forte" for b in blocchi for s in b["serie"]): return False
    return True

CELLE = [("principiante", "a1", 36), ("principiante", "a2", 36), ("intermedio", "a1", 28), ("intermedio", "a2", 28),
         ("intermedio", "b1", 28), ("intermedio", "b2", 28), ("intermedio", "c1", 28)]

def main():
    for f in glob.glob(os.path.join(CARTELLA, "*-g[0-9][0-9].json")):
        os.remove(f)
    indice_path = os.path.join(CARTELLA, "indice.json")
    indice = json.load(open(indice_path))
    indice["allenamenti"] = [v for v in indice["allenamenti"] if not re.search(r"-g\d\d\.json$", v["file"])]
    titoli = {(v["livello"], json.load(open(os.path.join(CARTELLA, v["file"])))["titolo"]) for v in indice["allenamenti"]}
    nuovi = []
    for liv, tip, quanti in CELLE:
        rng = random.Random(f"swimwave-{liv}-{tip}")
        firme, n, tentativi = set(), 0, 0
        while n < quanti and tentativi < 20000:
            tentativi += 1
            titolo, blocchi, obiettivi, tappe = (principiante if liv == "principiante" else intermedio)(rng, tip)
            if not valido(liv, tip, blocchi): continue
            firma = json.dumps(blocchi, sort_keys=True)
            if firma in firme: continue
            firme.add(firma)
            n += 1
            m = metri(blocchi)
            base, k = titolo, 1
            while (liv, titolo) in titoli:
                k += 1
                titolo = f"{base} · {m} m" if k == 2 else f"{base} · {m} m · variante {k - 1}"
            titoli.add((liv, titolo))
            w = {"titolo": titolo[:80], "vasca_metri": 25, "durata_stimata_min": durata(liv, blocchi), "blocchi": blocchi}
            nome = f"{liv}-{tip}-g{n:02d}.json"
            with open(os.path.join(CARTELLA, nome), "w") as f:
                json.dump(w, f, ensure_ascii=False, indent=2); f.write("\n")
            nuovi.append({"file": nome, "livello": liv, "obiettivi": obiettivi, "tappe": tappe, "tipologia": tip, "stato": "approvato"})
        if n < quanti: raise SystemExit(f"{liv}/{tip}: solo {n} allenamenti su {quanti}")
    indice["allenamenti"] += nuovi
    indice["nota_generati"] = ("Gli allenamenti '*-gNN.json' sono generati da tools/genera_allenamenti.py con le stesse regole dei test. "
                               "Volumi, recuperi, intensità e durate sono nostre proposte prudenti, senza una fonte diretta.")
    testa = {k: v for k, v in indice.items() if k != "allenamenti"}
    out = "{\n" + ",\n".join(f"  {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}" for k, v in testa.items()) + ',\n  "allenamenti": [\n'
    out += ",\n".join("    " + json.dumps(v, ensure_ascii=False) for v in indice["allenamenti"]) + "\n  ]\n}\n"
    json.loads(out)
    open(indice_path, "w").write(out)
    print(len(nuovi), "allenamenti generati; totale", len(indice["allenamenti"]))

main()
