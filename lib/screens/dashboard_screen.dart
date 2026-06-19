import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/lernplan_state.dart';
import '../widgets/themenbereich_karte.dart';
import 'themenbereich_screen.dart';

// Startbildschirm: Übersicht über alle Themenbereiche mit Gesamt-Banner
// für heute fällige Karten.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LernplanState>();

    if (state.ladeLaeuft || state.lernplan == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final lernplan = state.lernplan!;
    final faelligGesamt = state.faelligeKartenGesamt();

    return Scaffold(
      appBar: AppBar(title: const Text('AP2 Lern-App')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              faelligGesamt > 0
                  ? 'Heute sind $faelligGesamt Karten fällig'
                  : 'Keine Karten heute fällig – gut gemacht!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          for (final themenbereich in lernplan.themenbereiche)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ThemenbereichKarte(
                themenbereich: themenbereich,
                fortschritt: state.fortschrittFuer(themenbereich.id),
                faelligeKarten: state.faelligeKartenFuer(themenbereich.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ThemenbereichScreen(themenbereich: themenbereich),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
