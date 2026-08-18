import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_providers.dart';

// Die bis zu 5 Kategorien mit der höchsten Fehlerquote im Attempt-Log.
class SchwacheThemenChart extends ConsumerWidget {
  const SchwacheThemenChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Die Daten kommen aus Hive und sind praktisch sofort da; solange sie
    // laden, zeigt die leere Liste den "noch keine Daten"-Hinweis.
    final themen = ref.watch(schwacheThemenProvider).value ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schwache Themen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (themen.isEmpty)
              const Text('Noch keine Daten – erst ein paar Fragen beantworten.')
            else
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
                            final index = value.toInt();
                            if (index < 0 || index >= themen.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                themen[index].kategorie,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < themen.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: themen[i].fehlerquote,
                              color: Theme.of(context).colorScheme.error,
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
