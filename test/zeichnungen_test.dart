// Prüfungszeichnungen und Stücklisten.
//
// Der Bestand ist Daten, kein Code - und Daten verrutschen still. Bis die
// Original-PDFs vorlagen, zeigten ALLE Zeichnungspfade in kurs.json auf
// Dateien, die es nie gab; der Platzhalter sprang ein und niemand merkte es.
// Und zwei Fragen nannten Positionsnummern, die zu anderen Bauteilen
// gehören. Beides fangen diese Tests ab.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/kurs_repository.dart';
import 'package:meine_app/models/lernpaket.dart';

/// "Pos. 12" / "Position 3" / "Pos 10.0"
final _positionsMuster = RegExp(
  r'\bPos(?:ition)?\.?\s*(\d+(?:\.\d+)?)',
  caseSensitive: false,
);

Set<String> _positionenIn(String text) =>
    _positionsMuster.allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Lernpaket paket;

  setUpAll(() async {
    paket = await KursRepository().paketFuer(KursRepository.standardKursId);
  });

  test('jeder Zeichnungspfad zeigt auf eine vorhandene Datei', () {
    final fehlend = <String>[];
    for (final pruefung in paket.kurs.pruefungen) {
      for (final zeichnung in pruefung.zeichnungen) {
        if (!File(zeichnung.pfad).existsSync()) {
          fehlend.add('${pruefung.code}: ${zeichnung.pfad}');
        }
      }
    }

    expect(
      fehlend,
      isEmpty,
      reason:
          'Fehlende Zeichnungen fallen im Betrieb nicht auf - der '
          'Platzhalter springt still ein:\n${fehlend.join('\n')}',
    );
  });

  test('jede Zeichnung trägt eine Beschriftung', () {
    for (final pruefung in paket.kurs.pruefungen) {
      for (final zeichnung in pruefung.zeichnungen) {
        expect(
          zeichnung.label.trim(),
          isNotEmpty,
          reason: '${pruefung.code}: ${zeichnung.pfad} ohne Label',
        );
      }
    }
  });

  test('jede Prüfung mit Zeichnungen hat auch eine Stückliste', () {
    for (final pruefung in paket.kurs.pruefungen) {
      if (pruefung.zeichnungen.isEmpty) continue;
      expect(
        pruefung.stueckliste,
        isNotEmpty,
        reason: '${pruefung.code} hat Zeichnungen, aber keine Stückliste',
      );
    }
  });

  // Der Test, der die beiden Bestandsfehler gefunden hätte: au-fa-020 und
  // au-me-028 nannten "Passscheibe (Pos. 34)", laut Stückliste ist 34 eine
  // Senkschraube.
  test('jede in einer Frage genannte Position steht in der Stückliste', () {
    final fehler = <String>[];

    for (final frage in paket.fragen) {
      final code = frage.pruefung;
      if (code == null) continue;

      final pruefung = paket.kurs.pruefungFuer(code);
      if (pruefung == null || pruefung.stueckliste.isEmpty) continue;

      final genannt = _positionenIn(
        '${frage.frage} ${frage.optionen.join(' ')} ${frage.erklaerung}',
      );
      for (final position in genannt) {
        if (!pruefung.stueckliste.containsKey(position)) {
          fehler.add('${frage.id} ($code): Pos. $position gibt es nicht');
        }
      }
    }

    expect(fehler, isEmpty, reason: fehler.join('\n'));
  });

  test('Fragen mit Zeichnungsbild gehören zur passenden Prüfung', () {
    final fehler = <String>[];

    for (final frage in paket.fragen) {
      final bild = frage.bildAsset;
      if (bild == null || !bild.startsWith('assets/zeichnungen/')) continue;

      // assets/zeichnungen/<CODE>/<datei>
      final ordner = bild.split('/')[2];
      if (frage.pruefung != ordner) {
        fehler.add(
          '${frage.id}: pruefung=${frage.pruefung}, Bild aus $ordner',
        );
      }
    }

    expect(fehler, isEmpty, reason: fehler.join('\n'));
  });

  test('jedes bildAsset ist auflösbar', () {
    for (final frage in paket.fragen) {
      final bild = frage.bildAsset;
      if (bild == null) continue;

      if (bild.startsWith('diag:')) continue; // fest eingebautes Diagramm
      expect(
        File(bild).existsSync(),
        isTrue,
        reason: '${frage.id}: $bild fehlt',
      );
    }
  });

  test('alle vier Prüfungen sind vollständig hinterlegt', () {
    final codes = paket.kurs.pruefungen.map((p) => p.code).toSet();
    expect(codes, containsAll(['W22', 'S17', 'S18', 'S19']));

    for (final pruefung in paket.kurs.pruefungen) {
      expect(
        pruefung.zeichnungen,
        isNotEmpty,
        reason: '${pruefung.code} ohne Zeichnungen',
      );
    }
  });
}
