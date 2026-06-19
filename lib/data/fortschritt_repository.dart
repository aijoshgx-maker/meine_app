import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/checkpoint_ergebnis.dart';
import '../models/karten_stand.dart';

// Kapselt das Lesen/Schreiben des gespeicherten Lernfortschritts
// (Spaced-Repetition-Stand pro Karte, Checkpoint-Verlauf) in shared_preferences.
class FortschrittRepository {
  static const _kartenStandKey = 'kartenStand';
  static const _checkpointErgebnisseKey = 'checkpointErgebnisse';

  Future<Map<String, KartenStand>> kartenStandLaden() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_kartenStandKey);
    if (text == null) return {};

    final json = jsonDecode(text) as Map<String, dynamic>;
    return json.map(
      (id, daten) =>
          MapEntry(id, KartenStand.fromJson(daten as Map<String, dynamic>)),
    );
  }

  Future<void> kartenStandSpeichern(Map<String, KartenStand> stand) async {
    final prefs = await SharedPreferences.getInstance();
    final json = stand.map((id, kartenStand) => MapEntry(id, kartenStand.toJson()));
    await prefs.setString(_kartenStandKey, jsonEncode(json));
  }

  Future<List<CheckpointErgebnis>> checkpointErgebnisseLaden() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_checkpointErgebnisseKey);
    if (text == null) return [];

    final liste = jsonDecode(text) as List;
    return liste
        .map((e) => CheckpointErgebnis.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> checkpointErgebnisHinzufuegen(CheckpointErgebnis ergebnis) async {
    final bisherige = await checkpointErgebnisseLaden();
    bisherige.add(ergebnis);

    final prefs = await SharedPreferences.getInstance();
    final json = bisherige.map((e) => e.toJson()).toList();
    await prefs.setString(_checkpointErgebnisseKey, jsonEncode(json));
  }
}
