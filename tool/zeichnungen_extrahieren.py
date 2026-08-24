# -*- coding: utf-8 -*-
"""Rendert die Pruefungszeichnungen aus den PDF-Originalen nach assets/.

Warum rendern statt eingebettete Bilder extrahieren: Die Scans von S18 und
S19 bestehen aus mehreren uebereinanderliegenden Ebenen (Grundscan plus
Strichzeichnungs-Overlays). Einzelne Bilder herauszuziehen ergaebe
unvollstaendige Blaetter.

    python tool/zeichnungen_extrahieren.py [--dpi 200] [--jpeg]
"""
import io
import os
import sys

import pymupdf

QUELLE = r'C:\Users\aijos\OneDrive\Desktop\aufgaben'
ZIEL = 'assets/zeichnungen'

# PDF -> (Pruefung, [(Seitenindex, Dateiname, Beschriftung), ...])
BLAETTER = {
    'Zeichnungen.pdf': ('S17', [
        (0, 'blatt_1_einstellantrieb.png',
         'Einstellantrieb – Gesamtschnitt A-A'),
        (1, 'blatt_2_sicherheitskupplung.png',
         'Sicherheitskupplung ECA 16 – Detail und Stückliste'),
        (2, 'blatt_3_antriebswelle.png',
         'Antriebswelle (Pos. 3) – Einzelteilzeichnung'),
        (3, 'blatt_4_hydraulikplan.png',
         'Hydraulikschaltplan und GRAFCET'),
    ]),
    'Zeichnungen   4  Stück.pdf': ('S18', [
        (2, 'blatt_1_schaltvorrichtung.png',
         'Schaltvorrichtung – Schnittdarstellung'),
        (0, 'blatt_2_stueckliste.png',
         'Schaltvorrichtung – Ansicht und Stückliste'),
        (1, 'blatt_3_hydraulikplan.png',
         'Hydraulikschaltplan und GRAFCET'),
        (3, 'blatt_4_verladeanlage.png',
         'Verladeanlage für Betonteile – Übersicht'),
    ]),
    'Zeichnung 2.pdf': ('S19', [
        (0, 'blatt_1_werkzeugspindelkasten.png',
         'Werkzeugspindelkasten – Schnittdarstellung'),
    ]),
    'Stückliste.pdf': ('S19', [
        (0, 'blatt_2_stueckliste.png',
         'Werkzeugspindelkasten – Stückliste'),
    ]),
    'Zeichnung 1.pdf': ('S19', [
        (0, 'blatt_3_hydraulikplan.png',
         'Hydraulikschaltplan und GRAFCET'),
    ]),
}


def main(argv):
    dpi = 200
    if '--dpi' in argv:
        dpi = int(argv[argv.index('--dpi') + 1])

    gesamt = 0
    zeilen = []
    for datei, (pruefung, blaetter) in sorted(BLAETTER.items()):
        pfad = os.path.join(QUELLE, datei)
        if not os.path.exists(pfad):
            print('FEHLT: %s' % pfad)
            return 1

        doc = pymupdf.open(pfad)
        ordner = os.path.join(ZIEL, pruefung)
        os.makedirs(ordner, exist_ok=True)

        for index, name, _ in blaetter:
            if index >= len(doc):
                print('  %s: Seite %d gibt es nicht' % (datei, index + 1))
                continue
            seite = doc[index]
            pix = seite.get_pixmap(dpi=dpi, colorspace=pymupdf.csGRAY)
            ziel = os.path.join(ordner, name)
            pix.save(ziel)
            groesse = os.path.getsize(ziel)
            gesamt += groesse
            zeilen.append('  %-4s %-38s %5dx%-5d %6.0f KB'
                          % (pruefung, name, pix.width, pix.height,
                             groesse / 1024))
        doc.close()

    print('\n'.join(zeilen))
    print('\nGesamt: %.1f MB bei %d dpi' % (gesamt / 1048576, dpi))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
