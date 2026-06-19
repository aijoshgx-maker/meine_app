import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/checkpoint_ergebnis.dart';
import '../models/checkpoint_frage.dart';
import '../models/modul.dart';
import '../state/lernplan_state.dart';

// Checkpoint-Quiz am Ende eines Moduls: Multiple-Choice-Fragen einzeln,
// am Ende Auswertung mit Bestanden/Nicht bestanden (70%-Schwelle).
class CheckpointScreen extends StatefulWidget {
  final Modul modul;

  const CheckpointScreen({super.key, required this.modul});

  @override
  State<CheckpointScreen> createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends State<CheckpointScreen> {
  int _aktuelleFrage = 0;
  int _richtigeAntworten = 0;
  int? _ausgewaehlteOption;
  bool _antwortAusgewertet = false;
  bool _abgeschlossen = false;

  void _optionAuswaehlen(int index) {
    if (_antwortAusgewertet) return;

    final frage = widget.modul.checkpointFragen[_aktuelleFrage];
    final richtig = index == frage.richtigeAntwortIndex;

    setState(() {
      _ausgewaehlteOption = index;
      _antwortAusgewertet = true;
      if (richtig) _richtigeAntworten++;
    });
  }

  Future<void> _naechsteFrage() async {
    final letzteFrage =
        _aktuelleFrage == widget.modul.checkpointFragen.length - 1;

    if (letzteFrage) {
      final ergebnis = CheckpointErgebnis(
        modulId: widget.modul.id,
        richtigeAntworten: _richtigeAntworten,
        gesamtFragen: widget.modul.checkpointFragen.length,
        abgeschlossenAm: DateTime.now(),
      );
      await context.read<LernplanState>().checkpointAbschliessen(ergebnis);
      setState(() => _abgeschlossen = true);
      return;
    }

    setState(() {
      _aktuelleFrage++;
      _ausgewaehlteOption = null;
      _antwortAusgewertet = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_abgeschlossen) {
      final bestanden = _richtigeAntworten / widget.modul.checkpointFragen.length >=
          CheckpointErgebnis.bestehensSchwelle;
      return Scaffold(
        appBar: AppBar(title: Text('${widget.modul.titel} – Checkpoint')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  bestanden ? Icons.check_circle : Icons.refresh,
                  color: bestanden ? Colors.green : Colors.orange,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  '$_richtigeAntworten von ${widget.modul.checkpointFragen.length} richtig',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(bestanden ? 'Bestanden!' : 'Noch nicht bestanden – weiter üben.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zurück zum Modul'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final frage = widget.modul.checkpointFragen[_aktuelleFrage];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Frage ${_aktuelleFrage + 1} von ${widget.modul.checkpointFragen.length}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(frage.frageText, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            for (var i = 0; i < frage.antwortOptionen.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _optionButton(frage, i),
              ),
            if (_antwortAusgewertet && frage.erklaerung != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  frage.erklaerung!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const Spacer(),
            if (_antwortAusgewertet)
              ElevatedButton(
                onPressed: _naechsteFrage,
                child: Text(
                  _aktuelleFrage == widget.modul.checkpointFragen.length - 1
                      ? 'Ergebnis anzeigen'
                      : 'Nächste Frage',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _optionButton(CheckpointFrage frage, int index) {
    Color? farbe;
    if (_antwortAusgewertet) {
      if (index == frage.richtigeAntwortIndex) {
        farbe = Colors.green;
      } else if (index == _ausgewaehlteOption) {
        farbe = Colors.red;
      }
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: farbe,
        foregroundColor: farbe != null ? Colors.white : null,
        alignment: Alignment.centerLeft,
      ),
      onPressed: () => _optionAuswaehlen(index),
      child: Text(frage.antwortOptionen[index]),
    );
  }
}
