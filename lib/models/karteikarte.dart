// Eine einzelne Karteikarte: Frage/Antwort-Inhalt plus der veränderliche
// Spaced-Repetition-Stand (Ease-Faktor, Intervall, Fälligkeitsdatum).
// Der Inhalt (frage/antwort) kommt aus den JSON-Dateien unter assets/content/,
// der SRS-Stand wird beim Start separat aus shared_preferences gemerged.
class Karteikarte {
  final String id;
  final String frage;
  final String antwort;
  final String themenbereich;
  final String modulId;

  double easeFactor;
  int intervallTage;
  int wiederholungen;
  DateTime faelligAm;
  DateTime? zuletztGelernt;

  Karteikarte({
    required this.id,
    required this.frage,
    required this.antwort,
    required this.themenbereich,
    required this.modulId,
    this.easeFactor = 2.5,
    this.intervallTage = 0,
    this.wiederholungen = 0,
    DateTime? faelligAm,
    this.zuletztGelernt,
  }) : faelligAm = faelligAm ?? DateTime.now();

  factory Karteikarte.fromJson(
    Map<String, dynamic> json, {
    required String themenbereich,
    required String modulId,
  }) {
    return Karteikarte(
      id: json['id'] as String,
      frage: json['frage'] as String,
      antwort: json['antwort'] as String,
      themenbereich: themenbereich,
      modulId: modulId,
    );
  }
}
