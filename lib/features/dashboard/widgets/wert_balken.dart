import 'package:flutter/material.dart';

/// Ein waagerechter Balken mit seiner Beschriftung darueber.
///
/// Loest ein Problem, das senkrechte Saeulen auf einem Telefon nicht loesen
/// koennen: Die Beschriftungen standen unter einer gemeinsamen Achse und
/// ueberlappten sich, sobald ein Name laenger war als sein Saeulenabstand -
/// "Technische Berechnungen" und "Zerspanung Grundlagen" nebeneinander
/// ergaben Buchstabensalat. Hier gehoert jede Beschriftung zu genau einem
/// Balken, liegt ueber ihm und hat die volle Breite. Ueberschneiden koennen
/// sie sich nicht mehr.
class WertBalken extends StatelessWidget {
  final String beschriftung;

  /// Fuellstand des Balkens, 0..1.
  final double anteil;

  /// Was rechts neben der Beschriftung steht, meist der Prozentwert.
  final String wert;

  final Color farbe;

  /// Optionale zweite Zeile, etwa die Zahl der Versuche - eine Quote ohne
  /// ihre Grundgesamtheit ist leicht misszuverstehen.
  final String? zusatz;

  const WertBalken({
    super.key,
    required this.beschriftung,
    required this.anteil,
    required this.wert,
    required this.farbe,
    this.zusatz,
  });

  @override
  Widget build(BuildContext context) {
    final textThema = Theme.of(context).textTheme;
    final farben = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  beschriftung,
                  style: textThema.bodyMedium,
                  // Zwei Zeilen statt eines abgeschnittenen Namens: Lieber
                  // umbrechen als "Technische Berechn…".
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                wert,
                style: textThema.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (zusatz != null)
            Text(
              zusatz!,
              style: textThema.bodySmall?.copyWith(color: farben.outline),
            ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: anteil.clamp(0.0, 1.0),
              minHeight: 8,
              color: farbe,
              backgroundColor: farben.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prozentwert als Text, wie ihn alle Balken auf dem Dashboard zeigen.
String prozent(double anteil) => '${(anteil * 100).round()} %';
