import 'package:flutter/material.dart';

import '../../../core/spaced_repetition/fsrs_scheduler.dart';

// Die vier FSRS-Selbsteinschätzungs-Buttons nach dem Aufdecken der Antwort.
class BewertungsButtons extends StatelessWidget {
  final void Function(Rating rating) onBewertet;

  const BewertungsButtons({super.key, required this.onBewertet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _button('Nochmal', Colors.red, Rating.again)),
        const SizedBox(width: 8),
        Expanded(child: _button('Schwer', Colors.orange, Rating.hard)),
        const SizedBox(width: 8),
        Expanded(child: _button('Gut', Colors.lightGreen, Rating.good)),
        const SizedBox(width: 8),
        Expanded(child: _button('Leicht', Colors.green, Rating.easy)),
      ],
    );
  }

  Widget _button(String text, Color farbe, Rating rating) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: farbe,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => onBewertet(rating),
      child: Text(text),
    );
  }
}
