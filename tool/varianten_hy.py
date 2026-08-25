# -*- coding: utf-8 -*-
"""Hydraulik, Pneumatik, Instandhaltung, Steuerung.

Bei den Pruefungsaufgaben variiert wieder nur die Betriebsgroesse: Bei der
Bohrstation S19 der Druck, nicht der Kolbendurchmesser; beim Hydraulikrohr
der Volumenstrom, nicht die verbaute Rohrabmessung.

Nicht umgestellt und warum:
  au-hy-029  hat eine Zeichnung; die Masse steht im Bild.
"""

HY = "auftragsanalyse_hydraulik.json"
IH = "auftragsanalyse_instandhaltung.json"
PN = "auftragsanalyse_pneumatik.json"
SR = "auftragsanalyse_steuerung_regelung.json"

KOLBEN = [32, 40, 50, 63, 80, 100, 125]
DRUECKE = [4, 5, 6, 7, 8]

KORREKTUREN = [
    (
        HY,
        "(Masse m = 35 000 kg)",
        "(Masse m = 35000 kg)",
        "Ziffernguppierung mit Leerzeichen (au-hy-024)",
    ),
    (
        PN,
        '"loesungswert":  1404.0,',
        '"loesungswert":  1401.5,',
        "au-pn-016: pi/4 * (63^2 - 20^2) * 0,5 N/mm^2 = 1401,5 N; der "
        "Loesungsweg selbst rechnet 1402 vor, gespeichert waren 1404",
    ),
]

