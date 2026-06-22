import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/arbeitsauftrag_store.dart';
import 'package:meine_app/data/attempt_history_store.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/arbeitsauftrag/providers/arbeitsauftrag_providers.dart';
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

class _FakeArbeitsauftragStore implements ArbeitsauftragStore {
  @override
  Map<String, bool> checklistStatus() => {};

  @override
  Future<void> checklistSetzen(String itemId, bool erledigt) async {}

  @override
  Map<String, String> dokumentationLaden() => {};

  @override
  Future<void> dokumentationSpeichern(Map<String, String> felder) async {}

  @override
  Map<String, String> fachgespraechAntworten() => {};

  @override
  Future<void> fachgespraechAntwortSetzen(String fragId, String text) async {}
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
          arbeitsauftragStoreProvider.overrideWithValue(
            _FakeArbeitsauftragStore(),
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Frei üben'), findsOneWidget);
    expect(find.text('Heute fällig'), findsOneWidget);
    expect(find.text('Prüfungssimulation'), findsOneWidget);
    expect(find.text('Arbeitsauftrag'), findsOneWidget);
    expect(find.text('Arbeitsauftrag-Fortschritt'), findsOneWidget);

    // Die Karten liegen weiter unten als der sichtbare Testviewport, daher
    // einzeln (in Reihenfolge) hin-scrollen statt alle gleichzeitig zu prüfen.
    for (final text in [
      'Behaltensquote',
      'Prüfungsreife (schriftlich)',
      'Konfidenz-Kalibrierung',
      'Schwache Themen',
    ]) {
      await tester.dragUntilVisible(
        find.text(text),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text(text), findsOneWidget);
    }
  });
}
