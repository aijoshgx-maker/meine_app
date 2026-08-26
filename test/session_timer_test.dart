// sessionTimerProvider: no-op für Nicht-Testlauf-Modi, echter Countdown mit
// Pause/Fortsetzen für den Testlauf.
//
// Der Countdown war lange ungetestet - genau der Pfad, der in einer echten
// Prüfungssimulation zählt.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/app/settings_providers.dart';
import 'package:meine_app/features/kurse/providers/kurs_providers.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/features/quiz/providers/session_timer_provider.dart';
import 'package:meine_app/models/frage.dart';

import 'hilfen/test_kurs.dart';

const _testFragen = [
  Frage(
    id: 'timer-001',
    bereich: 'allgemein',
    kategorie: 'Test',
    typ: 'single',
    frage: 'Testfrage',
    optionen: ['A', 'B'],
    richtigeIndizes: [0],
    reihenfolge: [],
    paare: [],
    luecken: [],
    akzeptierteKurzantworten: [],
    erklaerung: 'Test.',
    schwierigkeit: 1,
    pruefung: 'T1',
    pruefungReihenfolge: 1,
  ),
];

/// Pumpt einen Consumer, der [modus] beobachtet, und gibt Zugriff auf
/// Zustand und Container.
///
/// Der Container wird noch im Testkörper entsorgt: flutter_test prüft direkt
/// nach dem Testkörper auf laufende Timer - erst in einem tearDown zu
/// entsorgen wäre zu spät, und der Countdown-Timer würde den Test kippen.
Future<(ProviderContainer, TimerZustand Function())> _pumpe(
  WidgetTester tester,
  QuizModus modus,
) async {
  late TimerZustand zustand;
  final container = ProviderContainer(
    overrides: [
      fsrsCardStoreProvider.overrideWithValue(FakeFsrsCardStore()),
      settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
      attemptHistoryStoreProvider.overrideWithValue(FakeAttemptHistoryStore()),
      aktivesPaketProvider.overrideWith((_) async => testPaket(_testFragen)),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          zustand = ref.watch(sessionTimerProvider(modus));
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();
  return (container, () => zustand);
}

void main() {
  testWidgets('gibt für Nicht-Testlauf-Modi Duration.zero zurück (no-op)', (
    tester,
  ) async {
    const modus = QuizModus.themenVertiefung(kategorie: 'Test');
    final (container, zustand) = await _pumpe(tester, modus);

    expect(zustand().verbleibend, Duration.zero);
    expect(zustand().pausiert, false);
    container.dispose();
  });

  testWidgets('startet beim Zeitlimit und zählt sekündlich herunter', (
    tester,
  ) async {
    const modus = QuizModus.pruefungssimulation(
      pruefungsId: 'T1',
      zeitlimitMinuten: 2,
    );
    final (container, zustand) = await _pumpe(tester, modus);

    expect(zustand().verbleibend, const Duration(minutes: 2));

    await tester.pump(const Duration(seconds: 1));
    expect(zustand().verbleibend, const Duration(seconds: 119));

    await tester.pump(const Duration(seconds: 5));
    expect(zustand().verbleibend, const Duration(seconds: 114));
    container.dispose();
  });

  testWidgets('pausieren friert den Countdown ein, fortsetzen löst ihn', (
    tester,
  ) async {
    const modus = QuizModus.pruefungssimulation(
      pruefungsId: 'T1',
      zeitlimitMinuten: 2,
    );
    final (container, zustand) = await _pumpe(tester, modus);
    final controller = container.read(sessionTimerProvider(modus).notifier);

    await tester.pump(const Duration(seconds: 2));
    final vorPause = zustand().verbleibend;

    controller.pausieren();
    await tester.pump();
    expect(zustand().pausiert, isTrue);

    await tester.pump(const Duration(seconds: 5));
    expect(
      zustand().verbleibend,
      vorPause,
      reason: 'Während der Pause darf keine Zeit ablaufen.',
    );

    controller.fortsetzen();
    await tester.pump(const Duration(seconds: 1));
    expect(zustand().pausiert, isFalse);
    expect(zustand().verbleibend, vorPause - const Duration(seconds: 1));
    container.dispose();
  });

  testWidgets('bei 0 endet die Session automatisch', (tester) async {
    // Kleinstmögliches Limit, damit der Test nicht 120 Sekunden pumpen muss.
    const modus = QuizModus.pruefungssimulation(
      pruefungsId: 'T1',
      zeitlimitMinuten: 1,
    );
    final (container, zustand) = await _pumpe(tester, modus);
    await container.read(quizSessionProvider(modus).future);

    await tester.pump(const Duration(seconds: 60));

    expect(zustand().verbleibend, Duration.zero);
    expect(
      container.read(quizSessionProvider(modus)).value?.fertig,
      isTrue,
      reason: 'Der abgelaufene Timer muss die Session beenden.',
    );
    container.dispose();
  });

  group('formatiereDauer', () {
    test('unter einer Stunde: mm:ss', () {
      expect(formatiereDauer(const Duration(minutes: 5, seconds: 7)), '05:07');
    });

    test('ab einer Stunde: hh:mm:ss', () {
      expect(
        formatiereDauer(const Duration(hours: 2, minutes: 3, seconds: 4)),
        '02:03:04',
      );
    });

    test('null und negativ werden zu 00:00', () {
      expect(formatiereDauer(Duration.zero), '00:00');
      expect(formatiereDauer(const Duration(seconds: -5)), '00:00');
    });
  });
}
