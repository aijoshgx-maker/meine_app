# -*- coding: utf-8 -*-
"""Loest die Fragen von den konkreten Pruefungssaetzen.

Aufruf:  python tool/pruefungsbezug_loesen.py

Die Fragen waren schon vorher in eigenen Worten formuliert. Was sie mit den
Pruefungssaetzen verband, war nicht der Satzbau, sondern die Konstruktion:
Einstellantrieb, Werkzeugspindelkasten, Verladeanlage, Schaltvorrichtung,
Bohrstation - mit Positionsnummern (Pos. 6) und Bauteilkennzeichen (-RM1,
QN1, BP1/BP2) aus genau diesen Blaettern.

Dieses Skript ersetzt diese Bezuege durch neutrale Beschreibungen. Der
fachliche Inhalt bleibt unveraendert - Zahlen, Loesungswerte und richtige
Antwortindizes ruehrt es nicht an.

NICHT angefasst werden die 27 Fragen mit `bildAsset`: Sie gehoeren zu einer
Zeichnung und bleiben vorerst zusammen mit ihr bestehen.

Wiederholt aufrufbar - die Ersetzungen sind Volltexte, keine Teilersetzungen.
"""

import io
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from varianten_setzen import FRAGEN_DIR, grenzen, kompakt, lies, schreib  # noqa: E402

