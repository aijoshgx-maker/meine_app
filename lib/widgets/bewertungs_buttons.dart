import 'package:flutter/material.dart';

import '../services/spaced_repetition_service.dart';

// Die vier Selbsteinschätzungs-Buttons nach dem Umdrehen einer Karte.
// Ruft onBewertet mit der gewählten Bewertung auf.
class BewertungsButtons extends StatelessWidget {
  final void Function(Bewertung bewertung) onBewertet;

  const BewertungsButtons({super.key, required this.onBewertet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _button('Nochmal', Colors.red, Bewertung.nochmal)),
        const SizedBox(width: 8),
        Expanded(child: _button('Schwer', Colors.orange, Bewertung.schwer)),
        const SizedBox(width: 8),
        Expanded(child: _button('Gut', Colors.lightGreen, Bewertung.gut)),
        const SizedBox(width: 8),
        Expanded(child: _button('Leicht', Colors.green, Bewertung.leicht)),
      ],
    );
  }

  Widget _button(String text, Color farbe, Bewertung bewertung) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: farbe,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => onBewertet(bewertung),
      child: Text(text),
    );
  }
}
