import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/quiz/providers/quiz_fragen_auswahl.dart';
import 'package:meine_app/features/quiz/providers/quiz_modus.dart';
import 'package:meine_app/models/frage.dart';

void main() {
  final auswahl = QuizFragenAuswahl();

  Frage frage(String id, String bereich, {String kategorie = 'Test'}) => Frage(
    id: id,
    bereich: bereich,
    kategorie: kategorie,
    typ: 'single',
    frage: 'Frage $id?',
    optionen: const ['a', 'b'],
    richtigeIndizes: const [0],
    reihenfolge: const [],
    paare: const [],
    luecken: const [],
    akzeptierteKurzantworten: const [],
    erklaerung: '...',
    schwierigkeit: 1,
  );

  final fragen = [
    frage('a1', 'auftragsanalyse', kategorie: 'Zerspanung'),
    frage('ft1', 'fertigungstechnik', kategorie: 'CNC'),
    frage('w1', 'wiso', kategorie: 'Tarifrecht'),
  ];

  test('freiUebung gibt alle Fragen unverändert zurück', () {
    final ergebnis = auswahl.waehleFragen(
      const QuizModus.freiUebung(),
      fragen,
      kartenstaende: {},
      zufall: Random(1),
    );
    expect(ergebnis, fragen);
  });

  group('heuteFaellig', () {
    test('Fragen ohne gespeicherten Stand gelten als sofort fällig', () {
      final ergebnis = auswahl.waehleFragen(
        const QuizModus.heuteFaellig(),
        fragen,
        kartenstaende: {},
        zufall: Random(1),
      );
      expect(ergebnis.toSet(), fragen.toSet());
    });

    test('nur Fragen mit due <= jetzt werden zurückgegeben', () {
      final jetzt = DateTime.now();
      final kartenstaende = {
        'a1': GespeicherteKarte(
          card: FsrsCard.newCard(
            now: jetzt,
          ).copyWith(due: jetzt.subtract(const Duration(days: 1))),
        ),
        'ft1': GespeicherteKarte(
          card: FsrsCard.newCard(
            now: jetzt,
          ).copyWith(due: jetzt.add(const Duration(days: 5))),
        ),
      };

      final ergebnis = auswahl.waehleFragen(
        const QuizModus.heuteFaellig(),
        fragen,
        kartenstaende: kartenstaende,
        zufall: Random(1),
      );

      // a1 ist fällig, ft1 noch nicht, w1 hat keinen Stand -> sofort fällig.
      expect(ergebnis.map((f) => f.id).toSet(), {'a1', 'w1'});
    });

    test('Tageslimit: maximal 30 Karten werden zurückgegeben', () {
      final vieleFragen = List.generate(
        50,
        (i) => frage('f$i', 'wiso', kategorie: 'Test'),
      );
      final ergebnis = auswahl.waehleFragen(
        const QuizModus.heuteFaellig(),
        vieleFragen,
        kartenstaende: {},
        zufall: Random(1),
      );
      expect(ergebnis.length, lessThanOrEqualTo(30));
    });
  });

  test('themenVertiefung filtert nur die gewählte Kategorie', () {
    final ergebnis = auswahl.waehleFragen(
      const QuizModus.themenVertiefung(kategorie: 'CNC'),
      fragen,
      kartenstaende: {},
      zufall: Random(1),
    );
    expect(ergebnis.map((f) => f.id).toList(), ['ft1']);
  });
}
