import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meine_app/features/pruefungssimulation/screens/pruefungs_auswahl_screen.dart';
import 'package:meine_app/features/quiz/providers/quiz_modus.dart';

void main() {
  testWidgets(
    'Tippen auf einen Teilbereich navigiert mit korrektem QuizModus',
    (tester) async {
      QuizModus? empfangenerModus;
      final router = GoRouter(
        initialLocation: '/pruefungssimulation',
        routes: [
          GoRoute(
            path: '/pruefungssimulation',
            builder: (context, state) => const PruefungsAuswahlScreen(),
          ),
          GoRoute(
            path: '/quiz',
            builder: (context, state) {
              empfangenerModus = state.extra as QuizModus;
              return const SizedBox.shrink();
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('Fertigungstechnik'));
      await tester.pumpAndSettle();

      expect(empfangenerModus, isNotNull);
      expect(empfangenerModus!.art, QuizArt.pruefungssimulation);
      expect(empfangenerModus!.bereich, 'fertigungstechnik');
      expect(empfangenerModus!.zeitlimit, const Duration(minutes: 120));
    },
  );
}
