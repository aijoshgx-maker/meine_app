import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/features/quiz/providers/session_timer_provider.dart';

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

void main() {
  testWidgets('Timer zählt herunter und beendet die Session bei Ablauf', (
    tester,
  ) async {
    const modus = QuizModus.pruefungssimulation(
      bereich: 'wiso',
      zeitlimit: Duration(seconds: 3),
    );

    late Duration restzeit;
    late bool fertig;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fsrsCardStoreProvider.overrideWithValue(_FakeFsrsCardStore()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            restzeit = ref.watch(sessionTimerProvider(modus));
            fertig =
                ref.watch(quizSessionProvider(modus)).value?.fertig ?? false;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // Fragen laden lassen (asynchron), Timer ist dann gestartet.
    await tester.pump();
    expect(restzeit, const Duration(seconds: 3));

    await tester.pump(const Duration(seconds: 1));
    expect(restzeit, const Duration(seconds: 2));
    expect(fertig, false);

    await tester.pump(const Duration(seconds: 2));
    expect(restzeit, Duration.zero);
    expect(fertig, true);
  });
}
