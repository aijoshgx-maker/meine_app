import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/arbeitsauftrag_inhalte.dart';
import '../providers/arbeitsauftrag_providers.dart';

const _phasenLabels = {
  ArbeitsauftragPhase.information: 'Informationsphase',
  ArbeitsauftragPhase.planung: 'Planungsphase',
  ArbeitsauftragPhase.durchfuehrung: 'Durchführungsphase',
  ArbeitsauftragPhase.kontrolle: 'Kontrollphase',
};

class ChecklisteTab extends ConsumerWidget {
  const ChecklisteTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(checklistProvider);
    final controller = ref.read(checklistProvider.notifier);
    final fortschritt = ref.watch(checklistFortschrittProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fortschritt,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${(fortschritt * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 16),
        for (final phase in ArbeitsauftragPhase.values) ...[
          Text(
            _phasenLabels[phase]!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final eintrag in checklistenEintraege.where(
            (e) => e.phase == phase,
          ))
            CheckboxListTile(
              title: Text(eintrag.text),
              value: status[eintrag.id] ?? false,
              onChanged: (_) => controller.umschalten(eintrag.id),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
