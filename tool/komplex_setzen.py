# -*- coding: utf-8 -*-
"""Erzeugt assets/fragen/komplexaufgaben.json aus tool/komplex_daten.py.

Aufruf:  python tool/komplex_setzen.py

Warum generiert und nicht von Hand geschrieben: Der Validator rechnet jede
variierende Aufgabe mit ihren Originalwerten nach und verlangt, dass genau
der gespeicherte Fragetext und genau der gespeicherte Loesungswert
herauskommt. Wer beides getrennt pflegt, laesst es frueher oder spaeter
auseinanderlaufen. Hier entsteht beides aus derselben Quelle.

Die Zahlformatierung bildet lib/core/quiz/frage_variante.dart nach - deutsche
Schreibweise, vier Nachkommastellen, keine nachlaufenden Nullen. Weicht sie
ab, meldet der Validator es sofort.
"""

import io
import json
import math
import os
import sys
from decimal import Decimal, ROUND_HALF_UP

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from komplex_daten import AUFGABEN  # noqa: E402

WURZEL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAGEN_DIR = os.path.join(WURZEL, "assets", "fragen")
ZIEL = os.path.join(FRAGEN_DIR, "komplexaufgaben.json")
MANIFEST = os.path.join(FRAGEN_DIR, "_manifest.json")
KURS = os.path.join(
    WURZEL, "assets", "kurse", "ap2-industriemechaniker", "kurs.json"
)

MAX_ZWISCHENSTELLEN = 4


def _round_dart(x):
    """Dart `.round()`: kaufmaennisch, halbe Werte vom Nullpunkt weg."""
    return math.floor(x + 0.5) if x >= 0 else math.ceil(x - 0.5)


def _fixed(wert, stellen):
    """Dart `toStringAsFixed` - halbe Werte aufrunden, nicht auf gerade."""
    q = Decimal(1).scaleb(-stellen)
    return str(Decimal(repr(wert)).quantize(q, rounding=ROUND_HALF_UP))


def deutsch(wert, max_stellen=MAX_ZWISCHENSTELLEN, nullen_behalten=False):
    text = _fixed(wert, max_stellen)
    if not nullen_behalten and "." in text:
        text = text.rstrip("0").rstrip(".")
    return text.replace(".", ",")


def runde(wert, stellen):
    faktor = 10 ** stellen
    return _round_dart(wert * faktor) / faktor


_FUNKTIONEN = {
    "sqrt": math.sqrt,
    "abs": abs,
    "round": lambda a: float(_round_dart(a)),
    "floor": lambda a: float(math.floor(a)),
    "ceil": lambda a: float(math.ceil(a)),
    "min": min,
    "max": max,
    "ln": math.log,
    "log": math.log10,
    "sin": lambda a: math.sin(math.radians(a)),
    "cos": lambda a: math.cos(math.radians(a)),
    "tan": lambda a: math.tan(math.radians(a)),
    "pi": math.pi,
}


def rechne(formel, werte):
    """Wertet einen Ausdruck der Formel-Engine aus (siehe core/formel)."""
    umfeld = dict(_FUNKTIONEN)
    umfeld.update({k: float(v) for k, v in werte.items()})
    return float(eval(formel.replace("^", "**"), {"__builtins__": {}}, umfeld))


def _platzhalter(vorlage, texte, aufgabe_id):
    import re

    def ersetze(treffer):
        name = treffer.group(1)
        if name not in texte:
            raise KeyError("%s: Platzhalter {%s} ist nicht belegt" % (aufgabe_id, name))
        return texte[name]

    return re.sub(r"\{([A-Za-z_][A-Za-z0-9_]*)\}", ersetze, vorlage)


