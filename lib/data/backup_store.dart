import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../core/plattform/datei_ablage.dart';
import 'attempt_history_store.dart';
import 'fsrs_card_store.dart';
import 'migrationen.dart';
import 'settings_store.dart';

// Export/Import des kompletten Lernstands (P9): FSRS-Kartenstände,
// Beantwortungsverlauf und Einstellungen als eine JSON-Datei. Schema von
// Anfang an versioniert, damit spätere Formatänderungen migrierbar bleiben.
//
// Version 2 sichert den Lernstand aller Kurse: Kartenschlüssel tragen seither
// die Kurs-id ("kursId::frageId"), Verlaufseinträge ein Feld kursId. Backups
// der Version 1 stammen aus der Zeit mit nur einem Kurs und werden beim
// Einlesen auf den Bestandskurs umgeschrieben.
//
// Das Backup enthält bewusst KEINE Kursinhalte - nur den Fortschritt. Ein
// importiertes Lernpaket exportiert man als Paketdatei, nicht als Backup.

const backupSchemaVersion = 2;

class BackupDaten {
  final int schemaVersion;
  final DateTime exportiertAm;
  final String appVersion;
  final Map<String, Map<String, dynamic>>
  karten; // "kursId::frageId" -> GespeicherteKarte.toMap()
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

    // Version 1 kannte nur einen Kurs: Kartenschlüssel waren nackte
    // Frage-ids, Verlaufseinträge trugen keine kursId. Beides hier
    // nachziehen, damit der alte Lernstand im Mehrkurs-Schema ankommt.
    final altesFormat = schemaVersion < 2;

    final karten = kartenRoh.map(
      (k, v) => MapEntry(
        altesFormat
            ? FsrsCardStore.schluessel(Migrationen.bestandsKursId, k as String)
            : k as String,
        Map<String, dynamic>.from(v as Map),
      ),
    );

    final verlauf = verlaufRoh.map((e) {
      final eintrag = Map<String, dynamic>.from(e as Map);
      eintrag['kursId'] ??= Migrationen.bestandsKursId;
      return eintrag;
    }).toList();

    return BackupDaten(
      schemaVersion: schemaVersion,
      exportiertAm: exportiertAm,
      appVersion: json['appVersion'] as String? ?? 'unbekannt',
      karten: karten,
      verlauf: verlauf,
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
    // Bewusst über alle Kurse hinweg: ein Backup soll den kompletten
    // Lernstand sichern, nicht nur den gerade aktiven Kurs.
    final karten = _kartenStore.alleKartenstaendeRoh().map(
      (schluessel, karte) => MapEntry(schluessel, karte.toMap()),
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

  /// Serialisiert [daten] zu den Bytes der Backup-Datei.
  ///
  /// Bewusst plattformfrei: Was danach damit passiert - teilen, speichern
  /// oder herunterladen - entscheidet der Aufrufer. Auf Web gibt es kein
  /// Dateisystem, in das hier geschrieben werden könnte.
  Uint8List alsBytes(BackupDaten daten) {
    const encoder = JsonEncoder.withIndent('  ');
    return Uint8List.fromList(utf8.encode(encoder.convert(daten.toJson())));
  }

  /// Vorgeschlagener Dateiname für einen Export.
  String dateinameFuer(DateTime zeitpunkt) => _dateinameFuer(zeitpunkt);

  /// Schreibt das Backup zusätzlich als echte Datei und gibt den Pfad zurück.
  /// Auf Web null - dort wird nur über die Bytes exportiert.
  Future<String?> alsTemporaereDatei(BackupDaten daten) =>
      DateiAblage.temporaerSchreiben(
        _dateinameFuer(daten.exportiertAm),
        alsBytes(daten),
      );

  String _dateinameFuer(DateTime zeitpunkt) {
    final iso = zeitpunkt
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    return 'lernstand-backup-$iso.json';
  }

  /// Importiert [daten]. [bekannteSchluessel] enthält alle bekannten
  /// Kartenschlüssel ("kursId::frageId") über alle installierten Kurse;
  /// alles andere wird übersprungen und gezählt statt abzubrechen - so
  /// bricht ein Import nicht, wenn sich der Fragenbestand zwischen Export
  /// und Import geändert hat oder ein Kurs nicht installiert ist.
  Future<ImportErgebnis> importieren(
    BackupDaten daten, {
    required ImportModus modus,
    required Set<String> bekannteSchluessel,
  }) async {
    var importiert = 0;
    var aktualisiert = 0;
    var uebersprungenUnbekannt = 0;

    if (modus == ImportModus.ersetzen) {
      await _kartenBoxLeeren();
    }

    final vorhandeneKarten = _kartenStore.alleKartenstaendeRoh();

    for (final entry in daten.karten.entries) {
      final schluessel = entry.key;
      if (!bekannteSchluessel.contains(schluessel)) {
        uebersprungenUnbekannt++;
        continue;
      }
      final importierteKarte = GespeicherteKarte.fromMap(entry.value);

      if (modus == ImportModus.zusammenfuehren) {
        final vorhandene = vorhandeneKarten[schluessel];
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
      await _kartenStore.speichernRoh(schluessel, importierteKarte);
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
          .map(
            (a) => '${a.kursId}|${a.frageId}|${a.zeitpunkt.toIso8601String()}',
          )
          .toSet();
      for (final roh in daten.verlauf) {
        final attempt = Attempt.fromMap(roh);
        final schluessel =
            '${attempt.kursId}|${attempt.frageId}|'
            '${attempt.zeitpunkt.toIso8601String()}';
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
