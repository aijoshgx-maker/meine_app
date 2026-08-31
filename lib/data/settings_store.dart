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
  static const kartenProTagKey = 'kartenProTag';

  /// Vorgaenger-Schluessel: Der Regler stand einmal fuer die NEUEN Karten
  /// pro Tag, inzwischen fuer das ganze Tagespensum. Wer damals einen Wert
  /// eingestellt hat, behaelt ihn - die Zahl bedeutet nur etwas anderes.
  static const _altNeueProTagKey = 'neueProTag';
  static const steigendeSchwierigkeitKey = 'steigendeSchwierigkeit';
  static const einfuehrungsFensterKey = 'einfuehrungsFenster';

  /// In wie vielen Tagen jede Frage mindestens einmal drankommen soll.
  ///
  /// Aus diesem Fenster leitet sich ab, wie viele bisher ungesehene Fragen
  /// taeglich fest eingeplant werden. Ohne ein solches Kontingent nehmen die
  /// faelligen Wiederholungen das ganze Tagesbudget ein, und der Rest des
  /// Kurses kommt nie dran.
  static const einfuehrungsFensterStandard = 90;
  static const einfuehrungsFensterMin = 30;
  static const einfuehrungsFensterMax = 180;

  /// Wie viele Karten insgesamt pro Tag anstehen - Wiederholungen und neue
  /// zusammen.
  ///
  /// Ein Topf statt zwei: 20 am Tag heisst 20, nicht 20 plus so viele
  /// Wiederholungen, wie gerade faellig sind.
  static const kartenProTagStandard = 20;
  static const kartenProTagMax = 50;

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

  int kartenProTagLaden() {
    final roh =
        _box.get(kartenProTagKey) ??
        _box.get(_altNeueProTagKey) ??
        kartenProTagStandard;
    final wert = (roh as num).toInt();
    return wert.clamp(0, kartenProTagMax);
  }

  Future<void> kartenProTagSpeichern(int anzahl) async {
    await _box.put(kartenProTagKey, anzahl.clamp(0, kartenProTagMax));
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

  int einfuehrungsFensterLaden() {
    final roh = _box.get(
      einfuehrungsFensterKey,
      defaultValue: einfuehrungsFensterStandard,
    );
    return (roh as num).toInt().clamp(
      einfuehrungsFensterMin,
      einfuehrungsFensterMax,
    );
  }

  Future<void> einfuehrungsFensterSpeichern(int tage) async {
    await _box.put(
      einfuehrungsFensterKey,
      tage.clamp(einfuehrungsFensterMin, einfuehrungsFensterMax),
    );
  }
}
