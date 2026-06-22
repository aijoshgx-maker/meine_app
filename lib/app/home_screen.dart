import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/quiz/providers/quiz_providers.dart';

// Vorläufiger Startbildschirm. Wird in einer späteren Runde durch das
// Dashboard (Phase 6, gewichteter Score/Kalibrierung) ersetzt.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faelligeAnzahl = ref.watch(faelligeAnzahlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AP2 Industriemechaniker')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () =>
                  context.go('/quiz', extra: const QuizModus.freiUebung()),
              child: const Text('Frei üben'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  context.go('/quiz', extra: const QuizModus.heuteFaellig()),
              child: Text(
                'Heute fällig${faelligeAnzahl.maybeWhen(data: (anzahl) => anzahl > 0 ? ' ($anzahl)' : '', orElse: () => '')}',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/pruefungssimulation'),
              child: const Text('Prüfungssimulation'),
            ),
          ],
        ),
      ),
    );
  }
}
