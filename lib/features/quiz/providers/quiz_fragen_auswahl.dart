import 'dart:math';

import '../../../data/fsrs_card_store.dart';
import '../../../models/frage.dart';
import 'quiz_modus.dart';

/// Das Tagespensum: die Karten, die heute anstehen.
///
/// Zwei getrennte Toepfe mit unterschiedlicher Rolle:
///
/// - [neue] sind bisher ungesehene Fragen. Sie laufen der Reihe nach durch,
///   [kartenProTag] Stueck am Tag. Das ist das eigentliche Kontingent.
/// - [wiederholungen] sind Karten, die man selbst mit "Nochmal" auf
///   Wiedervorlage gelegt hat. Sie kommen OBENDRAUF, nicht aus dem
///   Kontingent - wer eine Frage zurueckgelegt hat, will sie wiedersehen,
///   ohne dass dafuer eine neue ausfaellt.
class Tagespensum {
  /// Selbst zurueckgelegte Karten ("Nochmal"). Zaehlen nicht aufs Kontingent.
  final List<Frage> wiederholungen;

  /// Bisher ungesehene Karten, so viele wie das Tagesbudget hergibt.
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

  /// Die Komplexaufgabe zuerst, danach die Wiedervorlage, zuletzt Neues.
  ///
  /// Die mehrstufige Aufgabe steht vorn, weil sie die meiste Aufmerksamkeit
  /// verlangt - und die ist am Anfang am groessten. Die zurueckgelegten
  /// Karten davor, weil man sie bewusst noch einmal sehen wollte; neues
  /// Material danach.
  List<Frage> get fragen => [...komplex, ...wiederholungen, ...neue];
}

// Reine, von Riverpod/Hive entkoppelte Auswahllogik: welche Fragen kommen in
// welcher Reihenfolge in eine Session, je nach QuizModus. Dadurch bleibt der
// QuizSessionController mode-agnostisch und diese Klasse ist ohne
// Provider-Setup unit-testbar.
class QuizFragenAuswahl {
  /// Stellt das Tagespensum zusammen.
  ///
  /// [kartenProTag] begrenzt die NEUEN Fragen - der Kurs laeuft damit in
  /// `Fragenzahl / kartenProTag` Tagen einmal durch. [neueHeuteSchon] geht
  /// davon ab, damit eine zweite Session am selben Tag nicht noch einmal das
  /// volle Kontingent auftischt.
  ///
  /// Wiederholt wird nur, was ausdruecklich mit "Nochmal" bewertet wurde.
  /// Diese Karten kommen zusaetzlich zum Kontingent und bleiben, bis sie
  /// einmal anders bewertet werden. Ein Terminplan, der von sich aus Karten
  /// zurueckholt, existiert nicht mehr.
  ///
  /// [heuteBearbeitet] haelt fest, was heute schon dran war - eine gerade
  /// beantwortete Wiedervorlage soll nicht in derselben Sitzung wieder
  /// auftauchen.
  ///
  /// Genau ein Platz ist zusaetzlich fuer eine Komplexaufgabe reserviert.
  /// Sie laeuft nicht im normalen Topf mit: Zwischen neunzehn Karteikarten
  /// wuerde eine Aufgabe, die zehn Minuten Rechnen kostet, entweder
  /// uebersprungen oder als Stoerung empfunden.
  Tagespensum tagespensum(
    List<Frage> alle, {
    required Map<String, GespeicherteKarte> kartenstaende,
    required Random zufall,
    required int kartenProTag,
    Set<String> heuteBearbeitet = const {},
    int neueHeuteSchon = 0,
    DateTime? jetzt,
  }) {
    final komplex = _komplexaufgabeDesTages(
      alle,
      kartenstaende: kartenstaende,
      zufall: zufall,
      heuteBearbeitet: heuteBearbeitet,
      jetzt: jetzt ?? DateTime.now(),
    );

    // Komplexaufgaben laufen ausschliesslich ueber ihren eigenen Platz -
    // sonst koennten am selben Tag mehrere davon im Pensum landen.
    final zurueckgelegt = <Frage>[];
    final ungesehen = <Frage>[];
    for (final frage in alle) {
      if (frage.komplex) continue;
      if (heuteBearbeitet.contains(frage.id)) continue;
      final stand = kartenstaende[frage.id];
      if (stand == null) {
        ungesehen.add(frage);
      } else if (stand.nochmal) {
        zurueckgelegt.add(frage);
      }
    }

    zurueckgelegt.shuffle(zufall);
    ungesehen.shuffle(zufall);

    // Die Komplexaufgabe belegt einen Platz des Kontingents, keinen
    // zusaetzlichen: Sie ist selbst neues Material. Nur die Wiedervorlage
    // kommt obendrauf, weil man sie ausdruecklich zurueckgelegt hat.
    final neuBudget = max(0, kartenProTag - neueHeuteSchon - komplex.length);

    return Tagespensum(
      wiederholungen: zurueckgelegt,
      neue: ungesehen.take(neuBudget).toList(),
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
    int neueHeuteSchon = 0,
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
          neueHeuteSchon: neueHeuteSchon,
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
