# -*- coding: utf-8 -*-
"""Sammelstelle der Variantenbeschreibungen.

Die Beschreibungen selbst liegen nach Fachgebiet getrennt (varianten_au,
varianten_tb, ...), damit eine Datei nicht auf tausend Zeilen anwaechst und
ein Diff lesbar bleibt. Hier werden sie nur zusammengelegt.

Aufgetragen werden sie mit  python tool/varianten_setzen.py
"""

import varianten_au
import varianten_ft
import varianten_hy
import varianten_tb

MODULE = [varianten_au, varianten_ft, varianten_hy, varianten_tb]

VARIANTEN = {}
KORREKTUREN = []

for modul in MODULE:
    doppelt = set(VARIANTEN) & set(modul.VARIANTEN)
    if doppelt:
        raise ValueError("Frage doppelt beschrieben: %s" % ", ".join(sorted(doppelt)))
    VARIANTEN.update(modul.VARIANTEN)
    KORREKTUREN.extend(getattr(modul, "KORREKTUREN", []))
