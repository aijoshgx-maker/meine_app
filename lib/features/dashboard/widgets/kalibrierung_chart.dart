import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/konfidenz.dart';
import '../providers/dashboard_providers.dart';

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
    final kalibrierung = ref.watch(kalibrierungProvider);
    final hochkonfidentFalsch = ref.watch(hochkonfidentFalschAnzahlProvider);

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
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: BarChart(
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
                          final konfidenz = Konfidenz.values.elementAt(
                            value.toInt().clamp(0, Konfidenz.values.length - 1),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _konfidenzLabels[konfidenz]!,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < Konfidenz.values.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: kalibrierung[Konfidenz.values[i]] ?? 0,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
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
