// Die Tipp-Funktion im Quiz.
//
// Zwei Zusagen zählen hier: Der Knopf erscheint nur, wenn es wirklich etwas
// zu erklären gibt — und er verrät nichts, wo der Tipp die Antwort wäre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/app/settings_providers.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/features/quiz/screens/quiz_screen.dart';
import 'package:meine_app/models/frage.dart';
import 'package:meine_app/models/glossar.dart';
import 'package:meine_app/models/lernpaket.dart';

import 'hilfen/test_kurs.dart';

final _glossar = Glossar(const [
  GlossarEintrag(
    begriff: 'ω (Winkelgeschwindigkeit)',
    alias: ['ω', 'Winkelgeschwindigkeit'],
    kurz: 'Wie schnell sich etwas dreht, in rad/s.',
    mehr: 'ω = 2 · π · n, mit n in 1/s.',
  ),
  GlossarEintrag(
    begriff: 'n (Drehzahl)',
    alias: ['Drehzahl'],
    kurz: 'Umdrehungen pro Zeit, meist in min⁻¹.',
  ),
]);

Frage _frage({
  required String id,
  required String text,
  List<String> tippsAus = const [],
}) => Frage(
  id: id,
  bereich: 'allgemein',
  kategorie: 'Test',
  typ: 'single',
  frage: text,
  optionen: const ['A', 'B'],
  richtigeIndizes: const [0],
  reihenfolge: const [],
  paare: const [],
  luecken: const [],
  akzeptierteKurzantworten: const [],
  erklaerung: 'Weil.',
  schwierigkeit: 1,
  tippsAus: tippsAus,
);

Future<void> _pumpe(
  WidgetTester tester,
  Frage frage, {
  Glossar? glossar,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fsrsCardStoreProvider.overrideWithValue(FakeFsrsCardStore()),
        settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
        attemptHistoryStoreProvider.overrideWithValue(
          FakeAttemptHistoryStore(),
        ),
        aktivesPaketProvider.overrideWith(
          (_) async => Lernpaket(
            kurs: testKurs(),
            fragen: [frage],
            glossar: glossar ?? _glossar,
          ),
        ),
      ],
      child: const MaterialApp(home: QuizScreen(modus: QuizModus.freiUebung())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('kein Knopf, wenn nichts zu erklären ist', (tester) async {
    await _pumpe(
      tester,
      _frage(id: 'a', text: 'Welches Werkzeug eignet sich zum Entgraten?'),
    );

    expect(find.textContaining('Tipp'), findsNothing);
  });

  testWidgets('ein gefundener Begriff: Knopf ohne Zähler', (tester) async {
    await _pumpe(
      tester,
      _frage(id: 'a', text: 'Berechne ω für die Antriebswelle.'),
    );

    expect(find.text('Tipp'), findsOneWidget);
  });

  testWidgets('mehrere Begriffe: Knopf mit Anzahl', (tester) async {
    await _pumpe(
      tester,
      _frage(id: 'a', text: 'Berechne ω aus der Drehzahl n.'),
    );

    expect(find.text('Tipp (2 Begriffe)'), findsOneWidget);
  });

  testWidgets('das Blatt zeigt Begriff und Kurzerklärung', (tester) async {
    await _pumpe(tester, _frage(id: 'a', text: 'Berechne ω.'));

    await tester.tap(find.text('Tipp'));
    await tester.pumpAndSettle();

    expect(find.text('ω (Winkelgeschwindigkeit)'), findsOneWidget);
    expect(
      find.text('Wie schnell sich etwas dreht, in rad/s.'),
      findsOneWidget,
    );
    // Die Vertiefung steckt noch im Aufklapper.
    expect(find.textContaining('2 · π · n'), findsNothing);
  });

  testWidgets('"Mehr" klappt die Vertiefung auf', (tester) async {
    await _pumpe(tester, _frage(id: 'a', text: 'Berechne ω.'));

    await tester.tap(find.text('Tipp'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 · π · n'), findsOneWidget);
  });

  // Ohne Ausschluss wäre der Tipp hier schlicht die Lösung.
  testWidgets('tippsAus blendet einen Eintrag aus', (tester) async {
    await _pumpe(
      tester,
      _frage(
        id: 'a',
        text: 'Welche Einheit hat die Winkelgeschwindigkeit?',
        tippsAus: const ['ω (Winkelgeschwindigkeit)'],
      ),
    );

    expect(find.textContaining('Tipp'), findsNothing);
  });

  testWidgets('ein Kurs ohne Glossar zeigt keinen Knopf', (tester) async {
    await _pumpe(
      tester,
      _frage(id: 'a', text: 'Berechne ω aus der Drehzahl n.'),
      glossar: Glossar.leer,
    );

    expect(find.textContaining('Tipp'), findsNothing);
  });
}
