import 'dart:typed_data';

import 'package:flutter/widgets.dart' show ImageProvider;

/// Web-Variante: Es gibt kein Dateisystem, auf das die App schreiben dürfte.
///
/// Die Methoden sind bewusst stille No-ops statt Exceptions - die Aufrufer
/// prüfen [verfuegbar], wo das Ergebnis zählt, und alles andere soll auf Web
/// einfach durchlaufen statt die Funktion zu blockieren.
///
/// Muss API-gleich zu datei_ablage_io.dart bleiben.
abstract final class DateiAblage {
  static bool get verfuegbar => false;

  static Future<String?> basisPfad() async => null;

  static Future<void> schreibe(String pfad, Uint8List bytes) async {}

  static Future<void> loescheOrdner(String pfad) async {}

  /// Auf Web gibt es keine lokal abgelegten Kursbilder - der Aufrufer zeigt
  /// dann seinen Platzhalter.
  static ImageProvider? bild(String pfad) => null;

  /// Exporte laufen auf Web direkt über die Bytes (Browser-Download bzw.
  /// Web-Share-API), nicht über eine temporäre Datei.
  static Future<String?> temporaerSchreiben(
    String dateiname,
    Uint8List bytes,
  ) async => null;
}
