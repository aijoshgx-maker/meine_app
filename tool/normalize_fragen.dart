// Expandiert Minimalformat-Fragendateien (nur die für den Fragetyp nötigen
// Felder) auf das Vollformat (alle Felder, leere als []/null) - siehe
// docs/FRAGENFORMAT.md und P11c in CLAUDE_CODE_PROMPTS.md.
//
// Aufruf:  dart run tool/normalize_fragen.dart <eingabe.json> <ausgabe.json>
//
// Führt KEINE inhaltliche Prüfung durch - dafür danach
// `dart run tool/validate_fragen.dart` laufen lassen.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

// Vollformat-Feldreihenfolge, identisch zu Frage.toJson() in
// lib/models/frage.dart, damit normalisierte Dateien genauso aussehen wie
// die übrigen Fragendateien im Projekt.
const _feldReihenfolge = [
  'id',
  'bereich',
  'kategorie',
  'typ',
  'frage',
  'optionen',
  'richtigeIndizes',
  'reihenfolge',
  'paare',
  'luecken',
  'loesungswert',
  'einheit',
  'toleranz',
  'akzeptierteKurzantworten',
  'wahr',
  'erklaerung',
  'selfExplanationPrompt',
  'bildAsset',
  'workedExample',
  'schwierigkeit',
  'pruefung',
  'pruefungReihenfolge',
];

// Felder, die als leere Liste statt null aufgefüllt werden, wenn sie fehlen.
const _listenFelder = {
  'optionen',
  'richtigeIndizes',
  'reihenfolge',
  'paare',
  'luecken',
  'akzeptierteKurzantworten',
};

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Aufruf: dart run tool/normalize_fragen.dart <eingabe.json> <ausgabe.json>',
    );
    exit(2);
  }

  final eingabeDatei = File(args[0]);
  if (!eingabeDatei.existsSync()) {
    stderr.writeln('Eingabedatei nicht gefunden: ${args[0]}');
    exit(2);
  }

  final bytes = eingabeDatei.readAsBytesSync();
  final raw = utf8.decode(bytes, allowMalformed: true);
  final text = raw.startsWith('﻿') ? raw.substring(1) : raw;

  dynamic geparst;
  try {
    geparst = jsonDecode(text);
  } catch (e) {
    stderr.writeln('JSON nicht parsebar: $e');
    exit(1);
  }

  if (geparst is! List) {
    stderr.writeln('Erwartet ein JSON-Array von Fragen auf oberster Ebene.');
    exit(1);
  }

  final normalisiert = geparst.map((roh) {
    final f = Map<String, dynamic>.from(roh as Map);
    final vollstaendig = <String, dynamic>{};
    for (final feld in _feldReihenfolge) {
      if (f.containsKey(feld)) {
        vollstaendig[feld] = f[feld];
      } else if (_listenFelder.contains(feld)) {
        vollstaendig[feld] = <dynamic>[];
      } else {
        vollstaendig[feld] = null;
      }
    }
    // Unbekannte Felder (Tippfehler im Minimalformat) nicht stillschweigend
    // verschlucken, sondern melden.
    final unbekannt = f.keys.toSet().difference(_feldReihenfolge.toSet());
    if (unbekannt.isNotEmpty) {
      stderr.writeln(
        "WARNUNG: unbekannte Felder bei id='${f['id']}': $unbekannt (werden ignoriert)",
      );
    }
    return vollstaendig;
  }).toList();

  const encoder = JsonEncoder.withIndent('  ');
  File(args[1]).writeAsStringSync('${encoder.convert(normalisiert)}\n');
  print('${normalisiert.length} Fragen normalisiert -> ${args[1]}');
  print('Jetzt prüfen: dart run tool/validate_fragen.dart');
}
