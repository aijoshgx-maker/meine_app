import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_providers.dart';

// Aktuelle Behaltensquote (Stat-Kachel) + 30-Tage-Trend der täglichen
// Trefferquote aus dem Attempt-Log (Annäherung, siehe Provider-Kommentar).
class BehaltensquoteChart extends ConsumerWidget {
  const BehaltensquoteChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final behaltensquote = ref.watch(behaltensquoteProvider);
    final verlauf = ref.watch(behaltensquoteVerlaufProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Behaltensquote',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            behaltensquote.when(
              data: (quote) => Text(
                '${(quote * 100).round()} %',
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
            const Text('30-Tage-Trend (tägliche Trefferquote)'),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 1,
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      color: Theme.of(context).colorScheme.primary,
                      spots: [
                        for (var i = 0; i < verlauf.length; i++)
                          FlSpot(i.toDouble(), verlauf[i].quote),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
