import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/arbeitsauftrag_inhalte.dart';
import '../providers/arbeitsauftrag_providers.dart';

class DokumentationTab extends ConsumerWidget {
  const DokumentationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final felder = ref.watch(dokumentationProvider);
    final controller = ref.read(dokumentationProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final (feldId, label) in dokumentationsFelder)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              key: ValueKey(feldId),
              initialValue: felder[feldId] ?? '',
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (text) => controller.feldSetzen(feldId, text),
            ),
          ),
      ],
    );
  }
}
