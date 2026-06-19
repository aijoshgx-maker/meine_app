import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/lernplan.dart';
import '../models/themenbereich.dart';

// Liest alle Inhalts-JSON-Dateien unter assets/content/ ein und baut daraus
// den Lernplan auf. Neue Themenbereiche werden hier einfach in die Liste
// eingetragen (und müssen zusätzlich in pubspec.yaml unter assets stehen).
class LernplanLoader {
  static const _dateien = [
    'assets/content/fertigungstechnik.json',
    'assets/content/technisches_zeichnen.json',
    'assets/content/steuerungstechnik.json',
    'assets/content/werkstoffkunde.json',
    'assets/content/mathematik.json',
  ];

  Future<Lernplan> laden() async {
    final themenbereiche = <Themenbereich>[];
    for (final pfad in _dateien) {
      final text = await rootBundle.loadString(pfad);
      final json = jsonDecode(text) as Map<String, dynamic>;
      themenbereiche.add(Themenbereich.fromJson(json));
    }
    return Lernplan(themenbereiche: themenbereiche);
  }
}
