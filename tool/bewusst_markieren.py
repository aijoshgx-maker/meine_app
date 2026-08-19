# -*- coding: utf-8 -*-
"""Setzt oder entfernt den "bewusstSo"-Marker fuer eine Liste von Fragen.

Damit laesst sich eine Entscheidung ("diese zwoelf Fragen sind absichtlich
so gebaut") in einem Schritt umsetzen, statt zwoelf JSON-Dateien von Hand
anzufassen.

    python tool/bewusst_markieren.py multi-anteil au-fl-013 au-fl-009
    python tool/bewusst_markieren.py --entfernen multi-anteil au-fl-013

Arbeitet bewusst zeilenweise statt ueber json.dumps: Die Fragendateien
halten Paar-Objekte einzeilig, was sich beim Neuserialisieren nicht
reproduzieren laesst - eine Markierung wuerde sonst die halbe Datei
umformatieren. So bleibt der Diff eine einzige Zeile je Frage.
"""
import io
import json
import os
import re
import sys

ORDNER = 'assets/fragen'


def _bearbeite(zeilen, ids, pruef_id, entfernen):
    """Gibt (neue_zeilen, betroffene_ids) zurueck."""
    id_muster = re.compile(r'^(\s*)"id":\s*"([^"]+)"')
    bewusst_muster = re.compile(r'^\s*"bewusstSo":\s*(\[[^\]]*\])\s*,?\s*$')

    ergebnis = []
    getroffen = set()
    i = 0
    while i < len(zeilen):
        zeile = zeilen[i]
        m = id_muster.match(zeile)
        if not m or m.group(2) not in ids:
            ergebnis.append(zeile)
            i += 1
            continue

        einrueckung, frage_id = m.group(1), m.group(2)
        getroffen.add(frage_id)
        ergebnis.append(zeile)
        i += 1

        # Bereich dieser Frage: bis zur naechsten "id"-Zeile bzw. Dateiende
        block = []
        while i < len(zeilen) and not id_muster.match(zeilen[i]):
            block.append(zeilen[i])
            i += 1

        # Vorhandene Liste einsammeln und die Zeile aus dem Block nehmen
        vorhanden = []
        rest = []
        for b in block:
            bm = bewusst_muster.match(b)
            if bm:
                try:
                    vorhanden = [x for x in json.loads(bm.group(1))
                                 if isinstance(x, str)]
                except ValueError:
                    vorhanden = []
            else:
                rest.append(b)

        if entfernen:
            neu = [x for x in vorhanden if x != pruef_id]
        else:
            neu = sorted(set(vorhanden) | {pruef_id})

        if neu:
            ergebnis.append('%s"bewusstSo": %s,'
                            % (einrueckung, json.dumps(neu, ensure_ascii=False)))
        ergebnis.extend(rest)

    return ergebnis, getroffen


def main(argv):
    entfernen = '--entfernen' in argv
    argv = [a for a in argv if a != '--entfernen']
    if len(argv) < 2:
        print(__doc__)
        return 1

    pruef_id, ids = argv[0], set(argv[1:])
    gefunden = set()

    for name in sorted(os.listdir(ORDNER)):
        if not name.endswith('.json') or name.startswith('_'):
            continue
        pfad = os.path.join(ORDNER, name)
        text = io.open(pfad, encoding='utf-8-sig').read()
        zeilen = text.split('\n')

        neu, getroffen = _bearbeite(zeilen, ids, pruef_id, entfernen)
        gefunden |= getroffen

        if getroffen and neu != zeilen:
            # Gegenprobe: Die Datei muss danach noch gueltiges JSON sein.
            inhalt = '\n'.join(neu)
            try:
                json.loads(inhalt)
            except ValueError as e:
                print('ABBRUCH bei %s - Ergebnis waere kein gueltiges JSON: %s'
                      % (name, e))
                return 1
            io.open(pfad, 'w', encoding='utf-8', newline='\n').write(inhalt)
            print('  aktualisiert: %s' % name)

    fehlend = ids - gefunden
    if fehlend:
        print('NICHT GEFUNDEN: %s' % ', '.join(sorted(fehlend)))
        return 1

    print('"%s" %s %d Fragen.'
          % (pruef_id, 'entfernt von' if entfernen else 'gesetzt fuer',
             len(gefunden)))
    print('Danach pruefen: dart run tool/validate_fragen.dart')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
