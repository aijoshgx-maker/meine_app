"""Traegt Variantenbeschreibungen in die Fragendateien ein.

Aufruf:  python tool/varianten_setzen.py

Warum ein Werkzeug und kein json.dump ueber die ganze Datei: Ein
Rueckschreiben der geparsten Struktur formatiert jede Frage neu und macht aus
einer Ergaenzung einen Diff ueber hunderte Zeilen - unpruefbar. Dieses Skript
arbeitet zeilenweise und fuegt genau den neuen Block ein.

Wiederholt aufrufbar: Ein bereits vorhandener varianten-Block wird ersetzt.
Damit ist tool/varianten_daten.py die einzige Wahrheitsquelle - wer dort einen
Wertebereich aendert, laesst das Skript einfach nochmal laufen.
"""

import io
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from varianten_daten import KORREKTUREN, VARIANTEN  # noqa: E402

WURZEL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAGEN_DIR = os.path.join(WURZEL, "assets", "fragen")


def lies(pfad):
    with io.open(pfad, encoding="utf-8", newline="") as f:
        text = f.read()
    zeilenende = "\r\n" if "\r\n" in text else "\n"
    return text.split(zeilenende), zeilenende


def schreib(pfad, zeilen, zeilenende):
    with io.open(pfad, "w", encoding="utf-8", newline="") as f:
        f.write(zeilenende.join(zeilen))


def kompakt(wert, einzug, tiefe):
    """JSON mit einzeiligen Wertelisten.

    json.dumps(indent=2) setzt jede Zahl einer Liste auf eine eigene Zeile -
    aus zwoelf Widerstandswerten werden vierzehn Zeilen. Die Datei waere
    dadurch unlesbar, obwohl der Inhalt trivial ist.
    """
    pad = einzug + "  " * tiefe
    if isinstance(wert, list):
        if all(isinstance(w, (int, float)) and not isinstance(w, bool) for w in wert):
            return json.dumps(wert, ensure_ascii=False)
        teile = [kompakt(w, einzug, tiefe + 1) for w in wert]
        return "[\n" + ",\n".join(pad + "  " + t for t in teile) + "\n" + pad + "]"
    if isinstance(wert, dict):
        teile = []
        for k, v in wert.items():
            teile.append(
                "%s  %s: %s"
                % (pad, json.dumps(k, ensure_ascii=False), kompakt(v, einzug, tiefe + 1))
            )
        return "{\n" + ",\n".join(teile) + "\n" + pad + "}"
    return json.dumps(wert, ensure_ascii=False)


def block(varianten, einzug, trenner=": "):
    """Serialisiert den varianten-Block mit dem Einzug der uebrigen Felder."""
    text = '%s"varianten"%s%s' % (einzug, trenner, kompakt(varianten, einzug, 0))
    if trenner != ": ":
        text = text.replace('": ', '"%s' % trenner)
    return text.split("\n")


def grenzen(zeilen, frage_id):
    """(erste Zeile, Zeile nach der letzten) des Frageobjekts mit dieser id."""
    # Toleranter Vergleich: einzelne Dateien schreiben "id":  "..." mit
    # zwei Leerzeichen.
    marker = re.compile(r'"id"\s*:\s*"%s"' % re.escape(frage_id))
    start = next((i for i, z in enumerate(zeilen) if marker.search(z)), None)
    if start is None:
        raise KeyError(frage_id)

    einzug = zeilen[start][: len(zeilen[start]) - len(zeilen[start].lstrip())]

    # Der Einzug des Objekts kommt von seiner oeffnenden Klammer, nicht aus
    # einer Annahme ueber die Einrueckungstiefe: Eine Datei rueckt mit zwei
    # Leerzeichen ein, eine andere mit vier.
    objekt_einzug = ""
    for i in range(start - 1, -1, -1):
        if zeilen[i].strip() == "{":
            objekt_einzug = zeilen[i][: len(zeilen[i]) - len(zeilen[i].lstrip())]
            break

    for i in range(start + 1, len(zeilen)):
        rumpf = zeilen[i].rstrip()
        if rumpf in (objekt_einzug + "}", objekt_einzug + "},"):
            return start, i, einzug
    raise ValueError("Objektende zu %s nicht gefunden" % frage_id)


def entferne(zeilen, frage_id):
    """Nimmt einen vorhandenen varianten-Block wieder heraus."""
    start, ende, einzug = grenzen(zeilen, frage_id)
    kopf = next(
        (i for i in range(start, ende) if zeilen[i].strip().startswith('"varianten"')),
        None,
    )
    if kopf is None:
        return zeilen

    zeilen = zeilen[:kopf] + zeilen[ende:]
    davor = kopf - 1
    if zeilen[davor].rstrip().endswith(","):
        zeilen[davor] = zeilen[davor].rstrip()[:-1]
    return zeilen


def setze(zeilen, frage_id, varianten):
    """Fuegt den Block am Ende des Frageobjekts mit dieser id ein."""
    zeilen = entferne(zeilen, frage_id)
    start, ende, einzug = grenzen(zeilen, frage_id)

    letztes = ende - 1
    if not zeilen[letztes].rstrip().endswith(","):
        zeilen[letztes] = zeilen[letztes].rstrip() + ","

    # Manche Dateien setzen zwei Leerzeichen hinter den Doppelpunkt; der
    # neue Block soll nicht aus dem Bild fallen.
    trenner = ":  " if '":  "' in zeilen[start] else ": "
    return zeilen[:ende] + block(varianten, einzug, trenner) + zeilen[ende:]


def korrigiere():
    """Textkorrekturen, ohne die eine Vorlage ihr Original nicht trifft."""
    angewandt = 0
    for datei, alt, neu, grund in KORREKTUREN:
        pfad = os.path.join(FRAGEN_DIR, datei)
        with io.open(pfad, encoding="utf-8", newline="") as f:
            text = f.read()
        if alt not in text:
            continue  # schon angewandt
        with io.open(pfad, "w", encoding="utf-8", newline="") as f:
            f.write(text.replace(alt, neu, 1))
        print("  korrigiert: %s (%s)" % (datei, grund))
        angewandt += 1
    return angewandt


def main():
    korrigiere()

    nach_datei = {}
    for frage_id, eintrag in VARIANTEN.items():
        nach_datei.setdefault(eintrag["datei"], []).append(frage_id)

    gesamt = 0
    for datei, ids in sorted(nach_datei.items()):
        pfad = os.path.join(FRAGEN_DIR, datei)
        zeilen, zeilenende = lies(pfad)
        for frage_id in ids:
            zeilen = setze(zeilen, frage_id, VARIANTEN[frage_id]["varianten"])
        schreib(pfad, zeilen, zeilenende)
        gesamt += len(ids)
        print("%-48s %d" % (datei, len(ids)))

    print("\n%d Aufgaben mit Varianten" % gesamt)


if __name__ == "__main__":
    main()
