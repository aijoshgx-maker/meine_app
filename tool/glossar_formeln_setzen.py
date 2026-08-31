# -*- coding: utf-8 -*-
"""Traegt die Formeln ins Glossar ein und ergaenzt fehlende Begriffe.

Aufruf:  python tool/glossar_formeln_setzen.py

Die Formeln standen bisher im Fliesstext des Feldes `mehr` - mitten in einem
Absatz, aufgeklappt hinter einem Ausklapper. Wer rechnet, braucht sie
zusammen und sofort. Als eigenes Feld `formeln` kann die Tippfunktion sie
sammeln und als Liste zeigen.

ROHFORM, nicht umgestellt: Bei einer Frage nach der Drehzahl steht hier
`vc = π · d · n / 1000` und nicht `n = vc · 1000 / (π · d)`. Das Umstellen
ist der Lernstoff; wer es abnimmt, nimmt die Aufgabe weg.

Wiederholt aufrufbar - vorhandene `formeln` werden ersetzt, vorhandene
Eintraege behalten ihren uebrigen Text.
"""

import io
import json
import os

WURZEL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GLOSSAR = os.path.join(WURZEL, "assets", "fragen", "_glossar.json")

# begriff -> Formeln in Rohform
FORMELN = {
    "ω (Winkelgeschwindigkeit)": [
        "ω = 2 · π · n        (n in 1/s)",
        "ω = 2 · π · n / 60   (n in min⁻¹)",
    ],
    "n (Drehzahl)": ["vc = π · d · n / 1000"],
    "vc (Schnittgeschwindigkeit)": ["vc = π · d · n / 1000"],
    "f (Vorschub)": ["vf = f · n", "vf = fz · z · n   (Fräsen)"],
    "ap (Schnitttiefe)": ["A = ap · f", "Q = ap · f · vc"],
    "p (Druck)": ["p = F / A"],
    "Q (Volumenstrom)": ["Q = A · v", "Q = V / t"],
    "M (Drehmoment)": [
        "M = F · r",
        "P = M · ω        (ω in rad/s)",
        "M = 9550 · P / n (P in kW, n in min⁻¹)",
    ],
    "i (Übersetzung)": ["i = n_an / n_ab = z_ab / z_an"],
    "m (Modul)": ["m = d / z", "da = m · (z + 2)"],
    "ν (Sicherheitsbeiwert)": ["σ_zul = Re / ν"],
    "OEE / Verfügbarkeit": [
        "OEE = Verfügbarkeit · Leistungsgrad · Qualitätsrate",
        "Verfügbarkeit = MTBF / (MTBF + MTTR)",
        "MTBF = Betriebszeit / Anzahl Ausfälle",
    ],
    "Passung": ["Höchstspiel = ES − ei", "Mindestspiel = EI − es"],
}

# Zusaetzliche Schreibweisen fuer vorhandene Eintraege.
#
# Ohne sie greift der Tipp bei Aufgaben nicht, die die Sache umschreiben
# statt sie zu benennen - "auf den kleinen Kolben wirkt eine Kraft" enthaelt
# das Wort "Druck" nirgends.
ALIAS_ERGAENZUNG = {
    "p (Druck)": ["Kolben", "hydraulische Presse"],
    "Passung": ["Abmaß", "Höchstspiel", "Mindestspiel"],
}

