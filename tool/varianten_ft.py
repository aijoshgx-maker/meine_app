# -*- coding: utf-8 -*-
"""Fertigungstechnik: CNC, Schnittdaten, Qualitaet, Umformen, Wirtschaft.

Nicht umgestellt und warum:
  ft-cnc-024, ft-cnc-025, ft-zg-007  haben eine Zeichnung; die Masse stehen
                                     im Bild.
"""

CNC = "fertigungstechnik_cnc_grundlagen.json"
AP = "fertigungstechnik_fertigungs_arbeitsplanung.json"
FV = "fertigungstechnik_fuegeverfahren.json"
MP = "fertigungstechnik_mess_prueftechnik.json"
QS = "fertigungstechnik_qualitaetssicherung.json"
SD = "fertigungstechnik_schnittdaten.json"
UT = "fertigungstechnik_umformen_trennen.json"
WW = "fertigungstechnik_werkstoffe_waermebehandlung.json"
WS = "fertigungstechnik_werkzeuge_schneidstoffe.json"
WF = "fertigungstechnik_wirtschaftliche_fertigung.json"
ZG = "fertigungstechnik_zerspanung_grundlagen.json"

FRAESER = [6, 8, 10, 12, 16, 20, 25, 32, 40, 50, 63]
SCHNITTGESCHW = [80, 100, 120, 150, 180, 200, 250, 300]
GEWINDE = [["M6", 1.0], ["M8", 1.25], ["M10", 1.5], ["M12", 1.75], ["M16", 2.0]]

KORREKTUREN = [
    (WF, "Fixkosten je Periode: 80 000", "Fixkosten je Periode: 80000",
     "Ziffernguppierung mit Leerzeichen (ft-wf-003)"),
    (WF, "Eine Maschine kostet 120 000 €, hat eine Nutzungsdauer von 10 Jahren und einen Restwert von 20 000 €",
     "Eine Maschine kostet 120000 €, hat eine Nutzungsdauer von 10 Jahren und einen Restwert von 20000 €",
     "Ziffernguppierung mit Leerzeichen (ft-wf-005)"),
]

