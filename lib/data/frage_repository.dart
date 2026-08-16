import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/frage.dart';

// Lädt alle Fragen aus assets/fragen/*.json.
// Die Dateinamen werden aus assets/fragen/_manifest.json gelesen, damit kein
// AssetManifest-Hacking nötig ist und die Reihenfolge deterministisch bleibt.
class FrageRepository {
  static const _manifestPfad = 'assets/fragen/_manifest.json';
  static const _ordner = 'assets/fragen/';

  Future<List<Frage>> laden() async {
    final manifestText = await rootBundle.loadString(_manifestPfad);
    final dateinamen = (jsonDecode(manifestText) as List).cast<String>();

    final fragen = <Frage>[];
    for (final name in dateinamen) {
      final text = await rootBundle.loadString('$_ordner$name');
      final liste = jsonDecode(text) as List;
      fragen.addAll(
        liste.map((e) => Frage.fromJson(e as Map<String, dynamic>)),
      );
    }
    return fragen;
  }
}
