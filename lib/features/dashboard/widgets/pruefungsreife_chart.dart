import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/kurs.dart';
import '../providers/dashboard_providers.dart';
import 'wert_balken.dart';

// Gewichteter Lernstand: ein Balken je Bereich plus eine zusammengefasste,
// gewichtete Gesamtzahl.
//
// Bereiche, Beschriftungen, Farben und Gewichte kommen aus dem aktiven Kurs -
// vorher standen hier die drei AP2-Bereiche mit 40/40/20 fest im Code.
class PruefungsreifeChart extends ConsumerWidget {
  const PruefungsreifeChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ergebnis = ref.watch(pruefungsreifeProvider);
    final kurs = ref.watch(aktiverKursProvider).value;

    final bereiche = kurs?.bereiche ?? const <Bereich>[];
    final gewichte = kurs?.normalisierteGewichte ?? const <String, double>{};

    // Die Gewichtung nur ausweisen, wenn sie nicht ohnehin gleichverteilt ist
    // - "gewichtet 33/33/33" wäre reines Rauschen.
    final ungleichGewichtet =
        gewichte.values.toSet().length > 1 && bereiche.isNotEmpty;
    final gewichtsText = ungleichGewichtet
        ? ' (gewichtet ${bereiche.map((b) => ((gewichte[b.id] ?? 0) * 100).round()).join('/')})'
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kurs?.begriffe.lernstand ?? 'Lernstand',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            ergebnis.when(
              data: (e) => Text(
                '${prozent(e.gewichtet)}$gewichtsText',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              loading: () => const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => const Text('–'),
            ),
            const SizedBox(height: 4),
            // Der Horizont gehört sichtbar dazu: Ohne ihn liest sich die Zahl
            // als "so viel kann ich gerade" und wirkt bei jedem Blick anders,
            // obwohl sie das gar nicht mehr tut.
            Text(
              'Geschätzt: So viel sitzt auch in '
              '$pruefungsreifeHorizontTage Tagen noch',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ergebnis.when(
              data: (e) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final bereich in bereiche)
                    WertBalken(
                      beschriftung: bereich.titel,
                      anteil: e.proBereich[bereich.id] ?? 0,
                      wert: prozent(e.proBereich[bereich.id] ?? 0),
                      farbe:
                          bereich.farbeAlsColor ??
                          Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
