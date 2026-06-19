import 'package:flutter/material.dart';

// Einfacher Fortschrittsbalken mit Prozentzahl daneben, wiederverwendet auf
// Dashboard und Themenbereich-Screen.
class Fortschrittsbalken extends StatelessWidget {
  final double anteil; // 0.0 bis 1.0

  const Fortschrittsbalken({super.key, required this.anteil});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: anteil, minHeight: 8),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(anteil * 100).round()}%'),
      ],
    );
  }
}
