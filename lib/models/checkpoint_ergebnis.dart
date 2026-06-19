// Das Ergebnis eines abgeschlossenen Checkpoint-Versuchs, wird als Verlauf
// unter dem shared_preferences-Key "checkpointErgebnisse" gespeichert.
class CheckpointErgebnis {
  static const double bestehensSchwelle = 0.7;

  final String modulId;
  final int richtigeAntworten;
  final int gesamtFragen;
  final DateTime abgeschlossenAm;

  const CheckpointErgebnis({
    required this.modulId,
    required this.richtigeAntworten,
    required this.gesamtFragen,
    required this.abgeschlossenAm,
  });

  bool get bestanden =>
      gesamtFragen > 0 && richtigeAntworten / gesamtFragen >= bestehensSchwelle;

  factory CheckpointErgebnis.fromJson(Map<String, dynamic> json) {
    return CheckpointErgebnis(
      modulId: json['modulId'] as String,
      richtigeAntworten: json['richtigeAntworten'] as int,
      gesamtFragen: json['gesamtFragen'] as int,
      abgeschlossenAm: DateTime.parse(json['abgeschlossenAm'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modulId': modulId,
      'richtigeAntworten': richtigeAntworten,
      'gesamtFragen': gesamtFragen,
      'abgeschlossenAm': abgeschlossenAm.toIso8601String(),
    };
  }
}
