# -*- coding: utf-8 -*-
"""Listet Fragen, denen eines der vorhandenen Diagramme beistehen koennte.

Es gibt 9 gezeichnete Diagramme, aber nur 7 Fragen mit Bild. 223 Fragen
liegen in Kategorien, zu denen thematisch eines passen WUERDE - pauschal
zuzuweisen waere aber falsch: Eine Hydraulik-Frage nach Oelviskositaet neben
einem Kolbenschnitt ist bestenfalls Dekoration.

Deshalb nur ein Bericht. Die Auswahl trifft ein Mensch, die Zuweisung
uebernimmt dann tool/bild_zuweisen.py.

    python tool/bild_kandidaten.py     # schreibt REVIEW_BILDER.md
"""
import io
import json
import os

ORDNER = 'assets/fragen'

# Welches Diagramm zu welchen Kategorien ueberhaupt in Frage kommt.
DIAGRAMME = {
    'schnittdaten': ['Schnittdaten', 'Zerspanung Grundlagen'],
    'werkzeugwinkel': ['Werkzeuge & Schneidstoffe'],
    'toleranzfeld': ['Toleranzen & Passungen'],
    'passungsdiagramm': ['Toleranzen & Passungen'],
    'zahnrad_geometrie': ['Maschinenelemente', 'Antriebstechnik (mechanisch)'],
    'hydraulik_kolben': ['Hydraulik'],
    'pneumatik_52_ventil': ['Pneumatik'],
    'grafcet_basis': ['Steuerung & Regelung', 'Steuerung und Regelung'],
    'kraeftedreieck': ['Technische Berechnungen'],
}


def laden():
    fragen = []
    for name in sorted(os.listdir(ORDNER)):
        if not name.endswith('.json') or name.startswith('_'):
            continue
        try:
            daten = json.load(io.open(os.path.join(ORDNER, name),
                                      encoding='utf-8-sig'))
        except Exception:
            continue
        if isinstance(daten, list):
            fragen.extend(f for f in daten if isinstance(f, dict))
    return fragen


def main():
    fragen = laden()
    z = []
    z.append('# Bild-Kandidaten - Durchsicht')
    z.append('')
    z.append('Erzeugt von `tool/bild_kandidaten.py`.')
    z.append('')
    z.append('Aufgelistet sind Fragen, deren **Kategorie** zu einem der 9')
    z.append('vorhandenen Diagramme passt. Das heisst noch nicht, dass das')
    z.append('Diagramm der Frage auch wirklich hilft - genau das ist die')
    z.append('Entscheidung, die hier zu treffen ist.')
    z.append('')
    z.append('**Faustregel:** Das Diagramm soll die Antwort stuetzen, nicht')
    z.append('die Seite fuellen. Wo es nur schmueckt, lieber weglassen.')
    z.append('')
    z.append('Zuweisen anschliessend mit:')
    z.append('')
    z.append('```bash')
    z.append('python tool/bild_zuweisen.py schnittdaten ft-zg-004 ft-sd-002')
    z.append('```')
    z.append('')
    z.append('---')
    z.append('')

    gesamt = 0
    for diagramm in sorted(DIAGRAMME):
        kats = DIAGRAMME[diagramm]
        treffer = [f for f in fragen
                   if f.get('kategorie') in kats and not f.get('bildAsset')]
        schon = [f for f in fragen
                 if f.get('bildAsset') == 'diag:' + diagramm]
        if not treffer and not schon:
            continue

        z.append('## `%s`' % diagramm)
        z.append('')
        z.append('Kategorien: %s' % ', '.join(kats))
        if schon:
            z.append('')
            z.append('Bereits zugewiesen: %s'
                     % ', '.join('`%s`' % f['id'] for f in schon))
        z.append('')
        z.append('%d Kandidaten:' % len(treffer))
        z.append('')
        for f in sorted(treffer, key=lambda x: x['id']):
            frage = (f.get('frage') or '').replace('\n', ' ')
            if len(frage) > 110:
                frage = frage[:107] + '...'
            z.append('- [ ] `%s` %s' % (f['id'], frage))
        z.append('')
        gesamt += len(treffer)

    z.append('---')
    z.append('')
    z.append('**%d Kandidaten insgesamt.**' % gesamt)
    # Nicht ueber stdout: Die Windows-Konsole laeuft unter cp1252 und
    # bricht bei Sonderzeichen aus den Fragetexten ab.
    ziel = 'REVIEW_BILDER.md'
    with io.open(ziel, 'w', encoding='utf-8', newline='\n') as datei:
        datei.write('\n'.join(z) + '\n')
    print('%s geschrieben: %d Kandidaten' % (ziel, gesamt))


if __name__ == '__main__':
    main()
