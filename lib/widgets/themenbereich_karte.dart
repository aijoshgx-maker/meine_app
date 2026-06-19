import 'package:flutter/material.dart';

import '../models/themenbereich.dart';
import 'fortschrittsbalken.dart';

// Eine Karte auf dem Dashboard für einen Themenbereich: Titel, Beschreibung,
// Fortschrittsbalken und Anzahl heute fälliger Karten.
class ThemenbereichKarte extends StatelessWidget {
  final Themenbereich themenbereich;
  final double fortschritt;
  final int faelligeKarten;
  final VoidCallback onTap;

  const ThemenbereichKarte({
    super.key,
    required this.themenbereich,
    required this.fortschritt,
    required this.faelligeKarten,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      themenbereich.titel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (faelligeKarten > 0)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$faelligeKarten fällig',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                themenbereich.beschreibung,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Fortschrittsbalken(anteil: fortschritt),
            ],
          ),
        ),
      ),
    );
  }
}