# Begriffe, die es noch nicht gab - vor allem fuer die Komplexaufgaben.
#
# Die alias-Listen sind bewusst eng gehalten: Ein zu breites Stichwort laesst
# den Tipp bei Fragen aufpoppen, in denen er nichts zu suchen hat.
NEUE = [
    {
        "begriff": "th (Hauptzeit)",
        "alias": ["Hauptzeit"],
        "kurz": "Reine Bearbeitungszeit eines Arbeitsgangs, ohne Rüsten und Wechseln.",
        "formeln": ["th = L / vf", "L = Werkstücklänge + An- und Überlauf"],
        "mehr": "Die Vorschubgeschwindigkeit vf steht selten in der Aufgabe — sie entsteht erst aus Drehzahl und Vorschub. An- und Überlauf gehören zum Weg: Das Werkzeug muss vor dem Werkstück anlaufen und hinter ihm austreten.",
    },
    {
        "begriff": "L₁₀ₕ (Lagerlebensdauer)",
        "alias": ["Lebensdauer", "Tragzahl"],
        "kurz": "Erwartete Laufzeit eines Wälzlagers, bei der 90 % noch nicht ausgefallen sind.",
        "formeln": [
            "L₁₀ = (C / P)^p        (p = 3 Kugel-, 10/3 Rollenlager)",
            "L₁₀ₕ = L₁₀ · 10⁶ / (60 · n)",
        ],
        "mehr": "C ist die dynamische Tragzahl des Lagers, P die äquivalente Belastung. L₁₀ kommt in Millionen Umdrehungen heraus — erst die Drehzahl macht daraus eine Zeit.",
    },
    {
        "begriff": "Riementrieb",
        "alias": ["Riemenlänge", "Achsabstand"],
        "kurz": "Zugmitteltrieb zwischen zwei Scheiben, formschlüssig (Zahnriemen) oder reibschlüssig (Keil-, Flachriemen).",
        "formeln": [
            "L = 2 · e + π/2 · (d₁ + d₂) + (d₂ − d₁)² / (4 · e)",
            "i = d₂ / d₁",
        ],
        "mehr": "Die Riemenlänge besteht aus den geraden Trumen, dem Umschlingungsanteil beider Scheiben und einem Zuschlag für die Schräglage der Trume. Der dritte Summand wird gern vergessen.",
    },
    {
        "begriff": "R (Federrate)",
        "alias": ["Federrate", "Druckfeder", "Federkraft"],
        "kurz": "Kraft je Federweg — wie hart eine Feder ist, in N/mm.",
        "formeln": ["R = F / s", "W = R/2 · (s₂² − s₁²)"],
        "mehr": "Die Federarbeit ist die Fläche unter der Kennlinie. Zwischen zwei Wegen zählt die Differenz der Quadrate — nicht das Quadrat der Differenz.",
    },
    {
        "begriff": "Q (Wärmemenge)",
        "alias": ["Wärmemenge", "Wärmekapazität", "Schmelzwärme"],
        "kurz": "Energie, die ein Körper beim Erwärmen aufnimmt oder beim Abkühlen abgibt.",
        "formeln": ["Q = m · c · Δϑ   (Erwärmen)", "Q = m · q       (Schmelzen)"],
        "mehr": "Während des Schmelzens steigt die Temperatur nicht — die Energie steckt in der Umwandlung. Wer nur den Erwärmungsanteil rechnet, unterschätzt den Bedarf erheblich.",
    },
    {
        "begriff": "Kehlnaht",
        "alias": ["Kehlnaht", "Nahtdicke", "Schweißnaht"],
        "kurz": "Schweißnaht im rechten Winkel zwischen zwei Blechen; a ist die Höhe des eingeschriebenen Dreiecks.",
        "formeln": ["A_w = a · l", "σ = F / A_w", "S = σ_zul / σ_vorh"],
        "mehr": "Die Nahtdicke a ist nicht die Blechdicke. Bei zwei Nähten zählt die doppelte Fläche.",
    },
    {
        "begriff": "cpk (Prozessfähigkeit)",
        "alias": ["cpk", "Prozessfähigkeit", "Standardabweichung"],
        "kurz": "Wie sicher ein Prozess innerhalb der Toleranz bleibt — Streuung UND Lage.",
        "formeln": [
            "cp  = (OSG − USG) / (6 · s)",
            "cpk = min(OSG − x̄, x̄ − USG) / (3 · s)",
        ],
        "mehr": "cp sieht nur die Streuung, cpk auch die Lage: Maßgeblich ist der kleinere Abstand des Mittelwerts zu einer der beiden Grenzen. Ein enger, aber außermittiger Prozess bekommt deshalb einen schlechten cpk.",
    },
    {
        "begriff": "α (Wärmeausdehnung)",
        "alias": ["Wärmeausdehnung", "Wärmeausdehnungskoeffizient", "Fügespiel"],
        "kurz": "Wie stark sich ein Werkstoff je Kelvin ausdehnt, in 10⁻⁶/K.",
        "formeln": ["Δl = l · α · ΔT"],
        "mehr": "Beim Fügen durch Erwärmen ist nicht nur das Übermaß zu weiten, sondern auch ein Fügespiel — sonst klemmt das Teil genau dann, wenn es sitzen soll. Das Ergebnis ist eine Temperaturdifferenz; die Raumtemperatur kommt noch dazu.",
    },
    {
        "begriff": "Luftverbrauch (Pneumatik)",
        "alias": ["Luftverbrauch", "Verdichtungsverhältnis", "Doppelhub"],
        "kurz": "Bedarf an angesaugter Luft, nicht an verdichteter — der Unterschied ist der Faktor, der gern fehlt.",
        "formeln": [
            "V = A · s",
            "Verdichtungsverhältnis = (p + 1) / 1",
            "V_angesaugt = V · Verdichtungsverhältnis",
        ],
        "mehr": "Bei 6 bar Überdruck ist das der Faktor 7. Wer ihn weglässt, meldet ein Siebtel des tatsächlichen Bedarfs — und der Kompressor ist zu klein.",
    },
    {
        "begriff": "σ (Zugspannung)",
        "alias": ["Zugspannung", "Streckgrenze"],
        "kurz": "Kraft je Querschnittsfläche, in N/mm².",
        "formeln": ["σ = F / A", "A = π/4 · d²   (Rundquerschnitt)", "S = Re / σ"],
        "mehr": "Der Querschnitt eines Rundstabs ist π/4 · d², nicht π · d². Bei kN und mm² muss vor dem Teilen auf N umgerechnet werden.",
    },
    {
        "begriff": "Kritische Menge",
        "alias": ["kritische Menge", "Fixkosten"],
        "kurz": "Stückzahl, ab der sich zwei Fertigungsverfahren in den Gesamtkosten die Waage halten.",
        "formeln": [
            "K = Kf + kv · x",
            "Kf₁ + kv₁ · x = Kf₂ + kv₂ · x",
        ],
        "mehr": "Aufgelöst ergibt sich die Differenz der Fixkosten geteilt durch die Ersparnis je Stück. Weil ab dieser Menge das andere Verfahren günstiger sein soll, wird aufgerundet — genau bei der kritischen Menge sind beide noch gleich teuer.",
    },
    {
        "begriff": "cos φ (Leistungsfaktor)",
        "alias": ["cos φ", "Leistungsfaktor", "Drehstrom"],
        "kurz": "Verhältnis von Wirk- zu Scheinleistung im Wechselstromnetz.",
        "formeln": [
            "P = √3 · U · I · cos φ   (Drehstrom)",
            "η = P_ab / P_zu",
        ],
        "mehr": "Die Typenschildleistung eines Motors ist die ABGEGEBENE Leistung — aufgenommen wird mehr, nämlich P/η. Und der Faktor √3 gehört bei Drehstrom dazu; wer ihn vergisst, landet um 73 % zu hoch.",
    },
    {
        "begriff": "Kegel",
        "alias": ["Kegelverhältnis", "Einstellwinkel", "Kegellänge"],
        "kurz": "Verjüngung eines Körpers, angegeben als Verhältnis C = 1 : x.",
        "formeln": [
            "C = (D − d) / L",
            "tan(α/2) = (D − d) / (2 · L)",
        ],
        "mehr": "Der Einstellwinkel am Oberschlitten ist der HALBE Kegelwinkel — er beschreibt die Neigung einer Mantellinie zur Achse. Der Radius wächst um L · tan(α/2), der Durchmesser um das Doppelte.",
    },
    {
        "begriff": "Hydraulikzylinder",
        "alias": ["Kolbenfläche", "Ringfläche", "Kolbendurchmesser"],
        "kurz": "Wandelt Druck in Kraft und Bewegung; ausfahrend wirkt die volle Kolbenfläche, einfahrend nur die Ringfläche.",
        "formeln": [
            "A_K = π/4 · d²",
            "A_R = π/4 · (d² − dₛ²)",
            "F = p · A · η",
            "t = V / Q",
        ],
        "mehr": "Bei gleichem Volumenstrom fährt der Zylinder schneller ein als aus, weil die Kolbenstange Platz wegnimmt. 1 bar = 0,1 N/mm².",
    },
]