# id -> Feld -> neuer Wert.
#   v_frage / v_erklaerung setzen die gleichnamigen Felder im varianten-Block;
#   sie muessen zum neuen Fragetext passen, sonst schlaegt der
#   Varianten-Validator an.
NEU = {
    # --- Hydraulik: Bauteilkennzeichen durch Bauteilnamen ersetzt ---------
    "au-fa-017": {
        "frage": "Welche Aussage über eine Hydraulikanlage mit Pumpe, Druckbegrenzungsventil, 4/3-Wegeventil und Hubzylinder ist korrekt?",
        "optionen": [
            "Die Pumpe saugt das Öl aus dem Druckspeicher an.",
            "Das 4/3-Wegeventil steuert das Aus- und Einfahren des Hubzylinders; in Mittelstellung ist die Pumpe vom Verbraucher getrennt.",
            "Der Filter reinigt ausschließlich das Rücklauföl.",
            "Das Druckbegrenzungsventil erhöht den Systemdruck.",
            "Beim Absenken der Last öffnet das Rückschlagventil selbsttätig durch die Schwerkraft.",
        ],
    },
    "au-hy-019": {
        "frage": "Durch welches Bauteil wird in einem Hydraulikkreis verhindert, dass eine angehobene Last bei Druckverlust schlagartig absinkt?",
        "optionen": [
            "Rückschlagventil",
            "Manometer",
            "Druckbegrenzungsventil",
            "4/3-Wegeventil",
            "Filter",
        ],
        "erklaerung": "Das Rückschlagventil im Hubzylinder-Kreis lässt Öl nur in eine Richtung fließen – in den Zylinder hinein, aber nicht heraus. Bei Druckverlust, etwa durch Pumpenausfall, bleibt es geschlossen und verhindert ein unkontrolliertes Absinken der Last. Das Druckbegrenzungsventil schützt vor Überdruck, sichert aber nicht gegen Druckverlust.",
    },
    "au-hy-020": {
        "frage": "Welches Bauteil schützt eine Hydraulikanlage vor zu hohem Druck?",
        "optionen": [
            "Druckbegrenzungsventil",
            "Filter",
            "Manometer",
            "Pumpe",
            "Rückschlagventil",
        ],
        "erklaerung": "Das Druckbegrenzungsventil (Sicherheitsventil) öffnet, wenn der Systemdruck einen eingestellten Grenzwert überschreitet, und leitet das Öl zurück zum Tank. So wird die Anlage vor Überlastung und Beschädigung geschützt. Der Filter reinigt das Öl, das Manometer zeigt den Druck nur an, die Pumpe erzeugt den Volumenstrom, das Rückschlagventil sperrt eine Fließrichtung.",
    },
    "au-hy-024": {
        "frage": "Zum Anheben einer Last (Masse m = 35000 kg) wird ein Hydraulikzylinder mit Betriebsdruck p = 150 bar eingesetzt. Welcher Mindest-Kolbendurchmesser d (in mm) ist erforderlich? (g = 9,81 m/s²; nächstgrößerer Normwert wählen)",
        "v_frage": "Zum Anheben einer Last (Masse m = {m} kg) wird ein Hydraulikzylinder mit Betriebsdruck p = {p} bar eingesetzt. Welcher Mindest-Kolbendurchmesser d (in mm) ist erforderlich? (g = 9,81 m/s²; nächstgrößerer Normwert wählen)",
    },
    "au-hy-025": {
        "frage": "In einem Hydraulikkreis steht ein Wegeventil in der Mittelstellung „offene Mitte“ (P gesperrt, A und B offen zu T). Welchen Schaltzustand haben die Arbeitsleitungen A und B?",
    },
    "au-hy-026": {
        "frage": "An einer Bohreinheit dürfen die Bohrspindeln erst anlaufen, wenn die Werkstückspannung vollständig aufgebaut ist. Welche hydraulischen Bauelemente übernehmen diese Verriegelungsfunktion?",
        "optionen": [
            "Drosselrückschlagventile an den Spannzylindern",
            "Druckbegrenzungsventile",
            "Druckschalter",
            "Wegeventile",
            "Rückschlagventile in der Speiseleitung",
        ],
        "freieAntwort": ["Druckwächter"],
        "erklaerung": "Druckschalter wandeln einen hydraulischen Druck in ein elektrisches Signal um. Sobald der Spanndruck in den Spannzylindern den eingestellten Schaltpunkt erreicht hat, schließen sie und geben das elektrische Startsignal für die Bohrspindeln frei. Druckbegrenzungsventile begrenzen den maximalen Systemdruck; Wegeventile steuern die Richtung, nicht den Verriegelungszustand.",
    },
    "au-hy-027": {
        "frage": "Die Spannzylinder einer Bohrvorrichtung haben Ø 80 mm Kolbendurchmesser. Der Betriebsdruck beträgt p = 100 bar. Welche Spannkraft F (in kN) wirkt auf der Kolbenseite? (Wirkungsgrad η = 0,84)",
        "v_frage": "Die Spannzylinder einer Bohrvorrichtung haben Ø {d} mm Kolbendurchmesser. Der Betriebsdruck beträgt p = {p} bar. Welche Spannkraft F (in kN) wirkt auf der Kolbenseite? (Wirkungsgrad η = {eta})",
    },
    "au-hy-028": {
        "frage": "Das Druckbegrenzungsventil einer hydraulischen Spannvorrichtung ist auf p = 100 bar eingestellt. Was passiert, wenn der Systemdruck diesen Wert überschreitet?",
        "optionen": [
            "Es schaltet die Pumpe ab.",
            "Es leitet das Öl zu einer zweiten Pumpe.",
            "Es schließt das Wegeventil.",
            "Es sperrt die Leitung vollständig ab.",
            "Es öffnet und leitet Öl zum Tank zurück und begrenzt den Druck so auf 100 bar.",
        ],
    },
    "au-hy-030": {
        "frage": "In einer Hydraulikanlage wird für einen Hubtisch ein 5/3-Wegeventil (elektrisch betätigt) eingesetzt, für einen Positionierzylinder ein 5/2-Wegeventil (manuell betätigt). Was ist der wesentliche Unterschied zwischen diesen Ventiltypen?",
        "erklaerung": "5/3-Wegeventil: 5 Anschlüsse (P, A, B, T1, T2), 3 Schaltstellungen (links – Mitte – rechts). Die federzentrierte Mittelstellung kann den Zylinder sperren oder drucklos schalten – wichtig als Sicherheitsfunktion bei Stromausfall, damit der Hubtisch stehen bleibt. Das 5/2-Ventil hat nur 2 Stellungen und keine definierte Mittelstellung.",
    },
    "au-hy-031": {
        "frage": "In einer Hydraulikanlage sind Rückschlagventile verbaut. Was ist die grundlegende Funktion eines Rückschlagventils?",
    },
    # --- Funktionsanalyse -------------------------------------------------
    "au-fa-018": {
        "frage": "Ein Kegelradgetriebe besitzt zwei gleich große Kegelräder (m = 2, z = 26). Welche Aufgabe erfüllt dieses Getriebe?",
    },
    "au-fa-023": {
        "frage": "In einer Hydraulikanlage ist ein Positionierzylinder mit einem eigenen Druckbegrenzungsventil (60 bar) abgesichert, obwohl das Hauptdruckbegrenzungsventil der Anlage auf 130 bar eingestellt ist. Warum ist die separate Absicherung notwendig?",
        "optionen": [
            "Weil das zweite Ventil den Zylinder nach dem Positionieren arretiert.",
            "Weil 130 bar für diesen Zylinder nicht ausreichen würden.",
            "Weil das zweite Ventil den Volumenstrom am Zylinder reguliert.",
            "Weil der Zylinder nur geringe Kräfte benötigt und zu hoher Druck das Werkstück oder die Führungskonstruktion beschädigen würde.",
            "Weil das Hauptventil zu weit vom Zylinder entfernt sitzt.",
        ],
        "erklaerung": "Der Positionierzylinder dient nur zum Ausrichten – 130 bar wären dafür überdimensioniert und könnten das Werkstück oder die Führungskonstruktion überlasten. Das separate Druckbegrenzungsventil mit 60 bar begrenzt den Druck in diesem Teilkreis auf einen sicheren Wert. Eine eigene Druckbegrenzung für empfindliche Teilkreise ist in Hydraulikanlagen mit unterschiedlichen Kraftanforderungen üblich.",
    },
    "au-fa-024": {
        "frage": "Eine Anlage im Außenbereich besteht aus einer Stahlrahmenkonstruktion; als Abdeckungen sind Aluminiumbleche direkt auf den Stahlträgern befestigt. An den Aluminiumblechen tritt Korrosion auf. Wie lässt sich diese Kontaktkorrosion gezielt verhindern?",
    },
    # --- Instandhaltung ---------------------------------------------------
    "au-ih-018": {
        "frage": "Im Rahmen einer planmäßigen Inspektion an einem Kegelradgetriebe werden verschiedene Tätigkeiten durchgeführt. Welche Tätigkeitskombination gehört zur Inspektion nach DIN 31051?",
    },
    "au-ih-020": {
        "frage": "An einer Bohreinheit wird ein Keilriemenantrieb nach Ablauf von 8 000 Betriebsstunden laut Wartungsplan ausgetauscht – unabhängig vom sichtbaren Zustand des Riemens. Welcher Instandhaltungsstrategie entspricht das?",
    },
    "au-ih-021": {
        "frage": "Vor dem Zerlegen eines Spindelkastens wird die Keilriemenspannung mit einem Federkraftmessgerät gemessen und mit dem Sollwert verglichen. Welche Instandhaltungsmaßnahme ist das nach DIN 31051?",
    },
    "au-ih-022": {
        "frage": "Beim Ausbau einer Werkzeugspindel müssen die Kegelrollenlager fachgerecht demontiert werden. Ordnen Sie die Schritte richtig (Schritt 1 = zuerst):",
    },
    "au-ih-023": {
        "frage": "Ein Zylinderrollenlager (d = 105 mm, Presspassung auf der Welle) soll durch Erwärmen montiert werden. Warum, und welche Maximaltemperatur darf dabei nicht überschritten werden?",
    },
    "au-ih-025": {
        "frage": "Ein Wartungsteam wartet planmäßig 5 baugleiche Anlagen in 16 Arbeitstagen. Eine 6. Anlage soll künftig mitgewartet werden. Wie viele Arbeitstage dauert der gesamte Wartungszyklus dann?",
        "v_frage": "Ein Wartungsteam wartet planmäßig {anlagen} baugleiche Anlagen in {tage} Arbeitstagen. Eine {neu}. Anlage soll künftig mitgewartet werden. Wie viele Arbeitstage dauert der gesamte Wartungszyklus dann?",
    },
    # --- Maschinenelemente ------------------------------------------------
    "au-me-023": {
        "frage": "Eine Bogenzahnkupplung überträgt das Drehmoment vom Motor auf eine Gelenkwelle. Welche Eigenschaft zeichnet die Bogenzahnkupplung aus?",
    },
    "au-me-029": {
        "frage": "Ein Schieberadgetriebe ermöglicht zwei Drehzahlstufen der Spindel. Welche Verbindungsart zwischen Schieberad und Welle wird eingesetzt, damit das Rad axial verschoben werden kann und gleichzeitig Drehmoment überträgt?",
    },
    "au-me-030": {
        "frage": "Ein Schieberadgetriebe hat in Gangstufe 1 die Zahnzahlen z₁=66 (Antrieb) und z₂=18 (Spindel). Der Antrieb dreht mit n₁ = 750 min⁻¹. Welche Drehzahl n₂ (in min⁻¹) erreicht die Spindel?",
        "v_frage": "Ein Schieberadgetriebe hat in Gangstufe 1 die Zahnzahlen z₁={z1} (Antrieb) und z₂={z2} (Spindel). Der Antrieb dreht mit n₁ = {n1} min⁻¹. Welche Drehzahl n₂ (in min⁻¹) erreicht die Spindel?",
    },
    "au-me-031": {
        "frage": "Welche Aussage beschreibt den Vorteil eines Zahnriemenantriebs gegenüber einem Keilriemenantrieb?",
    },
    "au-me-033": {
        "frage": "Eine Werkzeugspindel ist mit Kegelrollenlagern (d = 50 mm) in O-Anordnung gelagert. Welche Lastrichtungen nimmt diese Anordnung auf?",
    },
    "au-me-034": {
        "frage": "In einem Getriebe sind Zylinderrollenlager der Bauform NJ (d = 105 mm, D = 160 mm, B = 26 mm) verbaut. Was unterscheidet die Bauform NJ von der Bauform NU?",
        "erklaerung": "Zylinderrollenlager Bauformen: NU = kein Bord am Innenring → axial in beide Richtungen frei → reines Loslager. NJ = ein fester Bord am Innenring → kann Axialkraft in einer Richtung aufnehmen → Halbfestlager. Beide nehmen radiale Kräfte auf. In der Praxis werden beide Bauformen kombiniert: NJ führt eine Axialrichtung, NU ermöglicht den Ausgleich der Wärmedehnung.",
    },
    # --- Steuerung und Regelung ------------------------------------------
    "au-sr-027": {
        "frage": "In einem GRAFCET soll erst dann in den nächsten Schritt übergegangen werden, wenn BEIDE Druckschalter einer Spannvorrichtung geschlossen haben. Welcher logische Operator verknüpft die beiden Signale in der Transitionsbedingung?",
        "erklaerung": "Die Transitionsbedingung lautet: Druckschalter 1 UND Druckschalter 2. Erst wenn beide Spannzylinder den Spanndruck erreicht haben, darf gebohrt werden. Das ist ein UND (AND, Konjunktion): Alle Bedingungen müssen erfüllt sein. Ein ODER würde bereits beim Ansprechen EINES Druckschalters freigeben – damit wäre unsicheres Bohren möglich.",
    },
    "au-sr-028": {
        "frage": "Ein Reed-Kontakt erkennt die Endlage eines Anschlags. Worauf reagiert ein Reed-Kontakt?",
    },
    "au-sr-029": {
        "frage": "Eine GRAFCET-Transitionsbedingung verknüpft zwei Signale mit einem Punkt (·), also mit UND. Sie soll in die Funktionsbausteinsprache (FBS/FBD, IEC 61131-3) der SPS übertragen werden. Welcher Funktionsbaustein wird verwendet?",
        "erklaerung": "Die GRAFCET-UND-Verknüpfung entspricht in der Funktionsbausteinsprache (FBS, IEC 61131-3) einem AND-Baustein. Beide Eingänge müssen „1“ (wahr) sein, damit der Ausgang „1“ wird und die Transition schaltet. Der AND-Baustein ist die direkte grafische Entsprechung der Booleschen UND-Funktion.",
    },
    "au-sr-030": {
        "frage": "In einer GRAFCET-Ablaufsteuerung unterscheidet man Schritte und Transitionen. Was beschreibt ein Schritt (Étape), und was beschreibt eine Transition?",
    },
    "au-sr-031": {
        "frage": "Ordnen Sie die Hydraulikventile ihrer Funktion zu.",
        "paare": [
            {
                "links": "4/3-Wegeventil",
                "rechts": "Steuert die Bewegungsrichtung eines doppeltwirkenden Zylinders",
            },
            {
                "links": "Druckbegrenzungsventil",
                "rechts": "Begrenzt den Systemdruck und leitet Überschussöl zum Tank",
            },
            {
                "links": "Drosselrückschlagventil",
                "rechts": "Drosselt in einer Richtung, in der Gegenrichtung fließt das Öl frei",
            },
            {
                "links": "Entsperrbares Rückschlagventil",
                "rechts": "Hält eine angehobene Last und wird zum Absenken gezielt geöffnet",
            },
        ],
        "erklaerung": "Wegeventile steuern die Richtung des Ölstroms, Druckventile den Druck. Das Druckbegrenzungsventil öffnet bei Überschreiten des eingestellten Werts zum Tank hin. Das Drosselrückschlagventil wirkt nur in einer Richtung drosselnd und bestimmt damit die Geschwindigkeit. Das entsperrbare Rückschlagventil sperrt selbsttätig und wird zum Absenken über eine Steuerleitung geöffnet – so bleibt eine angehobene Last auch bei Druckverlust stehen.",
    },
    "au-sr-032": {
        "frage": "Eine GRAFCET-Ablaufsteuerung hat sechs Schritte (S0–S5). Der erste Schritt S0 ist immer aktiv, wenn die Anlage in Ruhe ist. Wie nennt man diesen Ausgangszustand, und wie wird er im GRAFCET-Diagramm gekennzeichnet?",
    },
    # --- Technische Berechnungen -----------------------------------------
    "au-tb-018": {
        "frage": "Eine Sicherheitskupplung spricht bei einem Grenzdrehmoment von M = 16 N·m an. Der Wirkdurchmesser der Synchronriemenscheibe beträgt d_w = 76,5 mm. Wie groß ist die maximale Zugkraft F (in N) auf den Zahnriemen?",
    },
    "au-tb-019": {
        "frage": "Ein Antrieb hat eine Antriebsleistung P₁ = 9,24 kW. Wirkungsgrad der Lagerstellen: η₁ = 0,95; Wirkungsgrad des Kegelradgetriebes: η₂ = 0,85. Wie groß ist die abgegebene Nutzleistung P₂ (in kW)?",
    },
    "au-tb-022": {
        "frage": "An einer Bohrspindel greift eine Vorschubkraft F = 200 N im Hebelarm r = 250 mm von der Lagerachse an. Welches Biegemoment M (in N·m) muss das Festlager aufnehmen?",
        "v_frage": "An einer Bohrspindel greift eine Vorschubkraft F = {F} N im Hebelarm r = {r_mm} mm von der Lagerachse an. Welches Biegemoment M (in N·m) muss das Festlager aufnehmen?",
    },
    "au-tb-023": {
        "frage": "Eine Bohrspindel dreht mit n = 330 min⁻¹ und hat an der Werkzeugaufnahme einen Außendurchmesser von d = 160 mm. Welche Umfangsgeschwindigkeit v (in m/s) herrscht an der Oberfläche?",
        "v_frage": "Eine Bohrspindel dreht mit n = {n} min⁻¹ und hat an der Werkzeugaufnahme einen Außendurchmesser von d = {d_mm} mm. Welche Umfangsgeschwindigkeit v (in m/s) herrscht an der Oberfläche?",
    },
    "au-tb-024": {
        "frage": "Der Antriebsmotor einer Bohreinheit hat eine Nennleistung P = 24 kW bei n = 1500 min⁻¹. Welches Drehmoment M (in N·m) liefert der Motor?",
        "v_frage": "Der Antriebsmotor einer Bohreinheit hat eine Nennleistung P = {P_kW} kW bei n = {n} min⁻¹. Welches Drehmoment M (in N·m) liefert der Motor?",
    },
    "au-tb-026": {
        "frage": "Die bisherige Bearbeitungszeit an einer Bohreinheit beträgt t₁ = 260 s. Durch neue Werkzeuge wird die Zeit auf t₂ = 195 s reduziert. Welche Zeitersparnis (in %) ergibt sich?",
        "v_frage": "Die bisherige Bearbeitungszeit an einer Bohreinheit beträgt t₁ = {t1} s. Durch neue Werkzeuge wird die Zeit auf t₂ = {t2} s reduziert. Welche Zeitersparnis (in %) ergibt sich?",
    },
    "au-tb-028": {
        "frage": "Ein Zylinderrollenlager NJ1021 (d = 105 mm) soll durch Erwärmen montiert werden. Die erforderliche Aufweitung des Innenrings beträgt Δd = 0,090 mm, der Wärmeausdehnungskoeffizient α = 16,1 × 10⁻⁶ /K, Raumtemperatur T₀ = 20 °C. Auf welche Temperatur T (in °C) muss das Lager erwärmt werden?",
        "v_frage": "Ein Zylinderrollenlager {lager} (d = {d} mm) soll durch Erwärmen montiert werden. Die erforderliche Aufweitung des Innenrings beträgt Δd = {dd} mm, der Wärmeausdehnungskoeffizient α = 16,1 × 10⁻⁶ /K, Raumtemperatur T₀ = {T0} °C. Auf welche Temperatur T (in °C) muss das Lager erwärmt werden?",
    },
    "au-tb-029": {
        "frage": "Ein Hubtisch hebt eine Palette (m = 2500 kg) um h = 0,5 m an. Berechnen Sie die verrichtete Hubarbeit W (in kJ). Verwenden Sie g = 10 m/s².",
        "v_frage": "Ein Hubtisch hebt eine Palette (m = {m} kg) um h = {h} m an. Berechnen Sie die verrichtete Hubarbeit W (in kJ). Verwenden Sie g = 10 m/s².",
    },
    # --- Werkstoffkunde ---------------------------------------------------
    "au-wk-020": {
        "frage": "Eine geschweißte Konsole besteht aus S235JR. Welche Werkstoffeigenschaft macht S235JR besonders geeignet für Schweißkonstruktionen?",
    },
    "au-wk-021": {
        "frage": "Zahnräder aus 16MnCr5 sollen eine harte, verschleißfeste Oberfläche bei zähem Kern erhalten. Welche Wärmebehandlung ist dafür vorgesehen?",
        "erklaerung": "16MnCr5 ist ein Einsatzstahl (DIN EN 10084). Mit 0,16 % C ist der Kohlenstoffgehalt zu niedrig für direktes Härten. Beim Einsatzhärten (Aufkohlen auf etwa 0,8 % C und anschließendes Abschrecken) entsteht eine harte, verschleißfeste Randschicht (HRC 58–63) bei zähem Kern – ideal für hoch belastete Zahnräder. Vergüten ergibt gleichmäßige Zähigkeit, aber keine Oberflächenhärte.",
    },
    "au-wk-022": {
        "frage": "Die Schaltgabel eines Schieberadgetriebes hat Gleiteinsätze aus CuSn12. Welche Eigenschaft macht diesen Werkstoff für Gleiteinsätze besonders geeignet?",
    },
    "au-wk-023": {
        "frage": "Führungsleisten in einem Spindelkopf bestehen aus PE-HD. Welcher Werkstoffgruppe gehört PE-HD an?",
    },
    "au-wk-024": {
        "frage": "Passstücke bestehen aus dem Automatenstahl 11SMn30+C. Welches Legierungselement verbessert bei diesem Werkstoff die Zerspanbarkeit?",
    },
    "au-wk-027": {
        "frage": "An einer Anlage im Außenbereich kommen Aluminiumprofile und Stahlkonstruktionen in direkten Kontakt. Nach kurzer Zeit tritt Korrosion an den Aluminiumteilen auf. Welche Korrosionsart ist das, und welches Metall wird vorzugsweise abgebaut?",
    },
    # --- Fertigungstechnik ------------------------------------------------
    "ft-cnc-020": {
        "frage": "Beim Einrichten einer CNC-Maschine wird der Maschinennullpunkt (M) benötigt. Wer legt den Maschinennullpunkt fest?",
    },
    "ft-cnc-021": {
        "frage": "Welche Werkzeugkorrekturen werden in einem CNC-Programm typischerweise programmiert?",
    },
    "ft-cnc-022": {
        "frage": "Für eine Vorschubachse wird eine Kugelgewindespindel eingesetzt statt einer Trapezgewindespindel. Welchen Hauptvorteil hat die Kugelgewindespindel?",
    },
    "ft-qs-022": {
        "frage": "Eine Fertigungsanlage hat hohe Stillstandszeiten. Um die Hauptursachen zu identifizieren, sollen die Störungsmeldungen nach Häufigkeit geordnet und die wichtigsten Ursachen priorisiert werden. Welche Qualitätsmethode ist hierfür geeignet?",
    },
    "ft-ww-018": {
        "frage": "Eine geschweißte Konsole soll nach dem Schweißen weiter mechanisch bearbeitet werden. Welches Wärmebehandlungsverfahren ist vorher durchzuführen?",
    },
    "ft-ww-021": {
        "frage": "Eine Ritzelwelle (16MnCr5, einsatzgehärtet HRC 58–62) muss an den Lagersitzen auf Endmaß geschliffen werden. Welches Schleifmittel ist geeignet?",
    },
    "ft-ww-022": {
        "frage": "Nach dem Einsatzhärten von Zahnrädern ist die aufgekohlte Randschicht zu dünn. Was ist die wahrscheinlichste Ursache?",
    },
    "ft-ww-023": {
        "frage": "Zahnräder bestehen aus dem Stahl 16MnCr5. Was bedeuten die Kurzzeichenbestandteile: die Zahl 16, das Kürzel MnCr und die Zahl 5?",
    },
    "ft-ww-024": {
        "frage": "Das Einsatzhärten von Zahnrädern aus 16MnCr5 besteht aus mehreren Wärmebehandlungsschritten. Welcher Schritt wird als letzter durchgeführt?",
    },
    # --- WiSo -------------------------------------------------------------
    "wi-kv-023": {
        "frage": "Die Metall AG (eingetragener Vollkaufmann) bestellt Hydraulikzylinder. Bei der Wareneingangskontrolle 3 Wochen nach Lieferung entdeckt der Lagerleiter einen versteckten Mangel. Welche gesetzliche Pflicht muss die Metall AG jetzt unverzüglich erfüllen?",
    },
    "wi-kv-024": {
        "frage": "Der Lieferant der Hydraulikzylinder liefert 4 Wochen zu spät. Die Metall AG erleidet dadurch einen Produktionsausfall (Schaden: 8.000 €). Welchen rechtlichen Anspruch hat die Metall AG gegen den Lieferanten?",
    },
    "wi-kv-021": {
        "frage": "Eine Bestellung für Werkzeugzubehör hat einen Nettobetrag von 1000 €. Bei Zahlung innerhalb von 10 Tagen gewährt der Lieferant 3 % Skonto. Wie viel Euro zahlt der Betrieb bei Nutzung des Skontos?",
        "v_frage": "Eine Bestellung für Werkzeugzubehör hat einen Nettobetrag von {netto} €. Bei Zahlung innerhalb von 10 Tagen gewährt der Lieferant {skonto} % Skonto. Wie viel Euro zahlt der Betrieb bei Nutzung des Skontos?",
    },
    # --- Verzinkungsanlage: eigener Pruefungssatz, beim ersten Durchgang
    #     uebersehen. Die Erklaerung von au-sr-023 nannte die Herkunft sogar
    #     ausdruecklich ("IHK-Schaltplanbezeichnung").
    "au-et-023": {
        "frage": "In einem Heizkreis ist ein NTC-Widerstand (Thermistor) verbaut. Wie verändert sich sein elektrischer Widerstand bei steigender Temperatur?",
    },
    "au-sr-023": {
        "frage": "Welches Sensorelement wird eingesetzt, um die Temperatur eines Schmelzbades zu messen?",
        "erklaerung": "Für Temperaturen in Schmelzbädern werden Thermoelemente (Typ K oder N) oder PT100-Widerstandsthermometer eingesetzt. Reedkontakte reagieren auf Magnetfelder, induktive und kapazitive Näherungsschalter auf Annäherung – alle drei erfassen Positionen, keine Temperaturen. Eine Lichtschranke erkennt die Unterbrechung eines Lichtwegs.",
    },
    "au-sr-024": {
        "frage": "In einem GRAFCET-Netz (SFC) soll ein Heizstab nach Erreichen der Solltemperatur abgeschaltet werden. Welche GRAFCET-Element-Kombination beschreibt diesen Ablauf korrekt?",
        "optionen": [
            "Transition (Temperatursensor ≥ ϑ_soll) → Schritt (Aktion: Heizstab ein) → Schritt",
            "Schritt → Schritt → Transition",
            "Aktion (Heizstab ein) → Schritt → Aktion (Heizstab aus)",
            "Transition → Aktion → Schritt",
            "Schritt (Aktion: Heizstab ein) → Transition (Temperatursensor ≥ ϑ_soll) → Schritt (Aktion: Heizstab aus)",
        ],
        "erklaerung": "GRAFCET besteht aus Schritten (Zuständen mit Aktionen) und Transitionen (Übergangsbedingungen). Der korrekte Ablauf ist: Schritt mit der Aktion „Heizstab ein“ → die Transition „Temperatursensor ≥ ϑ_soll“ schaltet → nächster Schritt mit der Aktion „Heizstab aus“. Aktionen sind immer einem Schritt zugeordnet, nie einer Transition.",
    },
    "au-sr-025": {
        "frage": "Ordnen Sie den Einsatzfällen den passenden Sensortyp zu.",
        "paare": [
            {
                "links": "Zylinder in Endstellung (Magnet am Kolben)",
                "rechts": "Reedkontakt",
            },
            {
                "links": "Erkennung eines metallischen Werkstückträgers",
                "rechts": "Induktiver Näherungsschalter",
            },
            {
                "links": "Temperatur eines Schmelzbades",
                "rechts": "Temperatursensor (Thermoelement)",
            },
        ],
        "erklaerung": "Der Reedkontakt wird von einem Permanentmagneten am Zylinderkolben betätigt und meldet so die Endstellung. Der induktive Näherungsschalter erkennt metallische Werkstückträger über das Wirbelstromprinzip. Die Temperatur eines Schmelzbades misst man mit einem Thermoelement oder einem PT100.",
    },
    "au-tb-016": {
        "frage": "Einem Zinkbad sollen 3000 kg Zink (spez. Wärmekapazität c = 0,4 kJ/(kg·K)) zugeführt werden. Das Zink hat eine Ausgangstemperatur von 420 °C und muss auf 680 °C erwärmt werden. Wie groß ist die benötigte Wärme Q (in MJ)?",
        "v_frage": "Einem Zinkbad sollen {m} kg Zink (spez. Wärmekapazität c = 0,4 kJ/(kg·K)) zugeführt werden. Das Zink hat eine Ausgangstemperatur von {T1} °C und muss auf {T2} °C erwärmt werden. Wie groß ist die benötigte Wärme Q (in MJ)?",
    },
    "au-hy-022": {
        "frage": "In einem hydraulischen Schaltplan ist eine Pumpe eingezeichnet. Das Symbol zeigt ein Dreieck (Förderrichtung) und einen Pfeil, der diagonal durch den Kreis verläuft. Welche Pumpe wird dargestellt?",
    },
}

