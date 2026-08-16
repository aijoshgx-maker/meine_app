import 'package:go_router/go_router.dart';

import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/fachgespraech/screens/fachgespraech_auswahl_screen.dart';
import '../features/fachgespraech/screens/fachgespraech_session_screen.dart';
import '../features/pruefungssimulation/screens/pruefungs_auswahl_screen.dart';
import '../features/quiz/providers/quiz_modus.dart';
import '../features/quiz/screens/quiz_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/themenauswahl/screens/themen_auswahl_screen.dart';
import 'shell_scaffold.dart';

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) => QuizScreen(modus: state.extra as QuizModus),
    ),
    GoRoute(
      path: '/themenauswahl',
      builder: (context, state) => const ThemenAuswahlScreen(),
    ),
    GoRoute(
      path: '/fachgespraech',
      builder: (context, state) => const FachgespraechAuswahlScreen(),
    ),
    GoRoute(
      path: '/fachgespraech/:szenarioId',
      builder: (context, state) => FachgespraechSessionScreen(
        szenarioId:
            Uri.decodeComponent(state.pathParameters['szenarioId'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/pruefungssimulation',
      builder: (context, state) => const PruefungsAuswahlScreen(),
    ),
  ],
);
