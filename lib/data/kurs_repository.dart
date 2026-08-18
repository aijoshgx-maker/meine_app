import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

import '../models/fachgespraech_szenario.dart';
import '../models/frage.dart';
import '../models/kurs.dart';
import '../models/lernpaket.dart';
import 'kurs_store.dart';

/// Einziger Zugang zu Kursen - egal ob mitgeliefert oder importiert.
///
/// Gebündelte Kurse liegen als Assets vor und werden über rootBundle
/// gelesen; importierte kommen aus dem [KursStore]. Nach außen sieht beides
/// gleich aus, damit die UI nicht zwischen den Quellen unterscheiden muss.
class KursRepository {
  /// Mit der App ausgelieferte Kurse. Jeder Eintrag zeigt auf eine kurs.json
  /// unter assets/, die auch in pubspec.yaml deklariert sein muss.
  static const gebuendelteKursPfade = <String>[
    'assets/kurse/ap2-industriemechaniker/kurs.json',
  ];

  /// Kurs, der beim allerersten Start aktiv ist.
  static const standardKursId = 'ap2-industriemechaniker';

  final KursStore _store;

  KursRepository({KursStore? store}) : _store = store ?? KursStore();

  String _ohneBom(String roh) => roh.startsWith('﻿') ? roh.substring(1) : roh;

  /// Alle verfügbaren Kurse: erst die gebündelten, dann die importierten in
  /// der Reihenfolge ihrer Installation.
  Future<List<Kurs>> alleKurse() async {
    final kurse = <Kurs>[];
    for (final pfad in gebuendelteKursPfade) {
      final kurs = await _gebuendeltenKursLesen(pfad);
      if (kurs != null) kurse.add(kurs);
    }
    kurse.addAll(_store.alleKurse());
    return kurse;
  }

  /// Lädt einen Kurs samt Inhalt. Wirft [StateError], wenn es ihn nicht gibt.
  Future<Lernpaket> paketFuer(String kursId) async {
    final importiert = _store.paketFuer(kursId);
    if (importiert != null) return importiert;

    for (final pfad in KursRepository.gebuendelteKursPfade) {
      final kurs = await _gebuendeltenKursLesen(pfad);
      if (kurs?.id != kursId) continue;
      return _gebuendeltesPaketLaden(kurs!);
    }
    throw StateError('Kurs "$kursId" ist nicht installiert.');
  }

  /// Der Kurs, der aktiv sein soll: der gewünschte, sonst der Standardkurs,
  /// sonst der erste verfügbare. Gibt null zurück, wenn gar keiner da ist.
  Future<Kurs?> aufloesen(String? gewuenschteId) async {
    final kurse = await alleKurse();
    if (kurse.isEmpty) return null;
    for (final kurs in kurse) {
      if (kurs.id == gewuenschteId) return kurs;
    }
    for (final kurs in kurse) {
      if (kurs.id == standardKursId) return kurs;
    }
    return kurse.first;
  }

  // -------------------------------------------------------------------

  Future<Kurs?> _gebuendeltenKursLesen(String pfad) async {
    try {
      final text = _ohneBom(await rootBundle.loadString(pfad));
      final json = Map<String, dynamic>.from(jsonDecode(text) as Map);
      // Ohne eigene Angabe liegen die Fragendateien neben der kurs.json.
      final ordner =
          json['assetOrdner'] as String? ??
          '${pfad.substring(0, pfad.lastIndexOf('/'))}/';
      return Kurs.fromJson(
        json,
        quelle: KursQuelle.gebuendelt,
        assetOrdner: ordner,
      );
    } catch (e, stack) {
      // Ein kaputter gebündelter Kurs darf die übrigen nicht mitreißen.
      debugPrint('KursRepository: $pfad nicht lesbar: $e\n$stack');
      return null;
    }
  }

  Future<Lernpaket> _gebuendeltesPaketLaden(Kurs kurs) async {
    final ordner = kurs.assetOrdner ?? '';

    final fragen = <Frage>[];
    for (final name in kurs.fragenDateien) {
      try {
        final text = _ohneBom(await rootBundle.loadString('$ordner$name'));
        final liste = jsonDecode(text) as List;
        fragen.addAll(
          liste.map((e) => Frage.fromJson(e as Map<String, dynamic>)),
        );
      } catch (e, stack) {
        // Eine kaputte Themendatei darf nicht die gesamte Fragenliste
        // mitreißen - die übrigen Themen sollen trotzdem laden.
        debugPrint('KursRepository: Fehler beim Laden von $name: $e\n$stack');
      }
    }

    final szenarien = <FachgespraechSzenario>[];
    final fgDatei = kurs.fachgespraechDatei;
    if (fgDatei != null) {
      try {
        szenarien.addAll(
          await FachgespraechSzenario.ladeAlle('$ordner$fgDatei'),
        );
      } catch (e, stack) {
        debugPrint('KursRepository: Fachgespräch nicht ladbar: $e\n$stack');
      }
    }

    return Lernpaket(kurs: kurs, fragen: fragen, szenarien: szenarien);
  }
}
