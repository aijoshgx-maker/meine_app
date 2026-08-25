# -*- coding: utf-8 -*-
"""WiSo, Werkstoffkunde, Technisches Zeichnen, Toleranzen.

Bei den WiSo-Aufgaben gilt eine zusaetzliche Grenze: Beitragssaetze und
Paragrafen sind Rechtsstand, kein Rechenstoff. Variabel ist immer nur das
Entgelt oder der Betrag - nie der Satz.

Nicht umgestellt und warum:
  au-tb-018  Sicherheitskupplung ECA 16 - Grenzmoment und Wirkdurchmesser
             sind Eigenschaften dieser Kupplung.
  au-tb-019  Einstellantrieb S17 - Antriebsleistung und beide Wirkungsgrade
             sind Auslegungsdaten der Baugruppe.
  au-tp-004  Die vier Grenzmasse von H7/g6 muessten aus ISO-286-Tabellen
             kommen. Sie aus dem Gedaechtnis nachzubilden waere geraten -
             und eine falsche Passungstabelle ist schlimmer als eine
             Aufgabe, die sich nicht aendert.
  wi-bo-013  Die Staffel des § 9 BetrVG ist Gesetzestext. Aus demselben
             Grund nicht nachgebildet.
"""

TB = "auftragsanalyse_technische_berechnungen.json"
TZ = "auftragsanalyse_technisches_zeichnen.json"
TP = "auftragsanalyse_toleranzen_passungen.json"
WK = "auftragsanalyse_werkstoffkunde.json"
BO = "wiso_betriebsorganisation.json"
ENT = "wiso_entgelt.json"
KV = "wiso_kaufvertrag.json"
MP = "wiso_markt_preisbildung.json"
SV = "wiso_sozialversicherung.json"
WKR = "wiso_wirtschaftskreislauf.json"

KORREKTUREN = [
    (WK, "reißt bei einer Kraft F = 60 000 N", "reißt bei einer Kraft F = 60000 N",
     "Ziffernguppierung mit Leerzeichen (au-wk-005)"),
    (SV, "Brutto-Arbeitsentgelt: 3 200 €/Monat", "Brutto-Arbeitsentgelt: 3200 €/Monat",
     "Ziffernguppierung mit Leerzeichen (wi-sv-002)"),
    (SV, "verdient bei der Metall AG 2.850 € brutto", "verdient bei der Metall AG 2850 € brutto",
     "Tausenderpunkt; sonst nirgends im Bestand (wi-sv-024)"),
    (KV, "Nettobetrag von 1 000 €", "Nettobetrag von 1000 €",
     "Ziffernguppierung mit Leerzeichen (wi-kv-021)"),
    (WKR, "betrug im Vorjahr 3 000 Mrd", "betrug im Vorjahr 3000 Mrd",
     "Ziffernguppierung mit Leerzeichen (wi-wk-011)"),
    (WKR, "Jahr beträgt es 3 090 Mrd", "Jahr beträgt es 3090 Mrd",
     "Ziffernguppierung mit Leerzeichen (wi-wk-011)"),
]

