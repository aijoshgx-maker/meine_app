import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_providers.dart';

const _bereichLabels = {
  'auftragsanalyse': 'Auftragsanalyse',
  'fertigungstechnik': 'Fertigungstechnik',
  'wiso': 'WiSo',
};

// Gewichtete schriftliche Prüfungsreife: Balken je Bereich + eine
// zusammengefasste, gewichtete Gesamtzahl (40/40/20).
class PruefungsreifeChart extends ConsumerWidget {
  const PruefungsreifeChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ergebnis = ref.watch(pruefungsreifeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prüfungsreife (schriftlich)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            ergebnis.when(
              data: (e) => Text(
                '${(e.gewichtet * 100).round()} % (gewichtet 40/40/20)',
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
                data: (e) => BarChart(
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
                            final bereich = _bereichLabels.keys.elementAt(
                              value.toInt().clamp(0, _bereichLabels.length - 1),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _bereichLabels[bereich]!,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < _bereichLabels.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY:
                                  e.proBereich[_bereichLabels.keys.elementAt(
                                    i,
                                  )] ??
                                  0,
                              color: Theme.of(context).colorScheme.primary,
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