def schreibe(eintraege):
    """Schreibt im Stil der Datei: ein Objekt je Eintrag, Listen einzeilig."""
    zeilen = ["["]
    for i, e in enumerate(eintraege):
        zeilen.append("  {")
        felder = []
        for schluessel in ("begriff", "alias", "kurz", "formeln", "mehr"):
            if schluessel not in e:
                continue
            wert = e[schluessel]
            if isinstance(wert, list) and not wert:
                continue
            felder.append(
                '    %s: %s'
                % (
                    json.dumps(schluessel, ensure_ascii=False),
                    json.dumps(wert, ensure_ascii=False),
                )
            )
        zeilen.append(",\n".join(felder))
        zeilen.append("  }" + ("," if i < len(eintraege) - 1 else ""))
    zeilen.append("]")
    with io.open(GLOSSAR, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(zeilen) + "\n")


def main():
    with io.open(GLOSSAR, encoding="utf-8") as f:
        eintraege = json.load(f)

    vorhanden = {e["begriff"] for e in eintraege}
    gesetzt = 0
    for e in eintraege:
        formeln = FORMELN.get(e["begriff"])
        if formeln:
            e["formeln"] = formeln
            gesetzt += 1
        for zusatz in ALIAS_ERGAENZUNG.get(e["begriff"], []):
            if zusatz not in e.setdefault("alias", []):
                e["alias"].append(zusatz)

    neu = 0
    for e in NEUE:
        if e["begriff"] in vorhanden:
            continue
        eintraege.append(e)
        neu += 1

    fehlend = (set(FORMELN) | set(ALIAS_ERGAENZUNG)) - vorhanden
    if fehlend:
        raise KeyError("Begriffe gibt es nicht: %s" % ", ".join(sorted(fehlend)))

    schreibe(eintraege)
    mit = sum(1 for e in eintraege if e.get("formeln"))
    print("%d Eintraege insgesamt, davon %d mit Formeln" % (len(eintraege), mit))
    print("  %d bestehende ergaenzt, %d neu angelegt" % (gesetzt, neu))


if __name__ == "__main__":
    main()
