import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';

import '../core/plattform/datei_ablage.dart';
import '../models/fachgespraech_szenario.dart';
import '../models/frage.dart';
import '../models/kurs.dart';
import '../models/lernpaket.dart';

/// Speichert vom Nutzer importierte Lernpakete.
///
/// Gebündelte Kurse landen bewusst NICHT hier - die liegen in assets/ und
/// würden die Box nur unnötig aufblähen. Wer alle Kurse braucht, geht über
/// KursRepository.
///
/// Bilder aus ZIP-Paketen liegen nicht in Hive, sondern als echte Dateien
/// unter `appDocs/kurse/<kursId>/`, damit Image.file() sie direkt anzeigen
/// kann.
class KursStore {
  static const boxName = 'kurse';

  Box get _box => Hive.box(boxName);

  /// Die Box, sofern geöffnet - sonst null.
  ///
  /// Lesende Zugriffe dürfen nicht voraussetzen, dass Hive schon
  /// initialisiert ist: einen gebündelten Kurs zu laden geht auch ohne, und
  /// ein früher Zugriff (Tests, Fehlerpfade beim Start) soll keine
  /// HiveError werfen, sondern schlicht "keine importierten Kurse" bedeuten.
  Box? get _boxWennOffen => Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;

  /// Verzeichnis, in dem die Bilder eines importierten Kurses liegen.
  /// Auf Web null - dort werden keine Bilder abgelegt.
  static Future<String?> bilderOrdner(String kursId) async {
    final basis = await DateiAblage.basisPfad();
    return basis == null ? null : '$basis/kurse/$kursId';
  }

  List<String> alleIds() =>
      _boxWennOffen?.keys.cast<String>().toList() ?? const [];

  bool kennt(String kursId) => _boxWennOffen?.containsKey(kursId) ?? false;

  /// Nur die Kursbeschreibung, ohne die Fragen zu deserialisieren - für
  /// Listenansichten, die 700 Fragen nicht anfassen müssen.
  Kurs? kursFuer(String kursId) {
    final roh = _boxWennOffen?.get(kursId);
    if (roh == null) return null;
    final eintrag = Map<String, dynamic>.from(roh as Map);
    return Kurs.fromJson(
      Map<String, dynamic>.from(eintrag['kurs'] as Map),
      quelle: KursQuelle.importiert,
    );
  }

  List<Kurs> alleKurse() {
    final kurse = <Kurs>[];
    for (final id in alleIds()) {
      final kurs = kursFuer(id);
      if (kurs != null) kurse.add(kurs);
    }
    return kurse;
  }

  /// Vollständiges Paket inklusive Fragen und Szenarien.
  Lernpaket? paketFuer(String kursId) {
    final roh = _boxWennOffen?.get(kursId);
    if (roh == null) return null;
    final eintrag = Map<String, dynamic>.from(roh as Map);

    final kurs = Kurs.fromJson(
      Map<String, dynamic>.from(eintrag['kurs'] as Map),
      quelle: KursQuelle.importiert,
    );
    final fragen = (eintrag['fragen'] as List? ?? [])
        .map((f) => Frage.fromJson(Map<String, dynamic>.from(f as Map)))
        .toList();
    final szenarien = (eintrag['szenarien'] as List? ?? [])
        .map(
          (s) => FachgespraechSzenario.fromJson(
            Map<String, dynamic>.from(s as Map),
          ),
        )
        .toList();

    return Lernpaket(kurs: kurs, fragen: fragen, szenarien: szenarien);
  }

  /// Schreibt ein geprüftes Paket in den Store und legt seine Bilder ab.
  ///
  /// Ein vorhandener Kurs gleicher ID wird ersetzt; der Lernfortschritt
  /// bleibt dabei erhalten, weil er in einer anderen Box unter
  /// `kursId::frageId` liegt und hier nicht angefasst wird.
  Future<void> installieren(Lernpaket paket) async {
    final kurs = paket.kurs.kopieMit(
      quelle: KursQuelle.importiert,
      installiertAm: DateTime.now(),
    );

    await _box.put(kurs.id, {
      'kurs': kurs.toJson(),
      'fragen': paket.fragen.map((f) => f.toJson()).toList(),
      'szenarien': paket.szenarien.map((s) => s.toJson()).toList(),
    });

    // Auf Web gibt es kein Dateisystem: Der Kurs wird trotzdem installiert,
    // seine Bilder zeigen dann einen Platzhalter. Ein Paket deswegen ganz
    // abzulehnen wäre die schlechtere Antwort.
    if (paket.bilder.isNotEmpty && DateiAblage.verfuegbar) {
      final ordner = await bilderOrdner(kurs.id);
      if (ordner != null) {
        // Alte Bilder desselben Kurses entfernen, damit ein erneuter Import
        // keine verwaisten Dateien hinterlässt.
        await DateiAblage.loescheOrdner(ordner);
        for (final eintrag in paket.bilder.entries) {
          await DateiAblage.schreibe('$ordner/${eintrag.key}', eintrag.value);
        }
      }
    }
  }

  /// Entfernt Kurs und Bilder. Der Lernfortschritt wird separat über
  /// FsrsCardStore.kursLoeschen() aufgeräumt.
  Future<void> entfernen(String kursId) async {
    await _boxWennOffen?.delete(kursId);

    // Der Kurs ist damit weg. Übrig gebliebene Bilddateien sind nur
    // verschwendeter Speicher - daran darf das Entfernen nicht scheitern.
    try {
      final ordner = await bilderOrdner(kursId);
      if (ordner != null) await DateiAblage.loescheOrdner(ordner);
    } catch (e, stack) {
      debugPrint('KursStore: Bilder von $kursId nicht löschbar: $e\n$stack');
    }
  }
}
