import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart' show ImageProvider, FileImage;
import 'package:path_provider/path_provider.dart';

/// Dateisystem-Zugriff auf Android, iOS, Windows, macOS und Linux.
///
/// Die Web-Variante in datei_ablage_web.dart muss dieselbe API anbieten.
abstract final class DateiAblage {
  /// Ob echte Dateien geschrieben werden können.
  static bool get verfuegbar => true;

  /// Basisverzeichnis für App-eigene Dateien.
  static Future<String?> basisPfad() async =>
      (await getApplicationDocumentsDirectory()).path;

  /// Schreibt [bytes] nach [pfad] und legt fehlende Ordner an.
  static Future<void> schreibe(String pfad, Uint8List bytes) async {
    final datei = File(pfad);
    await datei.parent.create(recursive: true);
    await datei.writeAsBytes(bytes);
  }

  /// Löscht [pfad] samt Inhalt, falls vorhanden.
  static Future<void> loescheOrdner(String pfad) async {
    final ordner = Directory(pfad);
    if (await ordner.exists()) await ordner.delete(recursive: true);
  }

  /// Bildquelle für eine Datei auf der Platte.
  static ImageProvider? bild(String pfad) => FileImage(File(pfad));

  /// Schreibt [bytes] als Datei ins temporäre Verzeichnis und gibt den Pfad
  /// zurück - für Exporte, die anschließend geteilt werden.
  static Future<String?> temporaerSchreiben(
    String dateiname,
    Uint8List bytes,
  ) async {
    try {
      final ordner = await getTemporaryDirectory();
      final pfad = '${ordner.path}/$dateiname';
      await File(pfad).writeAsBytes(bytes);
      return pfad;
    } catch (e, stack) {
      debugPrint('DateiAblage: temporäre Datei fehlgeschlagen: $e\n$stack');
      return null;
    }
  }
}
