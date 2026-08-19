// Zuordnungsaufgaben auf kleinen Bildschirmen.
//
// Regression: Die Auswahl lag früher als DropdownButton in einer Row neben
// dem Begriff - also auf der halben Bildschirmbreite. Das Popup wurde am
// Bildschirmrand abgeschnitten, lange Begriffe wie "Zugdruckumformen" waren
// nicht lesbar. Diese Tests laufen deshalb bewusst auf einer schmalen
// Handy-Fläche.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/features/quiz/screens/quiz_screen.dart';
import 'package:meine_app/models/frage.dart';

import 'hilfen/test_kurs.dart';

// Bewusst lange Begriffe - genau die waren im Dropdown abgeschnitten.
const _rechts = [
  'Zugdruckumformen',
  'Druckumformen',
  'Biegeumformen',
  'Zugumformen',
];

final _zuordnungsFrage = Frage(
  id: 'zo-001',
  bereich: 'allgemein',
  kategorie: 'Umformen',
  typ: 'zuordnung',
  frage: 'Ordne jedem Verfahren seine Hauptgruppe zu.',
  optionen: const [],
  richtigeIndizes: const [],
  reihenfolge: const [],
  paare: const [
    Paar(links: 'Tiefziehen', rechts: 'Zugdruckumformen'),
    Paar(links: 'Schmieden', rechts: 'Druckumformen'),
    Paar(links: 'Abkanten', rechts: 'Biegeumformen'),
    Paar(links: 'Streckziehen', rechts: 'Zugumformen'),
  ],
  luecken: const [],
  akzeptierteKurzantworten: const [],
  erklaerung: 'Die vier Hauptgruppen nach DIN 8582.',
  schwierigkeit: 2,
);

/// Schmaler Handy-Bildschirm (etwa Pixel-Format bei 3-facher Dichte).
void _handyBildschirm(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2160);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpeQuiz(WidgetTester tester) async {
  const modus = QuizModus.freiUebung();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fsrsCardStoreProvider.overrideWithValue(FakeFsrsCardStore()),
        attemptHistoryStoreProvider.overrideWithValue(
          FakeAttemptHistoryStore(),
        ),
        aktivesPaketProvider.overrideWith(
          (_) async => testPaket([_zuordnungsFrage]),
        ),
      ],
      child: const MaterialApp(home: QuizScreen(modus: modus)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('jeder Begriff bekommt eine eigene Auswahl', (tester) async {
    _handyBildschirm(tester);
    await _pumpeQuiz(tester);

    for (final begriff in [
      'Tiefziehen',
      'Schmieden',
      'Abkanten',
      'Streckziehen',
    ]) {
      expect(find.text(begriff), findsOneWidget);
    }
    expect(find.text('Zuordnen…'), findsNWidgets(4));
  });

  testWidgets('die Auswahl nutzt die volle Breite', (tester) async {
    _handyBildschirm(tester);
    await _pumpeQuiz(tester);

    final breite = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final feld = tester.getRect(find.byType(InputDecorator).first);

    // Vorher lag das Feld in einer Row neben dem Begriff und war damit rund
    // halb so breit. Mit Rand bleibt es knapp unter der vollen Breite.
    expect(
      feld.width,
      greaterThan(breite * 0.8),
      reason: 'Die Auswahl soll die Bildschirmbreite nutzen, nicht die Hälfte.',
    );
    expect(feld.right, lessThanOrEqualTo(breite));
  });

  testWidgets('alle Optionen sind im Auswahlblatt vollständig sichtbar', (
    tester,
  ) async {
    _handyBildschirm(tester);
    await _pumpeQuiz(tester);

    await tester.tap(find.text('Zuordnen…').first);
    await tester.pumpAndSettle();

    final breite = tester.view.physicalSize.width / tester.view.devicePixelRatio;

    for (final option in _rechts) {
      final treffer = find.text(option);
      expect(treffer, findsWidgets, reason: '"$option" fehlt im Auswahlblatt.');

      // Der Kern der Regression: Der Text darf nicht über den Bildschirmrand
      // hinausragen, sonst ist er abgeschnitten.
      final rect = tester.getRect(treffer.first);
      expect(
        rect.right,
        lessThanOrEqualTo(breite),
        reason: '"$option" ragt über den rechten Bildschirmrand hinaus.',
      );
      expect(rect.left, greaterThanOrEqualTo(0.0));
    }
  });

  testWidgets('eine Auswahl wird übernommen und angezeigt', (tester) async {
    _handyBildschirm(tester);
    await _pumpeQuiz(tester);

    await tester.tap(find.text('Zuordnen…').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biegeumformen').last);
    await tester.pumpAndSettle();

    // Die getroffene Wahl steht jetzt im Feld, eine Zuordnung weniger offen.
    expect(find.text('Biegeumformen'), findsOneWidget);
    expect(find.text('Zuordnen…'), findsNWidgets(3));
  });

  testWidgets('Weiter bleibt gesperrt, bis alles zugeordnet ist', (
    tester,
  ) async {
    _handyBildschirm(tester);
    await _pumpeQuiz(tester);

    ElevatedButton weiterKnopf() => tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Weiter'),
    );

    expect(weiterKnopf().onPressed, isNull);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Zuordnen…').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_rechts[i]).last);
      await tester.pumpAndSettle();
    }

    expect(find.text('Zuordnen…'), findsNothing);
    expect(weiterKnopf().onPressed, isNotNull);
  });
}
