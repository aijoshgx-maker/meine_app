// sessionTimerProvider gibt für Nicht-Sim-Modi Duration.zero zurück.
// Dieser Test stellt sicher, dass er fehlerfrei aufgebaut wird.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/features/quiz/providers/session_timer_provider.dart';
import 'package:meine_app/models/frage.dart';

class _FakeFsrsCardStore implements FsrsCardStore {
  @override
  GespeicherteKarte? kartenStandFuer(String frageId) => null;
  @override
  Map<String, GespeicherteKarte> alleKartenstaende() => {};
  @override
  Future<void> speichern(String frageId, GespeicherteKarte karte) async {}
}

const _testFragen = [
  Frage(
    id: 'timer-wiso-001',
    bereich: 'wiso',
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
  ),
];

void main() {
  testWidgets('sessionTimerProvider gibt Duration.zero zurück (no-op)', (
    tester,
  ) async {
    const modus = QuizModus.themenVertiefung(kategorie: 'Test');

    late TimerZustand timerZustand;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fsrsCardStoreProvider.overrideWithValue(_FakeFsrsCardStore()),
          fragenProvider.overrideWith((_) async => _testFragen),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            timerZustand = ref.watch(sessionTimerProvider(modus));
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pump();
    expect(timerZustand.verbleibend, Duration.zero);
    expect(timerZustand.pausiert, false);
  });
}
