# -*- coding: utf-8 -*-
"""Setzt Lueckentext- und Kurzantwort-Listen neu, wo das Formelzeichen vorne stand.

Aufruf:  python tool/tippbare_antworten_setzen.py

Die Loesungsansicht zeigt immer den ERSTEN Eintrag einer Antwortliste. Stand
dort ein Formelzeichen wie ε, η oder π, las man nach dem Aufdecken eine
Antwort, die sich auf einer deutschen Handytastatur gar nicht eintippen
laesst. Gemeldet an au-tb-003 (Hookesches Gesetz), gefunden an neun Stellen.

Regel: Vorne steht die ausgeschriebene, tippbare Fassung. Das Zeichen selbst
bleibt als weitere akzeptierte Schreibweise erhalten - wer eine Tastatur mit
griechischen Buchstaben hat, soll nicht bestraft werden.

Nicht angefasst: ft-mp-001 ("20°C"). Das Gradzeichen ist auf der
Handytastatur erreichbar.

Wiederholt aufrufbar - der vorhandene Block wird ersetzt.
"""

import io
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from varianten_setzen import FRAGEN_DIR, grenzen, kompakt, lies, schreib  # noqa: E402

# datei -> { frage_id: { feldname: neuer Wert } }
NEUE_ANTWORTEN = {
    "auftragsanalyse_antriebstechnik.json": {
        # η in der Formel M2 = M1 · i · {{1}}
        "au-at-012": {
            "luecken": [["eta", "Wirkungsgrad", "η"], ["38", "38,0"]]
        },
        "au-at-009": {
            "akzeptierteKurzantworten": [
                "omega = 2 * pi * n / 60",
                "2 pi n durch 60",
                "ω = 2π · n/60",
                "ω = (2π · n) / 60",
                "ω = 2πn/60",
            ]
        },
    },
    "auftragsanalyse_elektrotechnik.json": {
        "au-et-001": {
            "akzeptierteKurzantworten": [
                "U = R * I",
                "U = R · I",
                "U=RI",
                "U = R mal I",
            ]
        },
    },
    "auftragsanalyse_hydraulik.json": {
        # Ohne Malzeichen war hier gar keine Variante tippbar.
        "au-hy-004": {
            "luecken": [
                ["v * A", "v mal A", "A * v", "v · A", "A · v"],
                ["l/min", "Liter pro Minute", "cm³/s"],
            ]
        },
    },
    "auftragsanalyse_technische_berechnungen.json": {
        "au-tb-003": {
            "luecken": [
                ["Epsilon", "eps", "ε", "Dehnung"],
                ["Elastizitätsmodul", "E-Modul"],
                ["Dehnung", "Verformung", "relative Längenänderung"],
            ]
        },
        # Ohne Malzeichen war auch hier keine Variante tippbar.
        "au-tb-014": {
            "akzeptierteKurzantworten": [
                "Pa*s",
                "Pascalsekunde",
                "Pa·s",
                "Pascal·Sekunde",
                "mPa·s",
                "N·s/m²",
            ]
        },
    },
    "fertigungstechnik_fuegeverfahren.json": {
        "ft-fv-006": {
            "akzeptierteKurzantworten": [
                "5-10 fache Fügeteildicke",
                "l/d >= 5-10",
                "l/d ≥ 5-10",
                "mindestens 10 mm",
                "10-20 mm",
            ]
        },
    },
    "fertigungstechnik_schnittdaten.json": {
        # π steht in derselben Frage zweimal.
        "ft-sd-007": {
            "luecken": [["pi", "π"], ["m/min"], ["pi", "π"]]
        },
    },
}


def ersetze(zeilen, frage_id, feld, wert):
    """Tauscht genau den Block eines Feldes im Frageobjekt aus."""
    start, ende, einzug = grenzen(zeilen, frage_id)

    kopf = next(
        (
            i
            for i in range(start, ende)
            if zeilen[i].strip().startswith('"%s"' % feld)
        ),
        None,
    )
    if kopf is None:
        raise KeyError("%s hat kein Feld %s" % (frage_id, feld))

    # Ende des Blocks: die Zeile, auf der die Klammer wieder zugeht. Bei
    # einzeiligen Feldern ist das die Kopfzeile selbst.
    schluss = kopf
    if not zeilen[kopf].rstrip().endswith(("],", "]")):
        for i in range(kopf + 1, ende):
            if zeilen[i].rstrip() in (einzug + "],", einzug + "]"):
                schluss = i
                break
        else:
            raise ValueError("Blockende zu %s/%s nicht gefunden" % (frage_id, feld))

    komma = "," if zeilen[schluss].rstrip().endswith(",") else ""
    trenner = ":  " if '":  "' in zeilen[start] else ": "
    text = '%s"%s"%s%s%s' % (einzug, feld, trenner, kompakt(wert, einzug, 0), komma)
    return zeilen[:kopf] + text.split("\n") + zeilen[schluss + 1 :]


def main():
    gesamt = 0
    for datei, eintraege in sorted(NEUE_ANTWORTEN.items()):
        pfad = os.path.join(FRAGEN_DIR, datei)
        zeilen, zeilenende = lies(pfad)
        for frage_id, felder in sorted(eintraege.items()):
            for feld, wert in felder.items():
                zeilen = ersetze(zeilen, frage_id, feld, wert)
                gesamt += 1
        schreib(pfad, zeilen, zeilenende)
        print("%-48s %d" % (datei, len(eintraege)))

    print("\n%d Felder neu gesetzt" % gesamt)


if __name__ == "__main__":
    main()
