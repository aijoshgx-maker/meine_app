import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'attempt_history_store.dart';
import 'fsrs_card_store.dart';
import 'settings_store.dart';

// Export/Import des kompletten Lernstands (P9): FSRS-Kartenstände,
// Beantwortungsverlauf und Einstellungen als eine JSON-Datei. Schema von
// Anfang an versioniert, damit spätere Formatänderungen migrierbar bleiben.

const backupSchemaVersion = 1;

class BackupDaten {
  final int schemaVersion;
  final DateTime exportiertAm;
  final String appVersion;
  final Map<String, Map<String, dynamic>>
  karten; // frageId -> GespeicherteKarte.toMap()
  final List<Map<String, dynamic>> verlauf; // Attempt.toMap()
  final Map<String, dynamic> einstellungen;

  const BackupDaten({
    required this.schemaVersion,
    required this.exportiertAm,
    required this.appVersion,
    required this.karten,
    required this.verlauf,
    required this.einstellungen,
  });

  int get anzahlKarten => karten.length;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'exportiertAm': exportiertAm.toIso8601String(),
    'appVersion': appVersion,
    'anzahlKarten': anzahlKarten,
    'karten': karten,
    'verlauf': verlauf,
    'einstellungen': einstellungen,
  };

  /// Wirft [FormatException], wenn die Datei kein gültiges Backup ist.
  factory BackupDaten.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int) {
      throw const FormatException(
        "Feld 'schemaVersion' fehlt oder ist ungültig.",
      );
    }
    if (schemaVersion > backupSchemaVersion) {
      throw FormatException(
        'Backup-Format (Version $schemaVersion) ist neuer als von dieser '
        'App-Version unterstützt (Version $backupSchemaVersion). Bitte App aktualisieren.',
      );
    }
    final exportiertAmRoh = json['exportiertAm'];
    final exportiertAm = exportiertAmRoh is String
        ? DateTime.tryParse(exportiertAmRoh)
        : null;
    if (exportiertAm == null) {
      throw const FormatException(
        "Feld 'exportiertAm' fehlt oder ist ungültig.",
      );
    }
    final kartenRoh = json['karten'];
    if (kartenRoh is! Map) {
      throw const FormatException("Feld 'karten' fehlt oder ist ungültig.");
    }
    final verlaufRoh = json['verlauf'];
    if (verlaufRoh is! List) {
      throw const FormatException("Feld 'verlauf' fehlt oder ist ungültig.");
    }

    return BackupDaten(
      schemaVersion: schemaVersion,
      exportiertAm: exportiertAm,
      appVersion: json['appVersion'] as String? ?? 'unbekannt',
      karten: kartenRoh.map(
        (k, v) => MapEntry(k as String, Map<String, dynamic>.from(v as Map)),
      ),
      verlauf: verlaufRoh
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      einstellungen: Map<String, dynamic>.from(
        (json['einstellungen'] as Map?) ?? {},
      ),
    );
  }
}

enum ImportModus { ersetzen, zusammenfuehren }

class ImportErgebnis {
  final int importiert;
  final int aktualisiert;
  final int uebersprungenUnbekannt;
  final int verlaufHinzugefuegt;

  const ImportErgebnis({
    required this.importiert,
    required this.aktualisiert,
    required this.uebersprungenUnbekannt,
    required this.verlaufHinzugefuegt,
  });
}

class BackupStore {
  final FsrsCardStore _kartenStore;
  final AttemptHistoryStore _verlaufStore;
  final SettingsStore _einstellungenStore;

  BackupStore({
    FsrsCardStore? kartenStore,
    AttemptHistoryStore? verlaufStore,
    SettingsStore? einstellungenStore,
  }) : _kartenStore = kartenStore ?? FsrsCardStore(),
       _verlaufStore = verlaufStore ?? AttemptHistoryStore(),
       _einstellungenStore = einstellungenStore ?? SettingsStore();

  BackupDaten erstellen({required String appVersion}) {
    final karten = _kartenStore.alleKartenstaende().map(
      (id, karte) => MapEntry(id, karte.toMap()),
    );
    final verlauf = _verlaufStore.alle().map((a) => a.toMap()).toList();
    final einstellungen = {
      SettingsStore.themeModeKey: _einstellungenStore.themeModeLaden(),
      SettingsStore.remindersEnabledKey: _einstellungenStore
          .remindersAktiviert(),
    };
    return BackupDaten(
      schemaVersion: backupSchemaVersion,
      exportiertAm: DateTime.now(),
      appVersion: appVersion,
      karten: karten,
      verlauf: verlauf,
      einstellungen: einstellungen,
    );
  }

