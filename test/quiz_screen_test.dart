import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/features/quiz/screens/quiz_screen.dart';
import 'package:meine_app/models/frage.dart';

class _FakeFsrsCardStore implements FsrsCardStore {
  final Map<String, GespeicherteKarte> _daten = {};

  @override
  GespeicherteKarte? kartenStandFuer(String frageId) => _daten[frageId];

  @override
  Map<String, GespeicherteKarte> alleKartenstaende() => Map.of(_daten);

  @override
  Future<void> speichern(String frageId, GespeicherteKarte karte) async {
    _daten[frageId] = karte;
  }
}

class _FakeAttemptHistoryStore implements AttemptHistoryStore {
  final List<Attempt> _eintraege = [];

  @override
  Future<void> anhaengen(Attempt attempt) async => _eintraege.add(attempt);

  @override
  List<Attempt> alle() => List.of(_eintraege);
}

// Zwei Testfragen – kein Asset-I/O nötig.
final _testFragen = [
  const Frage(
    id: 'test-001',
    bereich: 'fertigungstechnik',
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
    bereich: 'fertigungstechnik',
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
    erklaerung: 'vc ist die Relativgeschwindigkeit zwischen Schneide und Werkstück.',
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
            fsrsCardStoreProvider.overrideWithValue(_FakeFsrsCardStore()),
            attemptHistoryStoreProvider.overrideWithValue(
              _FakeAttemptHistoryStore(),
            ),
            fragenProvider.overrideWith((_) async => _testFragen),
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
