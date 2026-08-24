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

  _aufdeckungsTests();
}

// Der Umbau der Aufdeckung zeigt die Lösung jetzt strukturiert an. Der
// gefährlichste Fehler dabei wäre, sie zu früh zu zeigen - dann wäre die
// Frage wertlos. Diese Tests halten den Ablauf fest.
void _aufdeckungsTests() {
  const modus = QuizModus.freiUebung();

  final langeFrage = Frage(
    id: 'lang-001',
    bereich: 'allgemein',
    kategorie: 'Test',
    typ: 'single',
    frage: 'Was beschreibt die Schnittgeschwindigkeit?',
    optionen: const ['Relativgeschwindigkeit', 'Vorschub', 'Spantiefe'],
    richtigeIndizes: const [0],
    reihenfolge: const [],
    paare: const [],
    luecken: const [],
    akzeptierteKurzantworten: const [],
    erklaerung:
        'Die Schnittgeschwindigkeit ist die Relativgeschwindigkeit zwischen '
        'Schneide und Werkstück. Sie wird in m/min angegeben und haengt vom '
        'Werkstoff sowie vom Schneidstoff ab, weshalb zu hohe Werte zu '
        'vorzeitigem Verschleiss fuehren.',
    schwierigkeit: 1,
  );

  Future<void> pumpe(WidgetTester tester, Frage frage) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fsrsCardStoreProvider.overrideWithValue(FakeFsrsCardStore()),
          attemptHistoryStoreProvider.overrideWithValue(
            FakeAttemptHistoryStore(),
          ),
          aktivesPaketProvider.overrideWith((_) async => testPaket([frage])),
        ],
        child: const MaterialApp(home: QuizScreen(modus: modus)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('vor dem Aufdecken ist die Lösung nicht sichtbar', (
    tester,
  ) async {
    await pumpe(tester, langeFrage);

    expect(find.text('Lösung'), findsNothing);
    expect(find.text('Ausführlich'), findsNothing);
  });

  testWidgets('nach dem Aufdecken erscheinen Lösung und Kurzfassung', (
    tester,
  ) async {
    await pumpe(tester, langeFrage);

    await tester.tap(find.text('Relativgeschwindigkeit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sicher'));
    await tester.pumpAndSettle();

    expect(find.text('Lösung'), findsOneWidget);
    // Kurzfassung: erster Satz sichtbar, der Rest noch nicht.
    expect(
      find.textContaining('Relativgeschwindigkeit zwischen'),
      findsWidgets,
    );
    expect(find.textContaining('vorzeitigem Verschleiss'), findsNothing);
  });

  testWidgets('der Aufklapper zeigt den Rest der Erklärung', (tester) async {
    await pumpe(tester, langeFrage);

    await tester.tap(find.text('Relativgeschwindigkeit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sicher'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ausführlich'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausführlich'));
    await tester.pumpAndSettle();

    expect(find.textContaining('vorzeitigem Verschleiss'), findsOneWidget);
  });

  // Aus der App gemeldet: Aufgeklappt stand derselbe Absatz zweimal
  // untereinander. Der Aufklapper ersetzt die Kurzfassung jetzt, statt sie
  // zu ergänzen.
  testWidgets('aufgeklappt steht kein Satz zweimal da', (tester) async {
    await pumpe(tester, langeFrage);

    await tester.tap(find.text('Relativgeschwindigkeit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sicher'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ausführlich'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausführlich'));
    await tester.pumpAndSettle();

    // Der erste Satz gehört nur zur Kurzfassung - taucht er nach dem
    // Aufklappen ein zweites Mal auf, steht die Erklärung doppelt da.
    expect(
      find.textContaining('Relativgeschwindigkeit zwischen'),
      findsOneWidget,
    );
    expect(find.text('Weniger'), findsOneWidget);
  });

  testWidgets('bei kurzer Erklärung gibt es nichts aufzuklappen', (
    tester,
  ) async {
    final kurz = Frage(
      id: 'kurz-001',
      bereich: 'allgemein',
      kategorie: 'Test',
      typ: 'wahrfalsch',
      frage: 'Island ist EU-Mitglied.',
      optionen: const [],
      richtigeIndizes: const [],
      reihenfolge: const [],
      paare: const [],
      luecken: const [],
      akzeptierteKurzantworten: const [],
      wahr: false,
      erklaerung: 'Island gehört zum EWR, nicht zur EU.',
      schwierigkeit: 1,
    );

    await pumpe(tester, kurz);
    await tester.tap(find.text('Falsch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sicher'));
    await tester.pumpAndSettle();

    expect(find.text('Lösung'), findsOneWidget);
    expect(find.text('Ausführlich'), findsNothing);
  });
}
