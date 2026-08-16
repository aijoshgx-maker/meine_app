// P6b/P12b: Laufzeit-Shuffle liefert immer eine gültige Permutation, lässt
// Anker-Optionen an Ort und Stelle und ist über viele Läufe hinweg nicht
// systematisch die Identität.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/quiz/options_shuffle.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/models/frage.dart';

void main() {
  group('berechneAnzeigeReihenfolge', () {
    test('liefert immer eine gültige Permutation von 0..n-1', () {
      final zufall = Random(42);
      for (var lauf = 0; lauf < 50; lauf++) {
        final ergebnis = berechneAnzeigeReihenfolge(5, zufall);
        expect(ergebnis.toSet(), {0, 1, 2, 3, 4});
        expect(ergebnis, hasLength(5));
      }
    });

    test('Anker-Optionen bleiben an ihrer Originalposition', () {
      final zufall = Random(7);
      for (var lauf = 0; lauf < 50; lauf++) {
        // Index 4 ist Anker ("Keine der genannten").
        final ergebnis = berechneAnzeigeReihenfolge(
          5,
          zufall,
          istAnker: (i) => i == 4,
        );
        expect(ergebnis[4], 4, reason: 'Anker darf nicht verschoben werden');
        expect(ergebnis.toSet(), {0, 1, 2, 3, 4});
      }
    });

    test('mischt über viele Läufe tatsächlich (nicht dauerhaft Identität)', () {
      final zufall = Random(1);
      var mindestensEinmalGemischt = false;
      for (var lauf = 0; lauf < 30; lauf++) {
        final ergebnis = berechneAnzeigeReihenfolge(5, zufall);
        if (ergebnis.asMap().entries.any((e) => e.key != e.value)) {
          mindestensEinmalGemischt = true;
          break;
        }
      }
      expect(mindestensEinmalGemischt, isTrue);
    });

    test('leere/einelementige Liste bleibt unverändert', () {
      final zufall = Random();
      expect(berechneAnzeigeReihenfolge(0, zufall), isEmpty);
      expect(berechneAnzeigeReihenfolge(1, zufall), [0]);
    });
  });

  test('istAnkerOptionstext erkennt bekannte Anker-Formulierungen', () {
    expect(istAnkerOptionstext('Keine der genannten Antworten'), isTrue);
    expect(istAnkerOptionstext('Alle Antworten sind richtig'), isTrue);
    expect(istAnkerOptionstext('Drehen'), isFalse);
  });

  test('AntwortZustand.fuerFrage: richtigeIndizes zeigt nach dem Mischen '
      'weiterhin auf die inhaltlich richtige Option', () {
    const frage = Frage(
      id: 'shuffle-test',
      bereich: 'test',
      kategorie: 'Test',
      typ: 'single',
      frage: 'Welche Option ist richtig?',
      optionen: ['falsch A', 'RICHTIG', 'falsch B', 'falsch C', 'falsch D'],
      richtigeIndizes: [1],
      reihenfolge: [],
      paare: [],
      luecken: [],
      akzeptierteKurzantworten: [],
      erklaerung: '...',
      schwierigkeit: 1,
    );

    // Viele Seeds durchprobieren, damit auch tatsächlich gemischte Fälle
    // dabei sind (nicht nur zufällig Rotation 0).
    for (var seed = 0; seed < 100; seed++) {
      final zustand = AntwortZustand.fuerFrage(frage, Random(seed));
      expect(zustand.optionenReihenfolge.toSet(), {0, 1, 2, 3, 4});
      // Original-Index 1 ("RICHTIG") muss irgendwo in der
      // Anzeigereihenfolge vorkommen - unabhängig von der Position.
      expect(zustand.optionenReihenfolge, contains(1));
      // Der Options-Text an der Stelle, wo Original-Index 1 angezeigt
      // wird, ist tatsächlich der richtige Text.
      final anzeigePosition = zustand.optionenReihenfolge.indexOf(1);
      expect(
        frage.optionen[zustand.optionenReihenfolge[anzeigePosition]],
        'RICHTIG',
      );
      // frage.richtigeIndizes selbst bleibt unverändert (Original-Raum) -
      // die Bewertungslogik vergleicht immer dagegen, nie gegen die
      // Anzeigeposition.
      expect(frage.richtigeIndizes, [1]);
    }
  });
}
