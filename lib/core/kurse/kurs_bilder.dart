import 'package:flutter/widgets.dart';

import '../../models/kurs.dart';
import '../plattform/datei_ablage.dart';

/// Löst Bildpfade eines Kurses zu einem [ImageProvider] auf.
///
/// Gebündelte Kurse liefern ihre Bilder als Assets, importierte als echte
/// Dateien unter `appDocs/kurse/<kursId>/`. Der Basispfad wird beim App-Start
/// einmal gesetzt, damit die Auflösung synchron im Widget-Build passieren
/// kann - ihn dort erst zu ermitteln ginge nur asynchron.
///
/// Auf Web gibt es keine abgelegten Dateien: dort liefert [fuer] für
/// importierte Kurse null, und der Aufrufer zeigt seinen Platzhalter.
class KursBilder {
  static String? _basisPfad;

  /// Einmalig in main() setzen, bevor die erste UI gebaut wird.
  static void basisPfadSetzen(String? pfad) => _basisPfad = pfad;

  /// Bildquelle für [pfad] innerhalb von [kurs]. Gibt null zurück, wenn der
  /// Pfad nicht auflösbar ist - der Aufrufer zeigt dann seinen Platzhalter.
  static ImageProvider? fuer(Kurs kurs, String pfad) {
    if (kurs.quelle == KursQuelle.gebuendelt) return AssetImage(pfad);

    final basis = _basisPfad;
    if (basis == null) return null;
    return DateiAblage.bild('$basis/kurse/${kurs.id}/$pfad');
  }
}