EINZEILIG = {"frage", "erklaerung"}


def _feldzeile(zeilen, start, ende, feld, einzug):
    """Index der Zeile, die `feld` auf genau dieser Einzugstiefe traegt."""
    marke = '%s"%s":' % (einzug, feld)
    for i in range(start, ende):
        if zeilen[i].startswith(marke):
            return i
    return None


def _blockende(zeilen, kopf, ende, einzug):
    if zeilen[kopf].rstrip().endswith(("],", "]")):
        return kopf
    for i in range(kopf + 1, ende):
        if zeilen[i].rstrip() in (einzug + "],", einzug + "]"):
            return i
    raise ValueError("Blockende nicht gefunden")


def ersetze(zeilen, frage_id, feld, wert, in_varianten=False):
    start, ende, einzug = grenzen(zeilen, frage_id)
    objekt_start = start

    if in_varianten:
        kopf_v = _feldzeile(zeilen, start, ende, "varianten", einzug)
        if kopf_v is None:
            raise KeyError("%s hat keinen varianten-Block" % frage_id)
        einzug = einzug + "  "
        start = kopf_v

    kopf = _feldzeile(zeilen, start, ende, feld, einzug)
    if kopf is None:
        raise KeyError("%s hat kein Feld %s" % (frage_id, feld))

    schluss = kopf if feld in EINZEILIG else _blockende(zeilen, kopf, ende, einzug)
    komma = "," if zeilen[schluss].rstrip().endswith(",") else ""
    trenner = ":  " if '":  "' in zeilen[objekt_start] else ": "
    text = '%s"%s"%s%s%s' % (einzug, feld, trenner, kompakt(wert, einzug, 0), komma)
    return zeilen[:kopf] + text.split("\n") + zeilen[schluss + 1 :]


