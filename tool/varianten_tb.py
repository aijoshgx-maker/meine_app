# -*- coding: utf-8 -*-
"""Technische Berechnungen.

Bei Pruefungsaufgaben variiert nur, was die Aufgabe selbst als gewaehlte
Betriebsgroesse einfuehrt - nie eine Abmessung oder Nennleistung des
benannten Bauteils. Sonst behauptete die Aufgabe etwas Falsches ueber die
Zeichnung, auf die sie sich beruft.

Nicht umgestellt und warum:
  au-tb-018  Sicherheitskupplung ECA 16 - Grenzmoment und Wirkdurchmesser
             sind Eigenschaften genau dieser Kupplung, es bleibt nichts
             frei Waehlbares uebrig.
  au-tb-019  Einstellantrieb S17 - Antriebsleistung und beide Wirkungsgrade
             sind Auslegungsdaten der Baugruppe.
  au-tb-020  hat eine Zeichnung; die Werte stehen im Bild.
  au-tb-027  hat eine Zeichnung.
"""

from varianten_basis import MOTORDREHZAHLEN, TB

KORREKTUREN = [
    (TB, "mit F = 42 000 N auf Zug", "mit F = 42000 N auf Zug",
     "Ziffernguppierung mit Leerzeichen (au-tb-004)"),
    (TB, "sollen 3 000 kg Zink", "sollen 3000 kg Zink",
     "Ziffernguppierung mit Leerzeichen (au-tb-016)"),
    (TB, "P = 24 kW bei n = 1 500 min", "P = 24 kW bei n = 1500 min",
     "Ziffernguppierung mit Leerzeichen (au-tb-024)"),
    (TB, "Betonteilen (m = 2 500 kg)", "Betonteilen (m = 2500 kg)",
     "Ziffernguppierung mit Leerzeichen (au-tb-029)"),
]

