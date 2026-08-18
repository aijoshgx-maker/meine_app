import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/kurs.dart';
import '../providers/dashboard_providers.dart';

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
                '${(e.gewichtet * 100).round()} %$gewichtsText',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              loading: () => const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => const Text('–'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ergebnis.when(
                data: (e) => bereiche.isEmpty
                    ? const SizedBox.shrink()
                    : BarChart(
                        BarChartData(
                          minY: 0,
                          maxY: 1,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= bereiche.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      bereiche[index].titel,
                                      style: const TextStyle(fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0; i < bereiche.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.proBereich[bereiche[i].id] ?? 0,
                                    color:
                                        bereiche[i].farbeAlsColor ??
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
