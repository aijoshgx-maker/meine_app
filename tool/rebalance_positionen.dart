// Einmal-Migrationsskript für P6b: verschiebt die Position der richtigen
// Antwort bei "single"-Fragen, damit die Position im Rohdatensatz nicht
// systematisch schief verteilt ist (Fallback/Export-Fall - die Laufzeit
// mischt die Anzeige ohnehin zusätzlich, siehe lib/core/quiz/options_shuffle.dart).
//
// Vorgehen: pro Frage wird eine deterministische Rotation der (nicht-Anker-)
// Optionen berechnet (Rotationsbetrag aus der Frage-id abgeleitet) und
// sowohl optionen als auch richtigeIndizes entsprechend permutiert.
// Geschrieben wird NICHT die ganze Datei neu (das würde auch unveränderte
// Fragen reformatieren und riesige, unreviewbare Diffs erzeugen), sondern
// nur die betroffenen "optionen"/"richtigeIndizes"-Textspannen der
// tatsächlich rotierten Fragen werden ersetzt - der Rest der Datei bleibt
// byteidentisch.
//
// Aufruf:  dart run tool/rebalance_positionen.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const _ankerMuster = [
  'keine der genannten',
  'keine der aufgeführten',
  'keine antwort ist richtig',
  'alle antworten sind richtig',
  'alle genannten antworten sind richtig',
];

bool _istAnker(String text) {
  final normalisiert = text.trim().toLowerCase();
  return _ankerMuster.any(normalisiert.contains);
}

void main() {
  final root = Directory.current.path;
  final fragenDir = Directory('$root/assets/fragen');
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

  final vorherHistogramm = <int, int>{};
  final nachherHistogramm = <int, int>{};
  var geaendert = 0;
  var uebersprungenAnker = 0;
  var gesamtSingle = 0;

  for (final file in dateien) {
    final bytes = file.readAsBytesSync();
    final raw = utf8.decode(bytes, allowMalformed: true);
    final text = raw.startsWith('﻿') ? raw.substring(1) : raw;
    final liste = jsonDecode(text) as List;

    var neuerText = text;
    // Von hinten nach vorne ersetzen, damit vorher berechnete Textspannen
    // durch spätere Ersetzungen nicht verschoben werden.
    final aenderungen = <_Aenderung>[];

    for (final roh in liste) {
      final f = roh as Map;
      if (f['typ'] != 'single') continue;
      final optionen = (f['optionen'] as List).cast<String>();
      final richtigeIndizes = (f['richtigeIndizes'] as List).cast<int>();
      if (optionen.length < 2 || richtigeIndizes.length != 1) continue;
      gesamtSingle++;
      vorherHistogramm[richtigeIndizes.first] =
          (vorherHistogramm[richtigeIndizes.first] ?? 0) + 1;

      if (optionen.any(_istAnker)) {
        uebersprungenAnker++;
        nachherHistogramm[richtigeIndizes.first] =
            (nachherHistogramm[richtigeIndizes.first] ?? 0) + 1;
        continue;
      }

      final id = f['id'] as String;
      final n = optionen.length;
      final rotation = _rotationAus(id, n);
      if (rotation == 0) {
        nachherHistogramm[richtigeIndizes.first] =
            (nachherHistogramm[richtigeIndizes.first] ?? 0) + 1;
        continue;
      }

      final neueOptionen = List<String>.filled(n, '');
      for (var alt = 0; alt < n; alt++) {
        neueOptionen[(alt + rotation) % n] = optionen[alt];
      }
      final neuerRichtigerIndex = (richtigeIndizes.first + rotation) % n;
      nachherHistogramm[neuerRichtigerIndex] =
          (nachherHistogramm[neuerRichtigerIndex] ?? 0) + 1;

      final idAnkerPos = _findeIdPosition(neuerText, id);
      if (idAnkerPos == null) {
        stderr.writeln(
          'WARNUNG: id $id in ${file.path} nicht per Textsuche gefunden - übersprungen.',
        );
        continue;
      }
      final optionenSpan = _findeArraySpan(neuerText, idAnkerPos, 'optionen');
      final indizesSpan = _findeArraySpan(
        neuerText,
        idAnkerPos,
        'richtigeIndizes',
      );
      if (optionenSpan == null || indizesSpan == null) {
        stderr.writeln(
          'WARNUNG: optionen/richtigeIndizes-Span für $id in ${file.path} nicht gefunden - übersprungen.',
        );
        continue;
      }
      aenderungen.add(_Aenderung(optionenSpan, jsonEncode(neueOptionen)));
      aenderungen.add(
        _Aenderung(indizesSpan, jsonEncode([neuerRichtigerIndex])),
      );
      geaendert++;
    }

    if (aenderungen.isEmpty) continue;

    aenderungen.sort((a, b) => b.span.$1.compareTo(a.span.$1));
    for (final aenderung in aenderungen) {
      final (start, end) = aenderung.span;
      neuerText =
          neuerText.substring(0, start) +
          aenderung.ersatz +
          neuerText.substring(end);
    }
    file.writeAsStringSync(neuerText);
  }

  print('Single-Choice-Fragen gesamt: $gesamtSingle');
  print('Verändert (rotiert): $geaendert');
  print('Übersprungen (Anker-Option vorhanden): $uebersprungenAnker');
  print('Positionsverteilung vorher: $vorherHistogramm');
  print('Positionsverteilung nachher: $nachherHistogramm');
}

class _Aenderung {
  final (int, int) span;
  final String ersatz;
  _Aenderung(this.span, this.ersatz);
}

int _rotationAus(String id, int n) {
  var summe = 0;
  for (final code in id.codeUnits) {
    summe += code;
  }
  return summe % n;
}

/// Findet die Position von `"id": "<id>"` (mit flexiblem Whitespace nach
/// dem Doppelpunkt, wie in manchen Dateien mit doppeltem Leerzeichen).
int? _findeIdPosition(String text, String id) {
  final pattern = RegExp('"id":\\s*"${RegExp.escape(id)}"');
  return pattern.firstMatch(text)?.start;
}

/// Sucht ab [ab] nach `"<feldName>":` und liefert die Textspanne des
/// darauffolgenden `[...]`-Arrays (Start/Ende-Offset, Ende exklusiv, d.h.
/// direkt nach der schließenden `]`). Berücksichtigt verschachtelte
/// Strings, damit Klammern innerhalb von Optionstexten nicht mitgezählt
/// werden.
(int, int)? _findeArraySpan(String text, int ab, String feldName) {
  final keyPattern = RegExp('"${RegExp.escape(feldName)}":\\s*');
  // Suche in einem begrenzten Fenster nach [ab], um nicht versehentlich in
  // die nächste Frage zu laufen (2000 Zeichen reichen für alle Felder vor
  // optionen/richtigeIndizes in einem Objekt).
  final fensterEnde = (ab + 2000).clamp(0, text.length);
  final fenster = text.substring(ab, fensterEnde);
  final keyMatch = keyPattern.firstMatch(fenster);
  if (keyMatch == null) return null;

  var i = ab + keyMatch.end;
  while (i < text.length && text[i] != '[') {
    i++;
  }
  if (i >= text.length) return null;
  final start = i;

  var tiefe = 0;
  var inString = false;
  for (; i < text.length; i++) {
    final ch = text[i];
    if (inString) {
      if (ch == '\\') {
        i++; // nächstes Zeichen (escaped) überspringen
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
    } else if (ch == '[') {
      tiefe++;
    } else if (ch == ']') {
      tiefe--;
      if (tiefe == 0) {
        return (start, i + 1);
      }
    }
  }
  return null;
}
