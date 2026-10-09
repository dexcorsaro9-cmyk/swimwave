#!/usr/bin/env python3
"""Genera le icone originali di Swimwave (iPhone e Apple Watch), 1024x1024 PNG senza trasparenza.

Disegno: sfondo con sfumatura navy (#0B2545 -> #134074), tre onde turchese (#1FB5C9) e una goccia corallo (#FF7A66).
Solo forme geometriche semplici, niente testo e niente persone.

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


def disegna() -> Image.Image:
    img = sfumatura()
    d = ImageDraw.Draw(img)
    spessore = 0.085 * G
    amp = 0.045 * G
    # Tre onde, sfasate un poco una dall'altra.
    onda(d, 0.54 * G, amp, spessore, TURCHESE, fase=0.0)
    onda(d, 0.68 * G, amp, spessore, TURCHESE, fase=0.6)
    onda(d, 0.82 * G, amp, spessore, TURCHESE, fase=1.2)
    # Goccia corallo in alto, al centro.
    goccia(d, 0.5 * G, 0.325 * G, 0.085 * G, CORALLO)
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
