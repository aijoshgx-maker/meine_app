import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/fachgespraech_provider.dart';

class FachgespraechAuswahlScreen extends ConsumerWidget {
  const FachgespraechAuswahlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final szenarien = ref.watch(fachgespraechSzenarienProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fachgespräch Simulation'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: szenarien.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final s = list[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    context.go('/fachgespraech/${Uri.encodeComponent(s.id)}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.titel,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Chip(
                            label: Text('${s.fragen.length} Fragen'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.kontext,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: s.kategorien
                            .map(
                              (k) => Chip(
                                label: Text(k),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }
}
