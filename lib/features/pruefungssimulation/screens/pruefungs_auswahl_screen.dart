import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../quiz/providers/quiz_modus.dart';

// Auswahl, welcher Prüfungsteil simuliert werden soll. Jeder Teilbereich
// bekommt seine echte Prüfungsdauer und zieht nur Fragen aus diesem Bereich
// (entspricht der realen Prüfungsstruktur: drei getrennte Prüfungstermine).
class PruefungsAuswahlScreen extends StatelessWidget {
  const PruefungsAuswahlScreen({super.key});

  static const _teilbereiche = [
    (
      bereich: 'auftragsanalyse',
      titel: 'Auftrags- und Funktionsanalyse',
      gewicht: '20 % der Prüfung',
      dauer: Duration(minutes: 120),
    ),
    (
      bereich: 'fertigungstechnik',
      titel: 'Fertigungstechnik',
      gewicht: '20 % der Prüfung',
      dauer: Duration(minutes: 120),
    ),
    (
      bereich: 'wiso',
      titel: 'Wirtschafts- und Sozialkunde',
      gewicht: '10 % der Prüfung',
      dauer: Duration(minutes: 60),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prüfungssimulation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final teil in _teilbereiche)
            Card(
              child: ListTile(
                title: Text(teil.titel),
                subtitle: Text(
                  '${teil.gewicht} · ${teil.dauer.inMinutes} Minuten',
                ),
                trailing: const Icon(Icons.play_arrow),
                onTap: () => context.go(
                  '/quiz',
                  extra: QuizModus.pruefungssimulation(
                    bereich: teil.bereich,
                    zeitlimit: teil.dauer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
