// Wächter über die Web-Tauglichkeit.
//
// Hintergrund: Der Web-Deploy war einen Monat lang kaputt, weil das
// Backup-Feature 'dart:io' importierte. Das ist im Web-Build ein
// Compile-Fehler, kein Laufzeitproblem - er fällt also weder beim Testen
// noch beim Analysieren auf, sondern erst im CI-Build, den niemand ansieht.
//
// Diese Tests kosten Millisekunden und fangen genau das ab.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Dateien, die plattformspezifisch sein DÜRFEN. Alles andere in lib/ muss
/// ohne Datei-APIs auskommen.
const _erlaubt = {'lib/core/plattform/datei_ablage_io.dart'};

/// Pakete, die es auf Web nicht gibt.
const _verboteneImporte = {
  "import 'dart:io'": 'dart:io',
  'package:path_provider/': 'path_provider',
};

List<File> _dartDateienInLib() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

String _relativ(File datei) => datei.path.replaceAll(r'\', '/');

void main() {
  test('kein Anwendungscode importiert dart:io oder path_provider', () {
    final verstoesse = <String>[];

    for (final datei in _dartDateienInLib()) {
      final pfad = _relativ(datei);
      if (_erlaubt.contains(pfad)) continue;

      final inhalt = datei.readAsStringSync();
      for (final eintrag in _verboteneImporte.entries) {
        if (inhalt.contains(eintrag.key)) {
          verstoesse.add('$pfad → ${eintrag.value}');
        }
      }
    }

    expect(
      verstoesse,
      isEmpty,
      reason:
          'Diese Dateien brechen den Web-Build. Zugriff auf Dateien läuft '
          'über lib/core/plattform/datei_ablage.dart:\n'
          '${verstoesse.join('\n')}',
    );
  });

  test('beide Plattform-Varianten der Naht existieren', () {
    for (final pfad in [
      'lib/core/plattform/datei_ablage.dart',
      'lib/core/plattform/datei_ablage_io.dart',
      'lib/core/plattform/datei_ablage_web.dart',
    ]) {
      expect(
        File(pfad).existsSync(),
        isTrue,
        reason: '$pfad fehlt - der bedingte Import greift dann ins Leere.',
      );
    }
  });

  test('beide Varianten bieten dieselbe API an', () {
    final io = File(
      'lib/core/plattform/datei_ablage_io.dart',
    ).readAsStringSync();
    final web = File(
      'lib/core/plattform/datei_ablage_web.dart',
    ).readAsStringSync();

    // Wird in der IO-Variante ein Member ergänzt, muss die Web-Variante
    // nachziehen - sonst bricht der Web-Build erst im CI.
    for (final member in [
      'verfuegbar',
      'basisPfad',
      'schreibe',
      'loescheOrdner',
      'bild',
      'temporaerSchreiben',
    ]) {
      expect(io, contains(member), reason: 'IO-Variante kennt $member nicht.');
      expect(
        web,
        contains(member),
        reason: 'Web-Variante hinkt hinterher: $member fehlt.',
      );
    }
  });

  test('die Web-Variante fasst selbst keine Datei-APIs an', () {
    final web = File(
      'lib/core/plattform/datei_ablage_web.dart',
    ).readAsStringSync();

    expect(web, isNot(contains("import 'dart:io'")));
    expect(web, isNot(contains('path_provider')));
  });
}
