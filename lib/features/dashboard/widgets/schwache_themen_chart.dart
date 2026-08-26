import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_providers.dart';
import 'wert_balken.dart';

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
            const SizedBox(height: 4),
            Text(
              'Anteil falscher Antworten',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (themen.isEmpty)
              const Text('Noch keine Daten – erst ein paar Fragen beantworten.')
            else
              for (final thema in themen)
                WertBalken(
                  beschriftung: thema.kategorie,
                  anteil: thema.fehlerquote,
                  wert: prozent(thema.fehlerquote),
                  farbe: Theme.of(context).colorScheme.error,
                  // Eine Fehlerquote ohne ihre Grundgesamtheit taeuscht:
                  // 100 % aus einem einzigen Versuch ist kein schwaches
                  // Thema, sondern ein Zufall.
                  zusatz: thema.anzahlVersuche == 1
                      ? '1 Versuch'
                      : '${thema.anzahlVersuche} Versuche',
                ),
          ],
        ),
      ),
    );
  }
}
