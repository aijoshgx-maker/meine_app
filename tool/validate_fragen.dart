// Validiert alle Fragendateien unter assets/fragen/.
//
// Aufruf:  dart run tool/validate_fragen.dart
// Exit-Code 0  -> keine FEHLER (Warnungen sind ok)
// Exit-Code 1  -> mindestens ein FEHLER
//
// Muss von der Projektwurzel aus laufen (dort wo pubspec.yaml liegt).
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const erlaubteTypen = {
  'single',
  'multi',
  'wahrfalsch',
  'rechnung',
  'kurzantwort',
  'lueckentext',
  'zuordnung',
  'reihenfolge',
};

const ankerOptionen = {
  'keine der genannten',
  'keine der genannten antworten',
  'alle antworten sind richtig',
  'alle genannten antworten sind richtig',
  'keine antwort ist richtig',
};

class Fund {
  final String schwere; // FEHLER | WARNUNG
  final String datei;
  final String? id;
  final String text;
  Fund(this.schwere, this.datei, this.id, this.text);

  @override
  String toString() {
    final prefix = id != null ? '$datei [$id]' : datei;
    return '$schwere  $prefix: $text';
  }
}

final funde = <Fund>[];
void fehler(String datei, String? id, String text) =>
    funde.add(Fund('FEHLER', datei, id, text));
void warnung(String datei, String? id, String text) =>
    funde.add(Fund('WARNUNG', datei, id, text));

// Prüfungen, die eine Frage per "bewusstSo" abschalten darf.
//
// Manche Warnungen sind Heuristiken, die eine ganze Klasse legitimer Fragen
// mittreffen. Beispiel multi-anteil: "Welche gehören zu X?" hat oft aus der
// Sache heraus fast nur richtige Optionen - dort IST die Abgrenzung der
// Lernstoff. Eine solche Frage umzuschreiben, nur damit die Metrik ruhig
// ist, macht sie fachlich schlechter.
//
// Die Ausnahme ist bewusst je Prüfung anzugeben und nicht pauschal: Wer
// "bewusstSo" setzt, schaltet genau eine Prüfung ab, nicht alle.
const bekanntePruefIds = {
  'multi-anteil': 'multi: fast alle Optionen richtig',
};

// Welche Ausnahmen tatsächlich gegriffen haben - alles andere ist veraltet
// und wird am Ende gemeldet, damit sich keine toten Marker ansammeln.
final benutzteAusnahmen = <String>{};

/// Warnung, sofern die Frage diese Prüfung nicht per "bewusstSo" abschaltet.
void warnungFallsNichtBewusst(
  String datei,
  String id,
  Map<String, dynamic> f,
  String pruefId,
  String text,
) {
  if (bewusstSoListe(f).contains(pruefId)) {
    benutzteAusnahmen.add('$datei|$id|$pruefId');
    return;
  }
  warnung(datei, id, text);
}

List<String> bewusstSoListe(Map<String, dynamic> f) =>
    ((f['bewusstSo'] as List?) ?? const [])
        .whereType<String>()
        .toList();

