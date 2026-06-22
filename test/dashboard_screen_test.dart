import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';

class _FakeFsrsCardStore implements FsrsCardStore {
  @override
  GespeicherteKarte? kartenStandFuer(String frageId) => null;

  @override
  Map<String, GespeicherteKarte> alleKartenstaende() => {};

  @override
  Future<void> speichern(String frageId, GespeicherteKarte karte) async {}
}

class _FakeAttemptHistoryStore implements AttemptHistoryStore {
  @override
  Future<void> anhaengen(Attempt attempt) async {}

  @override
  List<Attempt> alle() => [];
}

void main() {
  testWidgets('Dashboard rendert alle Kennzahlen ohne Fehler (leere Daten)', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fsrsCardStoreProvider.overrideWithValue(_FakeFsrsCardStore()),
          attemptHistoryStoreProvider.overrideWithValue(
            _FakeAttemptHistoryStore(),
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Frei üben'), findsOneWidget);
    expect(find.text('Heute fällig'), findsOneWidget);
    expect(find.text('Prüfungssimulation'), findsOneWidget);
    expect(find.text('Behaltensquote'), findsOneWidget);
    expect(find.text('Prüfungsreife (schriftlich)'), findsOneWidget);

    // Die unteren Karten liegen außerhalb des sichtbaren Testviewports.
    await tester.dragUntilVisible(
      find.text('Schwache Themen'),
      find.byType(ListView),
      const Offset(0, -300),
    );

    expect(find.text('Konfidenz-Kalibrierung'), findsOneWidget);
    expect(find.text('Schwache Themen'), findsOneWidget);
  });
}
