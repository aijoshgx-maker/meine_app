// Zugriff auf das Dateisystem - oder eben nicht.
//
// Der Web-Build kennt kein dart:io. Ein Import davon ist dort schon ein
// Compile-Fehler, kein Laufzeitproblem - kIsWeb-Abfragen im Code reichen
// deshalb nicht aus. Stattdessen gibt es diese Naht zweimal: einmal echt
// (datei_ablage_io.dart) und einmal als Stub (datei_ablage_web.dart).
//
// Regel: Außerhalb von datei_ablage_io.dart importiert kein Anwendungscode
// dart:io oder path_provider. Ein Test wacht darüber.
export 'datei_ablage_io.dart'
    if (dart.library.js_interop) 'datei_ablage_web.dart';