void main(List<String> args) {
  final root = Directory.current.path;
  final fragenDir = Directory('$root/assets/fragen');
  if (!fragenDir.existsSync()) {
    stderr.writeln(
      'Verzeichnis assets/fragen nicht gefunden. Im Projektwurzelverzeichnis ausführen.',
    );
    exit(2);
  }

  final diagKeys = _ladeDiagKeys(root);
  final assetPfade = _ladePubspecAssetOrdner(root);
  final manifestListe = _ladeManifest(fragenDir);
  _pruefeRechtsstand(fragenDir);
  _pruefeGlossar(fragenDir);

  final alleDateien =
      fragenDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final alleIds = <String, String>{}; // id -> erste Datei
  // Für Positionsverteilung / Ähnlichkeitscheck über alle Fragen hinweg.
  final alleFragenTexte = <String, List<String>>{}; // datei -> frage-texte
  final alleFragenObjekte = <_FrageMitDatei>[];

  for (final file in alleDateien) {
    final name = file.uri.pathSegments.last;
    // Dateien mit fuehrendem Unterstrich sind Metadaten, keine Fragen -
    // _manifest, _rechtsstand, _glossar. Als Konvention statt Aufzaehlung,
    // damit die naechste solche Datei nicht wieder 26 Fehler ausloest.
    if (name.startsWith('_')) continue;

    if (name != 'fachgespraech_szenarien.json' &&
        !manifestListe.contains(name)) {
      fehler(name, null, 'Datei ist nicht in _manifest.json gelistet.');
    }

    final bytes = file.readAsBytesSync();
    final hatBom =
        bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF;
    if (hatBom) {
      fehler(name, null, 'Datei beginnt mit UTF-8-BOM (EF BB BF).');
    }
    final raw = utf8.decode(bytes, allowMalformed: true);
    // utf8.decode() already strips a leading BOM itself; only strip again if
    // the decoded string still carries one (defensive, matches
    // frage_repository.dart's own BOM guard).
    final text = raw.startsWith('﻿') ? raw.substring(1) : raw;

    dynamic geparst;
    try {
      geparst = jsonDecode(text);
    } catch (e) {
      fehler(name, null, 'JSON nicht parsebar: $e');
      continue;
    }

    if (name == 'fachgespraech_szenarien.json') {
      _validiereSzenarien(name, geparst, alleIds);
      continue;
    }

    if (geparst is! List) {
      fehler(name, null, 'Erwartet ein JSON-Array auf oberster Ebene.');
      continue;
    }

    // Encoding-Verdacht: Datei ohne einen einzigen Umlaut bei > 5 Fragen.
    if (geparst.length > 5) {
      final voll = geparst.map((e) => jsonEncode(e)).join();
      final hatUmlaut = RegExp(r'[äöüÄÖÜß]').hasMatch(voll);
      if (!hatUmlaut) {
        warnung(
          name,
          null,
          'Keine Umlaute in ${geparst.length} Fragen gefunden (Encoding-Verdacht).',
        );
      }
    }

    final positionZaehler = <int, int>{};
    var singleAnzahl = 0;

    for (final roh in geparst) {
      if (roh is! Map) {
        fehler(name, null, 'Frage-Eintrag ist kein Objekt: $roh');
        continue;
      }
      final f = Map<String, dynamic>.from(roh);
      final id = f['id'] as String?;
      if (id == null || id.isEmpty) {
        fehler(name, null, 'Frage ohne id: ${jsonEncode(f)}');
        continue;
      }
      if (alleIds.containsKey(id)) {
        fehler(name, id, 'Doppelte id, bereits in ${alleIds[id]}.');
      } else {
        alleIds[id] = name;
      }

      alleFragenObjekte.add(_FrageMitDatei(name, id, f));
      (alleFragenTexte[name] ??= []).add((f['frage'] as String?) ?? '');

      _validiereFrage(name, id, f, diagKeys, assetPfade);

      if ((f['typ'] as String?) == 'single') {
        singleAnzahl++;
        final ri = _intList(f['richtigeIndizes']);
        if (ri.length == 1) {
          positionZaehler[ri.first] = (positionZaehler[ri.first] ?? 0) + 1;
        }
      }
    }

    // Positionsverteilung stark unausgewogen.
    if (singleAnzahl >= 5 && positionZaehler.isNotEmpty) {
      final maxAnteil =
          positionZaehler.values.reduce((a, b) => a > b ? a : b) / singleAnzahl;
      if (maxAnteil > 0.5) {
        warnung(
          name,
          null,
          'Positionsverteilung der richtigen Antwort bei single stark unausgewogen: '
          '$positionZaehler (von $singleAnzahl Fragen).',
        );
      }
    }
  }

  // Ähnlichkeit über alle Fragen hinweg (Token-Jaccard, > 0.85).
  _pruefeAehnlichkeit(alleFragenObjekte);
  _pruefeVeralteteAusnahmen(alleFragenObjekte);

  // Ausgabe
  final fehlerListe = funde.where((f) => f.schwere == 'FEHLER').toList();
  final warnungListe = funde.where((f) => f.schwere == 'WARNUNG').toList();

  print('=== Validierung assets/fragen/ ===');
  print('Dateien geprüft: ${alleDateien.length}');
  print('Fragen gesamt (ohne Fachgespräch): ${alleFragenObjekte.length}');
  print('');
  print('--- FEHLER (${fehlerListe.length}) ---');
  for (final f in fehlerListe) {
    print(f);
  }
  print('');
  print('--- WARNUNGEN (${warnungListe.length}) ---');
  for (final w in warnungListe) {
    print(w);
  }
  print('');
  print(
    fehlerListe.isEmpty
        ? 'ERGEBNIS: OK (0 Fehler, ${warnungListe.length} Warnungen)'
        : 'ERGEBNIS: FEHLGESCHLAGEN (${fehlerListe.length} Fehler, ${warnungListe.length} Warnungen)',
  );

  exit(fehlerListe.isEmpty ? 0 : 1);
}