VARIANTEN = {
    "au-tb-001": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "M": {"von": 50.0, "bis": 800.0, "schritt": 10.0},
                "n": {"werte": MOTORDREHZAHLEN},
            },
            "original": {"M": 400, "n": 1500},
            "zwischen": {"omega": "round(2 * pi * n / 60 * 100) / 100"},
            "frage": "Eine Welle überträgt ein Drehmoment M = {M} Nm bei einer Drehzahl n = {n} min⁻¹. Berechne die übertragene Leistung P in kW.",
            "loesung": "M * 2 * pi * n / 60 / 1000",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "P = M · ω = M · 2π · n/60 = {M} Nm · 2π · {n}/60 s⁻¹ = {M} · {omega} ≈ {loesung} kW. Diese Formel verbindet Drehmoment und Drehzahl mit der Leistung — fundamental für Getriebe-, Motor- und Wellenauslegung.",
            "workedExample": "1) Winkelgeschwindigkeit: ω = 2π · n/60 = 2π · {n}/60 = {omega} rad/s\n2) Leistung: P = M · ω = {M} Nm · {omega} rad/s ≈ {loesung} kW",
        },
    },
    # Wertepaare aus einer Tabelle, damit die Spannung immer unter der
    # Streckgrenze bleibt - sonst waere der Satz "Stab ist sicher" in der
    # Erklaerung mal richtig und mal falsch.
    "au-tb-004": {
        "datei": TB,
        "varianten": {
            "spalten": ["F", "A"],
            "zeilen": [
                [42000, 200], [30000, 150], [24000, 200], [36000, 300],
                [50000, 250], [18000, 100], [44000, 400], [33000, 150],
            ],
            "original": {"F": 42000, "A": 200},
            "zwischen": {"S": "round(235 / (F / A) * 100) / 100"},
            "frage": "Ein Stahlstab (E = 210 000 N/mm²) mit Querschnitt A = {A} mm² wird mit F = {F} N auf Zug belastet. Berechne die Zugspannung σ in N/mm² und prüfe, ob der Stab aus S235 (R_eH = 235 N/mm²) sicher ist.",
            "loesung": "F / A",
            "rundung": 1,
            "toleranzProzent": 0.5,
            "erklaerung": "σ = F/A = {F} N / {A} mm² = {loesung} N/mm². Da σ = {loesung} < R_eH = 235 N/mm², liegt die Spannung unterhalb der Streckgrenze → Stab ist sicher (keine plastische Verformung). Sicherheitsfaktor S = R_eH/σ = 235/{loesung} ≈ {S}. In der Praxis wäre S ≥ 1,5-2,0 anzustreben.",
            "workedExample": "σ = F/A = {F} N / {A} mm² = {loesung} N/mm²\nSicherheitsnachweis: σ = {loesung} < R_eH = 235 N/mm² → bestanden\nSicherheitsfaktor: S = 235/{loesung} ≈ {S}",
        },
    },
    "au-tb-006": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "z1": {"werte": [15, 18, 20, 22, 25]},
                "z2": {"werte": [60, 66, 75, 80, 90]},
                "n1": {"werte": MOTORDREHZAHLEN},
            },
            "original": {"z1": 20, "z2": 80, "n1": 1400},
            "zwischen": {"i": "z2 / z1"},
            "frage": "Ein Zahnradgetriebe hat Antriebszähnezahl z₁ = {z1} und Abtriebszähnezahl z₂ = {z2}. Die Antriebsdrehzahl ist n₁ = {n1} min⁻¹. Berechne die Abtriebsdrehzahl n₂ in min⁻¹.",
            "loesung": "n1 * z1 / z2",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "i = z₂/z₁ = {z2}/{z1} = {i} (Übersetzungsverhältnis). n₂ = n₁ / i = {n1} / {i} = {loesung} min⁻¹. Drehmoment steigt: M₂ = M₁ · i · η (mit Wirkungsgrad η). Merksatz: größeres Rad → langsamer, mehr Drehmoment.",
            "workedExample": "1) Übersetzung: i = z₂/z₁ = {z2}/{z1} = {i}\n2) Abtriebsdrehzahl: n₂ = n₁/i = {n1}/{i} = {loesung} min⁻¹",
        },
    },
    # Steigung und Flankendurchmesser gehoeren zum Gewinde und muessen
    # zusammenpassen - deshalb aus der Tabelle. Das Anzugsmoment waehlt der
    # Monteur, das wird gewuerfelt.
    "au-tb-009": {
        "datei": TB,
        "varianten": {
            "spalten": ["gewinde", "p", "d2", "r_m"],
            "zeilen": [
                ["M8", 1.25, 7.188, 5.75],
                ["M10", 1.5, 9.026, 7],
                ["M12", 1.75, 10.863, 8.25],
                ["M16", 2.0, 14.701, 12],
            ],
            "variablen": {"M_A": {"von": 15.0, "bis": 120.0, "schritt": 5.0}},
            "original": {"gewinde": "M10", "p": 1.5, "d2": 9.026, "r_m": 7, "M_A": 35},
            "zwischen": {
                "nenner": "round((0.16 * p + 0.58 * d2 * 0.1 + 0.12 * r_m) * 1000) / 1000",
            },
            "frage": "Eine Schraube {gewinde} (Steigung p = {p} mm, Kopfreibungsradius r_m = {r_m} mm, Flankenreibzahl µ_f = 0,1, Kopfreibzahl µ_k = 0,12) soll mit Anzugsmoment M_A = {M_A} Nm angezogen werden. Wie groß ist die erzeugte Vorspannkraft F_V näherungsweise in kN? (Nutze: F_V ≈ M_A / (0,16·p + 0,58·d₂·µ_f + µ_k·r_m) mit d₂={d2} mm)",
            "loesung": "M_A * 1000 / (0.16 * p + 0.58 * d2 * 0.1 + 0.12 * r_m) / 1000",
            "rundung": 1,
            "toleranzProzent": 2.0,
            "erklaerung": "Schraubenberechnung: M_A ≈ F_V · (0,16·p + 0,58·d₂·µ_f + µ_k·r_m). Nenner: 0,16·{p} + 0,58·{d2}·0,1 + 0,12·{r_m} ≈ {nenner} mm. F_V ≈ M_A / Nenner = {M_A} Nm / {nenner} mm ≈ {loesung} kN.",
            "workedExample": "Nenner = 0,16·p + 0,58·d₂·µ_f + µ_k·r_m\nNenner = 0,16·{p} + 0,58·{d2}·0,1 + 0,12·{r_m} ≈ {nenner} mm\nF_V = M_A / Nenner = {M_A} · 1000 Nmm / {nenner} mm ≈ {loesung} kN",
        },
    },
    "au-tb-015": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "F_u": {"von": 100.0, "bis": 2000.0, "schritt": 50.0},
                "d": {"werte": [80, 100, 125, 160, 200, 250, 315, 400]},
            },
            "original": {"F_u": 500, "d": 200},
            "zwischen": {"r": "d / 2"},
            "frage": "Ein Keilriemen überträgt eine Umfangskraft F_u = {F_u} N bei einem Riemenscheibendurchmesser d = {d} mm. Berechne das übertragene Drehmoment M in Nm.",
            "loesung": "F_u * d / 2 / 1000",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "M = F_u · r = F_u · d/2 = {F_u} N · {r} mm = {loesung} Nm. Merke: r = d/2 und die Einheitenumrechnung mm → m, hier {d} mm Durchmesser also {r} mm Radius.",
            "workedExample": "M = F_u · r = {F_u} N · ({d} mm/2) = {F_u} N · {r} mm\nM = {loesung} Nm",
        },
    },
    "au-tb-016": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "m": {"werte": [1500, 2000, 2500, 3000, 3500, 4000, 5000]},
                "T1": {"werte": [400, 410, 420, 430, 440]},
                "dT": {"werte": [180, 200, 220, 240, 260, 280, 300]},
            },
            # Endtemperatur abgeleitet statt zweiter Ziehung: sonst koennte
            # sie unter der Anfangstemperatur liegen.
            "original": {"m": 3000, "T1": 420, "dT": 260},
            "zwischen": {"T2": "T1 + dT"},
            "frage": "Dem Zinkbad einer Verzinkungsanlage sollen {m} kg Zink (spez. Wärmekapazität c = 0,4 kJ/(kg·K)) zugeführt werden. Das Zink hat eine Ausgangstemperatur von {T1} °C und muss auf {T2} °C erwärmt werden. Wie groß ist die benötigte Wärme Q (in MJ)?",
            "loesung": "m * 0.4 * dT / 1000",
            "rundung": 1,
            "toleranzProzent": 0.5,
            "erklaerung": "Q = m · c · Δϑ = {m} kg · 0,4 kJ/(kg·K) · ({T2} - {T1}) K = {m} · 0,4 · {dT} = {loesung} MJ.",
            "workedExample": "Q = m · c · Δϑ\nΔϑ = {T2} °C − {T1} °C = {dT} K\nQ = {m} kg · 0,4 kJ/(kg·K) · {dT} K\nQ = {loesung} MJ",
        },
    },
    "au-tb-017": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "c": {"werte": [3, 4, 5, 6, 8, 10, 12, 15, 20]},
                "s": {"von": 2.0, "bis": 40.0, "schritt": 1.0},
            },
            "original": {"c": 5, "s": 8},
            "frage": "Eine Druckfeder hat eine Federkonstante c = {c} N/mm. Wie groß ist die Kraft F (in N), wenn die Feder um s = {s} mm zusammengedrückt wird?",
            "loesung": "c * s",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "Das Hookesche Gesetz für Federn: F = c · s = {c} N/mm · {s} mm = {loesung} N. Die Kraft wächst linear mit dem Federweg, solange die Feder im elastischen Bereich arbeitet.",
            "workedExample": "F = c · s\nF = {c} N/mm · {s} mm = {loesung} N",
        },
    },
    # Pruefung S19: r = 250 mm ist Spindelgeometrie und bleibt, die
    # Vorschubkraft ist eine Betriebsgroesse.
    "au-tb-022": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "F": {"von": 80.0, "bis": 600.0, "schritt": 20.0},
                "r_mm": {"werte": [250]},
            },
            "original": {"F": 200, "r_mm": 250},
            "zwischen": {"r_m": "r_mm / 1000"},
            "frage": "An der Bohrspindel (S19) greift eine Vorschubkraft F = {F} N im Hebelarm r = {r_mm} mm von der Lagerachse an. Welches Biegemoment M (in N·m) muss das Festlager aufnehmen?",
            "loesung": "F * r_mm / 1000",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "Biegemoment: M = F · r = {F} N · {r_m} m = {loesung} N·m. Das Festlager muss dieses Kippmoment aufnehmen. Bei der Lagerdimensionierung muss das Biegemoment in die äquivalente dynamische Belastung eingerechnet werden.",
            "workedExample": "M = F · r\nM = {F} N · {r_m} m = {loesung} N·m",
        },
    },
    # Pruefung S19: d = 160 mm ist die Werkzeugaufnahme, nur die Drehzahl
    # waehlt der Bearbeiter.
    "au-tb-023": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "n": {"von": 100.0, "bis": 900.0, "schritt": 10.0},
                "d_mm": {"werte": [160]},
            },
            "original": {"n": 330, "d_mm": 160},
            "zwischen": {
                "n_s": "round(n / 60 * 10000) / 10000",
                "d_m": "d_mm / 1000",
            },
            "frage": "Die Bohrspindel (S19) dreht mit n = {n} min⁻¹ und hat einen Außendurchmesser von d = {d_mm} mm (Werkzeugaufnahme). Welche Umfangsgeschwindigkeit v (in m/s) herrscht an der Oberfläche?",
            "loesung": "pi * d_mm / 1000 * n / 60",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Umfangsgeschwindigkeit: v = π · d · n (n in s⁻¹). Umrechnung: n = {n}/60 = {n_s} s⁻¹. v = π · {d_m} m · {n_s} = {loesung} m/s.",
            "workedExample": "n = {n} min⁻¹ = {n_s} s⁻¹\nv = π · d · n = π · {d_m} m · {n_s} s⁻¹ ≈ {loesung} m/s",
        },
    },
    # Pruefung S19: Nennleistung und Nenndrehzahl sind Typenschilddaten und
    # gehoeren zusammen - deshalb aus der Tabelle.
    "au-tb-024": {
        "datei": TB,
        "varianten": {
            "spalten": ["P_kW", "n"],
            "zeilen": [
                [24, 1500], [11, 1450], [15, 1500], [18.5, 1470],
                [30, 1500], [37, 1480], [7.5, 1440],
            ],
            "original": {"P_kW": 24, "n": 1500},
            "frage": "Der Motor der Bohrstation (S19) hat eine Nennleistung P = {P_kW} kW bei n = {n} min⁻¹. Welches Drehmoment M (in N·m) liefert der Motor?",
            "loesung": "P_kW * 1000 * 60 / (2 * pi * n)",
            "rundung": 1,
            "toleranzProzent": 0.5,
            "erklaerung": "Formel: M = P · 60 / (2π · n). Mit P = {P_kW} kW und n = {n} min⁻¹: M = {P_kW} · 1000 · 60 / (2π · {n}) ≈ {loesung} N·m.",
            "workedExample": "M = P · 60 / (2π · n)\nM = {P_kW} · 1000 · 60 / (2π · {n})\nM ≈ {loesung} N·m",
        },
    },
    # Steigung gehoert zum Gewinde (Tabelle), Drehzahl waehlt der Bearbeiter.
    "au-tb-025": {
        "datei": TB,
        "varianten": {
            "spalten": ["gewinde", "p"],
            "zeilen": [["M6", 1.0], ["M8", 1.25], ["M10", 1.5], ["M12", 1.75], ["M16", 2.0]],
            "variablen": {"n": {"von": 100.0, "bis": 600.0, "schritt": 10.0}},
            "original": {"gewinde": "M10", "p": 1.5, "n": 280},
            "frage": "Ein Gewindebohrer {gewinde} (Steigung p = {p} mm) dreht mit n = {n} min⁻¹. Welche Vorschubgeschwindigkeit vf (in mm/min) ist erforderlich, um synchron mit dem Gewinde vorzuschieben?",
            "loesung": "n * p",
            "rundung": 1,
            "toleranzProzent": 0.5,
            "erklaerung": "Beim Gewindeschneiden gilt: vf = n · p = {n} min⁻¹ · {p} mm = {loesung} mm/min. Der Vorschub muss genau der Steigung entsprechen, da sonst das Gewinde zerstört wird. Zahnriemenantriebe an der Bohrspindel sichern diese Synchronität durch schlupffreien Formschluss.",
            "workedExample": "vf = n · p = {n} · {p} = {loesung} mm/min",
        },
    },
    "au-tb-026": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "t1": {"von": 120.0, "bis": 480.0, "schritt": 20.0},
                "anteil": {"werte": [10, 15, 20, 25, 30, 40]},
            },
            # Die verbesserte Zeit wird abgeleitet, nicht gewuerfelt - sonst
            # koennte sie ueber der alten liegen.
            "original": {"t1": 260, "anteil": 25},
            "zwischen": {
                "t2": "round(t1 * (100 - anteil) / 100)",
                "dt": "t1 - round(t1 * (100 - anteil) / 100)",
            },
            "frage": "Die bisherige Bearbeitungszeit an der Bohrstation beträgt t₁ = {t1} s. Durch neue Werkzeuge wird die Zeit auf t₂ = {t2} s reduziert. Welche Zeitersparnis (in %) ergibt sich?",
            "loesung": "dt / t1 * 100",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "Zeitersparnis = (t₁ − t₂) / t₁ · 100 % = ({t1} − {t2}) / {t1} · 100 % = {dt}/{t1} · 100 % = {loesung} %.",
            "workedExample": "Δt = {t1} − {t2} = {dt} s\nErsparnis = {dt} / {t1} · 100 % = {loesung} %",
        },
    },
    # Pruefung S18: Lagerdurchmesser und Aufweitung gehoeren zum Lagertyp
    # und zur Passung - beide zusammen aus der Tabelle.
    "au-tb-028": {
        "datei": TB,
        "varianten": {
            "spalten": ["lager", "d", "dd"],
            "zeilen": [
                ["NJ1021", 105, 0.090],
                ["NJ1020", 100, 0.085],
                ["NJ1018", 90, 0.075],
                ["NJ1024", 120, 0.100],
                ["NJ1026", 130, 0.110],
            ],
            "variablen": {"T0": {"werte": [15, 18, 20, 22, 25]}},
            "original": {"lager": "NJ1021", "d": 105, "dd": 0.09, "T0": 20},
            # Die dritte Stelle ist die Aussage: 0,090 mm ist auf ein
            # Tausendstel angegeben, 0,09 mm nur auf ein Hundertstel.
            "stellen": {"dd": 3},
            "zwischen": {"dT": "round(dd / (0.0000161 * d) * 10) / 10"},
            "frage": "Das Zylinderrollenlager {lager} (d = {d} mm) der Schaltvorrichtung (S18) soll durch Erwärmen montiert werden. Die erforderliche Aufweitung des Innenrings beträgt Δd = {dd} mm, der Wärmeausdehnungskoeffizient α = 16,1 × 10⁻⁶ /K, Raumtemperatur T₀ = {T0} °C. Auf welche Temperatur T (in °C) muss das Lager erwärmt werden?",
            "loesung": "T0 + dd / (0.0000161 * d)",
            "rundung": 0,
            "toleranzProzent": 3.0,
            "erklaerung": "Temperaturerhöhung: Δt = Δd / (α · d) = {dd} / (16,1 × 10⁻⁶ · {d}) ≈ {dT} K. Montagetemperatur: T = T₀ + Δt = {T0} + {dT} ≈ {loesung} °C. Praxishinweis: Lager nicht über 80–100 °C erwärmen (Härteverlust, Schmierstoffzerstörung). Geeignet: Ölbad, Induktionserwärmer, Lagerheizgerät – nie offene Flamme.",
            "workedExample": "Δt = Δd / (α · d) = {dd} / (16,1 × 10⁻⁶ · {d}) = {dT} K\nT = {T0} + {dT} ≈ {loesung} °C",
        },
    },
    # Pruefung S18: Die Hubhoehe ist Anlagengeometrie, die Last nicht.
    "au-tb-029": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "m": {"von": 500.0, "bis": 4000.0, "schritt": 100.0},
                "h": {"werte": [0.5]},
            },
            "original": {"m": 2500, "h": 0.5},
            "frage": "Der Hubtisch der Verladeanlage (S18) hebt eine Palette mit Betonteilen (m = {m} kg) um h = {h} m an. Berechnen Sie die verrichtete Hubarbeit W (in kJ). Verwenden Sie g = 10 m/s².",
            "loesung": "m * 10 * h / 1000",
            "rundung": 1,
            "toleranzProzent": 1.0,
            "erklaerung": "Hubarbeit: W = m · g · h = {m} kg · 10 m/s² · {h} m = {loesung} kJ. Die Hubarbeit ist die Energie, die aufgewendet wird, um eine Last gegen die Schwerkraft anzuheben. In der Praxis muss der Hydraulikzylinder zusätzlich Reib- und Verlustenergie aufbringen (η < 1).",
            "workedExample": "W = m · g · h = {m} · 10 · {h} = {loesung} kJ",
        },
    },
    "au-tb-030": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "anzahl": {"werte": [6, 8, 10, 12, 15, 16]},
                "stunden": {"von": 12.0, "bis": 60.0, "schritt": 2.0},
            },
            "original": {"anzahl": 8, "stunden": 20},
            "zwischen": {
                "je": "round(stunden / anzahl * 100) / 100",
                "neu": "anzahl + 1",
            },
            "frage": "Ein Prüfteam benötigt für die Endkontrolle von {anzahl} baugleichen Baugruppen insgesamt {stunden} Arbeitsstunden. Eine {neu}. Baugruppe soll künftig mitgeprüft werden. Wie viele Arbeitsstunden dauert die Endkontrolle dann insgesamt?",
            "loesung": "stunden / anzahl * (anzahl + 1)",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Aufwand pro Baugruppe: t_Baugruppe = {stunden} / {anzahl} = {je} Stunden. Für {neu} Baugruppen: t_gesamt = {neu} · {je} = {loesung} Stunden. Dieser lineare Ansatz setzt gleiche Teamkapazität und gleichen Prüfaufwand je Baugruppe voraus.",
            "workedExample": "t_Baugruppe = {stunden} / {anzahl} = {je} Stunden\nt_gesamt = {neu} · {je} = {loesung} Stunden",
        },
    },
}
