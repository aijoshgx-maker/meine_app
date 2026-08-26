# -*- coding: utf-8 -*-
"""Traegt das Feld `freieAntwort` in die Fragendateien ein.

Aufruf:  python tool/freie_antwort_setzen.py

`freieAntwort` haelt die Antworten, die gelten, wenn eine single-Frage auf
der hoechsten Haertestufe ohne ihre Optionen gestellt wird (siehe
lib/core/quiz/frage_haerte.dart).

Warum von Hand gepflegt und nicht aus dem Optionstext abgeleitet: Die kurzen
Optionen im Bestand taugen nur teilweise als freie Antwort. "Reed-Kontakt"
funktioniert, "Ja, fuer 9 Monate" nicht - das ist eine Antwort auf eine
Auswahlfrage und ohne die Auswahl unloesbar. Eine automatische Ableitung
wuerde Fragen erzeugen, an denen man zu Unrecht scheitert.

Aufnahmekriterien: Die Frage fragt nach genau einem Begriff, Kennwert oder
Verfahren, und der ist ohne Blick auf die Optionen benennbar. Nicht
aufgenommen: Ja/Nein-Antworten, ganze Saetze und Antworten, die nur eine von
mehreren angebotenen Formulierungen sind.

Wiederholt aufrufbar - ein vorhandener Block wird ersetzt.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from varianten_setzen import FRAGEN_DIR, grenzen, kompakt, lies, schreib  # noqa: E402

FELD = "freieAntwort"

# datei -> { frage_id: [akzeptierte Antworten] }
#
# Mehrere Schreibweisen, wo der Begriff mehr als eine gelaeufige Form hat.
# Der Bestandstest prueft, dass keine davon zugleich auf eine falsche Option
# derselben Frage passt.
FREIE_ANTWORTEN = {
    "auftragsanalyse_antriebstechnik.json": {
        "au-at-013": ["Wirkungsgrad", "Wirkungsgrad η"],
    },
    "auftragsanalyse_elektrotechnik.json": {
        "au-et-017": ["Schutzleiter", "Schutzleiter (PE)", "PE", "Schutzerdung"],
    },
    "auftragsanalyse_funktionsanalyse.json": {
        "au-fa-007": ["Wirkliniendiagramm"],
    },
    "auftragsanalyse_hydraulik.json": {
        "au-hy-010": ["HFA", "HFA-Flüssigkeit"],
        "au-hy-017": ["ISO VG 46", "VG 46", "46"],
        "au-hy-026": ["Druckschalter", "Druckschalter BP1/BP2"],
    },
    "auftragsanalyse_instandhaltung.json": {
        "au-ih-017": ["DIN 31051", "31051"],
    },
    "auftragsanalyse_maschinenelemente.json": {
        "au-me-020": ["Umfangslast", "Laufring mit Umfangslast"],
        "au-me-022": ["Keilwellenverbindung", "Keilwelle"],
        "au-me-027": ["Rutschkupplung"],
    },
    "auftragsanalyse_steuerung_regelung.json": {
        "au-sr-026": ["Reed-Kontakt", "Reedschalter"],
        "au-sr-027": ["UND", "AND", "UND-Verknüpfung", "Konjunktion"],
        "au-sr-029": ["AND-Baustein", "UND-Baustein", "AND", "UND"],
    },
    "auftragsanalyse_technische_berechnungen.json": {
        "au-tb-008": [
            "Polares Widerstandsmoment",
            "Polares Widerstandsmoment Wp",
            "Wp",
        ],
    },
    "auftragsanalyse_werkstoffkunde.json": {
        "au-wk-008": ["Rockwell", "Rockwell-Härteprüfung", "HRC"],
        "au-wk-016": ["Einsatzstahl"],
        "au-wk-023": ["Thermoplast"],
    },
    "fertigungstechnik_cnc_grundlagen.json": {
        "ft-cnc-010": ["M03", "M3"],
    },
    "fertigungstechnik_fertigungs_arbeitsplanung.json": {
        "ft-ap-011": ["Optimale Losgröße", "Losgröße"],
    },
    "fertigungstechnik_fuegeverfahren.json": {
        "ft-fv-005": ["Wellenlöten"],
        "ft-fv-013": ["Ultraschallschweißen"],
    },
    "fertigungstechnik_qualitaetssicherung.json": {
        "ft-qs-018": ["Tastschnittgerät", "Profilometer"],
    },
    "fertigungstechnik_schnittdaten.json": {
        "ft-sd-010": ["mm²", "mm2", "Quadratmillimeter"],
    },
    "fertigungstechnik_werkstoffe_waermebehandlung.json": {
        "ft-ww-018": ["Spannungsarmglühen"],
    },
    "fertigungstechnik_zerspanung_grundlagen.json": {
        "ft-zg-004": ["Fließspan"],
        "ft-zg-015": ["Reiben"],
    },
    "wiso_betriebsorganisation.json": {
        "wi-bo-012": ["Aufsichtsrat"],
    },
    "wiso_kaufvertrag.json": {
        "wi-kv-018": ["Kapitalgesellschaft"],
    },
    "wiso_sozialversicherung.json": {
        "wi-sv-022": ["Pflegeversicherung"],
    },
    "wiso_tarifrecht.json": {
        "wi-tr-016": ["Arbeitsgericht"],
        "wi-tr-019": ["20", "20 Beschäftigte", "Ab 20 Beschäftigten"],
    },
}


def entferne(zeilen, frage_id):
    """Nimmt einen vorhandenen Block wieder heraus."""
    start, ende, _ = grenzen(zeilen, frage_id)
    kopf = next(
        (
            i
            for i in range(start, ende)
            if zeilen[i].strip().startswith('"%s"' % FELD)
        ),
        None,
    )
    if kopf is None:
        return zeilen

    zeilen = zeilen[:kopf] + zeilen[ende:]
    davor = kopf - 1
    if zeilen[davor].rstrip().endswith(","):
        zeilen[davor] = zeilen[davor].rstrip()[:-1]
    return zeilen


def setze(zeilen, frage_id, antworten):
    zeilen = entferne(zeilen, frage_id)
    start, ende, einzug = grenzen(zeilen, frage_id)

    letztes = ende - 1
    if not zeilen[letztes].rstrip().endswith(","):
        zeilen[letztes] = zeilen[letztes].rstrip() + ","

    # Manche Dateien setzen zwei Leerzeichen hinter den Doppelpunkt.
    trenner = ":  " if '":  "' in zeilen[start] else ": "
    text = '%s"%s"%s%s' % (einzug, FELD, trenner, kompakt(antworten, einzug, 0))
    return zeilen[:ende] + text.split("\n") + zeilen[ende:]


def main():
    gesamt = 0
    for datei, eintraege in sorted(FREIE_ANTWORTEN.items()):
        pfad = os.path.join(FRAGEN_DIR, datei)
        zeilen, zeilenende = lies(pfad)
        for frage_id, antworten in sorted(eintraege.items()):
            zeilen = setze(zeilen, frage_id, antworten)
        schreib(pfad, zeilen, zeilenende)
        gesamt += len(eintraege)
        print("%-48s %d" % (datei, len(eintraege)))

    print("\n%d Fragen mit freier Antwort" % gesamt)


if __name__ == "__main__":
    main()
