import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/features/quiz/screens/quiz_screen.dart';
import 'package:meine_app/models/frage.dart';

import 'hilfen/test_kurs.dart';

// Zwei Testfragen – kein Asset-I/O nötig.
final _testFragen = [
  const Frage(
    id: 'test-001',
    bereich: 'allgemein',
    kategorie: 'Zerspanung',
    typ: 'single',
    frage: 'Welches Verfahren gehört zur Zerspanung?',
    optionen: ['Drehen', 'Gießen', 'Schweißen', 'Schmieden'],
    richtigeIndizes: [0],
    reihenfolge: [],
    paare: [],
    luecken: [],
    akzeptierteKurzantworten: [],
    erklaerung: 'Drehen ist ein spanendes Verfahren.',
    schwierigkeit: 1,
  ),
  const Frage(
    id: 'test-002',
    bereich: 'allgemein',
    kategorie: 'Zerspanung',
    typ: 'single',
    frage: 'Was beschreibt die Schnittgeschwindigkeit?',
    optionen: [
      'Geschwindigkeit der Werkzeugschneide',
      'Vorschub pro Umdrehung',
      'Spantiefe',
      'Drehzahl der Spindel',
    ],
    richtigeIndizes: [0],
    reihenfolge: [],
    paare: [],
    luecken: [],
    akzeptierteKurzantworten: [],
    erklaerung:
        'vc ist die Relativgeschwindigkeit zwischen Schneide und Werkstück.',
    schwierigkeit: 1,
  ),
];

void main() {
  const modus = QuizModus.freiUebung();

  testWidgets(
    'Quiz-Screen: Single-Choice → Konfidenz → Aufdecken → Bewertung',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fsrsCardStoreProvider.overrideWithValue(FakeFsrsCardStore()),
            attemptHistoryStoreProvider.overrideWithValue(
              FakeAttemptHistoryStore(),
            ),
            aktivesPaketProvider.overrideWith(
              (_) async => testPaket(_testFragen),
            ),
          ],
          child: const MaterialApp(home: QuizScreen(modus: modus)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Frage 1 von'), findsOneWidget);
      expect(find.text('Drehen'), findsOneWidget);

      await tester.tap(find.text('Drehen'));
      await tester.pump();
      await tester.tap(find.text('Weiter'));
      await tester.pump();

      // Neue UX: 3 Buttons statt Chip + separater Aufdecken-Button.
      expect(find.text('Wie sicher warst du?'), findsOneWidget);

      // Ein Tap auf 'Sicher' setzt Konfidenz UND deckt sofort auf.
      await tester.tap(find.text('Sicher'));
      await tester.pump();

      expect(find.text('Richtig'), findsOneWidget);
      expect(find.text('Gut'), findsOneWidget);

      await tester.tap(find.text('Gut'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Frage 2 von'), findsOneWidget);
    },
  );
}
