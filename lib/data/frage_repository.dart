import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/frage.dart';

// Lädt den Fragenkatalog aus dem gebundenen JSON-Asset assets/fragen.json.
class FrageRepository {
  static const _pfad = 'assets/fragen.json';

  Future<List<Frage>> laden() async {
    final text = await rootBundle.loadString(_pfad);
    final json = jsonDecode(text) as List;
    return json
        .map((eintrag) => Frage.fromJson(eintrag as Map<String, dynamic>))
        .toList();
  }
}
