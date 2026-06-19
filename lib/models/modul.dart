import 'karteikarte.dart';
import 'checkpoint_frage.dart';

// Ein Lernmodul innerhalb eines Themenbereichs: eine Gruppe von Karteikarten
// plus ein optionaler Checkpoint-Test. hatInhalt = false markiert Module,
// die noch keine echten Lerninhalte haben ("Inhalte folgen").
class Modul {
  final String id;
  final String titel;
  final String themenbereichId;
  final List<Karteikarte> karteikarten;
  final List<CheckpointFrage> checkpointFragen;
  final bool hatInhalt;

  const Modul({
    required this.id,
    required this.titel,
    required this.themenbereichId,
    required this.karteikarten,
    required this.checkpointFragen,
    required this.hatInhalt,
  });

  factory Modul.fromJson(
    Map<String, dynamic> json, {
    required String themenbereichId,
    required String themenbereichTitel,
  }) {
    final modulId = json['id'] as String;
    return Modul(
      id: modulId,
      titel: json['titel'] as String,
      themenbereichId: themenbereichId,
      hatInhalt: json['hatInhalt'] as bool,
      karteikarten: (json['karteikarten'] as List)
          .map(
            (karte) => Karteikarte.fromJson(
              karte as Map<String, dynamic>,
              themenbereich: themenbereichTitel,
              modulId: modulId,
            ),
          )
          .toList(),
      checkpointFragen: (json['checkpointFragen'] as List)
          .map(
            (frage) => CheckpointFrage.fromJson(frage as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
