# -*- coding: utf-8 -*-
"""Bereitet die zu leichten multi-Fragen zur fachlichen Durchsicht auf.

Erfindet nichts: liest nur den Bestand und stellt ihn so dar, dass sich je
Frage schnell entscheiden laesst, welche Option geaendert werden soll.

Aufruf:
    dart run tool/validate_fragen.dart > validator.txt
    python tool/multi_bericht.py validator.txt
"""
import io
import json
import os
import re
import sys
import collections

quelle = sys.argv[1] if len(sys.argv) > 1 else 'validator.txt'
aus = io.open(quelle, encoding='utf-8', errors='replace').read()

muster = re.compile(r'WARNUNG\s+(\S+)\s+\[([^\]]+)\]:\s*multi: (\d+) von (\d+)')
treffer = {}
for zeile in aus.splitlines():
    m = muster.search(zeile)
    if m:
        treffer[m.group(2)] = (m.group(1), int(m.group(3)), int(m.group(4)))

ordner = 'assets/fragen'
fragen = {}
for name in sorted(os.listdir(ordner)):
    if not name.endswith('.json') or name.startswith('_'):
        continue
    try:
        daten = json.load(io.open(os.path.join(ordner, name),
                                  encoding='utf-8-sig'))
    except Exception:
        continue
    if not isinstance(daten, list):
        continue
    for f in daten:
        if isinstance(f, dict) and f.get('id') in treffer:
            fragen[f['id']] = (name, f)

nach_datei = collections.defaultdict(list)
for fid, (name, f) in fragen.items():
    nach_datei[name].append(f)

z = []
z.append('# Zu leichte Multi-Fragen - Durchsicht')
z.append('')
z.append('Erzeugt von `tool/multi_bericht.py` aus den Warnungen von')
z.append('`tool/validate_fragen.dart`. **%d Fragen** betroffen.' % len(fragen))
z.append('')
z.append('## Worum es geht')
z.append('')
z.append('Bei diesen Fragen sind fast alle Optionen richtig. Die Bewertung')
z.append('verlangt zwar die exakte Menge, ein blindes "alles ankreuzen" kostet')
z.append('also den Punkt - trotzdem trennt so eine Frage kaum zwischen Koennen')
z.append('und Raten. Wer die eine falsche Option kennt, hat sie geloest.')
z.append('')
z.append('## Wie du damit arbeitest')
z.append('')
z.append('Pro Frage gibt es zwei sinnvolle Wege:')
z.append('')
z.append('1. **Eine richtige Option zu einer falschen umformulieren** - meist')
z.append('   die beste Wahl, weil die Optionszahl gleich bleibt und die Frage')
z.append('   ihren Zuschnitt behaelt.')
z.append('2. **Eine plausible falsche Option ergaenzen** und dafuer eine')
z.append('   richtige streichen.')
z.append('')
z.append('Sag mir je Frage, was gelten soll - ich trage es ein und ziehe die')
z.append('Erklaerung nach. Von allein aendere ich hier nichts: Welche Aussage')
z.append('fachlich haltbar ist, entscheidest du.')
z.append('')
z.append('---')
z.append('')

for name in sorted(nach_datei):
    z.append('## %s' % name.replace('.json', ''))
    z.append('')
    for f in sorted(nach_datei[name], key=lambda x: x['id']):
        richtig = set(f.get('richtigeIndizes', []))
        opts = f.get('optionen', [])
        _, r, g = treffer[f['id']]
        z.append('### `%s` - %d von %d richtig' % (f['id'], r, g))
        z.append('')
        z.append('> %s' % f.get('frage', '').replace('\n', ' '))
        z.append('')
        for i, o in enumerate(opts):
            z.append('- [%s] %s' % ('x' if i in richtig else ' ', o))
        z.append('')
        erkl = f.get('erklaerung', '').replace('\n', ' ')
        if erkl:
            z.append('*Erklaerung:* %s' % erkl)
            z.append('')
    z.append('')

io.open('REVIEW_MULTI.md', 'w', encoding='utf-8', newline='\n').write('\n'.join(z))
print('REVIEW_MULTI.md: %d Fragen aus %d Dateien' % (len(fragen), len(nach_datei)))
