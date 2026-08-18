import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../models/fachgespraech_szenario.dart';
import '../../models/frage.dart';
import '../../models/kurs.dart';
import '../../models/lernpaket.dart';

/// Höchste Paketversion, die diese App lesen kann. Ein Paket mit höherer
/// Version wird abgelehnt statt halb interpretiert.
const int paketSchemaVersion = 1;

/// Fehler beim Einlesen eines Lernpakets. Die Meldung ist bewusst so
/// formuliert, dass sie unverändert in der UI angezeigt werden kann.
class PaketFormatException implements Exception {
  final String nachricht;
  const PaketFormatException(this.nachricht);

  @override
  String toString() => nachricht;
}

/// Ergebnis des Einlesens: das Paket plus nicht-fatale Auffälligkeiten,
/// die dem Nutzer vor dem Installieren gezeigt werden.
class PaketErgebnis {
  final Lernpaket paket;
  final List<String> warnungen;

  const PaketErgebnis({required this.paket, this.warnungen = const []});
}

/// Liest Lernpakete aus einer JSON-Datei oder einem ZIP-Archiv.
///
/// JSON: alles in einer Datei, Fragen unter "fragen" inline.
/// ZIP:  kurs.json im Wurzelverzeichnis, Fragen in den unter
///       "fragenDateien" genannten Dateien, Bilder frei daneben.
class PaketParser {
  /// Erkennt das Format am Dateinamen und liest entsprechend ein.
  PaketErgebnis ausDatei(String dateiname, Uint8List bytes) {
    final name = dateiname.toLowerCase();
    if (name.endsWith('.zip')) return ausZip(bytes);
    if (name.endsWith('.json')) {
      return ausJson(utf8.decode(bytes, allowMalformed: true));
    }
    throw const PaketFormatException(
      'Nicht unterstütztes Format. Erwartet wird eine .json- oder '
      '.zip-Datei.',
    );
  }

  /// Liest ein Paket aus einer einzelnen JSON-Datei.
  PaketErgebnis ausJson(String text) {
    final wurzel = _dekodiere(_ohneBom(text));
    final fragenRoh = wurzel['fragen'];
    if (fragenRoh is! List) {
      throw const PaketFormatException(
        "Feld 'fragen' fehlt. In einer JSON-Datei müssen die Fragen direkt "
        "unter 'fragen' stehen.",
      );
    }
    final szenarienRoh = wurzel['fachgespraech'] as List? ?? const [];
    return _bauen(wurzel, fragenRoh, szenarienRoh, const {});
  }

  /// Liest ein Paket aus einem ZIP-Archiv.
  PaketErgebnis ausZip(Uint8List bytes) {
    final Archive archiv;
    try {
      archiv = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw PaketFormatException('Das ZIP-Archiv ist beschädigt: $e');
    }

    // Dateien nach normalisiertem Pfad ablegen. Ein Archiv, das alles in
    // einem Unterordner hat, wird dabei transparent entpackt.
    final dateien = <String, Uint8List>{};
    for (final eintrag in archiv.files) {
      if (!eintrag.isFile) continue;
      dateien[_normalisiere(eintrag.name)] = Uint8List.fromList(
        eintrag.content as List<int>,
      );
    }
    final praefix = _wurzelPraefix(dateien.keys);
    final inhalt = <String, Uint8List>{
      for (final e in dateien.entries) e.key.substring(praefix.length): e.value,
    };

    final kursDatei = inhalt['kurs.json'];
    if (kursDatei == null) {
      throw const PaketFormatException(
        'Im Archiv fehlt die Datei kurs.json im Wurzelverzeichnis.',
      );
    }
    final wurzel = _dekodiere(
      _ohneBom(utf8.decode(kursDatei, allowMalformed: true)),
    );

    final warnungen = <String>[];

    // Fragen: entweder inline oder über fragenDateien verteilt.
    final fragenRoh = <dynamic>[];
    final inlineFragen = wurzel['fragen'];
    if (inlineFragen is List) fragenRoh.addAll(inlineFragen);

    final dateiNamen = (wurzel['fragenDateien'] as List? ?? const [])
        .map((e) => e as String)
        .toList();
    for (final name in dateiNamen) {
      final roh = inhalt[_normalisiere(name)] ?? inhalt['fragen/$name'];
      if (roh == null) {
        warnungen.add("Datei '$name' aus fragenDateien fehlt im Archiv.");
        continue;
      }
      try {
        final liste = jsonDecode(
          _ohneBom(utf8.decode(roh, allowMalformed: true)),
        );
        if (liste is List) {
          fragenRoh.addAll(liste);
        } else {
          warnungen.add("Datei '$name' enthält keine Fragenliste.");
        }
      } catch (e) {
        warnungen.add("Datei '$name' ist kein gültiges JSON: $e");
      }
    }

    if (fragenRoh.isEmpty) {
      throw const PaketFormatException(
        'Das Archiv enthält keine Fragen. Erwartet werden sie inline unter '
        "'fragen' oder in den unter 'fragenDateien' genannten Dateien.",
      );
    }

    // Fachgespräch-Szenarien
    var szenarienRoh = wurzel['fachgespraech'] as List? ?? const [];
    final fgDatei = wurzel['fachgespraechDatei'] as String?;
    if (fgDatei != null) {
      final roh = inhalt[_normalisiere(fgDatei)];
      if (roh == null) {
        warnungen.add("Fachgespräch-Datei '$fgDatei' fehlt im Archiv.");
      } else {
        try {
          final liste = jsonDecode(
            _ohneBom(utf8.decode(roh, allowMalformed: true)),
          );
          if (liste is List) szenarienRoh = liste;
        } catch (e) {
          warnungen.add("Fachgespräch-Datei '$fgDatei' ist ungültig: $e");
        }
      }
    }

    // Bilder: alles was keine .json ist, bleibt als Datei erhalten.
    final bilder = <String, Uint8List>{
      for (final e in inhalt.entries)
        if (!e.key.toLowerCase().endsWith('.json')) e.key: e.value,
    };

    return _bauen(
      wurzel,
      fragenRoh,
      szenarienRoh,
      bilder,
      vorhandeneWarnungen: warnungen,
    );
  }

