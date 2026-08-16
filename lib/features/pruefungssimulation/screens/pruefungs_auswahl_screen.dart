import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../quiz/providers/quiz_providers.dart';
import '../../quiz/providers/session_timer_provider.dart';
import '../data/pruefungs_metadaten.dart';

class PruefungsAuswahlScreen extends ConsumerWidget {
  const PruefungsAuswahlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prüfungssimulation'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Schriftliche Theorieprüfung simulieren',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Wähle eine Prüfung. Der Timer läuft mit dem realen Zeitlimit. '
            'Über den Zeichnungs-Button (unten rechts) kannst du alle '
            'Prüfungszeichnungen einsehen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          for (final info in PruefungsMetadaten.alle)
            _PruefungsKarte(
              info: info,
              onStart: () => _starteSimulation(context, ref, info),
            ),
        ],
      ),
    );
  }

  void _starteSimulation(
      BuildContext context, WidgetRef ref, PruefungsInfo info) {
    final modus = QuizModus.pruefungssimulation(
      pruefungsId: info.id,
      zeitlimitMinuten: info.zeitlimitMinuten,
    );
    // Alten Stand verwerfen → nächster Start beginnt immer von vorne.
    ref.invalidate(quizSessionProvider(modus));
    ref.invalidate(sessionTimerProvider(modus));
    context.go('/quiz', extra: modus);
  }
}

class _PruefungsKarte extends StatelessWidget {
  final PruefungsInfo info;
  final VoidCallback onStart;

  const _PruefungsKarte({required this.info, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    info.bezeichnung,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _ZeitChip(minuten: info.zeitlimitMinuten),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              info.beschreibung,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Wrap(
                  spacing: 4,
                  children: [
                    for (final key in info.diagrammKeys.take(3))
                      Chip(
                        label: Text(key.replaceAll('_', ' ')),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        labelStyle: Theme.of(context).textTheme.labelSmall,
                      ),
                    if (info.diagrammKeys.length > 3)
                      Chip(
                        label: Text('+${info.diagrammKeys.length - 3}'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        labelStyle: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Starten'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZeitChip extends StatelessWidget {
  final int minuten;
  const _ZeitChip({required this.minuten});

  @override
  Widget build(BuildContext context) {
    final stunden = minuten ~/ 60;
    final rest = minuten % 60;
    final text = stunden > 0
        ? '${stunden}h${rest > 0 ? ' ${rest}min' : ''}'
        : '${minuten}min';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
