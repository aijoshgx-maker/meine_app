import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/modul.dart';
import '../state/lernplan_state.dart';
import 'checkpoint_screen.dart';
import 'kartenlernen_screen.dart';

// Einstieg in ein Modul: Karten lernen oder Checkpoint starten, plus
// Anzeige des letzten Checkpoint-Ergebnisses.
class ModulScreen extends StatelessWidget {
  final Modul modul;

  const ModulScreen({super.key, required this.modul});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LernplanState>();
    final faelligeKarten = state.faelligeKartenInModul(modul).length;
    final letztesErgebnis = state.letztesErgebnisFuer(modul.id);

    return Scaffold(
      appBar: AppBar(title: Text(modul.titel)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${modul.karteikarten.length} Karten insgesamt, $faelligeKarten heute fällig',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: modul.karteikarten.isEmpty
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KartenlernenScreen(modul: modul),
                      ),
                    ),
              child: const Text('Karten lernen'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: modul.checkpointFragen.isEmpty
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckpointScreen(modul: modul),
                      ),
                    ),
              child: const Text('Checkpoint starten'),
            ),
            if (letztesErgebnis != null) ...[
              const SizedBox(height: 24),
              Text(
                'Letzter Checkpoint: ${letztesErgebnis.richtigeAntworten}/${letztesErgebnis.gesamtFragen} '
                '(${letztesErgebnis.bestanden ? "bestanden" : "nicht bestanden"})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
