# -*- coding: utf-8 -*-
"""Gemeinsame Wertelisten fuer die Variantenbeschreibungen.

Die Bereiche sind bewusst eng: Widerstaende aus der E12-Reihe, Spannungen aus
dem, was in einer Werkstatt anliegt, Zaehnezahlen aus gaengigen
Getriebestufen. Eine Aufgabe mit 137 Ohm an 83 Volt waere zwar rechenbar,
aber keine, die jemand in der Pruefung sieht.
"""

E12 = [10, 15, 22, 33, 47, 68, 100, 150, 220, 330, 470, 680]
SPANNUNGEN = [12, 24, 48, 60, 110, 120, 230]
MOTORDREHZAHLEN = [700, 900, 960, 1000, 1400, 1450, 1500, 2800, 3000]

# Dateinamen, die mehrfach vorkommen.
AT = "auftragsanalyse_antriebstechnik.json"
ET = "auftragsanalyse_elektrotechnik.json"
ME = "auftragsanalyse_maschinenelemente.json"
TB = "auftragsanalyse_technische_berechnungen.json"
