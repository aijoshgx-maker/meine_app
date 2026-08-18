import 'package:hive/hive.dart';

// Kleine Box für App-weite Einstellungen (Theme-Modus, Erinnerungen an/aus,
// aktiver Kurs, erreichte Datenversion).
class SettingsStore {
  static const boxName = 'app_settings';
  static const themeModeKey = 'themeMode';
  static const remindersEnabledKey = 'remindersEnabled';
  static const aktiverKursKey = 'aktiverKurs';
  static const datenVersionKey = 'datenVersion';

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

  /// Id des zuletzt gewählten Kurses. null, wenn noch nie einer gewählt
  /// wurde - dann greift der Standardkurs.
  String? aktiverKursLaden() => _box.get(aktiverKursKey) as String?;

  Future<void> aktiverKursSpeichern(String kursId) async {
    await _box.put(aktiverKursKey, kursId);
  }

  /// Erreichte Datenversion (siehe Migrationen). 0 = Stand vor der ersten
  /// Migration.
  int datenVersionLaden() =>
      (_box.get(datenVersionKey, defaultValue: 0) as num).toInt();

  Future<void> datenVersionSpeichern(int version) async {
    await _box.put(datenVersionKey, version);
  }
}
