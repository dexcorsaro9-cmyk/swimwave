#!/usr/bin/env python3
"""Genera le icone originali di Swimwave (iPhone e Apple Watch), 1024x1024 PNG senza trasparenza.

Disegno: sfondo con sfumatura navy (#0B2545 -> #134074); una bracciata stilizzata di stile libero (il braccio che si alza e
rientra in acqua) il cui arco è anche la cresta di un'onda, in turquoise (#1FB5C9), con la mano (cerchio corallo #FF7A66)
che entra in acqua; sotto, due linee d'acqua. Solo forme geometriche semplici, niente testo e niente volti.

Uso (dalla cartella app/):  python3 tools/genera_icone.py [--anteprime cartella]
Richiede Pillow:  pip install pillow --break-system-packages
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

NAVY = (0x0B, 0x25, 0x45)
NAVY_CHIARO = (0x13, 0x40, 0x74)
TURCHESE = (0x1F, 0xB5, 0xC9)
CORALLO = (0xFF, 0x7A, 0x66)
TURCHESE_SCURO = (0x1A, 0x8F, 0xA8)

FINALE = 1024
SS = 4  # supercampionamento per bordi morbidi
G = FINALE * SS


def sfumatura() -> Image.Image:
    """Diagonale: navy in alto a sinistra, navy chiaro in basso a destra."""
    piccola = Image.new("RGB", (256, 256))
    px = piccola.load()
    for y in range(256):
        for x in range(256):
            t = (x + y) / 510.0
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(NAVY, NAVY_CHIARO))
    return piccola.resize((G, G), Image.BICUBIC)


def onda(draw: ImageDraw.ImageDraw, y0: float, ampiezza: float, spessore: float, colore, fase: float = 0.0):
    """Una linea ondulata con estremi tondi, da margine a margine dell'area sicura."""
    x_inizio, x_fine = 0.17 * G, 0.83 * G
    lunghezza = x_fine - x_inizio
    punti = []
    n = 400
    for i in range(n + 1):
        t = i / n
        x = x_inizio + lunghezza * t
        y = y0 + ampiezza * math.sin(2 * math.pi * (1.0 * t) + fase)
        punti.append((x, y))
    r = spessore / 2
    # Cerchi lungo il percorso: spessore uniforme e estremi tondi.
    for (x, y) in punti:
        draw.ellipse((x - r, y - r, x + r, y + r), fill=colore)


def goccia(draw: ImageDraw.ImageDraw, cx: float, cy: float, raggio: float, colore):
    """Goccia: cerchio con la punta in alto (vertice a 2 raggi sopra il centro, lati tangenti al cerchio)."""
    draw.ellipse((cx - raggio, cy - raggio, cx + raggio, cy + raggio), fill=colore)
    punta = (cx, cy - 2.0 * raggio)
    # Punti di tangenza: a 60 gradi dalla verticale vista dal centro (cos 60 = raggio / distanza = 1/2).
    t1 = (cx - raggio * math.sin(math.radians(60)), cy - raggio * math.cos(math.radians(60)))
    t2 = (cx + raggio * math.sin(math.radians(60)), cy - raggio * math.cos(math.radians(60)))
    draw.polygon([punta, t1, (cx, cy), t2], fill=colore)


def bezier(p0, p1, p2, p3, t):
    u = 1 - t
    return (u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
            u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1])


def tratto_affusolato(draw, punti, spessore_inizio, spessore_fine, colore):
    """Curva con spessore che cambia dolcemente dall'inizio alla fine, estremi tondi."""
    n = len(punti) - 1
    for i, (x, y) in enumerate(punti):
        t = i / n
        r = (spessore_inizio + (spessore_fine - spessore_inizio) * t) / 2
        draw.ellipse((x - r, y - r, x + r, y + r), fill=colore)


def disegna() -> Image.Image:
    img = sfumatura()
    d = ImageDraw.Draw(img)
    # Due linee d'acqua in basso (la seconda più sottile).
    onda(d, 0.80 * G, 0.030 * G, 0.060 * G, TURCHESE_SCURO, fase=0.4)
    onda(d, 0.90 * G, 0.026 * G, 0.045 * G, TURCHESE_SCURO, fase=1.3)
    # Il braccio, in un tratto solo: sale dal pelo dell'acqua a sinistra (spalla), culmina in un gomito alto spostato
    # a sinistra, ricade verso destra con l'avambraccio e finisce arricciandosi verso l'interno come il labbro di
    # un'onda che si frange: è insieme la bracciata e la cresta di un'onda. Più spesso alla spalla, sottile alla mano.
    segmenti = [
        ((0.12 * G, 0.74 * G), (0.14 * G, 0.40 * G), (0.24 * G, 0.15 * G), (0.46 * G, 0.15 * G)),
        ((0.46 * G, 0.15 * G), (0.70 * G, 0.15 * G), (0.88 * G, 0.34 * G), (0.84 * G, 0.52 * G)),
        ((0.84 * G, 0.52 * G), (0.81 * G, 0.64 * G), (0.66 * G, 0.64 * G), (0.62 * G, 0.53 * G)),
    ]
    punti = []
    for seg in segmenti:
        punti += [bezier(*seg, i / 300) for i in range(301)]
    tratto_affusolato(d, punti, 0.125 * G, 0.060 * G, TURCHESE)
    # La mano: goccia corallo alla punta del riccio, che sta per rientrare in acqua.
    mx, my = punti[-1]
    r = 0.05 * G
    d.ellipse((mx - r, my - r, mx + r, my + r), fill=CORALLO)
    return img.resize((FINALE, FINALE), Image.LANCZOS).convert("RGB")  # RGB: nessuna trasparenza


CONTENTS_IPHONE = {
    "images": [{"filename": "icona-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
    "info": {"author": "xcode", "version": 1},
}
CONTENTS_WATCH = {
    "images": [{"filename": "icona-1024.png", "idiom": "universal", "platform": "watchos", "size": "1024x1024"}],
    "info": {"author": "xcode", "version": 1},
}


def scrivi(cartella: Path, contenuto: dict, img: Image.Image):
    cartella.mkdir(parents=True, exist_ok=True)
    img.save(cartella / "icona-1024.png", "PNG")
    (cartella / "Contents.json").write_text(json.dumps(contenuto, indent=2) + "\n", encoding="utf-8")
    print("scritto", cartella)


def main():
    app = Path(__file__).resolve().parent.parent
    img = disegna()
    scrivi(app / "Swimwave/Assets.xcassets/AppIcon.appiconset", CONTENTS_IPHONE, img)
    scrivi(app / "SwimwaveWatch/Assets.xcassets/AppIcon.appiconset", CONTENTS_WATCH, img)
    if "--anteprime" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--anteprime") + 1])
        out.mkdir(parents=True, exist_ok=True)
        img.resize((60, 60), Image.LANCZOS).save(out / "60.png")
        img.resize((512, 512), Image.LANCZOS).save(out / "512.png")


if __name__ == "__main__":
    main()
