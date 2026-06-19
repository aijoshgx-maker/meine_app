import 'modul.dart';

// Ein Themenbereich der AP2-Prüfung (z. B. Fertigungstechnik), bestehend
// aus mehreren Modulen. Entspricht genau einer JSON-Datei unter assets/content/.
class Themenbereich {
  final String id;
  final String titel;
  final String beschreibung;
  final List<Modul> module;

  const Themenbereich({
    required this.id,
    required this.titel,
    required this.beschreibung,
    required this.module,
  });

  factory Themenbereich.fromJson(Map<String, dynamic> json) {
    final titel = json['titel'] as String;
    final themenbereichId = json['id'] as String;
    return Themenbereich(
      id: themenbereichId,
      titel: titel,
      beschreibung: json['beschreibung'] as String,
      module: (json['module'] as List)
          .map((modul) => Modul.fromJson(
                modul as Map<String, dynamic>,
                themenbereichId: themenbereichId,
                themenbereichTitel: titel,
              ))
          .toList(),
    );
  }
}
