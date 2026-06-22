import 'package:hive/hive.dart';

// Kapselt die drei Hive-Boxen des Arbeitsauftrag-Features: Checkliste
// (itemId -> bool), Dokumentation (ein fester Eintrag, überschrieben statt
// Verlauf) und Fachgespräch-Antworten (fragId -> Freitext).
class ArbeitsauftragStore {
  static const checklistBoxName = 'arbeitsauftrag_checklist';
  static const dokumentationBoxName = 'arbeitsauftrag_dokumentation';
  static const fachgespraechBoxName = 'fachgespraech_antworten';

  static const _dokumentationKey = 'aktuell';

  Box get _checklistBox => Hive.box(checklistBoxName);
  Box get _dokumentationBox => Hive.box(dokumentationBoxName);
  Box get _fachgespraechBox => Hive.box(fachgespraechBoxName);

  Map<String, bool> checklistStatus() {
    return {
      for (final key in _checklistBox.keys)
        key as String: _checklistBox.get(key) as bool,
    };
  }

  Future<void> checklistSetzen(String itemId, bool erledigt) async {
    await _checklistBox.put(itemId, erledigt);
  }

  Map<String, String> dokumentationLaden() {
    final roh = _dokumentationBox.get(_dokumentationKey);
    if (roh == null) return {};
    return Map<String, String>.from(roh as Map);
  }

  Future<void> dokumentationSpeichern(Map<String, String> felder) async {
    await _dokumentationBox.put(_dokumentationKey, felder);
  }

  Map<String, String> fachgespraechAntworten() {
    return {
      for (final key in _fachgespraechBox.keys)
        key as String: _fachgespraechBox.get(key) as String,
    };
  }

  Future<void> fachgespraechAntwortSetzen(String fragId, String text) async {
    await _fachgespraechBox.put(fragId, text);
  }
}