  // ---------------------------------------------------------------------

  PaketErgebnis _bauen(
    Map<String, dynamic> wurzel,
    List<dynamic> fragenRoh,
    List<dynamic> szenarienRoh,
    Map<String, Uint8List> bilder, {
    List<String> vorhandeneWarnungen = const [],
  }) {
    final warnungen = [...vorhandeneWarnungen];

    _pruefeSchemaVersion(wurzel);
    final kurs = _leseKurs(wurzel);

    final bereichsIds = kurs.bereiche.map((b) => b.id).toSet();
    final fragen = <Frage>[];
    final gesehenIds = <String>{};
    var fehlerhaft = 0;

    for (var i = 0; i < fragenRoh.length; i++) {
      final roh = fragenRoh[i];
      if (roh is! Map) {
        fehlerhaft++;
        continue;
      }
      try {
        final frage = Frage.fromJson(Map<String, dynamic>.from(roh));

        if (frageTypOderNull(frage.typ) == null) {
          warnungen.add(
            "Frage '${frage.id}': unbekannter Typ '${frage.typ}' - "
            'übersprungen.',
          );
          fehlerhaft++;
          continue;
        }
        if (!gesehenIds.add(frage.id)) {
          warnungen.add(
            "Frage-ID '${frage.id}' kommt mehrfach vor - nur die erste wird "
            'verwendet.',
          );
          continue;
        }
        if (!bereichsIds.contains(frage.bereich)) {
          warnungen.add(
            "Frage '${frage.id}' verweist auf den unbekannten Bereich "
            "'${frage.bereich}'.",
          );
        }
        fragen.add(frage);
      } catch (e) {
        fehlerhaft++;
        if (warnungen.length < 20) {
          warnungen.add('Frage an Position ${i + 1} ist unvollständig: $e');
        }
      }
    }

    if (fragen.isEmpty) {
      throw const PaketFormatException(
        'Keine einzige Frage konnte gelesen werden. Bitte das Format gegen '
        'docs/PAKETFORMAT.md prüfen.',
      );
    }
    if (fehlerhaft > 0) {
      warnungen.add(
        '$fehlerhaft von ${fragenRoh.length} Fragen wurden übersprungen.',
      );
    }

    // Szenarien sind optional - ein Fehler hier darf das Paket nicht kippen.
    final szenarien = <FachgespraechSzenario>[];
    for (final roh in szenarienRoh) {
      try {
        szenarien.add(
          FachgespraechSzenario.fromJson(Map<String, dynamic>.from(roh as Map)),
        );
      } catch (e) {
        warnungen.add('Ein Fachgespräch-Szenario ist unvollständig: $e');
      }
    }

    // Feature-Flags gegen den tatsächlichen Inhalt abgleichen, damit die UI
    // keine leeren Modi anbietet.
    final hatPruefungsfragen = fragen.any((f) => f.pruefung != null);
    if (kurs.features.pruefungssimulation &&
        (kurs.pruefungen.isEmpty || !hatPruefungsfragen)) {
      warnungen.add(
        'Testläufe sind aktiviert, aber es gibt keine zugeordneten Fragen - '
        'der Modus bleibt ausgeblendet.',
      );
    }
    if (kurs.features.fachgespraech && szenarien.isEmpty) {
      warnungen.add(
        'Dialog ist aktiviert, aber das Paket enthält keine Szenarien - '
        'der Modus bleibt ausgeblendet.',
      );
    }

    return PaketErgebnis(
      paket: Lernpaket(
        kurs: kurs,
        fragen: fragen,
        szenarien: szenarien,
        bilder: bilder,
      ),
      warnungen: warnungen,
    );
  }

