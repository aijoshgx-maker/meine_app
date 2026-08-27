import 'dart:math';

import '../../../data/fsrs_card_store.dart';
import '../../../models/frage.dart';
import 'quiz_modus.dart';

/// Das Tagespensum: die Karten, die heute anstehen.
///
/// Ein einziges Budget fuer alles. Wiederholungen und neue Karten getrennt
/// zu deckeln hiess in der Praxis, dass an einem Tag achtzig Karten
/// vorlagen - eine Zahl, vor der man gar nicht erst anfaengt.
///
/// Bewusst ein eigener Typ und nicht nur eine Zahl: Dashboard und Session
/// muessen dasselbe meinen, und die Aufteilung gehoert in den Text auf dem
/// Dashboard ("13 Wiederholungen · 7 neu").
class Tagespensum {
  /// Karten mit gespeichertem Stand, deren Termin erreicht ist.
  final List<Frage> wiederholungen;

  /// Bisher ungesehene Karten, soweit das Tagesbudget noch reicht.
  final List<Frage> neue;

  /// Die Komplexaufgabe des Tages - hoechstens eine, oft keine.
  final List<Frage> komplex;

  const Tagespensum({
    required this.wiederholungen,
    required this.neue,
    this.komplex = const [],
  });

  static const leer = Tagespensum(wiederholungen: [], neue: []);

  int get gesamt => wiederholungen.length + neue.length + komplex.length;

  /// Die Komplexaufgabe zuerst, danach Wiederholungen, zuletzt neue Karten.
  ///
  /// Die mehrstufige Aufgabe steht vorn, weil sie die meiste Aufmerksamkeit
  /// verlangt - und die ist am Anfang einer Session am groessten. Danach
  /// gilt wie bisher: Was man schon einmal wusste, ist am ehesten wieder zu
  /// verlieren; neue Karten fuellen auf, was frei bleibt.
  List<Frage> get fragen => [...komplex, ...wiederholungen, ...neue];
}

// Reine, von Riverpod/Hive entkoppelte Auswahllogik: welche Fragen kommen in
// welcher Reihenfolge in eine Session, je nach QuizModus. Dadurch bleibt der
// QuizSessionController mode-agnostisch und diese Klasse ist ohne
// Provider-Setup unit-testbar.
class QuizFragenAuswahl {
  /// Stellt das Tagespensum zusammen.
  ///
  /// [kartenProTag] ist die Obergrenze fuer den ganzen Tag, nicht je Topf.
  /// [heuteBearbeitet] sind die heute schon beantworteten Fragen; sie gehen
  /// vom Budget ab, damit eine zweite Session nicht noch einmal das volle
  /// Pensum auftischt.
  ///
  /// Ueberfaellige Wiederholungen summieren sich nicht auf. Wer eine Woche
  /// aussetzt, findet am achten Tag genauso [kartenProTag] Karten vor wie am
  /// ersten - nur eben die am laengsten faelligen zuerst. Alles andere fuehrt
  /// zu einem Berg, vor dem man kapituliert.
  ///
  /// Genau ein Platz ist fuer eine Komplexaufgabe reserviert. Sie laeuft
  /// nicht im normalen Topf mit: Zwischen neunzehn Karteikarten wuerde eine
  /// Aufgabe, die zehn Minuten Rechnen kostet, entweder uebersprungen oder
  /// als Stoerung empfunden. Ist sie heute schon erledigt, faellt der Platz
  /// an die uebrigen Karten zurueck.
  Tagespensum tagespensum(
    List<Frage> alle, {
    required Map<String, GespeicherteKarte> kartenstaende,
    required Random zufall,
    required int kartenProTag,
    Set<String> heuteBearbeitet = const {},
    DateTime? jetzt,
  }) {
    final zeitpunkt = jetzt ?? DateTime.now();
    final budget = max(0, kartenProTag - heuteBearbeitet.length);
    if (budget == 0) return Tagespensum.leer;

    final komplex = _komplexaufgabeDesTages(
      alle,
      kartenstaende: kartenstaende,
      zufall: zufall,
      heuteBearbeitet: heuteBearbeitet,
      jetzt: zeitpunkt,
    );

    // Komplexaufgaben laufen ausschliesslich ueber ihren eigenen Platz -
    // sonst koennten am selben Tag mehrere davon im Pensum landen.
    final faellige = <Frage>[];
    final ungesehen = <Frage>[];
    for (final frage in alle) {
      if (frage.komplex) continue;
      final stand = kartenstaende[frage.id];
      if (stand == null) {
        ungesehen.add(frage);
      } else if (!stand.card.due.isAfter(zeitpunkt)) {
        faellige.add(frage);
      }
    }

    // Die am laengsten ueberfaellige Karte zuerst: Sie ist am ehesten wieder
    // verloren. Gemischt wird nur, was am selben Termin haengt.
    faellige.shuffle(zufall);
    faellige.sort(
      (a, b) => kartenstaende[a.id]!.card.due.compareTo(
        kartenstaende[b.id]!.card.due,
      ),
    );
    ungesehen.shuffle(zufall);

    final rest = budget - komplex.length;
    final wiederholungen = faellige.take(rest).toList();
    final neue = ungesehen.take(rest - wiederholungen.length).toList();

    return Tagespensum(
      wiederholungen: wiederholungen,
      neue: neue,
      komplex: komplex,
    );
  }

