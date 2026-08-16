// Erzeugt eine Übersichtstabelle über den Fragenbestand in REPORT_FRAGEN.md.
//
// Aufruf:  dart run tool/report_fragen.dart
//
// Nutzt dieselbe leichte Ladefunktion wie validate_fragen.dart, ist aber
// unabhängig davon lauffähig (kein Import), damit ein kaputter Validator den
// Report nicht mit runterreißt.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current.path;
  final fragenDir = Directory('$root/assets/fragen');
  if (!fragenDir.existsSync()) {
    stderr.writeln('Verzeichnis assets/fragen nicht gefunden.');
    exit(2);
  }

  final dateien =
      fragenDir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.json') &&
                !f.path.endsWith('_manifest.json') &&
                !f.path.endsWith('_rechtsstand.json') &&
                !f.path.endsWith('fachgespraech_szenarien.json'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final zeilen = <String>[];
  zeilen.add('# Fragenreport');
  zeilen.add('');
  zeilen.add('Erzeugt von `tool/report_fragen.dart`.');
  zeilen.add('');

  var gesamtFragen = 0;
  final gesamtTypen = <String, int>{};
  final gesamtSchwierigkeit = <int, int>{};
  final gesamtBereich = <String, int>{};
  final gesamtPosition = <int, int>{};
  var gesamtSingle = 0;

  zeilen.add('## Je Datei');
  zeilen.add('');
  zeilen.add(
    '| Datei | Fragen | single | multi | rechnung | wahrfalsch | kurzantwort | lueckentext | zuordnung | reihenfolge |',
  );
  zeilen.add('|---|---|---|---|---|---|---|---|---|---|');

  for (final file in dateien) {
    dynamic geparst;
    try {
      final bytes = file.readAsBytesSync();
      final raw = utf8.decode(bytes, allowMalformed: true);
      final text = raw.startsWith('﻿') ? raw.substring(1) : raw;
      geparst = jsonDecode(text);
    } catch (e) {
      zeilen.add('| ${file.uri.pathSegments.last} | FEHLER: $e |||||||||');
      continue;
    }
    if (geparst is! List) continue;

    final typZaehler = <String, int>{};
    for (final roh in geparst) {
      final f = Map<String, dynamic>.from(roh as Map);
      gesamtFragen++;
      final typ = (f['typ'] as String?) ?? '?';
      typZaehler[typ] = (typZaehler[typ] ?? 0) + 1;
      gesamtTypen[typ] = (gesamtTypen[typ] ?? 0) + 1;

      final schwierigkeit = f['schwierigkeit'];
      if (schwierigkeit is int) {
        gesamtSchwierigkeit[schwierigkeit] =
            (gesamtSchwierigkeit[schwierigkeit] ?? 0) + 1;
      }
      final bereich = (f['bereich'] as String?) ?? '?';
      gesamtBereich[bereich] = (gesamtBereich[bereich] ?? 0) + 1;

      if (typ == 'single') {
        gesamtSingle++;
        final ri = (f['richtigeIndizes'] as List? ?? [])
            .map((e) => e as int)
            .toList();
        if (ri.length == 1) {
          gesamtPosition[ri.first] = (gesamtPosition[ri.first] ?? 0) + 1;
        }
      }
    }

    String c(String t) => (typZaehler[t] ?? 0).toString();
    zeilen.add(
      '| ${file.uri.pathSegments.last} | ${geparst.length} | ${c('single')} | ${c('multi')} | '
      '${c('rechnung')} | ${c('wahrfalsch')} | ${c('kurzantwort')} | ${c('lueckentext')} | '
      '${c('zuordnung')} | ${c('reihenfolge')} |',
    );
  }

  zeilen.add('');
  zeilen.add('## Gesamt');
  zeilen.add('');
  zeilen.add('- Fragen gesamt: $gesamtFragen');
  zeilen.add('- Dateien: ${dateien.length}');
  zeilen.add('');
  zeilen.add('### Bereiche');
  zeilen.add('');
  for (final e
      in gesamtBereich.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))) {
    zeilen.add('- ${e.key}: ${e.value}');
  }
  zeilen.add('');
  zeilen.add('### Typverteilung');
  zeilen.add('');
  for (final e
      in gesamtTypen.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))) {
    zeilen.add('- ${e.key}: ${e.value}');
  }
  zeilen.add('');
  zeilen.add('### Schwierigkeitsverteilung');
  zeilen.add('');
  for (final grad in [1, 2, 3]) {
    zeilen.add('- $grad: ${gesamtSchwierigkeit[grad] ?? 0}');
  }
  zeilen.add('');
  zeilen.add(
    '### Positionsverteilung der richtigen Antwort (single, gesamt $gesamtSingle)',
  );
  zeilen.add('');
  final positionen = gesamtPosition.keys.toList()..sort();
  for (final p in positionen) {
    zeilen.add('- Position $p: ${gesamtPosition[p]}');
  }
  zeilen.add('');
  zeilen.add('## Warnungen / Fehler');
  zeilen.add('');
  zeilen.add(
    'Siehe `dart run tool/validate_fragen.dart` für die vollständige Liste.',
  );
  zeilen.add('');

  File('$root/REPORT_FRAGEN.md').writeAsStringSync(zeilen.join('\n'));
  print('REPORT_FRAGEN.md geschrieben (${zeilen.length} Zeilen).');
}
