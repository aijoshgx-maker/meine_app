# -*- coding: utf-8 -*-
"""Variantenbeschreibungen fuer die Rechenaufgaben.

Die Formeln sind aus dem jeweils vorhandenen workedExample abgeschrieben -
der zeigt bei jeder Aufgabe den Rechenweg, ist also belegte Vorlage und keine
Vermutung. Der Validator rechnet jede davon mit den Originalwerten nach und
verlangt genau den Wert, der seit jeher gespeichert ist.

Wertebereiche sind bewusst eng: Widerstaende aus der E12-Reihe, Spannungen
aus dem, was in einer Werkstatt vorkommt, Zaehnezahlen aus gaengigen
Getriebestufen. Eine Aufgabe mit 137 Ohm an 83 Volt waere zwar rechenbar,
aber keine, die jemand in der Pruefung sieht.
"""

# Textkorrekturen, ohne die eine Vorlage ihr Original nicht wiederherstellen
# kann. Jede einzeln begruendet - stillschweigend aendert hier nichts.
KORREKTUREN = [
    (
        "auftragsanalyse_elektrotechnik.json",
        "Heizwiderstand R = 1 500 Ω",
        "Heizwiderstand R = 1500 Ω",
        "Ziffernguppierung mit Leerzeichen, sonst nirgends im Bestand",
    ),
    (
        "auftragsanalyse_antriebstechnik.json",
        '"loesungswert": 5314.0,',
        '"loesungswert": 5314.5,',
        "gespeichert war der aus dem Loesungsweg abgelesene, gerundete Wert; "
        "exakt sind es 35 * 2pi * 1450/60 = 5314,5 W",
    ),
]

# Wiederkehrende Wertelisten.
E12 = [10, 15, 22, 33, 47, 68, 100, 150, 220, 330, 470, 680]
SPANNUNGEN = [12, 24, 48, 60, 110, 120, 230]
MOTORDREHZAHLEN = [700, 900, 960, 1000, 1400, 1450, 1500, 2800, 3000]

