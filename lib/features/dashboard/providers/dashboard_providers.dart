import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/attempt_history_store.dart';
import '../../kurse/providers/kurs_providers.dart';
import '../../quiz/providers/quiz_providers.dart';

export '../../kurse/providers/kurs_providers.dart'
    show aktiverKursProvider, lernfortschrittVersionProvider;
export '../../quiz/providers/quiz_fragen_auswahl.dart' show Tagespensum;
export '../../quiz/providers/quiz_providers.dart'
    show
        attemptHistoryStoreProvider,
        faelligeAnzahlProvider,
        fehlerquellenAnzahlProvider,
        tagespensumProvider;

// Alle Auswertungen beziehen sich immer auf genau den aktiven Kurs - sonst
// würden sich Fortschritte verschiedener Lernthemen zu einer nichtssagenden
// Mischzahl vermengen.
//
// Sie beobachten außerdem lernfortschrittVersionProvider: die Daten kommen
// direkt aus Hive, das Riverpod nicht beobachten kann, und würden sich sonst
// innerhalb einer Session nie aktualisieren.

// Aktuelle Behaltensquote: Ø currentRetrievability() über alle Karten, die
// schon mindestens einmal gelernt wurden (nie gelernte Karten fließen nicht
// ein, da sie noch keine Aussage über Behalten zulassen).
final behaltensquoteProvider = FutureProvider<double>((ref) async {
  ref.watch(lernfortschrittVersionProvider);
  final paket = await ref.watch(aktivesPaketProvider.future);
  final kartenstaende = ref
      .read(fsrsCardStoreProvider)
      .alleKartenstaende(paket.kurs.id);
  final scheduler = ref.read(fsrsSchedulerProvider);
  final jetzt = DateTime.now();

  final werte = <double>[];
  for (final frage in paket.fragen) {
    final stand = kartenstaende[frage.id];
    if (stand == null) continue;
    werte.add(scheduler.currentRetrievability(stand.card, jetzt));
  }
  if (werte.isEmpty) return 0;
  return werte.reduce((a, b) => a + b) / werte.length;
});

// Tägliche Trefferquote der letzten 30 Tage aus dem Attempt-Log – eine
// Annäherung an den Behaltens-Trend (echte rückwirkende FSRS-Retrievability
// ist aus dem gespeicherten Stand nicht rekonstruierbar, da nur der jeweils
// letzte Kartenstand gespeichert wird).
class TagesQuote {
  final DateTime tag;
  final double quote; // 0..1, 0 wenn an diesem Tag nichts gelernt wurde

  const TagesQuote({required this.tag, required this.quote});
}

final behaltensquoteVerlaufProvider = FutureProvider<List<TagesQuote>>((
  ref,
) async {
  final versuche = await _versucheDesKurses(ref);
  final jetzt = DateTime.now();
  final heute = DateTime(jetzt.year, jetzt.month, jetzt.day);

  return [
    for (var i = 29; i >= 0; i--)
      _tagesQuoteFuer(versuche, heute.subtract(Duration(days: i))),
  ];
});

/// Beantwortungsversuche des aktiven Kurses. Gemeinsame Basis aller
/// verlaufsbasierten Auswertungen.
Future<List<Attempt>> _versucheDesKurses(Ref ref) async {
  ref.watch(lernfortschrittVersionProvider);
  final kurs = await ref.watch(aktiverKursProvider.future);
  return ref.read(attemptHistoryStoreProvider).fuerKurs(kurs.id);
}

TagesQuote _tagesQuoteFuer(List<Attempt> versuche, DateTime tag) {
  final naechsterTag = tag.add(const Duration(days: 1));
  final tagesVersuche = versuche.where(
    (a) => !a.zeitpunkt.isBefore(tag) && a.zeitpunkt.isBefore(naechsterTag),
  );
  if (tagesVersuche.isEmpty) return TagesQuote(tag: tag, quote: 0);
  final richtige = tagesVersuche.where((a) => a.korrekt).length;
  return TagesQuote(tag: tag, quote: richtige / tagesVersuche.length);
}

