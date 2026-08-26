import 'package:hive/hive.dart';

// Kleine Box für App-weite Einstellungen (Theme-Modus, Erinnerungen an/aus,
// aktiver Kurs, erreichte Datenversion).
class SettingsStore {
  static const boxName = 'app_settings';
  static const themeModeKey = 'themeMode';
  static const remindersEnabledKey = 'remindersEnabled';
  static const aktiverKursKey = 'aktiverKurs';
  static const datenVersionKey = 'datenVersion';
  static const letztesAutoBackupKey = 'letztesAutoBackup';
  static const neueProTagKey = 'neueProTag';
  static const steigendeSchwierigkeitKey = 'steigendeSchwierigkeit';

  /// Wie viele bisher ungesehene Karten pro Tag dazukommen.
  ///
  /// Der Wert bestimmt das Lerntempo: 20 am Tag bedeutet, dass ein Kurs mit
  /// 680 Fragen in etwa fünf Wochen einmal vollständig angefangen ist.
  static const neueProTagStandard = 20;
  static const neueProTagMax = 50;

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

  /// Zeitpunkt der letzten automatischen Sicherung. null, wenn noch nie
  /// eine lief.
  DateTime? letztesAutoBackupLaden() {
    final roh = _box.get(letztesAutoBackupKey);
    return roh is String ? DateTime.tryParse(roh) : null;
  }

  Future<void> letztesAutoBackupSpeichern(DateTime zeitpunkt) async {
    await _box.put(letztesAutoBackupKey, zeitpunkt.toIso8601String());
  }

  int neueProTagLaden() {
    final roh = _box.get(neueProTagKey, defaultValue: neueProTagStandard);
    final wert = (roh as num).toInt();
    return wert.clamp(0, neueProTagMax);
  }

  Future<void> neueProTagSpeichern(int anzahl) async {
    await _box.put(neueProTagKey, anzahl.clamp(0, neueProTagMax));
  }

  /// Ob Fragen mit dem Koennen haerter werden sollen.
  ///
  /// Erprobung, deshalb ein eigener Schalter: Ohne ihn liesse sich der
  /// Versuch nur durch einen Eingriff in den Code beenden.
  bool steigendeSchwierigkeitLaden() =>
      _box.get(steigendeSchwierigkeitKey, defaultValue: true) as bool;

  Future<void> steigendeSchwierigkeitSpeichern(bool aktiv) async {
    await _box.put(steigendeSchwierigkeitKey, aktiv);
  }
}
