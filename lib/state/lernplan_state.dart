import 'package:flutter/foundation.dart';

import '../data/fortschritt_repository.dart';
import '../data/lernplan_loader.dart';
import '../models/checkpoint_ergebnis.dart';
import '../models/karten_stand.dart';
import '../models/karteikarte.dart';
import '../models/lernplan.dart';
import '../models/modul.dart';
import '../models/themenbereich.dart';
import '../services/spaced_repetition_service.dart';

// Einzige Quelle der Wahrheit für die UI: lädt Lernplan + gespeicherten
// Fortschritt beim Start, hält beides im Speicher und schreibt Änderungen
// (Kartenbewertung, Checkpoint-Ergebnis) sofort zurück in die Persistenz.
class LernplanState extends ChangeNotifier {
  final LernplanLoader _loader;
  final FortschrittRepository _repository;
  final SpacedRepetitionService _srsService;

  Lernplan? lernplan;
  bool ladeLaeuft = true;
  List<CheckpointErgebnis> checkpointErgebnisse = [];

  LernplanState({
    LernplanLoader? loader,
    FortschrittRepository? repository,
    SpacedRepetitionService? srsService,
  }) : _loader = loader ?? LernplanLoader(),
       _repository = repository ?? FortschrittRepository(),
       _srsService = srsService ?? SpacedRepetitionService();

  Future<void> initialisieren() async {
    final geladenerLernplan = await _loader.laden();
    final kartenStand = await _repository.kartenStandLaden();

    for (final themenbereich in geladenerLernplan.themenbereiche) {
      for (final modul in themenbereich.module) {
        for (final karte in modul.karteikarten) {
          final gespeicherterStand = kartenStand[karte.id];
          if (gespeicherterStand != null) {
            karte.easeFactor = gespeicherterStand.easeFactor;
            karte.intervallTage = gespeicherterStand.intervallTage;
            karte.wiederholungen = gespeicherterStand.wiederholungen;
            karte.faelligAm = gespeicherterStand.faelligAm;
            karte.zuletztGelernt = gespeicherterStand.zuletztGelernt;
          }
        }
      }
    }

    lernplan = geladenerLernplan;
    checkpointErgebnisse = await _repository.checkpointErgebnisseLaden();
    ladeLaeuft = false;
    notifyListeners();
  }

  List<Karteikarte> _alleKarten() => [
    for (final themenbereich in lernplan?.themenbereiche ?? <Themenbereich>[])
      for (final modul in themenbereich.module) ...modul.karteikarten,
  ];

  int faelligeKartenGesamt() =>
      _alleKarten().where(_srsService.istFaellig).length;

  int faelligeKartenFuer(String themenbereichId) {
    final themenbereich = lernplan?.themenbereiche.firstWhere(
      (tb) => tb.id == themenbereichId,
    );
    if (themenbereich == null) return 0;
    return [
      for (final modul in themenbereich.module) ...modul.karteikarten,
    ].where(_srsService.istFaellig).length;
  }

  List<Karteikarte> faelligeKartenInModul(Modul modul) =>
      modul.karteikarten.where(_srsService.istFaellig).toList();

  // Anteil der Karten in diesem Themenbereich, die schon mindestens einmal
  // gelernt wurden (0.0 bis 1.0). Dient als einfacher Fortschrittsindikator.
  double fortschrittFuer(String themenbereichId) {
    final themenbereich = lernplan?.themenbereiche.firstWhere(
      (tb) => tb.id == themenbereichId,
    );
    if (themenbereich == null) return 0;

    final karten = [
      for (final modul in themenbereich.module) ...modul.karteikarten,
    ];
    if (karten.isEmpty) return 0;

    final gelernteKarten = karten.where((k) => k.zuletztGelernt != null).length;
    return gelernteKarten / karten.length;
  }

  CheckpointErgebnis? letztesErgebnisFuer(String modulId) {
    final ergebnisseFuerModul = checkpointErgebnisse.where(
      (e) => e.modulId == modulId,
    );
    if (ergebnisseFuerModul.isEmpty) return null;
    return ergebnisseFuerModul.reduce(
      (a, b) => a.abgeschlossenAm.isAfter(b.abgeschlossenAm) ? a : b,
    );
  }

  Future<void> karteBewerten(Karteikarte karte, Bewertung bewertung) async {
    _srsService.bewerten(karte, bewertung);

    final kartenStand = await _repository.kartenStandLaden();
    kartenStand[karte.id] = KartenStand(
      easeFactor: karte.easeFactor,
      intervallTage: karte.intervallTage,
      wiederholungen: karte.wiederholungen,
      faelligAm: karte.faelligAm,
      zuletztGelernt: karte.zuletztGelernt,
    );
    await _repository.kartenStandSpeichern(kartenStand);

    notifyListeners();
  }

  Future<void> checkpointAbschliessen(CheckpointErgebnis ergebnis) async {
    await _repository.checkpointErgebnisHinzufuegen(ergebnis);
    checkpointErgebnisse.add(ergebnis);
    notifyListeners();
  }
}