VARIANTEN = {
    # --- Antriebstechnik ---------------------------------------------
    "au-at-002": {
        "datei": "auftragsanalyse_antriebstechnik.json",
        "varianten": {
            "variablen": {
                "n1": {"werte": MOTORDREHZAHLEN},
                "z1": {"werte": [15, 18, 20, 25]},
                "z2": {"werte": [45, 54, 60, 75]},
                "z3": {"werte": [12, 15, 18, 20]},
                "z4": {"werte": [36, 45, 54, 60]},
            },
            "original": {"n1": 960, "z1": 20, "z2": 60, "z3": 15, "z4": 45},
            "zwischen": {
                "i1": "z2 / z1",
                "i2": "z4 / z3",
                "i_ges": "i1 * i2",
            },
            "frage": "Ein Motor dreht mit n₁ = {n1} min⁻¹ und treibt über ein zweistufiges Getriebe eine Ausgangswelle an. Stufe 1: z₁ = {z1}, z₂ = {z2}. Stufe 2: z₃ = {z3}, z₄ = {z4}. Berechnen Sie die Abtriebsdrehzahl n_ab.",
            "loesung": "n1 / i_ges",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "Gesamtübersetzung: i_ges = i₁ · i₂ = (z₂/z₁) · (z₄/z₃) = {i1} · {i2} = {i_ges}. Abtriebsdrehzahl: n_ab = n₁/i_ges = {n1}/{i_ges} ≈ {loesung} min⁻¹.",
            "workedExample": "Gegeben: n₁ = {n1} min⁻¹, z₁={z1}, z₂={z2}, z₃={z3}, z₄={z4}\nSchritt 1: i₁ = z₂/z₁ = {z2}/{z1} = {i1}\nSchritt 2: i₂ = z₄/z₃ = {z4}/{z3} = {i2}\nSchritt 3: i_ges = i₁ · i₂ = {i1} · {i2} = {i_ges}\nSchritt 4: n_ab = n₁ / i_ges = {n1} / {i_ges} ≈ {loesung} min⁻¹",
        },
    },
    "au-at-003": {
        "datei": "auftragsanalyse_antriebstechnik.json",
        "varianten": {
            "variablen": {
                "P1": {"von": 1.5, "bis": 22.0, "schritt": 0.1},
                "eta": {"werte": [0.8, 0.82, 0.85, 0.88, 0.9, 0.92, 0.94, 0.95]},
            },
            "original": {"P1": 5.5, "eta": 0.92},
            "frage": "Ein Motor liefert an der Antriebswelle eine Leistung P₁ = {P1} kW bei einem Wirkungsgrad η = {eta}. Berechnen Sie die abgegebene Nutzleistung P₂.",
            "loesung": "eta * P1",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Der Wirkungsgrad beschreibt das Verhältnis von Nutzleistung zu zugeführter Leistung: η = P₂/P₁. Umgestellt: P₂ = η · P₁ = {eta} · {P1} kW = {loesung} kW.",
            "workedExample": "Gegeben: P₁ = {P1} kW, η = {eta}\nFormel: η = P₂/P₁ → P₂ = η · P₁\nRechnung: P₂ = {eta} · {P1} kW = {loesung} kW",
        },
    },
    "au-at-004": {
        "datei": "auftragsanalyse_antriebstechnik.json",
        "varianten": {
            "variablen": {
                "n": {"werte": MOTORDREHZAHLEN},
                "M": {"von": 5.0, "bis": 120.0, "schritt": 5.0},
            },
            "original": {"n": 1450, "M": 35},
            # Gerundet, damit im Lösungsweg dieselben Zahlen stehen, mit
            # denen dort gerechnet wird.
            "zwischen": {
                "n_s": "round(n / 60 * 1000) / 1000",
                "omega": "round(2 * pi * n / 60 * 100) / 100",
            },
            "frage": "Ein Elektromotor dreht mit n = {n} min⁻¹ und gibt ein Drehmoment M = {M} N·m ab. Berechnen Sie die abgegebene mechanische Leistung P.",
            "loesung": "M * 2 * pi * n / 60",
            "rundung": 1,
            "toleranzProzent": 0.2,
            "erklaerung": "P = M · ω = M · 2π · n. Mit n in s⁻¹: n = {n}/60 s⁻¹ ≈ {n_s} s⁻¹. ω = 2π · {n_s} ≈ {omega} rad/s. P = {M} N·m · {omega} rad/s ≈ {loesung} W.",
            "workedExample": "Gegeben: n = {n} min⁻¹ = {n_s} s⁻¹, M = {M} N·m\nSchritt 1: ω = 2π · n = 2π · {n_s} ≈ {omega} rad/s\nSchritt 2: P = M · ω = {M} · {omega} ≈ {loesung} W",
        },
    },
    # --- Elektrotechnik ----------------------------------------------
    "au-et-002": {
        "datei": "auftragsanalyse_elektrotechnik.json",
        "varianten": {
            "variablen": {
                "U": {"werte": SPANNUNGEN},
                "I": {"von": 0.1, "bis": 3.0, "schritt": 0.1},
            },
            "original": {"U": 24, "I": 0.6},
            "frage": "An einem Widerstand liegen {U} V an. Der fließende Strom beträgt {I} A. Berechne den Widerstandswert R.",
            "loesung": "U / I",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Nach dem Ohm'schen Gesetz gilt: R = U / I = {U} V / {I} A = {loesung} Ω.",
            "workedExample": "Formel: R = U / I\nR = {U} V / {I} A\nR = {loesung} Ω",
        },
    },
    "au-et-003": {
        "datei": "auftragsanalyse_elektrotechnik.json",
        "varianten": {
            "variablen": {"R1": {"werte": E12}, "R2": {"werte": E12}},
            "original": {"R1": 100, "R2": 150},
            "frage": "Zwei Widerstände R1 = {R1} Ω und R2 = {R2} Ω sind parallel geschaltet. Berechne den Gesamtwiderstand R_ges.",
            "loesung": "R1 * R2 / (R1 + R2)",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Bei Parallelschaltung gilt: 1/R_ges = 1/R1 + 1/R2. Zusammengefasst: R_ges = (R1 · R2)/(R1 + R2) = ({R1} · {R2})/({R1} + {R2}) = {loesung} Ω. Der Gesamtwiderstand ist immer kleiner als der kleinste Einzelwiderstand.",
            "workedExample": "Formel Parallel: 1/R_ges = 1/R1 + 1/R2\n1/R_ges = 1/{R1} + 1/{R2}\nZusammengefasst: R_ges = (R1 · R2)/(R1 + R2)\nR_ges = ({R1} · {R2})/({R1} + {R2}) = {loesung} Ω",
        },
    },
    "au-et-004": {
        "datei": "auftragsanalyse_elektrotechnik.json",
        "varianten": {
            "variablen": {
                # Nur Netzspannungen: 3000 W an 24 V waeren 125 A - rechenbar,
                # aber kein Geraet, das jemand anschliesst.
                "U": {"werte": [230, 400]},
                "P": {"von": 500.0, "bis": 5000.0, "schritt": 50.0},
            },
            "original": {"U": 230, "P": 1150},
            "frage": "Ein elektrisches Gerät nimmt bei {U} V eine Leistung von P = {P} W auf. Welcher Strom I fließt?",
            "loesung": "P / U",
            "rundung": 2,
            "toleranzProzent": 2.0,
            "erklaerung": "Elektrische Leistung: P = U · I. Umgestellt: I = P / U = {P} W / {U} V = {loesung} A.",
            "workedExample": "Formel: P = U · I → I = P / U\nI = {P} W / {U} V\nI = {loesung} A",
        },
    },
    "au-et-019": {
        "datei": "auftragsanalyse_elektrotechnik.json",
        "varianten": {
            "variablen": {
                "R1": {"werte": E12},
                "R2": {"werte": E12},
                "R3": {"werte": E12},
                "U": {"werte": SPANNUNGEN},
            },
            "original": {"R1": 10, "R2": 20, "R3": 30, "U": 120},
            "zwischen": {"R_ges": "R1 + R2 + R3"},
            "frage": "Drei Widerstände R1 = {R1} Ω, R2 = {R2} Ω, R3 = {R3} Ω sind in Reihe geschaltet. An der Gesamtschaltung liegt U = {U} V. Wie groß ist der Strom I?",
            "loesung": "U / R_ges",
            "rundung": 3,
            "toleranzProzent": 2.0,
            "erklaerung": "Reihenschaltung: R_ges = R1 + R2 + R3 = {R1} + {R2} + {R3} = {R_ges} Ω. Strom: I = U / R_ges = {U} V / {R_ges} Ω = {loesung} A. In der Reihenschaltung fließt durch alle Widerstände derselbe Strom.",
            "workedExample": "R_ges = R1 + R2 + R3 = {R1} + {R2} + {R3} = {R_ges} Ω\nI = U / R_ges = {U} V / {R_ges} Ω\nI = {loesung} A",
        },
    },
    "au-et-022": {
        "datei": "auftragsanalyse_elektrotechnik.json",
        "varianten": {
            "variablen": {
                "R": {"werte": [470, 560, 680, 820, 1000, 1200, 1500, 1800, 2200, 2700]},
                "P": {"werte": [2, 3, 5, 8, 10, 15, 20, 25]},
            },
            "original": {"R": 1500, "P": 5},
            "zwischen": {"quotient": "round(P / R * 1000000) / 1000000"},
            "frage": "An einem Heizwiderstand R = {R} Ω wird eine elektrische Leistung P = {P} W umgesetzt. Berechnen Sie die Stromstärke I (in mA).",
            "loesung": "sqrt(P / R) * 1000",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "Aus P = I² · R folgt: I = √(P/R) = √({P}/{R}) = √{quotient} ≈ {loesung} mA. Die Umrechnung von A in mA erfolgt mit dem Faktor 1000.",
            "workedExample": "P = I² · R  →  I² = P/R\nI = √(P/R) = √({P} W / {R} Ω) = √({quotient}) ≈ {loesung} mA",
        },
    },
    # --- Maschinenelemente -------------------------------------------
    "au-me-005": {
        "datei": "auftragsanalyse_maschinenelemente.json",
        "varianten": {
            "variablen": {
                "n1": {"werte": MOTORDREHZAHLEN},
                "z1": {"werte": [15, 18, 20, 22, 25]},
                "z2": {"werte": [45, 54, 60, 66, 75]},
            },
            "original": {"n1": 1450, "z1": 18, "z2": 54},
            "zwischen": {"i": "z2 / z1"},
            "frage": "Ein Antriebsmotor läuft mit n₁ = {n1} min⁻¹ und treibt über ein einstufiges Zahnradgetriebe (z₁ = {z1}, z₂ = {z2}) eine Ausgangswelle an. Berechnen Sie die Abtriebsdrehzahl n₂.",
            "loesung": "n1 * z1 / z2",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "Die Abtriebsdrehzahl berechnet sich über das Übersetzungsverhältnis i = z₂/z₁ = {z2}/{z1} = {i}. Damit gilt n₂ = n₁/i = {n1}/{i} ≈ {loesung} min⁻¹.",
            "workedExample": "Gegeben: n₁ = {n1} min⁻¹, z₁ = {z1}, z₂ = {z2}\nSchritt 1: i = z₂/z₁ = {z2}/{z1} = {i}\nSchritt 2: n₂ = n₁/i = {n1} min⁻¹ / {i} = {loesung} min⁻¹",
        },
    },
    "au-me-009": {
        "datei": "auftragsanalyse_maschinenelemente.json",
        "varianten": {
            "variablen": {
                "F": {"von": 100.0, "bis": 2000.0, "schritt": 50.0},
                "r": {"werte": [0.02, 0.03, 0.04, 0.05, 0.06, 0.08, 0.1, 0.125]},
            },
            "original": {"F": 500, "r": 0.04},
            "frage": "An einer Welle mit Radius r = {r} m wirkt eine Tangentialkraft F = {F} N. Berechnen Sie das übertragene Drehmoment M.",
            "loesung": "F * r",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Das Drehmoment berechnet sich nach M = F · r = {F} N · {r} m = {loesung} N·m. Entscheidend ist der Hebelarm: Derselbe Kraftbetrag erzeugt am doppelten Radius das doppelte Moment.",
            "workedExample": "Gegeben: F = {F} N, r = {r} m\nFormel: M = F · r\nRechnung: M = {F} N · {r} m = {loesung} N·m",
        },
    },
    "au-me-015": {
        "datei": "auftragsanalyse_maschinenelemente.json",
        "varianten": {
            "variablen": {
                "c": {"werte": [4, 5, 6, 8, 10, 12, 15, 20, 25]},
                "F": {"von": 40.0, "bis": 400.0, "schritt": 10.0},
            },
            "original": {"c": 8, "F": 120},
            "frage": "Eine Druckfeder hat eine Federkonstante c = {c} N/mm. Um wie viel mm wird die Feder komprimiert, wenn eine Kraft von F = {F} N aufgebracht wird?",
            "loesung": "F / c",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Das Hook'sche Gesetz für Federn lautet: F = c · s, umgestellt: s = F/c = {F} N / {c} N/mm = {loesung} mm. Der Federweg wächst linear mit der Kraft, solange die Feder im elastischen Bereich bleibt.",
            "workedExample": "Gegeben: c = {c} N/mm, F = {F} N\nFormel: F = c · s → s = F/c\nRechnung: s = {F} N / {c} (N/mm) = {loesung} mm",
        },
    },
    # Prüfungsaufgabe: Die Zähnezahlen gehören zum echten Getriebe aus S19
    # und bleiben deshalb fest - variabel ist nur die frei gewählte
    # Antriebsdrehzahl.
    "au-me-030": {
        "datei": "auftragsanalyse_maschinenelemente.json",
        "varianten": {
            "variablen": {
                "z1": {"werte": [66]},
                "z2": {"werte": [18]},
                "n1": {"von": 400.0, "bis": 1600.0, "schritt": 50.0},
            },
            "original": {"z1": 66, "z2": 18, "n1": 750},
            "zwischen": {"i": "round(z1 / z2 * 1000) / 1000"},
            "frage": "Das Schieberadgetriebe (S19) hat in Gangstufe 1 die Zahnzahlen z₁={z1} (Antrieb) und z₂={z2} (Spindel). Der Antrieb dreht mit n₁ = {n1} min⁻¹. Welche Drehzahl n₂ (in min⁻¹) erreicht die Spindel?",
            "loesung": "n1 * z1 / z2",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "Übersetzung: i = z₁/z₂ = {z1}/{z2} = {i}. Ausgangsdrehzahl: n₂ = n₁ · z₁/z₂ = {n1} · {z1}/{z2} = {loesung} min⁻¹. Da z₁ > z₂ (große Zähnezahl treibt kleine an), liegt eine Übersetzung ins Schnelle vor.",
            "workedExample": "i = z₁/z₂ = {z1}/{z2} = {i}\nn₂ = n₁ · z₁/z₂ = {n1} · {z1}/{z2} = {loesung} min⁻¹",
        },
    },
}
