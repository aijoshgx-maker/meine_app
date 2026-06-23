import 'package:hive/hive.dart';

// Kleine Box für App-weite Einstellungen (Theme-Modus, Erinnerungen an/aus).
class SettingsStore {
  static const boxName = 'app_settings';
  static const themeModeKey = 'themeMode';
  static const remindersEnabledKey = 'remindersEnabled';

  Box get _box => Hive.box(boxName);

  String? themeModeLaden() => _box.get(themeModeKey) as String?;

  Future<void> themeModeSpeichern(String wert) async {
    await _box.put(themeModeKey, wert);
  }

  bool remindersAktiviert() =>
      _box.get(remindersEnabledKey, defaultValue: false) as bool;

  Future<void> remindersAktiviertSpeichern(bool aktiviert) async {
    await _box.put(remindersEnabledKey, aktiviert);
  }
}
