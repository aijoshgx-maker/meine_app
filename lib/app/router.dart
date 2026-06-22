import 'package:go_router/go_router.dart';

import '../features/pruefungssimulation/screens/pruefungs_auswahl_screen.dart';
import '../features/quiz/providers/quiz_modus.dart';
import '../features/quiz/screens/quiz_screen.dart';
import 'home_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/quiz',
      builder: (context, state) => QuizScreen(modus: state.extra as QuizModus),
    ),
    GoRoute(
      path: '/pruefungssimulation',
      builder: (context, state) => const PruefungsAuswahlScreen(),
    ),
  ],
);
