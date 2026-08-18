import 'dart:typed_data';

import 'fachgespraech_szenario.dart';
import 'frage.dart';
import 'kurs.dart';

/// Ein vollständig eingelesenes Lernpaket: Kursbeschreibung plus Inhalt.
///
/// Beim Import wird ein Paket komplett in den Speicher gelesen, geprüft und
/// erst danach installiert - so hinterlässt ein kaputtes Paket keinen
/// halbfertigen Kurs.
class Lernpaket {
  final Kurs kurs;
  final List<Frage> fragen;
  final List<FachgespraechSzenario> szenarien;

  /// Mitgelieferte Bilder: relativer Pfad im Paket -> Dateiinhalt.
  /// Nur bei ZIP-Paketen gefüllt.
  final Map<String, Uint8List> bilder;

  const Lernpaket({
    required this.kurs,
    required this.fragen,
    this.szenarien = const [],
    this.bilder = const {},
  });

  /// Alle in den Fragen vorkommenden Kategorien, gruppiert nach Bereich und
  /// in der Bereichsreihenfolge des Kurses. Ersetzt die früher fest im Code
  /// stehende Kategorienliste.
  Map<String, List<String>> get kategorienProBereich {
    final gruppen = <String, List<String>>{};
    for (final frage in fragen) {
      final liste = gruppen.putIfAbsent(frage.bereich, () => []);
      if (!liste.contains(frage.kategorie)) liste.add(frage.kategorie);
    }
    for (final liste in gruppen.values) {
      liste.sort();
    }

    // In Bereichsreihenfolge des Kurses ausgeben, unbekannte Bereiche hinten.
    final sortiert = <String, List<String>>{};
    for (final bereich in kurs.bereiche) {
      final liste = gruppen.remove(bereich.id);
      if (liste != null && liste.isNotEmpty) sortiert[bereich.id] = liste;
    }
    sortiert.addAll(gruppen);
    return sortiert;
  }

  /// Anzahl Fragen je Prüfungscode - für die Auswahl der Testläufe.
  Map<String, int> get fragenProPruefung {
    final zaehler = <String, int>{};
    for (final frage in fragen) {
      final code = frage.pruefung;
      if (code == null) continue;
      zaehler[code] = (zaehler[code] ?? 0) + 1;
    }
    return zaehler;
  }
}
