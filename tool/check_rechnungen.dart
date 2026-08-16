// Verifikationslauf für P3: extrahiert aus jeder "rechnung"-Frage den
// loesungswert und prüft heuristisch, ob die in erklaerung/workedExample
// zuletzt genannte Zahl vor der Einheit innerhalb loesungswert ± toleranz
// liegt. Das ist eine Heuristik zum Aufspüren weiterer Widersprüche
// zwischen Lösungswert und Erklärtext (wie ft-sd-005, au-tb-009, au-ih-007,
// wi-ent-006, ft-ws-012 in P3) - kein Ersatz für manuelle Prüfung.
//
// Aufruf:  dart run tool/check_rechnungen.dart
// Ergebnis: REVIEW_RECHNUNGEN.md mit allen Treffern zur manuellen Prüfung.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

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

  final treffer = <String>[];
  var geprueft = 0;
  var ohneKandidat = 0;

  for (final file in dateien) {
    final bytes = file.readAsBytesSync();
    final raw = utf8.decode(bytes, allowMalformed: true);
    final text = raw.startsWith('﻿') ? raw.substring(1) : raw;
    final liste = jsonDecode(text) as List;
    final name = file.uri.pathSegments.last;

    for (final roh in liste) {
      final f = Map<String, dynamic>.from(roh as Map);
      if (f['typ'] != 'rechnung') continue;
      final loesungswert = (f['loesungswert'] as num?)?.toDouble();
      final toleranz = (f['toleranz'] as num?)?.toDouble();
      final einheit = f['einheit'] as String?;
      if (loesungswert == null || toleranz == null || einheit == null) {
        continue; // wird schon von validate_fragen.dart als FEHLER gemeldet
      }
      geprueft++;

      final id = f['id'] as String;
      final volltext = '${f['erklaerung'] ?? ''}\n${f['workedExample'] ?? ''}';
      final kandidat = _letzteZahlVorEinheit(volltext, einheit);

      if (kandidat == null) {
        ohneKandidat++;
        continue;
      }

      final diff = (kandidat - loesungswert).abs();
      if (diff > toleranz) {
        treffer.add(
          '- **$id** ($name): loesungswert = $loesungswert $einheit ± $toleranz, '
          'im Text gefunden: $kandidat $einheit (Differenz: ${diff.toStringAsFixed(3)})',
        );
      }
    }
  }

  final out = StringBuffer()
    ..writeln('# Review: Rechnung-Fragen – Konsistenzprüfung')
    ..writeln()
    ..writeln('Erzeugt von `tool/check_rechnungen.dart`.')
    ..writeln()
    ..writeln(
      'Heuristik: letzte im Erklärtext/workedExample genannte Zahl vor der '
      'Einheit wird mit `loesungswert ± toleranz` verglichen. '
      '**Kein Beweis für einen Fehler** - jeder Treffer muss manuell geprüft '
      'werden (Formeln mit Zwischenschritten, mehrdeutige Einheiten-Strings '
      'usw. erzeugen auch Falsch-Positive).',
    )
    ..writeln()
    ..writeln('Geprüfte rechnung-Fragen: $geprueft')
    ..writeln(
      'Ohne erkennbaren Zahl-Kandidaten (Heuristik greift nicht): $ohneKandidat',
    )
    ..writeln('Treffer (Differenz > Toleranz): ${treffer.length}')
    ..writeln()
    ..writeln('## Treffer')
    ..writeln();
  if (treffer.isEmpty) {
    out.writeln('Keine Treffer.');
  } else {
    for (final t in treffer) {
      out.writeln(t);
    }
  }

  File('$root/REVIEW_RECHNUNGEN.md').writeAsStringSync(out.toString());
  print(
    'REVIEW_RECHNUNGEN.md geschrieben: $geprueft geprüft, ${treffer.length} Treffer, '
    '$ohneKandidat ohne Kandidat.',
  );
}

/// Sucht die letzte Zahl vor [einheit] (oder unmittelbar davor mit ≈/=)
/// im Text. Zahlen dürfen Leerzeichen als Tausendertrennzeichen und Komma
/// als Dezimaltrennzeichen haben (deutsche Schreibweise).
double? _letzteZahlVorEinheit(String text, String einheit) {
  final einheitEscaped = RegExp.escape(einheit);
  final pattern = RegExp(
    r'([-−]?\d[\d ]*(?:[.,]\d+)?)\s*' + einheitEscaped + r'\b',
  );
  final matches = pattern.allMatches(text).toList();
  if (matches.isEmpty) return null;
  final letzterMatch = matches.last.group(1)!;
  final normalisiert = letzterMatch
      .replaceAll(' ', '')
      .replaceAll('−', '-')
      .replaceAll(',', '.');
  return double.tryParse(normalisiert);
}
