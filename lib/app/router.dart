import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/fachgespraech/screens/fachgespraech_auswahl_screen.dart';
import '../features/fachgespraech/screens/fachgespraech_session_screen.dart';
import '../features/kurse/screens/kurs_verwaltung_screen.dart';
import '../features/pruefungssimulation/screens/pruefungs_auswahl_screen.dart';
import '../features/quiz/providers/quiz_modus.dart';
import '../features/quiz/screens/quiz_screen.dart';
import '../features/settings/screens/backup_screen.dart';
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
          path: '/kurse',
          builder: (context, state) => const KursVerwaltungScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/backup',
          builder: (context, state) => const BackupScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/quiz',
      // extra kann fehlen (Deep-Link, Web-Reload, Browser-Zurück). Früher
      // war das ein ungeprüfter Cast und damit ein Absturz.
      builder: (context, state) {
        final modus = state.extra;
        if (modus is! QuizModus) return const _ModusFehlt();
        return QuizScreen(modus: modus);
      },
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
        szenarioId: Uri.decodeComponent(
          state.pathParameters['szenarioId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/pruefungssimulation',
      builder: (context, state) => const PruefungsAuswahlScreen(),
    ),
  ],
);

/// Wird gezeigt, wenn /quiz ohne Modus geöffnet wurde - statt abzustürzen.
class _ModusFehlt extends StatelessWidget {
  const _ModusFehlt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.help_outline, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Diese Seite lässt sich nur aus der App heraus öffnen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Zum Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
