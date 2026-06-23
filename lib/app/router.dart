import 'package:go_router/go_router.dart';

import '../features/arbeitsauftrag/screens/arbeitsauftrag_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/pruefungssimulation/screens/pruefungs_auswahl_screen.dart';
import '../features/quiz/providers/quiz_modus.dart';
import '../features/quiz/screens/quiz_screen.dart';
import '../features/settings/screens/settings_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(
      path: '/quiz',
      builder: (context, state) => QuizScreen(modus: state.extra as QuizModus),
    ),
    GoRoute(
      path: '/pruefungssimulation',
      builder: (context, state) => const PruefungsAuswahlScreen(),
    ),
    GoRoute(
      path: '/arbeitsauftrag',
      builder: (context, state) => const ArbeitsauftragScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