  void _pruefeSchemaVersion(Map<String, dynamic> wurzel) {
    final version = wurzel['schemaVersion'];
    if (version is! int) {
      throw const PaketFormatException(
        "Feld 'schemaVersion' fehlt oder ist keine Zahl. Erwartet: "
        '"schemaVersion": $paketSchemaVersion',
      );
    }
    if (version > paketSchemaVersion) {
      throw PaketFormatException(
        'Das Paket hat Format-Version $version, diese App unterstützt '
        'höchstens $paketSchemaVersion. Bitte die App aktualisieren.',
      );
    }
  }

  Kurs _leseKurs(Map<String, dynamic> wurzel) {
    final id = wurzel['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const PaketFormatException("Feld 'id' fehlt oder ist leer.");
    }
    if (!_gueltigeId.hasMatch(id)) {
      throw PaketFormatException(
        "Die Kurs-ID '$id' enthält unerlaubte Zeichen. Erlaubt sind "
        'Buchstaben, Ziffern, Bindestrich und Unterstrich.',
      );
    }
    final titel = wurzel['titel'];
    if (titel is! String || titel.trim().isEmpty) {
      throw const PaketFormatException("Feld 'titel' fehlt oder ist leer.");
    }

    final bereicheRoh = wurzel['bereiche'];
    if (bereicheRoh is! List || bereicheRoh.isEmpty) {
      throw const PaketFormatException(
        "Feld 'bereiche' fehlt oder ist leer. Ein Kurs braucht mindestens "
        'einen Bereich.',
      );
    }

    final Kurs kurs;
    try {
      kurs = Kurs.fromJson(wurzel);
    } catch (e) {
      throw PaketFormatException('Die Kursbeschreibung ist ungültig: $e');
    }

    final ids = <String>{};
    for (final bereich in kurs.bereiche) {
      if (!ids.add(bereich.id)) {
        throw PaketFormatException(
          "Die Bereichs-ID '${bereich.id}' kommt mehrfach vor.",
        );
      }
    }
    return kurs;
  }

  static final _gueltigeId = RegExp(r'^[a-zA-Z0-9_-]+$');

  Map<String, dynamic> _dekodiere(String text) {
    final dynamic wurzel;
    try {
      wurzel = jsonDecode(text);
    } catch (e) {
      throw PaketFormatException('Die Datei ist kein gültiges JSON: $e');
    }
    if (wurzel is! Map) {
      throw const PaketFormatException(
        'Die Datei enthält kein JSON-Objekt. Erwartet wird ein Objekt mit '
        "den Feldern 'schemaVersion', 'id', 'titel', 'bereiche' und 'fragen'.",
      );
    }
    return Map<String, dynamic>.from(wurzel);
  }

  String _ohneBom(String roh) => roh.startsWith('﻿') ? roh.substring(1) : roh;

  String _normalisiere(String pfad) =>
      pfad.replaceAll('\\', '/').replaceFirst(RegExp(r'^\./'), '');

  /// Gemeinsamer Wurzelordner aller Einträge, damit ein Archiv mit einem
  /// umschließenden Ordner ("paket/kurs.json") genauso funktioniert wie eins
  /// ohne. Gibt '' zurück, wenn es keinen gemeinsamen Ordner gibt.
  String _wurzelPraefix(Iterable<String> pfade) {
    if (pfade.any((p) => p == 'kurs.json')) return '';
    final ordner = pfade
        .where((p) => p.contains('/'))
        .map((p) => '${p.split('/').first}/')
        .toSet();
    if (ordner.length != 1) return '';
    final praefix = ordner.single;
    return pfade.every((p) => p.startsWith(praefix)) ? praefix : '';
  }
}
