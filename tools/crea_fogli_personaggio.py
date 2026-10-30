#!/usr/bin/env python3
"""Trasforma un video di Flow (sfondo verde) in un foglio di fotogrammi per l'app, come per lo squalo.

Uso: python3 -I tools/crea_fogli_personaggio.py <video.mp4> <id-personaggio> <posa> [--k N] [--andata-ritorno]
  posa: nuota | festa | concentrato | stanco | attesa
Passi: estrae i fotogrammi a 24 fps, toglie lo sfondo verde (chroma key) tenendo solo il personaggio, ritaglia sull'unione
dei riquadri, chiude il ciclo con una dissolvenza (primo e ultimo fotogramma si raccordano), riduce a 12 fps.
Scrive il foglio (9 colonne) per il Watch (128 px per fotogramma) in app/SwimwaveWatch/Assets.xcassets/<id>-<posa>-sheet.imageset,
e per l'iPhone (nuota 240 px, festa e stanco 200 px) in app/Swimwave/Assets.xcassets/. Il sorgente va in assets/personaggi/<id>/.
Stampa i dati da riportare in app/Swimwave/Tema/Personaggio.swift (fotogrammi e proporzione).
Serve: ffmpeg, numpy, Pillow, scipy.
"""
import argparse, glob, json, os, subprocess, sys, tempfile
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

RADICE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
LARGHEZZA_IPHONE = {"nuota": 240, "festa": 200, "stanco": 200}
LARGHEZZA_WATCH = 128
COLONNE = 9


def tinta_sfondo(a):
    """Tinta (in gradi) del verde di sfondo, misurata sui quattro angoli: ogni video di Flow ha un verde un po' diverso
    (verde puro per lo squalo, più verso il turchese per delfino e tartaruga) e un valore fisso lascerebbe puntini."""
    angoli = np.concatenate([a[:30, :30].reshape(-1, 3), a[:30, -30:].reshape(-1, 3),
                             a[-30:, :30].reshape(-1, 3), a[-30:, -30:].reshape(-1, 3)])
    r, g, b = np.median(angoli, axis=0)
    mx, mn = max(r, g, b), min(r, g, b)
    d = mx - mn + 1e-6
    if mx == g:
        return 60 * ((b - r) / d) + 120
    if mx == b:
        return 60 * ((r - g) / d) + 240
    return (60 * ((g - b) / d)) % 360


def chiave(path):
    """Toglie lo sfondo verde e tiene la sola figura più grande (scarta granelli e riflessi isolati).
    Si toglie solo ciò che ha la tinta e la forza del verde di sfondo: una pelle verde chiaro (tartaruga) resta."""
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(np.float32) / 255.0
    h0 = tinta_sfondo(a)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx, mn = a.max(-1), a.min(-1)
    d = mx - mn + 1e-6
    h = np.zeros_like(mx)
    h = np.where(mx == g, 60 * ((b - r) / d) + 120, h)
    h = np.where(mx == r, (60 * ((g - b) / d)) % 360, h)
    h = np.where(mx == b, 60 * ((r - g) / d) + 240, h)
    s = d / (mx + 1e-6)
    verde = np.clip(1 - np.abs(h - h0) / 30.0, 0, 1) * np.clip((s - 0.45) / 0.2, 0, 1)
    al = np.asarray(Image.fromarray(((1 - verde) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7)))
    etichette, n = ndimage.label(al > 128)
    if n == 0:
        raise SystemExit(f"{path}: nessuna figura trovata")
    grandezze = ndimage.sum(np.ones_like(etichette), etichette, index=range(1, n + 1))
    grande = int(np.argmax(grandezze)) + 1
    alfa = np.where(etichette == grande, al, 0).astype(np.uint8)
    rgb = np.asarray(im).astype(np.float32)
    sem = (alfa > 0) & (alfa < 250)
    gg = rgb[..., 1]
    lim = (rgb[..., 0] + rgb[..., 2]) / 2
    rgb[..., 1] = np.where(sem & (gg > lim), lim, gg)   # toglie l'alone verde sui bordi
    return Image.fromarray(np.dstack([rgb.astype(np.uint8), alfa]), "RGBA")


def trova_ciclo(F, minimo=40):
    """Per un movimento che si ripete: sceglie inizio e fine, a distanza di almeno `minimo` fotogrammi, dove le due immagini
    sono più simili (stessa posa della coda e delle pinne), e tiene solo i fotogrammi in mezzo."""
    piccoli = []
    for f in F:
        im = Image.fromarray(f.astype(np.uint8), "RGBA").resize((96, round(96 * f.shape[0] / f.shape[1])), Image.BILINEAR)
        x = np.asarray(im).astype(np.float32)
        x[..., :3] *= x[..., 3:] / 255
        piccoli.append(x)
    migliore = None
    for i in range(len(F)):
        for j in range(i + minimo, len(F)):
            d = float(np.abs(piccoli[i] - piccoli[j]).mean())
            if migliore is None or d < migliore[0]:
                migliore = (d, i, j)
    _, i, j = migliore
    print(f"ciclo: fotogrammi {i}-{j} (differenza {migliore[0]:.2f})", file=sys.stderr)
    return F[i:j]


