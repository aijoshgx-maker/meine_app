# -*- coding: utf-8 -*-
"""Setzt oder entfernt bildAsset fuer eine Liste von Fragen.

    python tool/bild_zuweisen.py schnittdaten ft-zg-004 ft-sd-002
    python tool/bild_zuweisen.py --entfernen ft-zg-004

Das erste Argument ist der Diagrammname ohne "diag:"-Vorsatz, oder ein
Dateipfad fuer echte Bilder. Beim Entfernen entfaellt es.

Arbeitet zeilenweise statt ueber json.dumps: Die Fragendateien halten
Paar-Objekte einzeilig, ein Neuserialisieren wuerde die halbe Datei
umformatieren. So bleibt der Diff eine Zeile je Frage.
"""
import io
import json
import os
import re
import sys

ORDNER = 'assets/fragen'

# Die 9 gezeichneten Diagramme - ein Tippfehler waere sonst still wirkungslos,
# weil unbekannte Keys von der App kommentarlos ignoriert werden.
BEKANNTE_DIAGRAMME = {
    'grafcet_basis', 'hydraulik_kolben', 'kraeftedreieck', 'passungsdiagramm',
    'pneumatik_52_ventil', 'schnittdaten', 'toleranzfeld', 'werkzeugwinkel',
    'zahnrad_geometrie',
}


def _bearbeite(zeilen, ids, wert):
    """wert=None entfernt. Gibt (neue_zeilen, getroffene_ids) zurueck."""
    id_muster = re.compile(r'^(\s*)"id":\s*"([^"]+)"')
    bild_muster = re.compile(r'^\s*"bildAsset":\s*.*,?\s*$')

    ergebnis = []
    getroffen = set()
    i = 0
    while i < len(zeilen):
        m = id_muster.match(zeilen[i])
        if not m or m.group(2) not in ids:
            ergebnis.append(zeilen[i])
            i += 1
            continue

        einrueckung, frage_id = m.group(1), m.group(2)
        getroffen.add(frage_id)
        ergebnis.append(zeilen[i])
        i += 1

        block = []
        while i < len(zeilen) and not id_muster.match(zeilen[i]):
            block.append(zeilen[i])
            i += 1

        # bildAsset ist in allen Bestandsdateien vorhanden (oft null) -
        # deshalb ersetzen statt einfuegen, sonst stuende es doppelt da.
        ersetzt = False
        for b in block:
            if bild_muster.match(b):
                if not ersetzt:
                    neu = 'null' if wert is None else json.dumps(
                        wert, ensure_ascii=False)
                    ergebnis.append('%s"bildAsset": %s,' % (einrueckung, neu))
                    ersetzt = True
            else:
                ergebnis.append(b)

        if not ersetzt and wert is not None:
            ergebnis.append('%s"bildAsset": %s,'
                            % (einrueckung, json.dumps(wert,
                                                       ensure_ascii=False)))

    return ergebnis, getroffen


def main(argv):
    entfernen = '--entfernen' in argv
    argv = [a for a in argv if a != '--entfernen']

    if entfernen:
        if not argv:
            print(__doc__)
            return 1
        wert, ids = None, set(argv)
    else:
        if len(argv) < 2:
            print(__doc__)
            return 1
        name, ids = argv[0], set(argv[1:])
        if '/' in name or name.endswith('.png') or name.endswith('.jpg'):
            wert = name
        else:
            if name not in BEKANNTE_DIAGRAMME:
                print('Unbekanntes Diagramm: %s' % name)
                print('Bekannt: %s' % ', '.join(sorted(BEKANNTE_DIAGRAMME)))
                return 1
            wert = 'diag:' + name

    gefunden = set()
    for datei in sorted(os.listdir(ORDNER)):
        if not datei.endswith('.json') or datei.startswith('_'):
            continue
        pfad = os.path.join(ORDNER, datei)
        zeilen = io.open(pfad, encoding='utf-8-sig').read().split('\n')

        neu, getroffen = _bearbeite(zeilen, ids, wert)
        gefunden |= getroffen
        if getroffen and neu != zeilen:
            inhalt = '\n'.join(neu)
            try:
                json.loads(inhalt)
            except ValueError as e:
                print('ABBRUCH bei %s - kein gueltiges JSON mehr: %s'
                      % (datei, e))
                return 1
            io.open(pfad, 'w', encoding='utf-8', newline='\n').write(inhalt)
            print('  aktualisiert: %s' % datei)

    fehlend = ids - gefunden
    if fehlend:
        print('NICHT GEFUNDEN: %s' % ', '.join(sorted(fehlend)))
        return 1

    print('%s fuer %d Fragen.'
          % ('bildAsset entfernt' if entfernen else wert, len(gefunden)))
    print('Danach pruefen: dart run tool/validate_fragen.dart')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
