import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/karteikarte.dart';
import '../models/modul.dart';
import '../services/spaced_repetition_service.dart';
import '../state/lernplan_state.dart';
import '../widgets/bewertungs_buttons.dart';

// Lern-Session für ein Modul: zeigt die fälligen Karten nacheinander.
// Tippen dreht die Karte um, danach erscheinen die Bewertungs-Buttons,
// die den nächsten Fälligkeitszeitpunkt über das LernplanState steuern.
class KartenlernenScreen extends StatefulWidget {
  final Modul modul;

  const KartenlernenScreen({super.key, required this.modul});

  @override
  State<KartenlernenScreen> createState() => _KartenlernenScreenState();
}

class _KartenlernenScreenState extends State<KartenlernenScreen> {
  late List<Karteikarte> _faelligeKarten;
  bool _antwortSichtbar = false;

  @override
  void initState() {
    super.initState();
    _faelligeKarten = context
        .read<LernplanState>()
        .faelligeKartenInModul(widget.modul);
  }

  void _karteUmdrehen() {
    setState(() => _antwortSichtbar = !_antwortSichtbar);
  }

  Future<void> _bewerten(Bewertung bewertung) async {
    final karte = _faelligeKarten.first;
    await context.read<LernplanState>().karteBewerten(karte, bewertung);
    setState(() {
      _faelligeKarten.removeAt(0);
      _antwortSichtbar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.modul.titel)),
      body: _faelligeKarten.isEmpty
          ? const Center(child: Text('Fertig für heute! Alle Karten gelernt.'))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${_faelligeKarten.length} Karten übrig',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _karteUmdrehen,
                      child: Card(
                        elevation: 4,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _antwortSichtbar
                                  ? _faelligeKarten.first.antwort
                                  : _faelligeKarten.first.frage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _antwortSichtbar
                        ? 'Wie gut wusstest du die Antwort?'
                        : 'Tippe auf die Karte, um die Antwort zu sehen',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  if (_antwortSichtbar) BewertungsButtons(onBewertet: _bewerten),
                ],
              ),
            ),
    );
  }
}
