import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/data/fsrs_card_store.dart';
import 'package:meine_app/features/quiz/providers/quiz_providers.dart';
import 'package:meine_app/features/quiz/screens/quiz_screen.dart';

// Einfacher In-Memory-Fake statt echter Hive-Dateioperationen, damit der
// Widget-Test schnell und ohne Datei-I/O läuft.
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
  const modus = QuizModus.freiUebung();

  testWidgets(
    'Quiz-Screen: Single-Choice-Frage -> Konfidenz -> Aufdecken -> Bewertung',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fsrsCardStoreProvider.overrideWithValue(_FakeFsrsCardStore()),
          ],
          child: const MaterialApp(home: QuizScreen(modus: modus)),
        ),
      );

      // Fragen werden asynchron aus dem Asset geladen.
      await tester.pumpAndSettle();

      // Erste Frage ist die single-choice Frage "ft-101" (Zerspanung).
      expect(find.textContaining('Frage 1 von'), findsOneWidget);
      expect(find.text('Drehen'), findsOneWidget);

      // Antwort auswählen und weiter zur Konfidenz-Abfrage.
      await tester.tap(find.text('Drehen'));
      await tester.pump();
      await tester.tap(find.text('Weiter'));
      await tester.pump();

      expect(find.text('Wie sicher bist du dir?'), findsOneWidget);

      // Konfidenz wählen und aufdecken.
      await tester.tap(find.text('Sicher'));
      await tester.pump();
      await tester.tap(find.text('Aufdecken'));
      await tester.pump();

      expect(find.text('Richtig'), findsOneWidget);
      expect(find.text('Gut'), findsOneWidget);

      // FSRS-Bewertung abgeben -> nächste Frage erscheint.
      await tester.tap(find.text('Gut'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Frage 2 von'), findsOneWidget);
    },
  );
}
