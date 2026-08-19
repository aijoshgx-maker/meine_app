# -*- coding: utf-8 -*-
"""Erzeugt die App-Icons.

Motiv: ein Stapel Lernkarten, bewusst themenneutral - die App ist ein
Framework fuer beliebige Lernthemen, das Icon soll also nicht auf
Industriemechanik festgelegt sein. Die vorderste Karte traegt einen Haken
als Zeichen fuer "gewusst".

Gerendert wird 4x so gross und dann herunterskaliert; das ergibt saubere
Kanten ohne eigene Antialiasing-Logik.
"""
from PIL import Image, ImageDraw

S = 1024          # Zielgroesse
F = 4             # Supersampling-Faktor
G = S * F

INDIGO       = (63, 81, 181)     # Colors.indigo, wie das App-Theme
INDIGO_TIEF  = (48, 63, 159)
KARTE_HELL   = (255, 255, 255)
KARTE_MITTE  = (222, 226, 245)
KARTE_HINTEN = (185, 193, 232)


def karte(zeichner, cx, cy, breite, hoehe, winkel_versatz, farbe, schatten=None):
    """Eine abgerundete Karte, leicht versetzt gestapelt."""
    x0 = cx - breite // 2 + winkel_versatz
    y0 = cy - hoehe // 2 - winkel_versatz
    kasten = [x0, y0, x0 + breite, y0 + hoehe]
    radius = int(48 * F)
    if schatten:
        versatz = int(10 * F)
        zeichner.rounded_rectangle(
            [kasten[0] + versatz, kasten[1] + versatz,
             kasten[2] + versatz, kasten[3] + versatz],
            radius=radius, fill=schatten)
    zeichner.rounded_rectangle(kasten, radius=radius, fill=farbe)
    return kasten


def motiv(hintergrund, mit_rand):
    """Zeichnet den Kartenstapel. mit_rand=True fuer das volle Icon."""
    bild = Image.new("RGBA", (G, G), hintergrund)
    d = ImageDraw.Draw(bild)

    # Beim adaptiven Icon muss das Motiv in der inneren Sicherheitszone
    # bleiben - Launcher beschneiden die Raender je nach Form.
    skala = 0.62 if not mit_rand else 0.72
    b = int(G * skala * 0.78)
    h = int(G * skala)
    cx = cy = G // 2

    karte(d, cx, cy, b, h, int(-46 * F), KARTE_HINTEN)
    karte(d, cx, cy, b, h, int(-23 * F), KARTE_MITTE)
    vorne = karte(d, cx, cy, b, h, 0, KARTE_HELL)

    # Haken auf der vordersten Karte
    hx0, hy0, hx1, hy1 = vorne
    mx = (hx0 + hx1) / 2
    my = (hy0 + hy1) / 2
    w = (hx1 - hx0)
    d.line(
        [(mx - w * 0.22, my + w * 0.02),
         (mx - w * 0.06, my + w * 0.18),
         (mx + w * 0.24, my - w * 0.20)],
        fill=INDIGO, width=int(34 * F), joint="curve")

    return bild.resize((S, S), Image.LANCZOS)


# 1. Volles App-Icon mit Hintergrund
voll = motiv(INDIGO, mit_rand=True)
voll.save("assets/branding/app_icon.png")

# 2. Vordergrund fuers adaptive Icon - transparent, Motiv kleiner
vorder = motiv((0, 0, 0, 0), mit_rand=False)
vorder.save("assets/branding/app_icon_foreground.png")

# 3. Store-Icon 512x512 (Play verlangt genau diese Groesse, ohne Alpha)
store = voll.convert("RGB").resize((512, 512), Image.LANCZOS)
store.save("assets/branding/play_store_icon_512.png")

# 4. Feature-Grafik 1024x500 fuer den Store-Eintrag
feature = Image.new("RGB", (1024, 500), INDIGO_TIEF)
fd = ImageDraw.Draw(feature)
for i in range(500):                       # dezenter Verlauf
    t = i / 500
    fd.line([(0, i), (1024, i)],
            fill=(int(48 + t * 15), int(63 + t * 18), int(159 + t * 22)))
sym = voll.resize((300, 300), Image.LANCZOS)
feature.paste(sym, (90, 100), sym)
feature.save("assets/branding/play_feature_graphic.png")

for p in ["app_icon.png", "app_icon_foreground.png",
          "play_store_icon_512.png", "play_feature_graphic.png"]:
    im = Image.open("assets/branding/" + p)
    print("%-32s %s %s" % (p, im.size, im.mode))
