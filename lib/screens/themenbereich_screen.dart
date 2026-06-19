import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/themenbereich.dart';
import '../state/lernplan_state.dart';
import '../widgets/fortschrittsbalken.dart';
import 'modul_screen.dart';

// Zeigt die Module eines Themenbereichs mit Fortschritt. Module ohne
// Inhalt ("Inhalte folgen") werden ausgegraut dargestellt.
class ThemenbereichScreen extends StatelessWidget {
  final Themenbereich themenbereich;

  const ThemenbereichScreen({super.key, required this.themenbereich});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LernplanState>();

    return Scaffold(
      appBar: AppBar(title: Text(themenbereich.titel)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final modul in themenbereich.module)
            Card(
              child: ListTile(
                enabled: modul.hatInhalt,
                title: Text(modul.titel),
                subtitle: modul.hatInhalt
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Fortschrittsbalken(
                          anteil: modul.karteikarten.isEmpty
                              ? 0
                              : modul.karteikarten
                                      .where((k) => k.zuletztGelernt != null)
                                      .length /
                                  modul.karteikarten.length,
                        ),
                      )
                    : const Text('Inhalte folgen'),
                trailing: modul.hatInhalt
                    ? Text('${state.faelligeKartenInModul(modul).length} fällig')
                    : null,
                onTap: modul.hatInhalt
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ModulScreen(modul: modul),
                          ),
                        )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