class _FrageMitDatei {
  final String datei;
  final String id;
  final Map<String, dynamic> f;
  _FrageMitDatei(this.datei, this.id, this.f);
}

List<int> _intList(dynamic v) =>
    (v as List? ?? []).map((e) => e as int).toList();
List<String> _strList(dynamic v) =>
    (v as List? ?? []).map((e) => e.toString()).toList();

void _validiereFrage(
  String datei,
  String id,
  Map<String, dynamic> f,
  Set<String> diagKeys,
  List<String> assetPfade,
) {
  final typ = f['typ'] as String?;
  final frage = (f['frage'] as String?) ?? '';
  final erklaerung = (f['erklaerung'] as String?) ?? '';
  final schwierigkeit = f['schwierigkeit'];
  final optionen = _strList(f['optionen']);
  final richtigeIndizes = _intList(f['richtigeIndizes']);
  final reihenfolge = _intList(f['reihenfolge']);
  final paare = (f['paare'] as List?) ?? [];
  final luecken = (f['luecken'] as List?) ?? [];
  final loesungswert = f['loesungswert'];
  final einheit = f['einheit'];
  final toleranz = f['toleranz'];
  final akzeptierteKurzantworten = _strList(f['akzeptierteKurzantworten']);
  final wahr = f['wahr'];
  final workedExample = f['workedExample'];

  // Ein Tippfehler in "bewusstSo" wuerde sonst still gar nichts abschalten -
  // die Warnung bliebe stehen und niemand wuesste warum.
  for (final pruefId in bewusstSoListe(f)) {
    if (!bekanntePruefIds.containsKey(pruefId)) {
      fehler(
        datei,
        id,
        "'bewusstSo' nennt die unbekannte Pruefung '$pruefId'. "
        'Bekannt: ${bekanntePruefIds.keys.join(", ")}.',
      );
    }
  }

  if (frage.trim().isEmpty) fehler(datei, id, "'frage' ist leer.");
  if (erklaerung.trim().isEmpty) {
    fehler(datei, id, "'erklaerung' ist leer.");
  } else if (erklaerung.length < 90) {
    warnung(
      datei,
      id,
      "'erklaerung' kürzer als 90 Zeichen (${erklaerung.length}).",
    );
  }

  if (schwierigkeit is! int || !{1, 2, 3}.contains(schwierigkeit)) {
    fehler(datei, id, "'schwierigkeit' nicht in {1,2,3}: $schwierigkeit");
  }

  if (typ == null || !erlaubteTypen.contains(typ)) {
    fehler(datei, id, "'typ' nicht im erlaubten Set: $typ");
    return; // Typspezifische Prüfungen ergeben ohne gültigen Typ keinen Sinn.
  }

  switch (typ) {
    case 'single':
      if (richtigeIndizes.length != 1) {
        fehler(
          datei,
          id,
          "single: richtigeIndizes.length != 1 (${richtigeIndizes.length}).",
        );
      }
      _pruefeOptionenBlock(datei, id, optionen, richtigeIndizes);
      break;
    case 'multi':
      if (richtigeIndizes.length < 2 ||
          richtigeIndizes.length == optionen.length) {
        fehler(
          datei,
          id,
          'multi: richtigeIndizes.length ${richtigeIndizes.length} ungültig '
          '(muss >=2 und < optionen.length=${optionen.length} sein).',
        );
      }
      if (optionen.length >= 4 &&
          richtigeIndizes.length == optionen.length - 1) {
        warnungFallsNichtBewusst(
          datei,
          id,
          f,
          'multi-anteil',
          'multi: ${richtigeIndizes.length} von ${optionen.length} Optionen '
              'richtig (zu leicht erratbar). Ist die Abgrenzung selbst der '
              'Lernstoff, mit "bewusstSo": ["multi-anteil"] kennzeichnen.',
        );
      }
      _pruefeOptionenBlock(datei, id, optionen, richtigeIndizes);
      break;
    case 'wahrfalsch':
      if (wahr is! bool) {
        fehler(datei, id, "wahrfalsch: 'wahr' ist kein bool: $wahr");
      }
      if (optionen.isNotEmpty) {
        fehler(datei, id, 'wahrfalsch: optionen ist nicht leer.');
      }
      break;
    case 'rechnung':
      if (loesungswert == null) {
        fehler(datei, id, 'rechnung: loesungswert ist null.');
      }
      if (einheit == null) fehler(datei, id, 'rechnung: einheit ist null.');
      if (toleranz == null) fehler(datei, id, 'rechnung: toleranz ist null.');
      if (optionen.isNotEmpty) {
        fehler(
          datei,
          id,
          'rechnung: optionen ist nicht leer (falsch typisiert).',
        );
      }
      if (richtigeIndizes.isNotEmpty) {
        fehler(
          datei,
          id,
          'rechnung: richtigeIndizes ist nicht leer (falsch typisiert).',
        );
      }
      if (workedExample == null || (workedExample as String).trim().isEmpty) {
        warnung(datei, id, 'rechnung ohne workedExample.');
      }
      break;
    case 'kurzantwort':
      if (akzeptierteKurzantworten.isEmpty) {
        fehler(datei, id, 'kurzantwort: akzeptierteKurzantworten ist leer.');
      } else if (akzeptierteKurzantworten.length == 1) {
        warnung(
          datei,
          id,
          'kurzantwort: nur eine akzeptierte Schreibweise (${akzeptierteKurzantworten.first}).',
        );
      }
      break;
    case 'lueckentext':
      final platzhalter = RegExp(
        r'\{\{(\d+)\}\}',
      ).allMatches(frage).map((m) => int.parse(m.group(1)!)).toSet();
      if (platzhalter.length != luecken.length) {
        fehler(
          datei,
          id,
          'lueckentext: Anzahl {{n}} im Fragetext (${platzhalter.length}) '
          '!= luecken.length (${luecken.length}).',
        );
      }
      final erwartet = List.generate(luecken.length, (i) => i + 1).toSet();
      final nummerierungGleich =
          platzhalter.length == erwartet.length &&
          platzhalter.every(erwartet.contains);
      if (platzhalter.isNotEmpty &&
          platzhalter.length == luecken.length &&
          !nummerierungGleich) {
        fehler(
          datei,
          id,
          'lueckentext: Nummerierung nicht lückenlos ab 1: $platzhalter',
        );
      }
      for (var i = 0; i < luecken.length; i++) {
        final varianten = (luecken[i] as List)
            .map((e) => e.toString())
            .toList();
        if (varianten.length == 1) {
          warnung(
            datei,
            id,
            'lueckentext: Lücke ${i + 1} akzeptiert nur eine Schreibweise (${varianten.first}).',
          );
        }
      }
      break;
    case 'zuordnung':
      if (paare.length < 2) {
        fehler(datei, id, 'zuordnung: weniger als 2 Paare (${paare.length}).');
      }
      final linksWerte = <String>[];
      final rechtsWerte = <String>[];
      for (final p in paare) {
        final m = Map<String, dynamic>.from(p as Map);
        linksWerte.add((m['links'] as String?) ?? '');
        rechtsWerte.add((m['rechts'] as String?) ?? '');
      }
      if (linksWerte.toSet().length != linksWerte.length) {
        fehler(datei, id, 'zuordnung: doppelte links-Werte.');
      }
      if (rechtsWerte.toSet().length != rechtsWerte.length) {
        warnung(datei, id, 'zuordnung: doppelte rechts-Werte.');
      }
      break;
    case 'reihenfolge':
      final n = optionen.length;
      final erwartet = List.generate(n, (i) => i);
      final sortiert = [...reihenfolge]..sort();
      if (n == 0 ||
          sortiert.length != n ||
          !_listenGleich(sortiert, erwartet)) {
        fehler(
          datei,
          id,
          'reihenfolge: reihenfolge ist keine gültige Permutation von 0..${n - 1}: $reihenfolge',
        );
      } else if (_listenGleich(reihenfolge, erwartet)) {
        warnung(
          datei,
          id,
          'reihenfolge: Identitätspermutation [0,1,2,...] – Lösung = Anzeigereihenfolge.',
        );
      }
      break;
  }

  // Typfremde Felder befüllt.
  final fehlermeldungenTypfremd = <String>[];
  if (typ != 'single' &&
      typ != 'multi' &&
      typ != 'reihenfolge' &&
      optionen.isNotEmpty) {
    fehlermeldungenTypfremd.add('optionen');
  }
  if (typ != 'single' && typ != 'multi' && richtigeIndizes.isNotEmpty) {
    fehlermeldungenTypfremd.add('richtigeIndizes');
  }
  if (typ != 'reihenfolge' && reihenfolge.isNotEmpty) {
    fehlermeldungenTypfremd.add('reihenfolge');
  }
  if (typ != 'zuordnung' && paare.isNotEmpty) {
    fehlermeldungenTypfremd.add('paare');
  }
  if (typ != 'lueckentext' && luecken.isNotEmpty) {
    fehlermeldungenTypfremd.add('luecken');
  }
  if (typ != 'rechnung' &&
      (loesungswert != null || einheit != null || toleranz != null)) {
    fehlermeldungenTypfremd.add('loesungswert/einheit/toleranz');
  }
  if (typ != 'kurzantwort' && akzeptierteKurzantworten.isNotEmpty) {
    fehlermeldungenTypfremd.add('akzeptierteKurzantworten');
  }
  if (typ != 'wahrfalsch' && wahr != null) {
    fehlermeldungenTypfremd.add('wahr');
  }
  if (fehlermeldungenTypfremd.isNotEmpty) {
    fehler(
      datei,
      id,
      'Typfremde Felder befüllt für typ=$typ: ${fehlermeldungenTypfremd.join(', ')}',
    );
  }

  // bildAsset
  final bildAsset = f['bildAsset'] as String?;
  if (bildAsset != null && bildAsset.isNotEmpty) {
    if (bildAsset.startsWith('diag:')) {
      final key = bildAsset.substring(5);
      if (!diagKeys.contains(key)) {
        fehler(
          datei,
          id,
          "bildAsset 'diag:$key' ist in technische_illustration.dart nicht registriert.",
        );
      }
    } else {
      final existiertAlsAssetOrdner = assetPfade.any(
        (p) => bildAsset.startsWith(p),
      );
      final file = File('${Directory.current.path}/$bildAsset');
      if (!existiertAlsAssetOrdner || !file.existsSync()) {
        fehler(
          datei,
          id,
          "bildAsset-Pfad '$bildAsset' existiert nicht bzw. ist nicht als pubspec-Asset erfasst.",
        );
      }
    }
  }
}

