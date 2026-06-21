import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/quiz_providers.dart';

// Konfidenz-Abfrage vor dem Aufdecken (Metakognition & Kalibrierung).
class KonfidenzAuswahl extends ConsumerWidget {
  final Konfidenz? ausgewaehlt;

  const KonfidenzAuswahl({super.key, required this.ausgewaehlt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quizSessionProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Wie sicher bist du dir?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final konfidenz in Konfidenz.values)
              ChoiceChip(
                label: Text(_label(konfidenz)),
                selected: ausgewaehlt == konfidenz,
                onSelected: (_) => controller.konfidenzSetzen(konfidenz),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: ausgewaehlt == null ? null : controller.aufdecken,
          child: const Text('Aufdecken'),
        ),
      ],
    );
  }

  String _label(Konfidenz k) => switch (k) {
    Konfidenz.sicher => 'Sicher',
    Konfidenz.unsicher => 'Unsicher',
    Konfidenz.geraten => 'Geraten',
  };
}
