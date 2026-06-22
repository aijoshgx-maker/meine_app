import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/quiz/providers/quiz_fragen_auswahl.dart';
import 'package:meine_app/features/quiz/providers/quiz_modus.dart';
import 'package:meine_app/models/frage.dart';

void main() {
  final auswahl = QuizFragenAuswahl();

  Frage frage(String id, String bereich) => Frage(
    id: id,
    bereich: bereich,
    kategorie: 'Test',
    typ: 'single',
    frage: 'Frage $id?',
    optionen: const ['a', 'b'],
    richtigeIndizes: const [0],
    akzeptierteKurzantworten: const [],
    erklaerung: '...',
    schwierigkeit: 1,
  );

  final fragen = [
    frage('a1', 'auftragsanalyse'),
    frage('ft1', 'fertigungstechnik'),
    frage('w1', 'wiso'),
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
  });

  test('pruefungssimulation filtert nur den gewählten Bereich', () {
    final ergebnis = auswahl.waehleFragen(
      const QuizModus.pruefungssimulation(
        bereich: 'fertigungstechnik',
        zeitlimit: Duration(minutes: 120),
      ),
      fragen,
      kartenstaende: {},
      zufall: Random(1),
    );
    expect(ergebnis.map((f) => f.id).toList(), ['ft1']);
  });
}