// Gewichtete schriftliche Prüfungsreife: Ø Retrievability je Bereich,
// kombiniert mit den normalisierten Prüfungsgewichten (20/20/10 -> 40/40/20).
// Bewusst getrennt vom Arbeitsauftrag-Fortschritt (Phase 7) – siehe Plan.
class PruefungsreifeErgebnis {
  final Map<String, double> proBereich;
  final double gewichtet;

  const PruefungsreifeErgebnis({
    required this.proBereich,
    required this.gewichtet,
  });
}

final pruefungsreifeProvider = FutureProvider<PruefungsreifeErgebnis>((
  ref,
) async {
  ref.watch(lernfortschrittVersionProvider);
  final paket = await ref.watch(aktivesPaketProvider.future);
  final kartenstaende = ref
      .read(fsrsCardStoreProvider)
      .alleKartenstaende(paket.kurs.id);
  final scheduler = ref.read(fsrsSchedulerProvider);
  final jetzt = DateTime.now();

  // Gewichte kommen aus dem Kurs. Ohne eigene Angabe zählen alle Bereiche
  // gleich viel.
  final gewichte = paket.kurs.normalisierteGewichte;

  final proBereich = <String, double>{};
  for (final bereich in gewichte.keys) {
    final werte = <double>[];
    for (final frage in paket.fragen.where((f) => f.bereich == bereich)) {
      final stand = kartenstaende[frage.id];
      if (stand == null) continue;
      werte.add(scheduler.currentRetrievability(stand.card, jetzt));
    }
    proBereich[bereich] = werte.isEmpty
        ? 0
        : werte.reduce((a, b) => a + b) / werte.length;
  }

  final gewichtet = gewichte.entries.fold<double>(
    0,
    (summe, eintrag) => summe + (proBereich[eintrag.key] ?? 0) * eintrag.value,
  );

  return PruefungsreifeErgebnis(proBereich: proBereich, gewichtet: gewichtet);
});

// Konfidenz-Kalibrierung: tatsächliche Trefferquote je Selbsteinschätzung.
// "sicher" sollte hoch liegen, "geraten" nahe Zufallsniveau.
final kalibrierungProvider = FutureProvider<Map<Konfidenz, double>>((
  ref,
) async {
  final versuche = await _versucheDesKurses(ref);
  return {for (final k in Konfidenz.values) k: _trefferquoteFuer(versuche, k)};
});

double _trefferquoteFuer(List<Attempt> versuche, Konfidenz konfidenz) {
  final passende = versuche.where((a) => a.konfidenz == konfidenz).toList();
  if (passende.isEmpty) return 0;
  return passende.where((a) => a.korrekt).length / passende.length;
}

// Anzahl hochkonfident-falscher Antworten ("sicher", aber falsch) – die
// Fälle, die laut Hypercorrection-Effekt am wirksamsten korrigierbar sind.
final hochkonfidentFalschAnzahlProvider = FutureProvider<int>((ref) async {
  final versuche = await _versucheDesKurses(ref);
  return versuche
      .where((a) => a.konfidenz == Konfidenz.sicher && !a.korrekt)
      .length;
});

// Schwache Themen: Kategorien mit der höchsten Fehlerquote im Attempt-Log,
// absteigend sortiert, auf die 5 schwächsten begrenzt.
class SchwachesThema {
  final String kategorie;
  final double fehlerquote;
  final int anzahlVersuche;

  const SchwachesThema({
    required this.kategorie,
    required this.fehlerquote,
    required this.anzahlVersuche,
  });
}

final schwacheThemenProvider = FutureProvider<List<SchwachesThema>>((
  ref,
) async {
  final versuche = await _versucheDesKurses(ref);
  final proKategorie = <String, List<Attempt>>{};
  for (final versuch in versuche) {
    proKategorie.putIfAbsent(versuch.kategorie, () => []).add(versuch);
  }

  final ergebnis = proKategorie.entries.map((eintrag) {
    final fehler = eintrag.value.where((a) => !a.korrekt).length;
    return SchwachesThema(
      kategorie: eintrag.key,
      fehlerquote: fehler / eintrag.value.length,
      anzahlVersuche: eintrag.value.length,
    );
  }).toList();

  ergebnis.sort((a, b) => b.fehlerquote.compareTo(a.fehlerquote));
  return ergebnis.take(5).toList();
});
