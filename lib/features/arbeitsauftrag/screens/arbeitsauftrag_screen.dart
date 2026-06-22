import 'package:flutter/material.dart';

import '../widgets/checkliste_tab.dart';
import '../widgets/dokumentation_tab.dart';
import '../widgets/fachgespraech_tab.dart';

// Praktischer Teil der Prüfungsvorbereitung (50% Gewichtung, kein Quiz):
// Checkliste, Dokumentationsvorlage und Fachgespräch-Trainer als Tabs einer
// zusammengehörigen Funktion.
class ArbeitsauftragScreen extends StatelessWidget {
  const ArbeitsauftragScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Arbeitsauftrag'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Checkliste'),
              Tab(text: 'Dokumentation'),
              Tab(text: 'Fachgespräch'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [ChecklisteTab(), DokumentationTab(), FachgespraechTab()],
        ),
      ),
    );
  }
}
