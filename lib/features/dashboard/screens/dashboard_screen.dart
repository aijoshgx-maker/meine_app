import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../quiz/providers/quiz_modus.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/behaltensquote_chart.dart';
import '../widgets/kalibrierung_chart.dart';
import '../widgets/pruefungsreife_chart.dart';
import '../widgets/schwache_themen_chart.dart';

// Zentrale Übersicht: Behaltensquote, Prüfungsreife, Kalibrierung, fällige
// Wiederholungen, schwache Themen. Ersetzt den bisherigen Platzhalter
// HomeScreen als Startbildschirm.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faelligeAnzahl = ref.watch(faelligeAnzahlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AP2 Industriemechaniker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                faelligeAnzahl.maybeWhen(
                  data: (anzahl) => anzahl > 0
                      ? 'Heute sind $anzahl Karten fällig'
                      : 'Keine Karten heute fällig – gut gemacht!',
                  orElse: () => 'Fällige Karten werden geladen...',
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      context.go('/quiz', extra: const QuizModus.freiUebung()),
                  child: const Text('Frei üben'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go(
                    '/quiz',
                    extra: const QuizModus.heuteFaellig(),
                  ),
                  child: const Text('Heute fällig'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/pruefungssimulation'),
                  child: const Text('Prüfungssimulation'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const BehaltensquoteChart(),
          const SizedBox(height: 12),
          const PruefungsreifeChart(),
          const SizedBox(height: 12),
          const KalibrierungChart(),
          const SizedBox(height: 12),
          const SchwacheThemenChart(),
        ],
      ),
    );
  }
}
