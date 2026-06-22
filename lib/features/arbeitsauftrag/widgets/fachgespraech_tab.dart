import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/arbeitsauftrag_inhalte.dart';
import '../providers/arbeitsauftrag_providers.dart';

class FachgespraechTab extends ConsumerWidget {
  const FachgespraechTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final antworten = ref.watch(fachgespraechProvider);
    final controller = ref.read(fachgespraechProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final (fragId, frageText) in fachgespraechFragen)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(frageText, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey(fragId),
                  initialValue: antworten[fragId] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Stichpunkt-Antwort',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (text) => controller.antwortSetzen(fragId, text),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