void _pruefeOptionenBlock(
  String datei,
  String id,
  List<String> optionen,
  List<int> richtigeIndizes,
) {
  if (optionen.length < 2) {
    fehler(datei, id, 'optionen.length < 2 (${optionen.length}).');
  }
  for (final idx in richtigeIndizes) {
    if (idx < 0 || idx >= optionen.length) {
      fehler(
        datei,
        id,
        'richtigeIndizes enthält Index außerhalb des Bereichs: $idx',
      );
    }
  }
  if (richtigeIndizes.toSet().length != richtigeIndizes.length) {
    fehler(
      datei,
      id,
      'richtigeIndizes enthält doppelte Indizes: $richtigeIndizes',
    );
  }
  final normiert = optionen.map((o) => o.trim().toLowerCase()).toList();
  if (normiert.toSet().length != normiert.length) {
    fehler(datei, id, 'optionen enthält doppelte Optionstexte.');
  }
}

bool _listenGleich(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void _validiereSzenarien(
  String datei,
  dynamic geparst,
  Map<String, String> alleIds,
) {
  if (geparst is! List) {
    fehler(datei, null, 'Erwartet ein JSON-Array auf oberster Ebene.');
    return;
  }
  for (final roh in geparst) {
    final s = Map<String, dynamic>.from(roh as Map);
    final id = s['id'] as String?;
    if (id == null || id.isEmpty) {
      fehler(datei, null, 'Szenario ohne id.');
      continue;
    }
    if (alleIds.containsKey(id)) {
      fehler(datei, id, 'Doppelte id, bereits in ${alleIds[id]}.');
    } else {
      alleIds[id] = datei;
    }
    for (final feld in ['titel', 'kontext', 'fertigungsauftrag']) {
      if ((s[feld] as String?)?.trim().isEmpty ?? true) {
        fehler(datei, id, "Szenario-Feld '$feld' ist leer oder fehlt.");
      }
    }
    if ((s['kategorien'] as List?)?.isEmpty ?? true) {
      fehler(datei, id, "Szenario-Feld 'kategorien' ist leer oder fehlt.");
    }
    final fragen = (s['fragen'] as List?) ?? [];
    if (fragen.isEmpty) {
      fehler(datei, id, 'Szenario ohne Fragen.');
    }
    for (final rohF in fragen) {
      final f = Map<String, dynamic>.from(rohF as Map);
      final fid = f['id'] as String?;
      if (fid == null || fid.isEmpty) {
        fehler(datei, id, 'Fachgespräch-Frage ohne id.');
        continue;
      }
      if (alleIds.containsKey(fid)) {
        fehler(datei, fid, 'Doppelte id, bereits in ${alleIds[fid]}.');
      } else {
        alleIds[fid] = datei;
      }
      for (final feld in ['pruefer', 'musterloesung', 'erklaerung']) {
        if ((f[feld] as String?)?.trim().isEmpty ?? true) {
          fehler(datei, fid, "Fachgespräch-Feld '$feld' ist leer oder fehlt.");
        }
      }
      if ((f['schluesselwoerter'] as List?)?.isEmpty ?? true) {
        fehler(
          datei,
          fid,
          "Fachgespräch-Feld 'schluesselwoerter' ist leer oder fehlt.",
        );
      }
      final schwierigkeit = f['schwierigkeit'];
      if (schwierigkeit is! int || !{1, 2, 3}.contains(schwierigkeit)) {
        fehler(datei, fid, "'schwierigkeit' nicht in {1,2,3}: $schwierigkeit");
      }
    }
  }
}

Set<String> _ladeDiagKeys(String root) {
  final file = File(
    '$root/lib/features/quiz/widgets/illustrationen/technische_illustration.dart',
  );
  if (!file.existsSync()) return {};
  final content = file.readAsStringSync();
  return RegExp(
    r"case '([a-zA-Z0-9_]+)':",
  ).allMatches(content).map((m) => m.group(1)!).toSet();
}

List<String> _ladePubspecAssetOrdner(String root) {
  final file = File('$root/pubspec.yaml');
  if (!file.existsSync()) return [];
  final lines = file.readAsLinesSync();
  final pfade = <String>[];
  var inAssets = false;
  for (final line in lines) {
    final trimmed = line.trimRight();
    if (RegExp(r'^\s*assets\s*:\s*$').hasMatch(trimmed)) {
      inAssets = true;
      continue;
    }
    if (inAssets) {
      final match = RegExp(r'^\s+-\s+(\S+)\s*$').firstMatch(trimmed);
      if (match != null) {
        pfade.add(match.group(1)!);
      } else if (trimmed.trim().isNotEmpty) {
        inAssets = false;
      }
    }
  }
  return pfade;
}

void _pruefeRechtsstand(Directory fragenDir) {
  final file = File('${fragenDir.path}/_rechtsstand.json');
  if (!file.existsSync()) {
    warnung(
      '_rechtsstand.json',
      null,
      'Datei fehlt - WISO-Rechtsstand ist nicht zentral gepflegt (siehe P4).',
    );
    return;
  }
  dynamic geparst;
  try {
    geparst = jsonDecode(file.readAsStringSync());
  } catch (e) {
    fehler('_rechtsstand.json', null, 'JSON nicht parsebar: $e');
    return;
  }
  final stand = geparst is Map ? geparst['stand'] as String? : null;
  if (stand == null) {
    fehler('_rechtsstand.json', null, "Feld 'stand' fehlt oder ist null.");
    return;
  }
  final standDatum = DateTime.tryParse(stand);
  if (standDatum == null) {
    fehler(
      '_rechtsstand.json',
      null,
      "Feld 'stand' ist kein gültiges Datum: $stand",
    );
    return;
  }
  final altersInMonaten =
      (DateTime.now().difference(standDatum).inDays) / 30.44;
  if (altersInMonaten > 14) {
    warnung(
      '_rechtsstand.json',
      null,
      "WISO-Rechtsstand ('$stand') ist älter als 14 Monate "
          '(${altersInMonaten.toStringAsFixed(1)} Monate) - Beitragssätze und '
          'Rechengrößen prüfen und aktualisieren.',
    );
  }
}

Set<String> _ladeManifest(Directory fragenDir) {
  final file = File('${fragenDir.path}/_manifest.json');
  if (!file.existsSync()) return {};
  final liste = jsonDecode(file.readAsStringSync()) as List;
  return liste.map((e) => e.toString()).toSet();
}

void _pruefeAehnlichkeit(List<_FrageMitDatei> fragen) {
  final tokenSets = fragen
      .map(
        (fd) => (fd.f['frage'] as String? ?? '')
            .toLowerCase()
            .split(RegExp(r'[^a-zäöüß0-9]+'))
            .where((t) => t.length > 2)
            .toSet(),
      )
      .toList();
  final gemeldet = <String>{};
  for (var i = 0; i < fragen.length; i++) {
    if (tokenSets[i].length < 3) continue;
    for (var j = i + 1; j < fragen.length; j++) {
      if (tokenSets[j].length < 3) continue;
      final a = tokenSets[i];
      final b = tokenSets[j];
      final schnitt = a.intersection(b).length;
      final vereinigung = a.union(b).length;
      if (vereinigung == 0) continue;
      final aehnlichkeit = schnitt / vereinigung;
      if (aehnlichkeit > 0.85) {
        final paarKey = ([fragen[i].id, fragen[j].id]..sort()).join('|');
        if (gemeldet.add(paarKey)) {
          warnung(
            fragen[i].datei,
            fragen[i].id,
            'Ähnlichkeit ${(aehnlichkeit * 100).toStringAsFixed(0)}% zu '
            '${fragen[j].id} (${fragen[j].datei}).',
          );
        }
      }
    }
  }
}

/// Meldet "bewusstSo"-Marker, die gar nichts mehr abschalten.
///
/// Ohne das sammeln sich tote Ausnahmen an: Wird eine Frage spaeter
/// umgebaut, bleibt der Marker stehen und deckt kuenftig womoeglich ein
/// echtes Problem zu.
void _pruefeVeralteteAusnahmen(List<_FrageMitDatei> alle) {
  for (final eintrag in alle) {
    for (final pruefId in bewusstSoListe(eintrag.f)) {
      if (!bekanntePruefIds.containsKey(pruefId)) continue;
      final schluessel = '${eintrag.datei}|${eintrag.id}|$pruefId';
      if (!benutzteAusnahmen.contains(schluessel)) {
        warnung(
          eintrag.datei,
          eintrag.id,
          "'bewusstSo: $pruefId' greift nicht mehr - die Pruefung wuerde "
          'hier ohnehin nicht anschlagen. Marker entfernen.',
        );
      }
    }
  }
}

/// Prueft das Glossar: gueltiges JSON, Pflichtfelder, keine Doppelungen.
///
/// Ohne das faellt ein kaputtes Glossar erst zur Laufzeit auf - und dort
/// still, weil ein Ladefehler bewusst geschluckt wird, damit der Kurs nicht
/// mitkippt.
void _pruefeGlossar(Directory fragenDir) {
  final file = File('${fragenDir.path}/_glossar.json');
  if (!file.existsSync()) return;

  final List<dynamic> liste;
  try {
    final roh = jsonDecode(file.readAsStringSync());
    if (roh is! List) {
      fehler('_glossar.json', null, 'Erwartet ein JSON-Array.');
      return;
    }
    liste = roh;
  } catch (e) {
    fehler('_glossar.json', null, 'JSON nicht parsebar: $e');
    return;
  }

  final gesehen = <String>{};
  for (var i = 0; i < liste.length; i++) {
    final eintrag = liste[i];
    if (eintrag is! Map) {
      fehler('_glossar.json', null, 'Eintrag ${i + 1} ist kein Objekt.');
      continue;
    }

    final begriff = eintrag['begriff'];
    if (begriff is! String || begriff.trim().isEmpty) {
      fehler('_glossar.json', null, "Eintrag ${i + 1}: 'begriff' fehlt.");
      continue;
    }
    if (!gesehen.add(begriff)) {
      fehler('_glossar.json', begriff, 'Begriff kommt mehrfach vor.');
    }

    final kurz = eintrag['kurz'];
    if (kurz is! String || kurz.trim().isEmpty) {
      fehler('_glossar.json', begriff, "'kurz' fehlt oder ist leer.");
    } else if (kurz.length > 160) {
      // Die Kurzfassung soll auf einen Blick lesbar sein - laengeres
      // gehoert nach "mehr".
      warnung(
        '_glossar.json',
        begriff,
        "'kurz' ist ${kurz.length} Zeichen lang - gehoert das nach 'mehr'?",
      );
    }
  }
}
