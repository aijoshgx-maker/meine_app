import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/konfidenz.dart';
import '../providers/dashboard_providers.dart';
import 'wert_balken.dart';

const _konfidenzLabels = {
  Konfidenz.sicher: 'Sicher',
  Konfidenz.unsicher: 'Unsicher',
  Konfidenz.geraten: 'Geraten',
};

// Konfidenz-Kalibrierung: tatsächliche Trefferquote je Selbsteinschätzung,
// plus Anzahl hochkonfident-falscher Antworten (Hypercorrection-Kandidaten).
class KalibrierungChart extends ConsumerWidget {
  const KalibrierungChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kalibrierung = ref.watch(kalibrierungProvider).value ?? const {};
    final hochkonfidentFalsch =
        ref.watch(hochkonfidentFalschAnzahlProvider).value ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konfidenz-Kalibrierung',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Hochkonfident falsch: $hochkonfidentFalsch'),
            const SizedBox(height: 4),
            Text(
              'Trefferquote je Selbsteinschätzung',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final konfidenz in Konfidenz.values)
              WertBalken(
                beschriftung: _konfidenzLabels[konfidenz]!,
                anteil: kalibrierung[konfidenz] ?? 0,
                wert: prozent(kalibrierung[konfidenz] ?? 0),
                farbe: Theme.of(context).colorScheme.secondary,
              ),
          ],
        ),
      ),
    );
  }
}