def salva_foglio(frames_np, larghezza, percorso_png):
    H = round(larghezza * frames_np[0].shape[0] / frames_np[0].shape[1])
    frames = [Image.fromarray(f.astype(np.uint8), "RGBA").resize((larghezza, H), Image.LANCZOS) for f in frames_np]
    righe = (len(frames) + COLONNE - 1) // COLONNE
    foglio = Image.new("RGBA", (COLONNE * larghezza, righe * H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        foglio.paste(f, ((i % COLONNE) * larghezza, (i // COLONNE) * H))
    os.makedirs(os.path.dirname(percorso_png), exist_ok=True)
    foglio.save(percorso_png, optimize=True)
    return len(frames), larghezza, H, righe


def imageset(cartella_assets, nome, foglio_png):
    d = os.path.join(RADICE, cartella_assets, f"{nome}.imageset")
    os.makedirs(d, exist_ok=True)
    Image.open(foglio_png).save(os.path.join(d, f"{nome}.png"), optimize=True)
    with open(os.path.join(d, "Contents.json"), "w") as f:
        json.dump({"images": [{"filename": f"{nome}.png", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}, f, indent=2)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("video"); ap.add_argument("personaggio"); ap.add_argument("posa")
    ap.add_argument("--k", type=int, default=8, help="fotogrammi di dissolvenza per chiudere il ciclo")
    ap.add_argument("--andata-ritorno", action="store_true", help="il movimento va avanti e poi torna indietro (attesa)")
    ap.add_argument("--cerca-ciclo", action="store_true",
                    help="movimento periodico (nuoto): taglia il video tra i due fotogrammi più simili invece di usare tutto")
    a = ap.parse_args()
    K = a.k
    with tempfile.TemporaryDirectory() as lavoro:
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", a.video, "-an", "-vf", "fps=24",
                        os.path.join(lavoro, "f_%03d.png")], check=True)
        ritagliati = [chiave(p) for p in sorted(glob.glob(os.path.join(lavoro, "f_*.png")))]
    bbs = [im.getbbox() for im in ritagliati]
    box = (min(b[0] for b in bbs), min(b[1] for b in bbs), max(b[2] for b in bbs), max(b[3] for b in bbs))
    F = [np.asarray(im.crop(box)).astype(np.float32) for im in ritagliati]
    N = len(F)
    if a.cerca_ciclo:
        F = trova_ciclo(F)
        N = len(F)
    if a.andata_ritorno:
        seq = (F + F[N - 2:0:-1])[::3]
    else:
        out = F[K:N - K]
        for j in range(K):   # dissolvenza tra la fine e l'inizio, con alfa premoltiplicato
            t = (j + 1) / (K + 1)
            x, y = F[N - K + j], F[j]
            px, py = x.copy(), y.copy()
            px[..., :3] *= x[..., 3:] / 255
            py[..., :3] *= y[..., 3:] / 255
            m = px * (1 - t) + py * t
            al = m[..., 3:]
            m[..., :3] = np.where(al > 0, m[..., :3] / (al / 255 + 1e-6), 0)
            out.append(np.clip(m, 0, 255))
        seq = out[::2]
    nome = f"{a.personaggio}-{a.posa}-sheet"
    sorgente = os.path.join(RADICE, "assets", "personaggi", a.personaggio, f"{a.posa}-sheet.png")
    n, w, h, righe = salva_foglio(seq, LARGHEZZA_WATCH, sorgente)
    imageset("app/SwimwaveWatch/Assets.xcassets", nome, sorgente)
    dati = {"nome": nome, "watch": {"fotogrammi": n, "righe": righe, "w": w, "h": h}}
    if a.posa in LARGHEZZA_IPHONE:
        with tempfile.TemporaryDirectory() as t:
            p = os.path.join(t, "iphone.png")
            ni, wi, hi, ri = salva_foglio(seq, LARGHEZZA_IPHONE[a.posa], p)
            imageset("app/Swimwave/Assets.xcassets", nome, p)
        dati["iphone"] = {"fotogrammi": ni, "righe": ri, "w": wi, "h": hi, "proporzione": f"{hi}.0 / {wi}.0"}
    dati["ciclo_primo_ultimo"] = round(float(np.abs(seq[0] - seq[-1]).mean()), 2)
    print(json.dumps(dati))


if __name__ == "__main__":
    main()