VARIANTEN = {
    "ft-cnc-005": {
        "datei": CNC,
        "varianten": {
            "variablen": {
                "d": {"werte": FRAESER},
                "vc": {"werte": SCHNITTGESCHW},
            },
            "original": {"d": 20, "vc": 120},
            "zwischen": {
                "nenner": "round(pi * d * 100) / 100",
                "zaehler": "vc * 1000",
            },
            "frage": "Ein CNC-Fräser mit Durchmesser d = {d} mm soll mit Schnittgeschwindigkeit vc = {vc} m/min betrieben werden. Berechne die erforderliche Spindeldrehzahl n in min⁻¹.",
            "loesung": "vc * 1000 / (pi * d)",
            "rundung": 0,
            "toleranzProzent": 1.0,
            "erklaerung": "n = vc × 1000 / (π × d) = {vc} × 1000 / (π × {d}) = {zaehler} / {nenner} ≈ {loesung} min⁻¹. In der CNC-Praxis wird gerundet. Die Schnittgeschwindigkeit hängt vom Werkstoff und Schneidstoff ab; der Programmierer berechnet die Drehzahl daraus.",
            "workedExample": "n = (vc · 1000) / (π · d) = ({vc} · 1000) / (π · {d}) = {zaehler} / {nenner} ≈ {loesung} min⁻¹",
        },
    },
    "ft-cnc-011": {
        "datei": CNC,
        "varianten": {
            "variablen": {
                "d": {"werte": FRAESER},
                "z": {"werte": [2, 3, 4, 5, 6, 8]},
                "n": {"von": 800.0, "bis": 6000.0, "schritt": 100.0},
                "fz": {"werte": [0.02, 0.04, 0.05, 0.06, 0.08, 0.1, 0.12, 0.15]},
            },
            "original": {"d": 12, "z": 3, "n": 2500, "fz": 0.05},
            "frage": "Ein CNC-Fräser (d = {d} mm, z = {z} Schneiden) arbeitet mit n = {n} min⁻¹ und einem Vorschub pro Schneide fz = {fz} mm. Berechne den Tischvorschub vf in mm/min.",
            "loesung": "fz * z * n",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "vf = fz · z · n = {fz} mm · {z} · {n} min⁻¹ = {loesung} mm/min. Der Tischvorschub (F-Wert im G-Code mit G94) ergibt sich aus Vorschub je Schneide × Schneidenzahl × Drehzahl. Bei höherer Schneidenzahl oder höherer Drehzahl steigt der Vorschub proportional.",
            "workedExample": "vf = fz · z · n = {fz} mm · {z} · {n} min⁻¹ = {loesung} mm/min",
        },
    },
    "ft-cnc-017": {
        "datei": CNC,
        "varianten": {
            "variablen": {
                "R": {"werte": [40, 50, 55, 65, 75, 80, 100, 120]},
                "phi": {"werte": [15, 20, 30, 36, 45, 60, 72]},
            },
            "original": {"R": 65, "phi": 30},
            "zwischen": {
                "cosw": "round(cos(phi) * 1000) / 1000",
                "sinw": "round(sin(phi) * 1000) / 1000",
                "x_genau": "round(R * cos(phi) * 10) / 10",
                "y": "round(R * sin(phi) * 10) / 10",
            },
            "frage": "Beim CNC-Fräsen eines Flansches soll Bohrung P2 auf einem Teilkreis R = {R} mm bei φ = {phi}° angefahren werden. Koordinatenursprung liegt im Kreismittelpunkt. Berechnen Sie die X-Koordinate von P2 (in mm, gerundet auf 1 mm).",
            "loesung": "R * cos(phi)",
            "rundung": 0,
            "toleranzProzent": 2.0,
            "erklaerung": "X = R · cos(φ) = {R} mm · cos({phi}°) = {R} · {cosw} ≈ {x_genau} mm ≈ {loesung} mm. Y = R · sin({phi}°) = {R} · {sinw} = {y} mm.",
            "workedExample": "X = R · cos(φ) = {R} · cos({phi}°) = {R} · {cosw} ≈ {loesung} mm\nY = R · sin(φ) = {R} · sin({phi}°) = {R} · {sinw} ≈ {y} mm",
        },
    },
    # Pruefung S17: Der Planfraeser ist das gewaehlte Werkzeug und bleibt;
    # Schnittgeschwindigkeit und Zahnvorschub legt der Planer fest.
    "ft-cnc-019": {
        "datei": CNC,
        "varianten": {
            "variablen": {
                "d": {"werte": [95]},
                "z": {"werte": [6]},
                "vc": {"werte": SCHNITTGESCHW},
                "fz": {"werte": [0.05, 0.08, 0.1, 0.12, 0.15, 0.2]},
            },
            "original": {"d": 95, "z": 6, "vc": 250, "fz": 0.1},
            "zwischen": {"n": "round(vc * 1000 / (pi * d) * 10) / 10"},
            "frage": "Die Auflagefläche des Schwenklagers wird mit einem Planfräser Ø {d} mm mit {z} Zähnen bearbeitet. Berechnen Sie die Vorschubgeschwindigkeit vf (in mm/min) bei vc = {vc} m/min und fz = {fz} mm.",
            "loesung": "vc * 1000 / (pi * d) * z * fz",
            "rundung": 0,
            "toleranzProzent": 1.0,
            "erklaerung": "Drehzahl: n = vc·1000/(π·d) = {vc}000/(π·{d}) = {n} min⁻¹. Vorschubgeschwindigkeit: vf = n · z · fz = {n} · {z} · {fz} ≈ {loesung} mm/min.",
            "workedExample": "n = vc·1000 / (π·d) = {vc} · 1000 / (π·{d}) = {n} min⁻¹\nvf = n · z · fz = {n} · {z} · {fz} ≈ {loesung} mm/min",
        },
    },
    "ft-cnc-023": {
        "datei": CNC,
        "varianten": {
            "spalten": ["gewinde", "p"],
            "zeilen": GEWINDE,
            "variablen": {"vf": {"von": 150.0, "bis": 900.0, "schritt": 15.0}},
            "original": {"gewinde": "M10", "p": 1.5, "vf": 420},
            "frage": "Ein Gewindebohrer {gewinde} (Steigung p = {p} mm) soll mit Vorschubgeschwindigkeit vf = {vf} mm/min arbeiten. Welche Drehzahl n (in min⁻¹) ist einzustellen?",
            "loesung": "vf / p",
            "rundung": 1,
            "toleranzProzent": 0.5,
            "erklaerung": "Beim Gewindebohren: n = vf / p = {vf} mm/min / {p} mm = {loesung} min⁻¹. Drehzahl und Vorschub müssen synchronisiert werden: vf = n · p. Eine Abweichung würde das Gewinde zerstören. Moderne CNC-Maschinen synchronisieren dies automatisch über rigides Gewindebohren (G84).",
            "workedExample": "n = vf / p = {vf} / {p} = {loesung} min⁻¹",
        },
    },
    "ft-ap-004": {
        "datei": AP,
        "varianten": {
            "variablen": {
                "th": {"von": 3.0, "bis": 25.0, "schritt": 1.0},
                "tn": {"von": 1.0, "bis": 10.0, "schritt": 1.0},
                "los": {"werte": [20, 25, 50, 80, 100, 200, 250]},
                "tr": {"von": 20.0, "bis": 180.0, "schritt": 10.0},
            },
            "original": {"th": 8, "tn": 3, "los": 50, "tr": 40},
            "zwischen": {"anteil": "round(tr / los * 1000) / 1000"},
            "frage": "Eine Fräsoperation hat eine Hauptzeit t_h = {th} min pro Stück und eine Nebenzeit t_n = {tn} min. Die Losgröße ist {los} Stück, die Rüstzeit t_r = {tr} min. Berechne die Fertigungszeit t_f je Stück in min.",
            "loesung": "th + tn + tr / los",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "t_f = t_h + t_n + t_r / n = {th} + {tn} + {tr}/{los} = {th} + {tn} + {anteil} = {loesung} min/Stück. Größere Losgrößen → kleinerer Rüstzeitanteil je Stück. Losgrößenoptimierung balanciert Rüstkosten gegen Lagerkosten.",
            "workedExample": "t_f = t_h + t_n + t_r/n = {th} + {tn} + {tr}/{los} = {loesung} min",
        },
    },
    "ft-ap-012": {
        "datei": AP,
        "varianten": {
            "variablen": {
                "stueck": {"werte": [200, 300, 400, 500, 600, 750, 800, 1000]},
                "stunden": {"werte": [6, 7, 7.5, 8, 10, 12]},
            },
            "original": {"stueck": 500, "stunden": 8},
            "zwischen": {"sekunden": "stunden * 3600"},
            "frage": "Ein Betrieb produziert {stueck} Teile pro Schicht ({stunden} Stunden). Berechne die Taktzeit T in Sekunden.",
            "loesung": "stunden * 3600 / stueck",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Taktzeit T = Verfügbare Zeit / Nachfrage. {stunden} h = {sekunden} s. T = {sekunden} s / {stueck} Stück = {loesung} s/Stück. Die Taktzeit ist der Produktionstakt, der sich aus dem Kundenbedarf ergibt. Alle Arbeitsstationen im Fließbetrieb müssen innerhalb der Taktzeit ihren Arbeitsgang abschließen.",
            "workedExample": "T = Verfügbare Zeit / Stückzahl = ({stunden} · 3600) s / {stueck} = {sekunden} / {stueck} = {loesung} s",
        },
    },
    "ft-fv-010": {
        "datei": FV,
        "varianten": {
            "variablen": {
                "l": {"von": 40.0, "bis": 400.0, "schritt": 10.0},
                "a": {"werte": [3, 4, 5, 6, 7, 8, 10]},
                "tau": {"werte": [80, 90, 100, 120, 140, 160]},
            },
            "original": {"l": 120, "a": 5, "tau": 100},
            "zwischen": {"A_w": "a * l"},
            "frage": "Eine Schweißnaht (Kehlnaht) hat eine Länge l = {l} mm und eine Nahtdicke a = {a} mm. Die zulässige Schubspannung des Grundwerkstoffs beträgt τ_zul = {tau} N/mm². Berechne die maximal zulässige Querkraft F in kN.",
            "loesung": "tau * a * l / 1000",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Kehlnaht: Nahtfläche A_w = a · l = {a} · {l} = {A_w} mm². Zulässige Kraft: F = τ_zul · A_w = {tau} · {A_w} N = {loesung} kN. Nahtdicke a = 0,7 × Schenkellänge (Kehlnaht-Geometrie). Doppelnaht verdoppelt die Tragfähigkeit.",
            "workedExample": "A_w = a · l = {a} mm · {l} mm = {A_w} mm²\nF = τ_zul · A_w = {tau} N/mm² · {A_w} mm² = {loesung} kN",
        },
    },
    "ft-fv-015": {
        "datei": FV,
        "varianten": {
            "variablen": {
                "D": {"werte": [30, 40, 50, 60, 80, 100]},
                "U": {"werte": [0.02, 0.03, 0.04, 0.05, 0.06, 0.08]},
                "mu": {"werte": [0.08, 0.1, 0.12, 0.15]},
                "l": {"werte": [25, 30, 40, 50, 60, 80]},
            },
            "original": {"D": 50, "U": 0.05, "mu": 0.12, "l": 40},
            "zwischen": {
                "Mt": "round(mu * (210000 * U / D) * pi * D^2 * l / 2 / 1000000) / 1000",
            },
            "frage": "Ein Querpreßverband hat Nenndurchmesser D = {D} mm, Übermaß U = {U} mm, E-Modul E = 210 000 N/mm², Reibzahl µ = {mu} und Fugenlänge l = {l} mm. Berechne den Fugendruck p näherungsweise in N/mm² (Formel für dünnwandige Hohlwelle: p ≈ E · U / D).",
            "loesung": "210000 * U / D",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "p ≈ E · U / D = 210 000 · {U} / {D} = {loesung} N/mm². Dies ist eine Näherung für gleiche Werkstoffe von Welle und Nabe. Übertragbares Drehmoment: M_t = µ · p · π · D² · l / 2 ≈ {Mt} kNm. Der Pressverband ist eine unlösbare, hochfeste Verbindung.",
            "workedExample": "p ≈ E · U / D = 210 000 N/mm² · {U} mm / {D} mm = {loesung} N/mm²",
        },
    },
    # Nennmass und Abmass gehoeren zusammen (ISO 286, Toleranzfeld H7) -
    # deshalb ganze Zeilen statt zweier unabhaengiger Ziehungen.
    "ft-mp-003": {
        "datei": MP,
        "varianten": {
            "spalten": ["N", "es"],
            "zeilen": [[25, 0.021], [40, 0.025], [50, 0.025], [60, 0.03], [80, 0.03], [100, 0.035]],
            "original": {"N": 40, "es": 0.025},
            "stellen": {"es": 3},
            "frage": "Ein Bauteil hat das Nennmaß {N} mm mit der Toleranz +{es} / –0,000 mm. Berechnen Sie das Höchstmaß.",
            "loesung": "N + es",
            "rundung": 3,
            "toleranzProzent": 0.01,
            "erklaerung": "Höchstmaß G_o = Nennmaß + oberes Abmaß = {N} + {es} = {loesung} mm. Das Höchstmaß ist die obere Grenze, die das Fertigmaß nicht überschreiten darf.",
            "workedExample": "Gegeben: Nennmaß N = {N} mm, oberes Abmaß ES = +{es} mm\nFormel: G_o = N + ES\nSchritt 1: G_o = {N} + {es} = {loesung} mm\nErgebnis: Höchstmaß = {loesung} mm",
        },
    },
    "ft-qs-007": {
        "datei": QS,
        "varianten": {
            "variablen": {
                "gesamt": {"werte": [500, 800, 1000, 1500, 2000, 2500, 4000, 5000]},
                "ausschuss_prozent": {"werte": [1, 2, 3, 4, 5]},
                "nacharbeit_prozent": {"werte": [1, 2, 3, 4]},
            },
            # Stueckzahlen abgeleitet statt gewuerfelt: sonst koennten
            # Ausschuss und Nacharbeit zusammen die Losgroesse uebersteigen.
            "original": {"gesamt": 2000, "ausschuss_prozent": 4, "nacharbeit_prozent": 2},
            "zwischen": {
                "ausschuss": "round(gesamt * ausschuss_prozent / 100)",
                "nacharbeit": "round(gesamt * nacharbeit_prozent / 100)",
                "gut": "gesamt - round(gesamt * ausschuss_prozent / 100) - round(gesamt * nacharbeit_prozent / 100)",
            },
            "frage": "Von {gesamt} gefertigten Teilen werden {ausschuss} als Ausschuss und {nacharbeit} als Nacharbeit bewertet. Berechne die Ausschussrate und die Erstgutrate FPY (First Pass Yield) in %.",
            "loesung": "(gesamt - round(gesamt * ausschuss_prozent / 100) - round(gesamt * nacharbeit_prozent / 100)) / gesamt * 100",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "FPY = Gutteile ohne Nacharbeit / Gesamtstückzahl. Gutteile auf Anhieb: {gesamt} - {ausschuss} (Ausschuss) - {nacharbeit} (Nacharbeit) = {gut}. FPY = {gut}/{gesamt} = {loesung} %. Ausschussrate = {ausschuss}/{gesamt} = {ausschuss_prozent} %. FPY ist wichtiger als reine Gutmenge, da Nacharbeit Kosten verursacht.",
            "workedExample": "Gutteile (ohne Nacharbeit) = {gesamt} - {ausschuss} - {nacharbeit} = {gut}\nFPY = {gut} / {gesamt} = {loesung} %",
        },
    },
    "ft-qs-013": {
        "datei": QS,
        "varianten": {
            "variablen": {
                "m1": {"von": 24.95, "bis": 25.05, "schritt": 0.01},
                "m2": {"von": 24.95, "bis": 25.05, "schritt": 0.01},
                "m3": {"von": 24.95, "bis": 25.05, "schritt": 0.01},
                "m4": {"von": 24.95, "bis": 25.05, "schritt": 0.01},
                "m5": {"von": 24.95, "bis": 25.05, "schritt": 0.01},
            },
            "original": {"m1": 25.01, "m2": 24.98, "m3": 25.03, "m4": 24.99, "m5": 25.02},
            "stellen": {"m1": 2, "m2": 2, "m3": 2, "m4": 2, "m5": 2, "summe": 2},
            "zwischen": {"summe": "round((m1 + m2 + m3 + m4 + m5) * 100) / 100"},
            "frage": "Eine Messreihe ergibt folgende 5 Messwerte: {m1}; {m2}; {m3}; {m4}; {m5} mm. Berechne den Mittelwert x̄ in mm.",
            "loesung": "(m1 + m2 + m3 + m4 + m5) / 5",
            "rundung": 3,
            "toleranzProzent": 0.01,
            "erklaerung": "x̄ = Σxi / n = ({m1} + {m2} + {m3} + {m4} + {m5}) / 5 = {summe} / 5 = {loesung} mm. In der Messtechnik: mit Messgeräten immer mehrfach messen und Mittelwert bilden → reduziert zufällige Messfehler (Standardmessunsicherheit sinkt mit √n).",
            "workedExample": "x̄ = ({m1} + {m2} + {m3} + {m4} + {m5}) / 5 = {summe} / 5 = {loesung} mm",
        },
    },
    "ft-qs-017": {
        "datei": QS,
        "varianten": {
            "variablen": {
                "gesamt": {"werte": [8, 10, 11, 12, 15, 18, 20, 24, 25]},
                "davon": {"werte": [2, 3, 4, 5]},
            },
            "original": {"gesamt": 11, "davon": 3},
            "frage": "In einer Stichprobenprüfung wurden insgesamt {gesamt} fehlerhafte Teile gefunden. Davon hatten {davon} Teile eine zu dünne Zinkschichtdicke. Wie viel Prozent (%) dieser Fehlerart entfallen auf alle Fehler (Anteil in der Fehlerstruktur)?",
            "loesung": "davon / gesamt * 100",
            "rundung": 1,
            "toleranzProzent": 2.0,
            "erklaerung": "{davon} von {gesamt} Fehlern entfallen auf 'zu dünne Zinkschichtdicke': {davon}/{gesamt} × 100 % ≈ {loesung} %. Dies ist der relative Anteil dieser Fehlerart an der Fehlergesamtheit – nützlich für die Pareto-Analyse zur Priorisierung von Verbesserungsmaßnahmen.",
            "workedExample": "Anteil = (Anzahl dieser Fehlerart) / (Gesamtfehler) × 100\nAnteil = {davon} / {gesamt} × 100 % ≈ {loesung} %",
        },
    },
    # Ganze Messreihen statt fuenf unabhaengiger Ziehungen: Sonst koennen
    # alle Werte zusammenfallen, und eine Spannweite von 0 ist keine
    # Aufgabe.
    "ft-qs-021": {
        "datei": QS,
        "varianten": {
            "spalten": ["m1", "m2", "m3", "m4", "m5"],
            "zeilen": [
                [20.02, 20.05, 19.98, 20.03, 20.04],
                [19.99, 20.01, 20.06, 19.97, 20.02],
                [20.00, 19.96, 20.02, 20.01, 19.99],
                [20.04, 19.94, 20.00, 20.03, 19.98],
                [19.97, 20.00, 19.99, 20.05, 20.01],
                [20.03, 20.02, 19.92, 20.00, 19.99],
            ],
            "original": {"m1": 20.02, "m2": 20.05, "m3": 19.98, "m4": 20.03, "m5": 20.04},
            "stellen": {"m1": 2, "m2": 2, "m3": 2, "m4": 2, "m5": 2, "gross": 2, "klein": 2},
            "zwischen": {
                "gross": "max(m1, m2, m3, m4, m5)",
                "klein": "min(m1, m2, m3, m4, m5)",
            },
            "frage": "In einer Stichprobe von 5 gebohrten Löchern werden folgende Durchmesser gemessen: {m1} / {m2} / {m3} / {m4} / {m5} mm. Wie groß ist die Spannweite R (in mm)?",
            "loesung": "max(m1, m2, m3, m4, m5) - min(m1, m2, m3, m4, m5)",
            "rundung": 2,
            "toleranzProzent": 5.0,
            "erklaerung": "Spannweite R = Maximalwert − Minimalwert. Max = {gross} mm; Min = {klein} mm. R = {gross} − {klein} = {loesung} mm. Die Spannweite ist ein einfaches Streuungsmaß in der statistischen Prozesskontrolle (SPC). Sie zeigt, wie weit die Messwerte auseinanderliegen.",
            "workedExample": "Max = {gross} mm; Min = {klein} mm\nR = Max − Min = {gross} − {klein} = {loesung} mm",
        },
    },
    "ft-sd-001": {
        "datei": SD,
        "varianten": {
            "variablen": {
                "d": {"werte": [20, 25, 32, 40, 50, 63, 80, 100, 125, 160]},
                "n": {"von": 100.0, "bis": 2000.0, "schritt": 50.0},
            },
            "original": {"d": 80, "n": 400},
            "zwischen": {"zaehler": "round(pi * d * n)"},
            "frage": "Ein Werkstück mit Durchmesser d = {d} mm wird gedreht. Die Drehzahl beträgt n = {n} min⁻¹. Berechne die Schnittgeschwindigkeit vc in m/min.",
            "loesung": "pi * d * n / 1000",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "vc = π · d · n / 1000 = π · {d} · {n} / 1000 ≈ {loesung} m/min.",
            "workedExample": "Gegeben: d = {d} mm, n = {n} min⁻¹\nFormel: vc = (π · d · n) / 1000\nSchritt 1: Zähler = π · {d} · {n} ≈ {zaehler} mm/min\nSchritt 2: Umrechnung in m/min: {zaehler} / 1000 = {loesung} m/min",
        },
    },
    "ft-sd-002": {
        "datei": SD,
        "varianten": {
            "variablen": {
                "vc": {"werte": [80, 100, 120, 150, 180, 200, 250, 300, 400]},
                "d": {"werte": FRAESER},
            },
            "original": {"vc": 250, "d": 50},
            "zwischen": {"nenner": "round(pi * d * 100) / 100"},
            "frage": "Für die Bearbeitung von Aluminium wird eine Schnittgeschwindigkeit von vc = {vc} m/min gewählt. Der Fräser hat einen Durchmesser von d = {d} mm. Berechne die erforderliche Drehzahl n in min⁻¹.",
            "loesung": "vc * 1000 / (pi * d)",
            "rundung": 0,
            "toleranzProzent": 1.0,
            "erklaerung": "n = vc · 1000 / (π · d) = {vc} · 1000 / (π · {d}) = {vc}000 / {nenner} ≈ {loesung} min⁻¹.",
            "workedExample": "Gegeben: vc = {vc} m/min, d = {d} mm\nFormel: n = (vc · 1000) / (π · d)\nSchritt 1: Nenner = π · {d} = {nenner} mm\nSchritt 2: n = ({vc} · 1000) / {nenner} ≈ {loesung} min⁻¹",
        },
    },
    "ft-sd-003": {
        "datei": SD,
        "varianten": {
            "variablen": {
                "fz": {"werte": [0.02, 0.04, 0.05, 0.06, 0.08, 0.1, 0.12, 0.15, 0.2]},
                "z": {"werte": [2, 3, 4, 5, 6, 8, 10]},
                "n": {"von": 400.0, "bis": 4000.0, "schritt": 100.0},
            },
            "original": {"fz": 0.08, "z": 4, "n": 1200},
            "zwischen": {"f": "round(fz * z * 1000) / 1000"},
            "frage": "Beim Fräsen beträgt der Vorschub pro Zahn fz = {fz} mm/Zahn, die Zähnezahl z = {z} und die Drehzahl n = {n} min⁻¹. Berechne die Vorschubgeschwindigkeit vf in mm/min.",
            "loesung": "fz * z * n",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "vf = fz · z · n = {fz} · {z} · {n} = {loesung} mm/min.",
            "workedExample": "Gegeben: fz = {fz} mm/Zahn, z = {z} Zähne, n = {n} min⁻¹\nFormel: vf = fz · z · n\nSchritt 1: f = fz · z = {fz} · {z} = {f} mm/U\nSchritt 2: vf = f · n = {f} · {n} = {loesung} mm/min",
        },
    },
    "ft-sd-004": {
        "datei": SD,
        "varianten": {
            "variablen": {
                "L": {"von": 50.0, "bis": 600.0, "schritt": 10.0},
                "f": {"werte": [0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5]},
                "n": {"von": 200.0, "bis": 2000.0, "schritt": 50.0},
            },
            "original": {"L": 200, "f": 0.25, "n": 800},
            "zwischen": {"vf": "round(f * n * 10) / 10"},
            "frage": "Beim Längsdrehen beträgt die zu zerspanende Länge L = {L} mm (inkl. Anlaufweg), der Vorschub f = {f} mm/U und die Drehzahl n = {n} min⁻¹. Berechne die Hauptzeit th in Minuten.",
            "loesung": "L / (f * n)",
            "rundung": 3,
            "toleranzProzent": 1.0,
            "erklaerung": "th = L / (f · n) = {L} / ({f} · {n}) = {L} / {vf} = {loesung} min.",
            "workedExample": "Gegeben: L = {L} mm, f = {f} mm/U, n = {n} min⁻¹\nFormel: th = L / (f · n)\nSchritt 1: vf = f · n = {f} · {n} = {vf} mm/min\nSchritt 2: th = L / vf = {L} / {vf} = {loesung} min",
        },
    },
    "ft-sd-005": {
        "datei": SD,
        "varianten": {
            "variablen": {
                "ap": {"werte": [0.5, 1, 1.5, 2, 2.5, 3, 4, 5, 6]},
                "f": {"werte": [0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5]},
                "vc": {"werte": SCHNITTGESCHW},
            },
            "original": {"ap": 2, "f": 0.2, "vc": 150},
            "zwischen": {"vc_mm": "vc * 1000", "Q_mm3": "round(ap * f * vc * 1000)"},
            "frage": "Das Zeitspanvolumen beim Drehen wird berechnet. Gegeben: ap = {ap} mm, f = {f} mm/U, vc = {vc} m/min. Berechne Q in cm³/min.",
            "loesung": "ap * f * vc",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Q = ap · f · vc = {ap} mm · {f} mm · {vc} m/min = {Q_mm3} mm³/min = {loesung} cm³/min. Achtung: 1 cm³ = 1000 mm³.",
            "workedExample": "Gegeben: ap = {ap} mm, f = {f} mm/U, vc = {vc} m/min\nFormel: Q = ap · f · vc (mit vc in mm/min)\nSchritt 1: vc in mm/min = {vc} · 1000 = {vc_mm} mm/min\nSchritt 2: Q = {ap} · {f} · {vc_mm} = {Q_mm3} mm³/min\nSchritt 3: Umrechnung: {Q_mm3} mm³/min ÷ 1000 = {loesung} cm³/min",
        },
    },
    # T bleibt eine vierte Potenz, damit die vierte Wurzel wie im
    # Loesungsweg glatt aufgeht.
    "ft-sd-006": {
        "datei": SD,
        "varianten": {
            "variablen": {
                "C": {"werte": [180, 200, 220, 240, 260, 300, 320]},
                "T": {"werte": [16, 81, 256]},
            },
            "original": {"C": 240, "T": 16},
            "zwischen": {"wurzel": "T^0.25"},
            "frage": "Die Taylor-Gleichung lautet vc · T^m = C mit m = 0,25 und C = {C}. Bei einer Standzeit von T = {T} min: Welche Schnittgeschwindigkeit vc ergibt sich in m/min?",
            "loesung": "C / T^0.25",
            "rundung": 0,
            "toleranzProzent": 2.0,
            "erklaerung": "vc = C / T^m = {C} / {T}^0,25 = {C} / {wurzel} = {loesung} m/min. ({T}^0,25 = ⁴√{T} = {wurzel})",
            "workedExample": "Gegeben: m = 0,25, C = {C}, T = {T} min\nFormel: vc · T^m = C  →  vc = C / T^m\nSchritt 1: T^m = {T}^0,25 = ⁴√{T} = {wurzel}\nSchritt 2: vc = {C} / {wurzel} = {loesung} m/min",
        },
    },
    "ft-ut-004": {
        "datei": UT,
        "varianten": {
            "variablen": {
                "tau": {"werte": [240, 280, 300, 320, 360, 400, 450]},
                "l": {"von": 50.0, "bis": 400.0, "schritt": 10.0},
                "s": {"werte": [1, 1.5, 2, 2.5, 3, 4, 5, 6]},
            },
            "original": {"tau": 320, "l": 150, "s": 4},
            "zwischen": {"A": "l * s", "F_kN": "round(tau * l * s / 100) / 10"},
            "frage": "Beim Scherschneiden soll ein Stahlblech mit der Scherfestigkeit τ = {tau} N/mm² gestanzt werden. Die Schnittlinie hat eine Länge von {l} mm, die Blechdicke beträgt {s} mm. Berechnen Sie die erforderliche Schnittkraft F.",
            "loesung": "tau * l * s",
            "rundung": 0,
            "toleranzProzent": 0.5,
            "erklaerung": "Die Schnittkraft berechnet sich nach F = τ · A, wobei A = l · s die Schnittfläche ist. Mit τ = {tau} N/mm², l = {l} mm und s = {s} mm ergibt sich: A = {l} mm · {s} mm = {A} mm². F = {tau} N/mm² · {A} mm² = {loesung} N = {F_kN} kN.",
            "workedExample": "Gegeben: τ = {tau} N/mm², l = {l} mm, s = {s} mm\nSchritt 1: Schnittfläche berechnen: A = l · s = {l} mm · {s} mm = {A} mm²\nSchritt 2: Schnittkraft berechnen: F = τ · A = {tau} N/mm² · {A} mm² = {loesung} N\nErgebnis: F = {loesung} N = {F_kN} kN",
        },
    },
    "ft-ut-008": {
        "datei": UT,
        "varianten": {
            "variablen": {
                "alpha": {"werte": [30, 45, 60, 90, 120]},
                "s": {"werte": [1, 1.5, 2, 2.5, 3, 4, 5]},
                "ri": {"werte": [2, 3, 4, 5, 6, 8, 10]},
                "k": {"werte": [0.3, 0.33, 0.4, 0.45, 0.5]},
            },
            "original": {"alpha": 90, "s": 3, "ri": 5, "k": 0.4},
            "zwischen": {
                "rad": "round(alpha * pi / 180 * 10000) / 10000",
                "rn": "ri + k * s",
            },
            "frage": "Ein Blechstreifen soll auf einer Länge von 200 mm um {alpha}° gebogen werden. Die Blechdicke beträgt s = {s} mm, der Innenbiegeradius r_i = {ri} mm. Berechnen Sie die Biegelänge (Länge der neutralen Faser) des gebogenen Abschnitts. Der k-Faktor beträgt {k}. Hinweis: l_Bogen = α · (r_i + k · s), α in Bogenmaß.",
            "loesung": "alpha * pi / 180 * (ri + k * s)",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "Die neutrale Faser liegt nicht genau in der Mitte der Blechdicke. Mit dem k-Faktor: r_n = r_i + k · s = {ri} + {k} · {s} = {rn} mm. Für {alpha}° gilt α = {rad} rad. l_Bogen = α · r_n = {rad} · {rn} ≈ {loesung} mm.",
            "workedExample": "Gegeben: r_i = {ri} mm, s = {s} mm, k = {k}, α = {alpha}° = {rad} rad\nSchritt 1: Radius der neutralen Faser: r_n = r_i + k · s = {ri} + {k} · {s} = {rn} mm\nSchritt 2: Bogenlänge: l_Bogen = α · r_n = {rad} · {rn} ≈ {loesung} mm",
        },
    },
    # Die Umrechnung 58 HRC = 639 HV steht so in der Aufgabe und bleibt -
    # andere Paare waeren geraten. Variabel ist der Messwert.
    "ft-ww-010": {
        "datei": WW,
        "varianten": {
            "variablen": {
                "soll_hrc": {"werte": [58]},
                "soll_hv": {"werte": [639]},
                "fehlt": {"von": 20.0, "bis": 120.0, "schritt": 5.0},
            },
            "original": {"soll_hrc": 58, "soll_hv": 639, "fehlt": 59},
            "zwischen": {
                "gemessen": "soll_hv - fehlt",
                "erreicht": "round((soll_hrc - fehlt / 9) * 10) / 10",
            },
            "frage": "Eine Stahlwelle soll auf {soll_hrc} HRC gehärtet werden. Laut Umrechnungstabelle entspricht {soll_hrc} HRC ≈ {soll_hv} HV. Die gemessene Vickershärte nach dem Härten beträgt {gemessen} HV. Um wie viel HRC fehlt die Welle ungefähr? (1 HRC ≈ 9 HV im Bereich 55-65 HRC)",
            "loesung": "fehlt / 9",
            "rundung": 1,
            "toleranzProzent": 2.0,
            "erklaerung": "ΔHV = {soll_hv} - {gemessen} = {fehlt} HV. ΔHRc = {fehlt} HV / 9 HV/HRC ≈ {loesung} HRC. Erreichter Wert ≈ {soll_hrc} - {loesung} ≈ {erreicht} HRC. Ursache: unzureichende Abkühlrate, zu kurze Haltezeit, zu niedriger C-Gehalt oder falsche Austenitisiertemperatur.",
            "workedExample": "ΔHV = {soll_hv} - {gemessen} = {fehlt} HV\nΔHRC = {fehlt} / 9 ≈ {loesung} HRC → Welle erreicht nur ~{erreicht} HRC statt {soll_hrc} HRC",
        },
    },
    "ft-ws-012": {
        "datei": WS,
        "varianten": {
            "variablen": {
                "T1": {"werte": [15, 20, 25, 30, 40, 45, 60]},
                "vc1": {"werte": [80, 100, 120, 150, 180]},
                "aufschlag": {"werte": [20, 30, 40, 50, 60, 80]},
                "m": {"werte": [0.2, 0.25, 0.3, 0.35]},
            },
            # Die zweite Schnittgeschwindigkeit wird aufgeschlagen, nicht
            # gewuerfelt - sonst koennte sie unter der ersten liegen und die
            # Aufgabe ihre Aussage verlieren.
            "original": {"T1": 30, "vc1": 100, "aufschlag": 40, "m": 0.3},
            "zwischen": {
                "vc2": "vc1 + aufschlag",
                "verhaeltnis": "round(vc1 / (vc1 + aufschlag) * 10000) / 10000",
                "exponent": "round(1 / m * 1000) / 1000",
            },
            "frage": "Ein Werkzeug hat eine Standzeit von T = {T1} min bei vc = {vc1} m/min (Taylor-Exponent m = {m}). Wie lange ist die Standzeit bei vc = {vc2} m/min? Berechne T2 in min (auf 1 Dezimalstelle).",
            "loesung": "T1 * (vc1 / (vc1 + aufschlag))^(1 / m)",
            "rundung": 1,
            "toleranzProzent": 3.0,
            "erklaerung": "T2 = T1 · (vc1/vc2)^(1/m) = {T1} · ({vc1}/{vc2})^(1/{m}) ≈ {loesung} min. Schon eine moderate Erhöhung der Schnittgeschwindigkeit verkürzt die Standzeit überproportional.",
            "workedExample": "Gegeben: T1 = {T1} min, vc1 = {vc1} m/min, vc2 = {vc2} m/min, m = {m}\nFormel: T2 = T1 · (vc1/vc2)^(1/m)\nSchritt 1: vc1/vc2 = {vc1}/{vc2} = {verhaeltnis}\nSchritt 2: 1/m = {exponent}\nSchritt 3: T2 = {T1} · {verhaeltnis}^{exponent} ≈ {loesung} min",
        },
    },
    "ft-wf-003": {
        "datei": WF,
        "varianten": {
            "variablen": {
                "fix": {"werte": [40000, 50000, 60000, 80000, 100000, 120000, 150000]},
                "kv": {"werte": [8, 10, 12, 15, 18, 20, 25]},
                "spanne": {"werte": [10, 15, 20, 25, 30, 40]},
            },
            # Der Preis ergibt sich aus den variablen Kosten plus Spanne -
            # sonst koennte er darunter liegen und es gaebe keinen
            # Break-Even.
            "original": {"fix": 80000, "kv": 15, "spanne": 20},
            "zwischen": {"preis": "kv + spanne"},
            "frage": "Fixkosten je Periode: {fix} €. Variable Kosten je Stück: {kv} €. Verkaufspreis je Stück: {preis} €. Berechne den Break-Even-Point (Mindestmenge) in Stück.",
            "loesung": "fix / spanne",
            "rundung": 1,
            "toleranzProzent": 0.5,
            "erklaerung": "BEP = Fixkosten / (Preis - variable Stückkosten) = {fix} / ({preis} - {kv}) = {fix} / {spanne} = {loesung} Stück. Deckungsbeitrag je Stück = {spanne} €. Ab dieser Menge wird Gewinn erzielt.",
            "workedExample": "Deckungsbeitrag = Preis - variable Stückkosten = {preis} - {kv} = {spanne} €/St.\nBEP = Fixkosten / Deckungsbeitrag = {fix} € / {spanne} €/St. = {loesung} Stück",
        },
    },
    "ft-wf-005": {
        "datei": WF,
        "varianten": {
            "variablen": {
                "aw": {"werte": [60000, 80000, 100000, 120000, 150000, 200000, 250000]},
                "rest_prozent": {"werte": [0, 5, 10, 15, 20, 25]},
                "jahre": {"werte": [5, 6, 8, 10, 12, 15]},
            },
            # Der Restwert als Anteil des Anschaffungswerts, damit er nie
            # darueber liegt.
            "original": {"aw": 120000, "rest_prozent": 16.6667, "jahre": 10},
            "zwischen": {
                "rw": "round(aw * rest_prozent / 100)",
                "differenz": "aw - round(aw * rest_prozent / 100)",
            },
            "frage": "Eine Maschine kostet {aw} €, hat eine Nutzungsdauer von {jahre} Jahren und einen Restwert von {rw} €. Berechne die jährliche lineare Abschreibung in €.",
            "loesung": "(aw - round(aw * rest_prozent / 100)) / jahre",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "Lineare Abschreibung: AfA (Absetzung für Abnutzung) = (Anschaffungswert - Restwert) / Nutzungsdauer = ({aw} - {rw}) / {jahre} = {differenz} / {jahre} = {loesung} €/Jahr. Abschreibungen sind keine Ausgaben, aber Kosten - sie bilden Kapital für Ersatzinvestitionen.",
            "workedExample": "AfA = (AW - RW) / n = ({aw} - {rw}) € / {jahre} Jahre = {loesung} €/Jahr",
        },
    },
    "ft-wf-011": {
        "datei": WF,
        "varianten": {
            "variablen": {
                "mss": {"werte": [45, 55, 60, 75, 90, 110, 130]},
                "th": {"von": 5.0, "bis": 60.0, "schritt": 1.0},
                "tn": {"von": 2.0, "bis": 20.0, "schritt": 1.0},
            },
            "original": {"mss": 75, "th": 18, "tn": 6},
            "zwischen": {
                "minuten": "th + tn",
                "stunden": "round((th + tn) / 60 * 10000) / 10000",
            },
            "frage": "Eine CNC-Drehmaschine hat einen Maschinenstundensatz von {mss} €/h. Die Hauptzeit eines Werkstücks beträgt {th} min, die Nebenzeit {tn} min. Berechne die Fertigungskosten (Maschinenanteil) je Stück in €.",
            "loesung": "mss * (th + tn) / 60",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "Fertigungszeit je Stück = t_h + t_n = {th} + {tn} = {minuten} min = {stunden} h. Maschinenkosten je Stück = MSS × Fertigungszeit = {mss} €/h × {stunden} h = {loesung} €/Stück. Dazu kommen Material-, Lohn- und Gemeinkosten.",
            "workedExample": "Fertigungszeit = ({th} + {tn}) min = {minuten} min = {stunden} h\nMaschinenkosten = {mss} €/h · {stunden} h = {loesung} €/Stück",
        },
    },
    "ft-zg-016": {
        "datei": ZG,
        "varianten": {
            "variablen": {
                "kc": {"werte": [1500, 1800, 2200, 2500, 2800, 3200, 3600, 4000]},
                "ap": {"werte": [0.5, 1, 1.5, 2, 2.5, 3, 4, 5]},
                "f": {"werte": [0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5]},
                "vc": {"werte": SCHNITTGESCHW},
            },
            "original": {"kc": 3200, "ap": 3, "f": 0.4, "vc": 120},
            "zwischen": {"Fc": "round(kc * ap * f * 10) / 10"},
            "frage": "Ein Werkstück aus Stahl wird gedreht. Die spezifische Schnittkraft beträgt kc = {kc} N/mm², die Schnitttiefe ap = {ap} mm, der Vorschub f = {f} mm/U und die Schnittgeschwindigkeit vc = {vc} m/min. Berechne die Schnittleistung Pc in kW.",
            "loesung": "kc * ap * f * vc / 60000",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Pc = Fc · vc / 60000. Fc = kc · ap · f = {kc} · {ap} · {f} = {Fc} N. Pc = {Fc} · {vc} / 60000 = {loesung} kW.",
            "workedExample": "Gegeben: kc = {kc} N/mm², ap = {ap} mm, f = {f} mm, vc = {vc} m/min\nSchritt 1: Schnittkraft Fc = kc · ap · f = {kc} · {ap} · {f} = {Fc} N\nSchritt 2: Pc = Fc · vc / 60 000 = {Fc} N · {vc} m/min / 60 000 = {loesung} kW",
        },
    },
}