def main():
    # id -> Datei, damit die Tabelle ohne Dateiangabe auskommt.
    wo = {}
    for name in sorted(os.listdir(FRAGEN_DIR)):
        if not name.endswith(".json") or name.startswith("_"):
            continue
        with io.open(os.path.join(FRAGEN_DIR, name), encoding="utf-8") as f:
            d = json.load(f)
        for fr in d if isinstance(d, list) else d.get("fragen", []):
            if isinstance(fr, dict) and fr.get("id"):
                wo[fr["id"]] = name

    nach_datei = {}
    for frage_id in NEU:
        if frage_id not in wo:
            raise KeyError("Frage %s gibt es nicht" % frage_id)
        nach_datei.setdefault(wo[frage_id], []).append(frage_id)

    gesamt = 0
    for datei, ids in sorted(nach_datei.items()):
        pfad = os.path.join(FRAGEN_DIR, datei)
        zeilen, zeilenende = lies(pfad)
        for frage_id in sorted(ids):
            for feld, wert in NEU[frage_id].items():
                if feld.startswith("v_"):
                    zeilen = ersetze(zeilen, frage_id, feld[2:], wert, True)
                else:
                    zeilen = ersetze(zeilen, frage_id, feld, wert)
                gesamt += 1
        schreib(pfad, zeilen, zeilenende)
        print("%-52s %d Fragen" % (datei, len(ids)))

    print("\n%d Fragen geloest, %d Felder ersetzt" % (len(NEU), gesamt))


if __name__ == "__main__":
    main()