  /// Waehlt hoechstens eine mehrstufige Aufgabe fuer heute.
  ///
  /// Faellige zuerst, die am laengsten ueberfaellige vorneweg; ist keine
  /// faellig, kommt eine noch ungesehene an die Reihe. Wurde heute schon
  /// eine bearbeitet, bleibt es dabei - eine am Tag ist der Sinn der Sache.
  List<Frage> _komplexaufgabeDesTages(
    List<Frage> alle, {
    required Map<String, GespeicherteKarte> kartenstaende,
    required Random zufall,
    required Set<String> heuteBearbeitet,
    required DateTime jetzt,
  }) {
    final kandidaten = alle.where((f) => f.komplex).toList();
    if (kandidaten.isEmpty) return const [];
    if (kandidaten.any((f) => heuteBearbeitet.contains(f.id))) return const [];

    final faellige = kandidaten.where((f) {
      final stand = kartenstaende[f.id];
      return stand != null && !stand.card.due.isAfter(jetzt);
    }).toList();

    if (faellige.isNotEmpty) {
      faellige.shuffle(zufall);
      faellige.sort(
        (a, b) => kartenstaende[a.id]!.card.due.compareTo(
          kartenstaende[b.id]!.card.due,
        ),
      );
      return [faellige.first];
    }

    final ungesehen = kandidaten
        .where((f) => kartenstaende[f.id] == null)
        .toList();
    if (ungesehen.isEmpty) return const [];
    ungesehen.shuffle(zufall);
    return [ungesehen.first];
  }

  List<Frage> waehleFragen(
    QuizModus modus,
    List<Frage> alle, {
    required Map<String, GespeicherteKarte> kartenstaende,
    required Random zufall,
    int kartenProTag = 20,
    Set<String> heuteBearbeitet = const {},
  }) {
    switch (modus.art) {
      case QuizArt.freiUebung:
        return List.of(alle);
      case QuizArt.heuteFaellig:
        return tagespensum(
          alle,
          kartenstaende: kartenstaende,
          zufall: zufall,
          kartenProTag: kartenProTag,
          heuteBearbeitet: heuteBearbeitet,
        ).fragen;
      case QuizArt.fehlerquellen:
        // Karten, die beim letzten Mal "sicher, aber falsch" waren. Das Flag
        // wird bei jeder Bewertung neu gesetzt - eine richtig beantwortete
        // Frage faellt also von selbst wieder heraus, die Menge leert sich.
        final schwachstellen = alle
            .where((f) => kartenstaende[f.id]?.hochkonfidentFalsch == true)
            .toList();
        schwachstellen.shuffle(zufall);
        return schwachstellen;
      case QuizArt.themenVertiefung:
        final auswahl = alle
            .where((f) => f.kategorie == modus.kategorie)
            .toList();
        auswahl.shuffle(zufall);
        return auswahl;
      case QuizArt.pruefungssimulation:
        // Nur die Fragen der gewählten Prüfung, in der originalen Reihenfolge.
        final pruefungsId = modus.pruefungsId!;
        final pruefungsFragen =
            alle.where((f) => f.pruefung == pruefungsId).toList()..sort(
              (a, b) => (a.pruefungReihenfolge ?? 0).compareTo(
                b.pruefungReihenfolge ?? 0,
              ),
            );
        return pruefungsFragen;
    }
  }
}