VARIANTEN = {
    # Pruefung S17: Laenge und Werkstoff der Antriebswelle bleiben, die
    # Betriebstemperaturen sind frei.
    "au-tb-021": {
        "datei": TB,
        "varianten": {
            "variablen": {
                "l1": {"werte": [214]},
                "T1": {"werte": [10, 15, 18, 20, 22, 25]},
                "dT": {"werte": [20, 25, 30, 35, 40, 50, 60]},
            },
            "original": {"l1": 214, "T1": 20, "dT": 30},
            "zwischen": {"T2": "T1 + dT"},
            "frage": "Die Antriebswelle aus legiertem Stahl (α = 16,1 × 10⁻⁶ K⁻¹) hat eine Länge l₁ = {l1} mm und erwärmt sich im Betrieb von {T1} °C auf {T2} °C. Wie groß ist die Längenänderung Δl (in mm)?",
            "loesung": "l1 * 0.0000161 * dT",
            "rundung": 3,
            "toleranzProzent": 3.0,
            "erklaerung": "Thermische Längenänderung: Δl = l₁ · α · Δt = {l1} mm · 16,1×10⁻⁶ K⁻¹ · {dT} K = {loesung} mm. Diese Wärmedehnung muss bei der Lagergestaltung berücksichtigt werden (Fest-Loslager-Anordnung).",
            "workedExample": "Δt = {T2} °C − {T1} °C = {dT} K\nΔl = l₁ · α · Δt\nΔl = {l1} mm · 0,0000161 K⁻¹ · {dT} K = {loesung} mm",
        },
    },
    "au-tz-007": {
        "datei": TZ,
        "varianten": {
            "variablen": {
                "faktor": {"werte": [2, 5, 10, 20]},
                "original_mass": {"von": 5.0, "bis": 60.0, "schritt": 5.0},
            },
            # Das Zeichnungsmass wird abgeleitet, damit die Division immer
            # glatt aufgeht.
            "original": {"faktor": 2, "original_mass": 30},
            "zwischen": {"zeichnungsmass": "faktor * original_mass"},
            "frage": "Eine technische Zeichnung hat den Maßstab {faktor}:1. Das in der Zeichnung gemessene Maß beträgt {zeichnungsmass} mm. Wie groß ist das tatsächliche Bauteilmaß?",
            "loesung": "original_mass",
            "rundung": 0,
            "toleranzProzent": 0.5,
            "erklaerung": "Bei einem Maßstab {faktor}:1 (Vergrößerungsmaßstab) ist die Zeichnung {faktor}-mal so groß wie das Original. Das tatsächliche Maß ergibt sich durch Division: {zeichnungsmass} mm ÷ {faktor} = {loesung} mm. Maßstab M = Zeichnungsmaß / Originalmaß.",
            "workedExample": "Gegeben: Maßstab {faktor}:1, Zeichnungsmaß = {zeichnungsmass} mm\nFormel: Originalmaß = Zeichnungsmaß ÷ Maßstabsfaktor\nRechnung: {zeichnungsmass} mm ÷ {faktor} = {loesung} mm\nErgebnis: Das tatsächliche Bauteilmaß beträgt {loesung} mm.",
        },
    },
    "au-tz-008": {
        "datei": TZ,
        "varianten": {
            "variablen": {
                "faktor": {"werte": [2, 5, 10, 20, 50]},
                "zeichnungsmass": {"von": 10.0, "bis": 120.0, "schritt": 5.0},
            },
            "original": {"faktor": 5, "zeichnungsmass": 50},
            "zwischen": {"original_mass": "faktor * zeichnungsmass"},
            "frage": "Ein Bauteil ist {original_mass} mm lang. Es soll im Maßstab 1:{faktor} gezeichnet werden. Welche Länge hat die Zeichnungsdarstellung in mm?",
            "loesung": "zeichnungsmass",
            "rundung": 0,
            "toleranzProzent": 0.5,
            "erklaerung": "Beim Verkleinerungsmaßstab 1:{faktor} ist das Zeichnungsmaß {faktor}-mal kleiner als das Original. Das Zeichnungsmaß ergibt sich durch: {original_mass} mm ÷ {faktor} = {loesung} mm. Für große Bauteile werden Verkleinerungsmaßstäbe (1:2, 1:5, 1:10 usw.) verwendet.",
            "workedExample": "Gegeben: Originallänge = {original_mass} mm, Maßstab 1:{faktor}\nFormel: Zeichnungsmaß = Originalmaß ÷ Nenner\nRechnung: {original_mass} mm ÷ {faktor} = {loesung} mm\nErgebnis: Die Zeichnungsdarstellung ist {loesung} mm lang.",
        },
    },
    # Nennmass und Grundabmass gehoeren zusammen (ISO 286, Toleranzfeld H7).
    "au-tp-003": {
        "datei": TP,
        "varianten": {
            "spalten": ["N", "es_um"],
            "zeilen": [[25, 21], [40, 25], [50, 25], [60, 30], [80, 30], [100, 35], [120, 35]],
            "original": {"N": 50, "es_um": 25},
            "zwischen": {"es_mm": "es_um / 1000"},
            "stellen": {"es_mm": 3},
            "frage": "Eine Bohrung ist mit Ø {N} H7 angegeben. Die Grundabmaße für H7 (Ø {N} mm) lauten: EI = 0 µm, ES = +{es_um} µm. Berechnen Sie das Höchstmaß der Bohrung in mm.",
            "loesung": "N + es_um / 1000",
            "rundung": 3,
            "toleranzProzent": 0.01,
            "erklaerung": "Das Höchstmaß einer Bohrung berechnet sich aus: G_max = Nennmaß + oberes Abmaß ES. Mit ES = +{es_um} µm = +{es_mm} mm: G_max = {N} + {es_mm} = {loesung} mm. Die Toleranz H7 bei Ø {N} mm beträgt {es_um} µm.",
            "workedExample": "Gegeben: Nennmaß = {N} mm, ES = +{es_um} µm = +{es_mm} mm, EI = 0 µm\nHöchstmaß G_max = Nennmaß + ES = {N} + {es_mm} = {loesung} mm\nMindestmaß G_min = Nennmaß + EI = {N} mm\nToleranz T = G_max – G_min = {es_mm} mm = {es_um} µm",
        },
    },
    "au-wk-005": {
        "datei": WK,
        "varianten": {
            "variablen": {
                "A": {"werte": [20, 30, 50, 78.5, 100, 150, 200, 250]},
                "Rm": {"werte": [340, 400, 450, 500, 550, 600, 700, 800, 900]},
            },
            # Die Kraft wird aus der Zugfestigkeit erzeugt, damit sie zum
            # Werkstoff passt - eine Probe mit 4000 N/mm^2 gaebe es nicht.
            "original": {"A": 100, "Rm": 600},
            "zwischen": {"F": "round(Rm * A)"},
            "frage": "Eine Stahlprobe hat im Zugversuch eine Querschnittsfläche von A₀ = {A} mm² und reißt bei einer Kraft F = {F} N. Berechne die Zugfestigkeit Rm in N/mm² (MPa).",
            "loesung": "round(Rm * A) / A",
            "rundung": 1,
            "toleranzProzent": 0.5,
            "erklaerung": "Zugfestigkeit Rm = F_max / A₀ = {F} N / {A} mm² = {loesung} N/mm² = {loesung} MPa. Die Zugfestigkeit ist die wichtigste Werkstoffkenngröße und wird im Zugversuch nach DIN EN ISO 6892-1 ermittelt.",
            "workedExample": "Rm = F_max / A₀ = {F} N / {A} mm² = {loesung} N/mm²",
        },
    },
    "au-wk-012": {
        "datei": WK,
        "varianten": {
            "variablen": {
                "L": {"werte": [500, 800, 1000, 1500, 2000, 2500, 3000, 5000]},
                "dT": {"werte": [20, 30, 40, 50, 60, 80, 100]},
            },
            "original": {"L": 2000, "dT": 50},
            "frage": "Ein Stahlstab hat eine Länge von L = {L} mm und wird auf ΔT = {dT} K erwärmt. Berechne die Längenänderung ΔL in mm. (Wärmeausdehnungskoeffizient α = 12 × 10⁻⁶ K⁻¹)",
            "loesung": "0.000012 * L * dT",
            "rundung": 2,
            "toleranzProzent": 3.0,
            "erklaerung": "ΔL = α · L · ΔT = 12 × 10⁻⁶ K⁻¹ · {L} mm · {dT} K = {loesung} mm. Wärmedehnung ist in der Konstruktion wichtig: Dehnungsfugen bei Brücken und Rohrleitungen, Passungen beachten.",
            "workedExample": "ΔL = α · L₀ · ΔT = 12·10⁻⁶ K⁻¹ · {L} mm · {dT} K = {loesung} mm",
        },
    },
    "wi-ent-003": {
        "datei": ENT,
        "varianten": {
            "variablen": {
                "brutto": {"von": 1800.0, "bis": 5000.0, "schritt": 50.0},
                "steuer_prozent": {"werte": [8, 10, 12, 14, 16, 18]},
                "sv_prozent": {"werte": [19, 20, 21]},
            },
            # Abzuege als Anteil vom Brutto, damit das Netto nie negativ wird.
            "original": {"brutto": 2800, "steuer_prozent": 12.5, "sv_prozent": 21.0714},
            "zwischen": {
                "lst": "round(brutto * steuer_prozent / 100)",
                "sv": "round(brutto * sv_prozent / 100)",
            },
            "frage": "Ein Arbeitnehmer (ledig, Steuerklasse I, keine Kinder) hat ein Bruttogehalt von {brutto} €/Monat. Lohnsteuer + Soli: {lst} €. SV-Beiträge (AN-Anteil): {sv} €. Wie hoch ist das Nettogehalt in €?",
            "loesung": "brutto - round(brutto * steuer_prozent / 100) - round(brutto * sv_prozent / 100)",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "Netto = Brutto - Steuern - SV-Beiträge = {brutto} - {lst} - {sv} = {loesung} €. In der Praxis erstellt der Arbeitgeber monatlich eine Gehaltsabrechnung. Er führt die einbehaltene Lohnsteuer ans Finanzamt und die SV-Beiträge an die Sozialversicherungsträger ab.",
            "workedExample": "Netto = Brutto - LSt - SV = {brutto} - {lst} - {sv} = {loesung} €",
        },
    },
    "wi-ent-006": {
        "datei": ENT,
        "varianten": {
            "variablen": {
                "stunden": {"werte": [151, 160, 168, 173, 180]},
                "lohn": {"von": 13.0, "bis": 32.0, "schritt": 0.5},
                "ueber": {"werte": [4, 6, 8, 10, 12, 15, 20]},
                "zuschlag": {"werte": [25, 30, 40, 50]},
            },
            "original": {"stunden": 168, "lohn": 18.5, "ueber": 10, "zuschlag": 25},
            "stellen": {"lohn": 2},
            "zwischen": {
                "grund": "round(stunden * lohn * 100) / 100",
                "faktor": "1 + zuschlag / 100",
                "ueberlohn": "round(ueber * lohn * (1 + zuschlag / 100) * 100) / 100",
            },
            "frage": "Ein Arbeitnehmer arbeitet monatlich {stunden} Stunden. Sein Stundenlohn beträgt {lohn} €. Er hat {ueber} Überstunden geleistet, die mit {zuschlag}% Zuschlag vergütet werden. Berechne das Bruttogehalt in €.",
            "loesung": "stunden * lohn + ueber * lohn * (1 + zuschlag / 100)",
            "rundung": 2,
            "toleranzProzent": 0.1,
            "erklaerung": "Grundlohn: {stunden} h × {lohn} €/h = {grund} €. Überstunden: {ueber} h × {lohn} × {faktor} = {ueberlohn} €. Gesamt: {grund} + {ueberlohn} = {loesung} €. Überstundenzuschlag: tariflich geregelt (meist 25-50%). Hinweis: Nur der Zuschlag ist steuer- und SV-frei, nicht der Grundlohn der Überstunde.",
            "workedExample": "Grundgehalt: {stunden} h × {lohn} €/h = {grund} €\nÜberstunden: {ueber} h × {lohn} €/h × {faktor} = {ueberlohn} €\nGesamt: {grund} + {ueberlohn} = {loesung} €",
        },
    },
    "wi-ent-014": {
        "datei": ENT,
        "varianten": {
            "variablen": {
                "richt_stueck": {"werte": [300, 400, 500, 600, 750, 800]},
                "richt_lohn": {"von": 2000.0, "bis": 4000.0, "schritt": 100.0},
                "mehr_prozent": {"werte": [5, 10, 15, 20, 25, 30]},
            },
            # Die Iststueckzahl wird aufgeschlagen, damit der Akkordlohn
            # ueber dem Richtsatzlohn liegt - so wie die Aufgabe es meint.
            "original": {"richt_stueck": 500, "richt_lohn": 2800, "mehr_prozent": 20},
            "zwischen": {
                "ist_stueck": "round(richt_stueck * (1 + mehr_prozent / 100))",
                "grad": "round(round(richt_stueck * (1 + mehr_prozent / 100)) / richt_stueck * 1000) / 1000",
            },
            "frage": "Ein Akkordarbeiter hat im Monat {ist_stueck} Stück produziert. Der Richtsatz beträgt {richt_stueck} Stück/Monat bei einem Richtsatzlohn von {richt_lohn} €. Berechne den Akkordlohn in €.",
            "loesung": "richt_lohn * round(richt_stueck * (1 + mehr_prozent / 100)) / richt_stueck",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "Stückakkord: Akkordlohn = Richtsatzlohn × (Ist-Stücke / Richtstücke) = {richt_lohn} × ({ist_stueck}/{richt_stueck}) = {richt_lohn} × {grad} = {loesung} €. Wichtig: Gesetzlich gilt der Mindestlohn als Untergrenze – auch im Akkord. Höchstakkord: oft tariflich auf 130-140% begrenzt.",
            "workedExample": "Akkordlohn = Richtsatzlohn × (Ist/Soll) = {richt_lohn} € × ({ist_stueck}/{richt_stueck}) = {richt_lohn} × {grad} = {loesung} €",
        },
    },
    "wi-kv-010": {
        "datei": KV,
        "varianten": {
            "variablen": {
                "liste": {"von": 500.0, "bis": 5000.0, "schritt": 100.0},
                "rabatt": {"werte": [5, 10, 15, 20, 25, 30]},
                "skonto": {"werte": [1, 2, 3]},
            },
            "original": {"liste": 1500, "rabatt": 20, "skonto": 2},
            "zwischen": {
                "nach_rabatt": "round(liste * (100 - rabatt) / 100 * 100) / 100",
                "r_faktor": "(100 - rabatt) / 100",
                "s_faktor": "(100 - skonto) / 100",
            },
            "frage": "Listenpreis: {liste} € netto. Händlerrabatt: {rabatt}%. Skonto bei Zahlung innerhalb 10 Tagen: {skonto}%. Berechne den Rechnungsbetrag nach Abzug aller Nachlässe (netto) in €.",
            "loesung": "liste * (100 - rabatt) / 100 * (100 - skonto) / 100",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "1) Rabatt: {liste} × {r_faktor} = {nach_rabatt} € (nach Rabatt). 2) Skonto: {nach_rabatt} × {s_faktor} = {loesung} € (nach Skonto). Reihenfolge immer: Rabatt zuerst, dann Skonto auf den rabattierten Betrag. Rabatt ist ein Preisabschlag auf den Listenpreis, Skonto ein Zahlungsabzug für schnelle Zahlung.",
            "workedExample": "1) Nach Rabatt ({rabatt}%): {liste} × {r_faktor} = {nach_rabatt} €\n2) Nach Skonto ({skonto}%): {nach_rabatt} × {s_faktor} = {loesung} €",
        },
    },
    "wi-kv-019": {
        "datei": KV,
        "varianten": {
            "variablen": {
                "aufwand": {"werte": [1, 1.5, 2, 2.5, 3, 4, 5, 8]},
                "faktor": {"werte": [1.1, 1.2, 1.25, 1.4, 1.5, 1.6, 1.8, 2]},
            },
            # Der Ertrag ergibt sich aus dem Aufwand mal Faktor - so bleibt
            # die Wirtschaftlichkeit ueber 1, wie es die Erklaerung sagt.
            "original": {"aufwand": 2, "faktor": 1.5},
            "zwischen": {"ertrag": "round(aufwand * faktor * 100) / 100"},
            "frage": "Die AllPrint GmbH hat im Geschäftsjahr Erträge von {ertrag} Mio. Euro und einen Aufwand von {aufwand} Mio. Euro. Wie groß ist die Wirtschaftlichkeit des Unternehmens?",
            "loesung": "round(aufwand * faktor * 100) / 100 / aufwand",
            "rundung": 2,
            "toleranzProzent": 1.0,
            "erklaerung": "Wirtschaftlichkeit = Ertrag / Aufwand = {ertrag} Mio. / {aufwand} Mio. = {loesung}. Ein Wert > 1 bedeutet: Erträge übersteigen den Aufwand → das Unternehmen wirtschaftet rentabel. Der Wert {loesung} bedeutet: für jeden Euro Aufwand werden {loesung} Euro Ertrag erwirtschaftet.",
            "workedExample": "Wirtschaftlichkeit = Ertrag / Aufwand\n= {ertrag} / {aufwand} = {loesung}",
        },
    },
    "wi-kv-021": {
        "datei": KV,
        "varianten": {
            "variablen": {
                "netto": {"von": 400.0, "bis": 8000.0, "schritt": 50.0},
                "skonto": {"werte": [1, 2, 2.5, 3]},
            },
            "original": {"netto": 1000, "skonto": 3},
            "zwischen": {"abzug": "round(netto * skonto / 100 * 100) / 100"},
            "frage": "Eine Bestellung für Bohrstations-Zubehör hat einen Nettobetrag von {netto} €. Bei Zahlung innerhalb von 10 Tagen gewährt der Lieferant {skonto} % Skonto. Wie viel Euro zahlt der Betrieb bei Nutzung des Skontos?",
            "loesung": "netto * (100 - skonto) / 100",
            "rundung": 2,
            "toleranzProzent": 0.1,
            "erklaerung": "Skonto = {netto} € · {skonto} % = {abzug} €. Zahlbetrag = {netto} € − {abzug} € = {loesung} €. Skonto ist ein Preisnachlass bei fristgerechter Zahlung. Der effektive Jahreszins des Skontos ist meist sehr hoch, daher lohnt sich seine Inanspruchnahme fast immer.",
            "workedExample": "Skonto = {netto} · {skonto}/100 = {abzug} €\nZahlbetrag = {netto} − {abzug} = {loesung} €",
        },
    },
    # Ganze Zeilen: Die Einordnung "einheitselastisch" steht in der
    # Erklaerung und muesste sonst mitwandern - eine Formel kann das nicht.
    "wi-mp-005": {
        "datei": MP,
        "varianten": {
            "spalten": ["p0", "p1", "q0", "q1", "klasse"],
            "zeilen": [
                [10, 12, 1000, 800, "einheitselastisch"],
                [20, 22, 500, 425, "elastisch"],
                [50, 60, 200, 190, "unelastisch"],
                [8, 10, 400, 300, "einheitselastisch"],
                [25, 30, 1200, 720, "elastisch"],
                [4, 5, 900, 855, "unelastisch"],
            ],
            "original": {"p0": 10, "p1": 12, "q0": 1000, "q1": 800, "klasse": "einheitselastisch"},
            "zwischen": {
                "dq": "q1 - q0",
                "dp": "p1 - p0",
                "mengen_aend": "round((q1 - q0) / q0 * 1000) / 1000",
                "preis_aend": "round((p1 - p0) / p0 * 1000) / 1000",
            },
            "frage": "Der Preis eines Produkts steigt von {p0} € auf {p1} €. Dadurch sinkt die Nachfragemenge von {q0} auf {q1} Stück. Berechne die Preiselastizität der Nachfrage (Betrag).",
            "loesung": "abs(((q1 - q0) / q0) / ((p1 - p0) / p0))",
            "rundung": 2,
            "toleranzProzent": 2.0,
            "erklaerung": "Preiselastizität ε = (ΔQ/Q₀) / (ΔP/P₀) = ({dq}/{q0}) / ({dp}/{p0}) = {mengen_aend} / {preis_aend}. Betrag = {loesung} ({klasse}). |ε| > 1: elastisch (Menge reagiert stark). |ε| < 1: unelastisch (Menge reagiert kaum). |ε| = 1: einheitselastisch.",
            "workedExample": "ΔQ/Q₀ = ({q1}-{q0})/{q0} = {mengen_aend}\nΔP/P₀ = ({p1}-{p0})/{p0} = {preis_aend}\nε = {mengen_aend} / {preis_aend} → |ε| = {loesung} ({klasse})",
        },
    },
    # Der Beitragssatz ist Rechtsstand und bleibt; variabel ist das Entgelt.
    "wi-sv-002": {
        "datei": SV,
        "varianten": {
            "variablen": {
                "brutto": {"von": 1500.0, "bis": 6000.0, "schritt": 50.0},
                "satz": {"werte": [40]},
            },
            "original": {"brutto": 3200, "satz": 40},
            "zwischen": {"gsvb": "round(brutto * satz / 100 * 100) / 100"},
            "frage": "Brutto-Arbeitsentgelt: {brutto} €/Monat. Gesamtsozialversicherungsbeitrag (GSVB): {satz}% des Bruttos. Wie hoch ist der Arbeitnehmeranteil zur Sozialversicherung in €?",
            "loesung": "brutto * satz / 100 / 2",
            "rundung": 2,
            "toleranzProzent": 0.5,
            "erklaerung": "GSVB = {satz}% × {brutto} = {gsvb} €. Davon trägt der AN die Hälfte: {gsvb} / 2 = {loesung} €. Der AG zahlt ebenfalls {loesung} €. Tatsächlicher Satz 2026: KV ~14,6%, PV ~3,6%, RV 18,6%, AV 2,6% = gesamt ~39,4% (je hälftig, außer UV = nur AG).",
            "workedExample": "GSVB = {satz}% · {brutto} € = {gsvb} €\nAN-Anteil = {gsvb} € / 2 = {loesung} €",
        },
    },
    "wi-sv-021": {
        "datei": SV,
        "varianten": {
            "variablen": {
                "brutto": {"von": 650.0, "bis": 1500.0, "schritt": 25.0},
                "satz": {"werte": [17.5]},
            },
            "original": {"brutto": 900, "satz": 17.5},
            "stellen": {"satz": 1},
            "zwischen": {"gesamt": "round(brutto * satz / 100 * 100) / 100"},
            "frage": "Ein Auszubildender verdient monatlich {brutto} € brutto. Der GKV-Beitragssatz beträgt insgesamt {satz} % (14,6 % allgemeiner Satz + 2,9 % durchschnittlicher Zusatzbeitrag 2026). AG und AN tragen je 50 %. Wie hoch ist der monatliche GKV-Anteil des Arbeitnehmers (in €)?",
            "loesung": "brutto * satz / 100 / 2",
            "rundung": 2,
            "toleranzProzent": 0.2,
            "erklaerung": "Gesamtbeitrag = {brutto} € · {satz} % = {gesamt} €. AN-Anteil = {gesamt} / 2 = {loesung} €.",
            "workedExample": "Gesamtbeitrag = {brutto} · {satz}/100 = {gesamt} €\nAN-Anteil = {gesamt} / 2 = {loesung} €",
        },
    },
    "wi-sv-024": {
        "datei": SV,
        "varianten": {
            "variablen": {
                "brutto": {"von": 1800.0, "bis": 6000.0, "schritt": 50.0},
                "satz": {"werte": [18.6]},
            },
            "original": {"brutto": 2850, "satz": 18.6},
            "stellen": {"satz": 1},
            "zwischen": {"gesamt": "round(brutto * satz / 100 * 100) / 100"},
            "frage": "Paul Fleissig verdient bei der Metall AG {brutto} € brutto/Monat. Der Rentenversicherungsbeitragssatz beträgt {satz} % (AG und AN tragen je 50 %). Wie hoch ist Pauls monatlicher Rentenversicherungsbeitrag (AN-Anteil, in €)?",
            "loesung": "brutto * satz / 100 / 2",
            "rundung": 2,
            "toleranzProzent": 0.2,
            "erklaerung": "Gesamtbeitrag RV = {brutto} € × {satz} % = {gesamt} €. AN-Anteil (50 %) = {gesamt} / 2 = {loesung} €. Die paritätische Aufteilung gilt für GKV, RV, ALV und PV – Arbeitgeber und Arbeitnehmer tragen je 50 %. Ausnahme: Unfallversicherung – die trägt der AG allein.",
            "workedExample": "RV-Gesamt = {brutto} · {satz}/100 = {gesamt} €\nAN-Anteil = {gesamt} / 2 = {loesung} €",
        },
    },
    "wi-wk-011": {
        "datei": WKR,
        "varianten": {
            "variablen": {
                "vorjahr": {"werte": [1200, 1500, 2000, 2500, 3000, 3500, 4000]},
                "wachstum": {"werte": [0.5, 1, 1.5, 2, 2.5, 3, 4, 5]},
            },
            # Das aktuelle BIP wird aus der Wachstumsrate erzeugt, damit die
            # Zahlen im Text zur Loesung passen.
            "original": {"vorjahr": 3000, "wachstum": 3},
            "zwischen": {
                "aktuell": "round(vorjahr * (1 + wachstum / 100))",
                "differenz": "round(vorjahr * (1 + wachstum / 100)) - vorjahr",
            },
            "frage": "Das BIP eines Landes betrug im Vorjahr {vorjahr} Mrd. €. In diesem Jahr beträgt es {aktuell} Mrd. €. Berechne das nominale Wirtschaftswachstum in %.",
            "loesung": "(round(vorjahr * (1 + wachstum / 100)) - vorjahr) / vorjahr * 100",
            "rundung": 2,
            "toleranzProzent": 2.0,
            "erklaerung": "Wachstumsrate = (BIPt - BIPt-1) / BIPt-1 × 100 = ({aktuell} - {vorjahr}) / {vorjahr} × 100 = {differenz}/{vorjahr} × 100 = {loesung} %. Nominales Wachstum enthält Preissteigerungen; reales Wachstum ist inflationsbereinigt (deflationiert mit dem BIP-Deflator).",
            "workedExample": "Wachstum = ({aktuell} - {vorjahr}) / {vorjahr} × 100 = {differenz} / {vorjahr} × 100 = {loesung} %",
        },
    },
}
