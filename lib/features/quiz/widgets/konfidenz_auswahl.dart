import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/quiz_providers.dart';

// Konfidenz-Abfrage: 3 Buttons, die Konfidenz setzen UND sofort aufdecken
// (ein einziger Tap statt Chip + separatem Aufdecken-Button).
class KonfidenzAuswahl extends ConsumerWidget {
  final QuizModus modus;

  const KonfidenzAuswahl({super.key, required this.modus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quizSessionProvider(modus).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Wie sicher warst du?',
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KonfidenzButton(
                label: 'Sicher',
                icon: Icons.check_circle_outline,
                farbe: Colors.green.shade600,
                onTap: () => controller.konfidenzUndAufdecken(Konfidenz.sicher),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _KonfidenzButton(
                label: 'Unsicher',
                icon: Icons.help_outline,
                farbe: Colors.orange.shade600,
                onTap: () =>
                    controller.konfidenzUndAufdecken(Konfidenz.unsicher),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _KonfidenzButton(
                label: 'Geraten',
                icon: Icons.casino_outlined,
                farbe: Colors.red.shade400,
                onTap: () =>
                    controller.konfidenzUndAufdecken(Konfidenz.geraten),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KonfidenzButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color farbe;
  final VoidCallback onTap;

  const _KonfidenzButton({
    required this.label,
    required this.icon,
    required this.farbe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: farbe,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
