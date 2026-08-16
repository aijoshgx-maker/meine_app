import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

import '../models/frage.dart';

// Lädt alle Fragen aus assets/fragen/*.json.
// Die Dateinamen werden aus assets/fragen/_manifest.json gelesen, damit kein
// AssetManifest-Hacking nötig ist und die Reihenfolge deterministisch bleibt.
class FrageRepository {
  static const _manifestPfad = 'assets/fragen/_manifest.json';
  static const _ordner = 'assets/fragen/';

  // Entfernt eine führende UTF-8-BOM (U+FEFF), falls vorhanden. Defensiv:
  // rootBundle.loadString() sollte den BOM zwar schon selbst entfernen,
  // aber verifizierte Release-Builds haben das nicht zuverlässig getan
  // (siehe CLAUDE_CODE_PROMPTS.md, P1a) - daher hier zusätzlich absichern.
  String _ohneBom(String raw) => raw.startsWith('﻿') ? raw.substring(1) : raw;

  Future<List<Frage>> laden() async {
    final manifestText = _ohneBom(await rootBundle.loadString(_manifestPfad));
    final dateinamen = (jsonDecode(manifestText) as List).cast<String>();

    final fragen = <Frage>[];
    for (final name in dateinamen) {
      try {
        final text = _ohneBom(await rootBundle.loadString('$_ordner$name'));
        final liste = jsonDecode(text) as List;
        fragen.addAll(
          liste.map((e) => Frage.fromJson(e as Map<String, dynamic>)),
        );
      } catch (e, stack) {
        // Eine kaputte/unlesbare Themendatei darf nicht die gesamte
        // Fragenliste mitreißen - die übrigen Themen sollen trotzdem laden.
        debugPrint('FrageRepository: Fehler beim Laden von $name: $e\n$stack');
      }
    }
    return fragen;
  }
}
