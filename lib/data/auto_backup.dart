import 'package:flutter/foundation.dart' show debugPrint;

import '../core/plattform/datei_ablage.dart';
import 'backup_store.dart';
import 'settings_store.dart';

/// Legt in regelmäßigen Abständen still eine Sicherung des Lernstands an.
///
/// Der Sinn: Ein manuelles Backup macht man genau dann nicht, wenn man es
/// bräuchte. Verliert jemand sein Gerät oder deinstalliert die App aus
/// Versehen, ist der gesamte Wiederholungsplan weg - und der ist über Monate
/// gewachsen, nicht in einer Stunde nachgebaut.
///
/// Bewusst zurückhaltend gehalten:
/// - läuft nur, wenn seit der letzten Sicherung [abstand] vergangen ist
/// - schreibt in das App-eigene Verzeichnis, fragt also nichts
/// - hält höchstens [maxDateien] Sicherungen und löscht die ältesten
/// - scheitert leise: Eine fehlgeschlagene Sicherung darf den App-Start
///   niemals aufhalten
///
/// Auf Web passiert nichts - dort gibt es kein Dateisystem, in das
/// ungefragt geschrieben werden könnte.
class AutoBackup {
  static const abstand = Duration(days: 7);
  static const maxDateien = 4;
  static const ordnerName = 'backups';

  final BackupStore _backupStore;
  final SettingsStore _einstellungen;

  AutoBackup({BackupStore? backupStore, SettingsStore? einstellungen})
    : _backupStore = backupStore ?? BackupStore(),
      _einstellungen = einstellungen ?? SettingsStore();

  /// Prüft, ob eine Sicherung fällig ist, und legt sie gegebenenfalls an.
  ///
  /// Gibt den Pfad der geschriebenen Datei zurück, oder null wenn nichts zu
  /// tun war. Wirft nie.
  Future<String?> ausfuehrenWennFaellig({
    required String appVersion,
    DateTime? jetzt,
  }) async {
    final zeitpunkt = jetzt ?? DateTime.now();

    try {
      if (!DateiAblage.verfuegbar) return null;
      if (!istFaellig(zeitpunkt)) return null;

      final basis = await DateiAblage.basisPfad();
      if (basis == null) return null;

      final daten = _backupStore.erstellen(appVersion: appVersion);
      final pfad =
          '$basis/$ordnerName/${_backupStore.dateinameFuer(zeitpunkt)}';

      await DateiAblage.schreibe(pfad, _backupStore.alsBytes(daten));
      await _einstellungen.letztesAutoBackupSpeichern(zeitpunkt);
      await _alteAufraeumen(basis);

      debugPrint('AutoBackup: $pfad (${daten.anzahlKarten} Karten)');
      return pfad;
    } catch (e, stack) {
      // Eine misslungene Sicherung ist ärgerlich, aber kein Grund, den
      // Start zu blockieren.
      debugPrint('AutoBackup fehlgeschlagen: $e\n$stack');
      return null;
    }
  }

  /// Ob seit der letzten Sicherung genug Zeit vergangen ist.
  ///
  /// Beim allerersten Start wird sofort gesichert - so existiert von Anfang
  /// an eine Kopie, statt erst nach einer Woche.
  bool istFaellig(DateTime jetzt) {
    final letztes = _einstellungen.letztesAutoBackupLaden();
    if (letztes == null) return true;
    return jetzt.difference(letztes) >= abstand;
  }

  /// Behält die neuesten [maxDateien] Sicherungen, löscht den Rest.
  Future<void> _alteAufraeumen(String basis) async {
    final dateien = await DateiAblage.dateienIn('$basis/$ordnerName');
    if (dateien.length <= maxDateien) return;

    // Der Dateiname trägt einen ISO-Zeitstempel, alphabetisch sortiert
    // entspricht also chronologisch.
    dateien.sort();
    for (final pfad in dateien.take(dateien.length - maxDateien)) {
      await DateiAblage.loescheDatei(pfad);
    }
  }
}
