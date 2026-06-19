// Der persistierte Spaced-Repetition-Stand einer Karte, getrennt vom Inhalt.
// Wird unter dem shared_preferences-Key "kartenStand" als Map<id, KartenStand>
// gespeichert und beim Start auf die passende Karteikarte gemerged.
class KartenStand {
  final double easeFactor;
  final int intervallTage;
  final int wiederholungen;
  final DateTime faelligAm;
  final DateTime? zuletztGelernt;

  const KartenStand({
    required this.easeFactor,
    required this.intervallTage,
    required this.wiederholungen,
    required this.faelligAm,
    this.zuletztGelernt,
  });

  factory KartenStand.fromJson(Map<String, dynamic> json) {
    return KartenStand(
      easeFactor: json['easeFactor'] as double,
      intervallTage: json['intervallTage'] as int,
      wiederholungen: json['wiederholungen'] as int,
      faelligAm: DateTime.parse(json['faelligAm'] as String),
      zuletztGelernt: json['zuletztGelernt'] == null
          ? null
          : DateTime.parse(json['zuletztGelernt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'easeFactor': easeFactor,
      'intervallTage': intervallTage,
      'wiederholungen': wiederholungen,
      'faelligAm': faelligAm.toIso8601String(),
      'zuletztGelernt': zuletztGelernt?.toIso8601String(),
    };
  }
}