def baue(a):
    """Rechnet eine Aufgabe mit ihren Originalwerten durch."""
    stellen = a.get("stellen", {})
    zahlen = {k: float(v) for k, v in a["original"].items()}
    texte = {
        k: deutsch(float(v), stellen.get(k, MAX_ZWISCHENSTELLEN), k in stellen)
        for k, v in a["original"].items()
    }

    for name, formel in a["zwischen"]:
        wert = rechne(formel, zahlen)
        zahlen[name] = wert
        texte[name] = deutsch(
            wert, stellen.get(name, MAX_ZWISCHENSTELLEN), name in stellen
        )

    roh = rechne(a["loesung"], zahlen)
    loesungswert = runde(roh, a["rundung"])
    zahlen["loesung"] = loesungswert
    texte["loesung"] = deutsch(loesungswert, a["rundung"])

    # Toleranz wie _toleranz() in frage_variante.dart.
    spielraum = 0.5 / 10 ** a["rundung"]
    prozent = a.get("toleranzProzent")
    if prozent is None:
        toleranz = a.get("toleranz", spielraum)
    else:
        toleranz = runde(
            max(abs(loesungswert) * prozent / 100, spielraum), a["rundung"] + 4
        )

    varianten = {
        "variablen": a["variablen"],
        "original": a["original"],
        "zwischen": {name: formel for name, formel in a["zwischen"]},
        "frage": a["frage"],
        "loesung": a["loesung"],
        "rundung": a["rundung"],
        "erklaerung": a["erklaerung"],
        "workedExample": a["workedExample"],
    }
    if prozent is not None:
        varianten["toleranzProzent"] = prozent
    if stellen:
        varianten["stellen"] = stellen

    return {
        "id": a["id"],
        "bereich": a["bereich"],
        "kategorie": a["kategorie"],
        "typ": "rechnung",
        "frage": _platzhalter(a["frage"], texte, a["id"]),
        "optionen": [],
        "richtigeIndizes": [],
        "reihenfolge": [],
        "paare": [],
        "luecken": [],
        "loesungswert": loesungswert,
        "einheit": a["einheit"],
        "toleranz": toleranz,
        "akzeptierteKurzantworten": [],
        "wahr": None,
        "erklaerung": _platzhalter(a["erklaerung"], texte, a["id"]),
        "selfExplanationPrompt": None,
        "bildAsset": None,
        "workedExample": _platzhalter(a["workedExample"], texte, a["id"]),
        "schwierigkeit": a["schwierigkeit"],
        "pruefung": None,
        "pruefungReihenfolge": None,
        "komplex": True,
        "varianten": varianten,
    }


def main():
    ids = [a["id"] for a in AUFGABEN]
    if len(set(ids)) != len(ids):
        raise ValueError("doppelte ids in komplex_daten.py")

    fragen = [baue(a) for a in AUFGABEN]

    with io.open(ZIEL, "w", encoding="utf-8", newline="\n") as f:
        json.dump(fragen, f, ensure_ascii=False, indent=2)
        f.write("\n")

    name = os.path.basename(ZIEL)

    # Was die App wirklich liest, ist die Dateiliste im Kurs - _manifest.json
    # kennt nur das Werkzeug. Beide werden gepflegt, damit sie nicht
    # auseinanderlaufen.
    with io.open(KURS, encoding="utf-8", newline="") as f:
        kurs_text = f.read()
    if '"%s"' % name not in kurs_text:
        anker = '  "fragenDateien": [\n'
        if anker not in kurs_text:
            raise ValueError("fragenDateien nicht in kurs.json gefunden")
        kurs_text = kurs_text.replace(anker, anker + '    "%s",\n' % name, 1)
        with io.open(KURS, "w", encoding="utf-8", newline="") as f:
            f.write(kurs_text)
        print("kurs.json ergaenzt um %s" % name)

    with io.open(MANIFEST, encoding="utf-8") as f:
        manifest = json.load(f)
    if name not in manifest:
        manifest.append(name)
        with io.open(MANIFEST, "w", encoding="utf-8", newline="\n") as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print("Manifest ergaenzt um %s" % name)

    print("%d Komplexaufgaben geschrieben:" % len(fragen))
    for fr in fragen:
        einheit = fr["einheit"] or ""
        print(
            "  %-6s %-34s %s %s"
            % (fr["id"], fr["kategorie"], fr["loesungswert"], einheit)
        )


if __name__ == "__main__":
    main()