  /// Schreibt [daten] als JSON-Datei ins Zielverzeichnis (Standard: das
  /// temporäre Verzeichnis, zum direkten Teilen über share_plus) und gibt
  /// den Pfad zurück.
  Future<File> alsDateiSchreiben(
    BackupDaten daten, {
    Directory? zielOrdner,
    String? dateiname,
  }) async {
    final ordner = zielOrdner ?? await getTemporaryDirectory();
    final name = dateiname ?? _dateinameFuer(daten.exportiertAm);
    final datei = File('${ordner.path}/$name');
    const encoder = JsonEncoder.withIndent('  ');
    await datei.writeAsString(encoder.convert(daten.toJson()));
    return datei;
  }

  String _dateinameFuer(DateTime zeitpunkt) {
    final iso = zeitpunkt
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    return 'ap2trainer-backup-$iso.json';
  }

  /// Importiert [daten]. [bekannteFrageIds] filtert unbekannte Frage-IDs
  /// heraus (überspringen + zählen, statt abzubrechen) - so bricht ein
  /// Import nicht, wenn sich der Fragenbestand zwischen Export und Import
  /// geändert hat.
  Future<ImportErgebnis> importieren(
    BackupDaten daten, {
    required ImportModus modus,
    required Set<String> bekannteFrageIds,
  }) async {
    var importiert = 0;
    var aktualisiert = 0;
    var uebersprungenUnbekannt = 0;

    if (modus == ImportModus.ersetzen) {
      await _kartenBoxLeeren();
    }

    for (final entry in daten.karten.entries) {
      final frageId = entry.key;
      if (!bekannteFrageIds.contains(frageId)) {
        uebersprungenUnbekannt++;
        continue;
      }
      final importierteKarte = GespeicherteKarte.fromMap(entry.value);

      if (modus == ImportModus.zusammenfuehren) {
        final vorhandene = _kartenStore.kartenStandFuer(frageId);
        if (vorhandene != null) {
          // Jüngeres "due" gewinnt (siehe P9-Vorgabe).
          if (!importierteKarte.card.due.isAfter(vorhandene.card.due)) {
            continue; // vorhandene Karte bleibt, da nicht "jünger"
          }
          aktualisiert++;
        } else {
          importiert++;
        }
      } else {
        importiert++;
      }
      await _kartenStore.speichern(frageId, importierteKarte);
    }

    var verlaufHinzugefuegt = 0;
    if (modus == ImportModus.ersetzen) {
      await _verlaufBoxLeeren();
      for (final roh in daten.verlauf) {
        await _verlaufStore.anhaengen(Attempt.fromMap(roh));
        verlaufHinzugefuegt++;
      }
      if (daten.einstellungen[SettingsStore.themeModeKey] is String) {
        await _einstellungenStore.themeModeSpeichern(
          daten.einstellungen[SettingsStore.themeModeKey] as String,
        );
      }
      if (daten.einstellungen[SettingsStore.remindersEnabledKey] is bool) {
        await _einstellungenStore.remindersAktiviertSpeichern(
          daten.einstellungen[SettingsStore.remindersEnabledKey] as bool,
        );
      }
    } else {
      // Zusammenführen: vorhandene Verlaufseinträge (frageId+zeitpunkt)
      // bleiben, importierte werden ergänzt, exakte Duplikate übersprungen.
      final vorhandeneSchluessel = _verlaufStore
          .alle()
          .map((a) => '${a.frageId}|${a.zeitpunkt.toIso8601String()}')
          .toSet();
      for (final roh in daten.verlauf) {
        final attempt = Attempt.fromMap(roh);
        final schluessel =
            '${attempt.frageId}|${attempt.zeitpunkt.toIso8601String()}';
        if (vorhandeneSchluessel.contains(schluessel)) continue;
        await _verlaufStore.anhaengen(attempt);
        verlaufHinzugefuegt++;
      }
      // Einstellungen werden beim Zusammenführen bewusst NICHT importiert -
      // dafür gibt es keine sinnvolle "merge"-Semantik, die aktuelle
      // Geräte-Einstellung bleibt gültig.
    }

    return ImportErgebnis(
      importiert: importiert,
      aktualisiert: aktualisiert,
      uebersprungenUnbekannt: uebersprungenUnbekannt,
      verlaufHinzugefuegt: verlaufHinzugefuegt,
    );
  }

  Future<void> _kartenBoxLeeren() => Hive.box(FsrsCardStore.boxName).clear();
  Future<void> _verlaufBoxLeeren() =>
      Hive.box(AttemptHistoryStore.boxName).clear();
}