VARIANTEN = {
    "au-hy-002": {
        "datei": HY,
        "varianten": {
            "variablen": {
                "d": {"werte": KOLBEN},
                "p": {"von": 50.0, "bis": 320.0, "schritt": 10.0},
            },
            "original": {"d": 80, "p": 200},
            "zwischen": {
                "A": "round(pi / 4 * d^2 * 10) / 10",
                "p_nmm": "p / 10",
                "F_N": "round(pi / 4 * d^2 * p / 10)",
            },
            "frage": "Ein Hydraulikzylinder hat einen Kolbendurchmesser von d = {d} mm. Der Systemdruck beträgt p = {p} bar. Berechne die Kolbenkraft F in kN.",
            "loesung": "pi / 4 * d^2 * p / 10 / 1000",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "F = p · A = p · (π/4 · d²). Mit p = {p} bar = {p_nmm} N/mm² und A = π/4 · {d}² = {A} mm² ergibt sich F = {p_nmm} · {A} ≈ {F_N} N ≈ {loesung} kN. Größere Kolbenfläche → größere Kraft bei gleichem Druck.",
            "workedExample": "1) Fläche: A = π/4 · d² = π/4 · {d}² mm² = {A} mm²\n2) Druck umrechnen: {p} bar = {p_nmm} N/mm²\n3) Kraft: F = p · A = {p_nmm} N/mm² · {A} mm² = {F_N} N ≈ {loesung} kN",
        },
    },
    "au-hy-007": {
        "datei": HY,
        "varianten": {
            "variablen": {
                "A1": {"werte": [5, 8, 10, 12, 15, 20, 25]},
                "A2": {"werte": [50, 80, 100, 120, 150, 200, 250]},
                "F1": {"von": 100.0, "bis": 1500.0, "schritt": 50.0},
            },
            "original": {"A1": 10, "A2": 100, "F1": 500},
            "zwischen": {
                "p": "round(F1 / A1 * 100) / 100",
                "verhaeltnis": "round(A2 / A1 * 100) / 100",
            },
            "frage": "Eine Druckübersetzung: Kolben 1 hat Fläche A₁ = {A1} cm², Kolben 2 hat Fläche A₂ = {A2} cm². Welche Kraft F₂ wirkt auf Kolben 2, wenn auf Kolben 1 eine Kraft F₁ = {F1} N aufgebracht wird?",
            "loesung": "F1 * A2 / A1",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "Druck p = F₁/A₁ = {F1}/{A1} = {p} N/cm². Da der Druck überall gleich ist (Pascal), gilt F₂ = p · A₂ = {p} · {A2} = {loesung} N. Das Flächenverhältnis ({A1}:{A2}) ergibt die Kraftverstärkung (×{verhaeltnis}).",
            "workedExample": "1) Druck: p = F₁/A₁ = {F1} N / {A1} cm² = {p} N/cm²\n2) Pascalsches Gesetz: gleicher Druck im gesamten System\n3) Kraft: F₂ = p · A₂ = {p} N/cm² · {A2} cm² = {loesung} N",
        },
    },
    "au-hy-015": {
        "datei": HY,
        "varianten": {
            "variablen": {
                "Q": {"von": 5.0, "bis": 80.0, "schritt": 5.0},
                "p": {"werte": [50, 80, 100, 120, 150, 180, 200, 250, 280]},
            },
            "original": {"Q": 20, "p": 150},
            "zwischen": {
                "p_MPa": "p / 10",
                "Q_m3s": "round(Q / 60000 * 10000000) / 10000000",
            },
            "frage": "Eine Hydraulikpumpe fördert Q = {Q} l/min bei einem Druck p = {p} bar. Berechne die hydraulische Leistung P in kW.",
            "loesung": "p * Q / 600",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "P = p · Q mit konsistenten Einheiten: p = {p} bar = {p_MPa} MPa; Q = {Q} l/min = {Q_m3s} m³/s; P = {loesung} kW. Hydraulische Leistung = Druck × Volumenstrom.",
            "workedExample": "1) Einheiten: p = {p} bar = {p_MPa} MPa\n2) Q = {Q} l/min ÷ 60 ÷ 1000 = {Q_m3s} m³/s\n3) P = p · Q = {loesung} kW",
        },
    },
    # Pruefung S18: Das verbaute Rohr bleibt, der Volumenstrom ist die
    # Betriebsgroesse.
    "au-hy-021": {
        "datei": HY,
        "varianten": {
            "variablen": {
                "d_a": {"werte": [20]},
                "s": {"werte": [2.5]},
                "Q": {"von": 6.0, "bis": 45.0, "schritt": 1.0},
            },
            "original": {"d_a": 20, "s": 2.5, "Q": 15},
            "zwischen": {
                "d_i": "d_a - 2 * s",
                "A": "round(pi / 4 * (d_a - 2 * s)^2 * 100) / 100",
                "Q_mm3s": "round(Q * 1000000 / 60)",
                "v_mms": "round(Q * 1000000 / 60 / (pi / 4 * (d_a - 2 * s)^2))",
            },
            "frage": "In der Anlage wird ein Hydraulikrohr HPL-E235-NBK {d_a} × {s} verbaut (Außendurchmesser {d_a} mm, Wanddicke {s} mm). Wie groß ist die Strömungsgeschwindigkeit v (in m/s) bei einem Volumenstrom Q = {Q} L/min?",
            "loesung": "Q * 1000000 / 60 / (pi / 4 * (d_a - 2 * s)^2) / 1000",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Innendurchmesser: d_i = {d_a} mm − 2×{s} mm = {d_i} mm. Querschnittsfläche: A = π/4 × d_i² = π/4 × {d_i}² = {A} mm². Volumenstrom umrechnen: Q = {Q} L/min = {Q_mm3s} mm³/s. Strömungsgeschwindigkeit: v = Q/A = {Q_mm3s} mm³/s ÷ {A} mm² ≈ {v_mms} mm/s = {loesung} m/s.",
            "workedExample": "1) d_i = {d_a} − 2·{s} = {d_i} mm\n2) A = π/4 · {d_i}² = {A} mm²\n3) Q = {Q} L/min = {Q_mm3s} mm³/s\n4) v = Q/A = {Q_mm3s} / {A} ≈ {v_mms} mm/s = {loesung} m/s",
        },
    },
    # Der geforderte Normwert laesst sich nicht ausrechnen - er wird aus der
    # Baureihe gewaehlt. Deshalb ganze Zeilen, jede einzeln nachgerechnet.
    "au-hy-024": {
        "datei": HY,
        "varianten": {
            "spalten": ["m", "p", "d_norm"],
            "zeilen": [
                [35000, 150, 180],
                [20000, 150, 140],
                [50000, 160, 200],
                [12000, 100, 125],
                [28000, 200, 140],
                [40000, 250, 160],
            ],
            "original": {"m": 35000, "p": 150, "d_norm": 180},
            "zwischen": {
                "F": "round(m * 9.81)",
                "p_nmm": "p / 10",
                "A": "round(m * 9.81 / (p / 10))",
                "d_ber": "round(sqrt(4 * (m * 9.81 / (p / 10)) / pi) * 10) / 10",
            },
            "frage": "Zum Anheben einer Coil-Haspel (Masse m = {m} kg) wird ein Hydraulikzylinder mit Betriebsdruck p = {p} bar eingesetzt. Welcher Mindest-Kolbendurchmesser d (in mm) ist erforderlich? (g = 9,81 m/s²; nächstgrößerer Normwert wählen)",
            "loesung": "d_norm",
            "rundung": 0,
            "erklaerung": "Gewichtskraft: F = m·g = {m}·9,81 = {F} N. Druck: p = {p} bar = {p_nmm} N/mm². Kolbenfläche: A = F/p = {F}/{p_nmm} = {A} mm². Kolbendurchmesser: d = √(4·A/π) ≈ {d_ber} mm. Nächstgrößerer Normwert: d = {loesung} mm.",
            "workedExample": "1) F = {m} · 9,81 = {F} N\n2) p = {p} bar = {p_nmm} N/mm²\n3) A = F/p = {F} / {p_nmm} = {A} mm²\n4) d = √(4·A/π) ≈ {d_ber} mm\n5) Normwert: d = {loesung} mm",
        },
    },
    # Pruefung S19: Kolbendurchmesser und Wirkungsgrad gehoeren zum
    # Spannzylinder, der Betriebsdruck wird eingestellt.
    "au-hy-027": {
        "datei": HY,
        "varianten": {
            "variablen": {
                "d": {"werte": [80]},
                "eta": {"werte": [0.84]},
                "p": {"von": 60.0, "bis": 220.0, "schritt": 10.0},
            },
            "original": {"d": 80, "eta": 0.84, "p": 100},
            "zwischen": {
                "A": "round(pi / 4 * d^2 * 10) / 10",
                "p_nmm": "p / 10",
                "F_th": "round(pi / 4 * d^2 * p / 10)",
            },
            "frage": "Die Spannzylinder der Bohrstation (S19) haben Ø {d} mm Kolbendurchmesser. Der Betriebsdruck beträgt p = {p} bar. Welche Spannkraft F (in kN) wirkt auf der Kolbenseite? (Wirkungsgrad η = {eta})",
            "loesung": "pi / 4 * d^2 * p / 10 * eta / 1000",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "Kolbenfläche: A = π/4 · d² = π/4 · {d}² = {A} mm². Theoretische Kraft: F_th = p · A = {p_nmm} N/mm² · {A} mm² = {F_th} N ({p} bar = {p_nmm} N/mm²). Mit Wirkungsgrad: F = F_th · η = {F_th} · {eta} ≈ {loesung} kN.",
            "workedExample": "A = π/4 · {d}² = {A} mm²\np = {p} bar = {p_nmm} N/mm²\nF_th = {p_nmm} · {A} = {F_th} N\nF = {F_th} · {eta} ≈ {loesung} kN",
        },
    },
    "au-ih-007": {
        "datei": IH,
        "varianten": {
            "variablen": {
                "schicht": {"werte": [420, 450, 480, 510, 540]},
                "wartung": {"werte": [10, 15, 20, 25, 30, 40]},
                "stoerung": {"von": 20.0, "bis": 120.0, "schritt": 5.0},
            },
            "original": {"schicht": 480, "wartung": 20, "stoerung": 60},
            "zwischen": {
                "planzeit": "schicht - wartung",
                "betriebszeit": "schicht - wartung - stoerung",
            },
            "frage": "Eine Anlage lief in einer Schicht von {schicht} Minuten. Davon war sie {stoerung} Minuten wegen Störungen ausgefallen. Die geplante Wartungsunterbrechung betrug {wartung} Minuten. Berechne die Verfügbarkeit V in %.",
            "loesung": "(schicht - wartung - stoerung) / (schicht - wartung) * 100",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "Verfügbarkeit V = (Betriebszeit / Planzeit) × 100. Planzeit = {schicht} - {wartung} (geplante Wartung zählt nicht als Ausfall) = {planzeit} Min. Betriebszeit = {planzeit} - {stoerung} (Störung) = {betriebszeit} Min. V = {betriebszeit}/{planzeit} × 100 ≈ {loesung} %.",
            "workedExample": "1) Planzeit = {schicht} - {wartung} (Wartung) = {planzeit} Min\n2) Betriebszeit = {planzeit} - {stoerung} (Störung) = {betriebszeit} Min\n3) V = {betriebszeit}/{planzeit} × 100 ≈ {loesung} %",
        },
    },
    "au-ih-013": {
        "datei": IH,
        "varianten": {
            "variablen": {
                "stunden": {"werte": [500, 800, 1000, 1200, 1500, 2000, 2500]},
                "ausfaelle": {"werte": [3, 4, 5, 6, 8, 10]},
                "reparatur": {"von": 10.0, "bis": 60.0, "schritt": 5.0},
            },
            "original": {"stunden": 1000, "ausfaelle": 5, "reparatur": 20},
            "zwischen": {
                "betrieb": "stunden - reparatur",
                "ohne_abzug": "round(stunden / ausfaelle * 10) / 10",
            },
            "frage": "Eine Anlage hatte in {stunden} Betriebsstunden {ausfaelle} Ausfälle. Die gesamte Reparaturdauer betrug {reparatur} Stunden. Berechne den MTBF in Stunden.",
            "loesung": "(stunden - reparatur) / ausfaelle",
            "rundung": 1,
            "toleranzProzent": 3.0,
            "erklaerung": "MTBF = Betriebszeit / Anzahl Ausfälle. Zieht man die Reparaturzeit von der Betriebszeit ab: Betriebszeit = {stunden} h - {reparatur} h = {betrieb} h, MTBF = {betrieb} h / {ausfaelle} = {loesung} h. Ohne Abzug der Reparaturzeit (reine Kalenderzeit-Methode): MTBF = {stunden} h / {ausfaelle} = {ohne_abzug} h. Beide Rechenwege sind gebräuchlich und liegen innerhalb der Toleranz.",
            "workedExample": "1) Betriebszeit (ohne Stillstand) = {stunden} h - {reparatur} h = {betrieb} h\n2) MTBF = {betrieb} h / {ausfaelle} Ausfälle = {loesung} h",
        },
    },
    "au-ih-025": {
        "datei": IH,
        "varianten": {
            "variablen": {
                "anlagen": {"werte": [4, 5, 6, 8, 10]},
                "tage": {"von": 8.0, "bis": 36.0, "schritt": 2.0},
            },
            "original": {"anlagen": 5, "tage": 16},
            "zwischen": {
                "je": "round(tage / anlagen * 100) / 100",
                "neu": "anlagen + 1",
            },
            "frage": "Ein Wartungsteam wartet planmäßig {anlagen} Verladeanlagen (S18) in {tage} Arbeitstagen. Eine baugleiche {neu}. Anlage soll künftig mitgewartet werden. Wie viele Arbeitstage dauert der gesamte Wartungszyklus dann?",
            "loesung": "tage / anlagen * (anlagen + 1)",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Aufwand pro Anlage: t_Anlage = {tage} / {anlagen} = {je} Tage/Anlage. Für {neu} Anlagen: t_gesamt = {neu} · {je} = {loesung} Tage. Der Wartungszyklus verlängert sich um {je} Tage. Dies ist lineare Kapazitätsplanung: gleiche Teamstärke, gleicher Aufwand je Anlage → Zeit wächst proportional zur Anlagenzahl.",
            "workedExample": "t_Anlage = {tage} / {anlagen} = {je} Tage\nt_gesamt = {neu} · {je} = {loesung} Tage",
        },
    },
    "au-pn-003": {
        "datei": PN,
        "varianten": {
            "variablen": {"d": {"werte": KOLBEN}, "p": {"werte": DRUECKE}},
            "original": {"d": 80, "p": 6},
            "zwischen": {
                "d_m": "d / 1000",
                "A_m2": "round(pi / 4 * (d / 1000)^2 * 1000000) / 1000000",
            },
            "frage": "Ein doppeltwirkender Pneumatikzylinder hat einen Kolbendurchmesser von d = {d} mm. Der Betriebsdruck beträgt p = {p} bar. Berechnen Sie die theoretische Vorschubkraft F.",
            "loesung": "pi / 4 * d^2 * p / 10",
            "rundung": 0,
            "toleranzProzent": 0.5,
            "erklaerung": "Kolbenfläche: A = π/4 · d² = π/4 · ({d_m} m)² ≈ {A_m2} m². Druck: p = {p} bar. Kraft: F = p · A ≈ {loesung} N.",
            "workedExample": "Gegeben: d = {d} mm = {d_m} m, p = {p} bar\nSchritt 1: A = π/4 · d² = π/4 · {d_m}² = {A_m2} m²\nSchritt 2: F = p · A = {loesung} N",
        },
    },
    "au-pn-004": {
        "datei": PN,
        "varianten": {
            "variablen": {
                "d": {"werte": [25, 32, 40, 50, 63, 80]},
                "h": {"von": 40.0, "bis": 320.0, "schritt": 10.0},
            },
            "original": {"d": 50, "h": 120},
            "zwischen": {
                "A": "round(pi / 4 * d^2 * 10) / 10",
                "V_cm3": "round(pi / 4 * d^2 * h / 100) / 10",
            },
            "frage": "Ein einfachwirkender Zylinder mit Kolbendurchmesser d = {d} mm und Hub h = {h} mm wird ausgefahren. Berechnen Sie das Luftvolumen V, das beim Ausfahren benötigt wird.",
            "loesung": "pi / 4 * d^2 * h",
            "rundung": 0,
            "toleranzProzent": 0.5,
            "erklaerung": "V = A · h = (π/4 · d²) · h = (π/4 · {d}²) · {h} = {A} mm² · {h} mm ≈ {loesung} mm³ ≈ {V_cm3} cm³.",
            "workedExample": "Gegeben: d = {d} mm, h = {h} mm\nSchritt 1: A = π/4 · {d}² ≈ {A} mm²\nSchritt 2: V = A · h = {A} · {h} ≈ {loesung} mm³",
        },
    },
    "au-pn-016": {
        "datei": PN,
        "varianten": {
            "variablen": {
                "d_K": {"werte": [40, 50, 63, 80, 100, 125]},
                "d_St": {"werte": [12, 16, 20, 25, 32]},
                "p": {"werte": DRUECKE},
            },
            "original": {"d_K": 63, "d_St": 20, "p": 5},
            "zwischen": {
                "diff": "d_K^2 - d_St^2",
                "A_ring": "round(pi / 4 * (d_K^2 - d_St^2) * 10) / 10",
            },
            "frage": "Ein doppeltwirkender Zylinder (Kolben-Ø {d_K} mm, Stangen-Ø {d_St} mm) wird bei p = {p} bar eingefahren. Berechnen Sie die Einfahrkraft F_ein.",
            "loesung": "pi / 4 * (d_K^2 - d_St^2) * p / 10",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "Wirksame Fläche (Ringfläche): A_ring = π/4 · (d_K² - d_St²) = π/4 · ({d_K}² - {d_St}²) = π/4 · {diff} ≈ {A_ring} mm². F = p · A ≈ {loesung} N. Beim Einfahren zählt nur die Ringfläche - die Kolbenstange nimmt Fläche weg, deshalb ist die Einfahrkraft stets kleiner als die Ausfahrkraft.",
            "workedExample": "Gegeben: d_K = {d_K} mm, d_St = {d_St} mm, p = {p} bar\nSchritt 1: A_ring = π/4 · ({d_K}² - {d_St}²) = π/4 · {diff} ≈ {A_ring} mm²\nSchritt 2: F = p · A ≈ {loesung} N",
        },
    },
    "au-sr-016": {
        "datei": SR,
        "varianten": {
            "variablen": {
                "w": {"von": 40.0, "bis": 220.0, "schritt": 5.0},
                "e": {"werte": [2, 3, 4, 5, 6, 8, 10, 12]},
            },
            # Der Istwert wird abgeleitet, damit die Differenz nie negativ
            # ausfaellt und die Aufgabe ihre Aussage behaelt.
            "original": {"w": 80, "e": 6},
            "zwischen": {"x": "w - e"},
            "frage": "Ein Regelkreis hat eine Führungsgröße von w = {w} °C und die gemessene Regelgröße beträgt x = {x} °C. Berechne die Regeldifferenz e.",
            "loesung": "w - x",
            "rundung": 1,
            "toleranzProzent": 2.0,
            "erklaerung": "Die Regeldifferenz ist die Abweichung zwischen Soll- und Istwert: e = w – x = {w} °C – {x} °C = {loesung} °C.",
            "workedExample": "Formel: e = w – x\ne = {w} °C – {x} °C\ne = {loesung} °C",
        },
    },
    "au-sr-022": {
        "datei": SR,
        "varianten": {
            "variablen": {
                "Kp": {"werte": [0.5, 1, 1.5, 2, 2.5, 3, 4, 5, 8, 10]},
                "e": {"von": 0.5, "bis": 12.0, "schritt": 0.5},
            },
            "original": {"Kp": 4, "e": 2.5},
            "frage": "Ein P-Regler hat Kp = {Kp} und die aktuelle Regeldifferenz beträgt e = {e}. Berechne die Stellgröße y.",
            "loesung": "Kp * e",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Die Stellgröße des P-Reglers berechnet sich: y = Kp · e = {Kp} · {e} = {loesung}. Beim reinen P-Regler ist die Stellgröße direkt proportional zur Regeldifferenz - deshalb bleibt eine bleibende Regelabweichung bestehen.",
            "workedExample": "Formel: y = Kp · e\ny = {Kp} · {e}\ny = {loesung}",
        },
    },
}
