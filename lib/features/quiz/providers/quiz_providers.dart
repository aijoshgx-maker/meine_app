import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/spaced_repetition/fsrs_scheduler.dart';
import '../../../data/frage_repository.dart';
import '../../../data/fsrs_card_store.dart';
import '../../../models/frage.dart';

final frageRepositoryProvider = Provider((ref) => FrageRepository());
final fsrsSchedulerProvider = Provider((ref) => FsrsScheduler());
final fsrsCardStoreProvider = Provider((ref) => FsrsCardStore());

final fragenProvider = FutureProvider<List<Frage>>(
  (ref) => ref.read(frageRepositoryProvider).laden(),
);

// Selbsteinschätzung der Sicherheit, abgefragt vor dem Aufdecken (Prinzip:
// Metakognition & Konfidenz-Kalibrierung).
enum Konfidenz { sicher, unsicher, geraten }

// Ablaufphase der aktuell angezeigten Frage, steuert was der QuizScreen zeigt.
enum FragePhase { antworten, konfidenz, aufgedeckt }

class AntwortZustand {
  final FragePhase phase;
  final Set<int> ausgewaehlteIndizes; // single/multi/wahrfalsch
  final Map<int, int>
  zuordnungsAuswahl; // zuordnung: linker Index -> Options-Index
  final String freitext; // rechnung/kurzantwort
  final Konfidenz? konfidenz;
  final bool? korrekt; // erst nach aufdecken() gesetzt
  final String selbsterklaerung;

  const AntwortZustand({
    this.phase = FragePhase.antworten,
    this.ausgewaehlteIndizes = const {},
    this.zuordnungsAuswahl = const {},
    this.freitext = '',
    this.konfidenz,
    this.korrekt,
    this.selbsterklaerung = '',
  });

  AntwortZustand copyWith({
    FragePhase? phase,
    Set<int>? ausgewaehlteIndizes,
    Map<int, int>? zuordnungsAuswahl,
    String? freitext,
    Konfidenz? konfidenz,
    bool? korrekt,
    String? selbsterklaerung,
  }) {
    return AntwortZustand(
      phase: phase ?? this.phase,
      ausgewaehlteIndizes: ausgewaehlteIndizes ?? this.ausgewaehlteIndizes,
      zuordnungsAuswahl: zuordnungsAuswahl ?? this.zuordnungsAuswahl,
      freitext: freitext ?? this.freitext,
      konfidenz: konfidenz ?? this.konfidenz,
      korrekt: korrekt ?? this.korrekt,
      selbsterklaerung: selbsterklaerung ?? this.selbsterklaerung,
    );
  }
}

class QuizSessionState {
  final List<Frage> fragen;
  final int index;
  final AntwortZustand antwort;
  final bool fertig;

  const QuizSessionState({
    required this.fragen,
    this.index = 0,
    this.antwort = const AntwortZustand(),
    this.fertig = false,
  });

  Frage? get aktuelleFrage =>
      (fertig || index >= fragen.length) ? null : fragen[index];

  QuizSessionState copyWith({
    int? index,
    AntwortZustand? antwort,
    bool? fertig,
  }) {
    return QuizSessionState(
      fragen: fragen,
      index: index ?? this.index,
      antwort: antwort ?? this.antwort,
      fertig: fertig ?? this.fertig,
    );
  }
}

final quizSessionProvider =
    AsyncNotifierProvider<QuizSessionController, QuizSessionState>(
      QuizSessionController.new,
    );

class QuizSessionController extends AsyncNotifier<QuizSessionState> {
  @override
  Future<QuizSessionState> build() async {
    final fragen = await ref.watch(fragenProvider.future);
    return QuizSessionState(fragen: fragen);
  }

  void auswahlUmschalten(int optionsIndex) {
    final aktuell = state.value;
    final frage = aktuell?.aktuelleFrage;
    if (aktuell == null || frage == null) return;

    final Set<int> neue;
    if (frage.typ == 'single' || frage.typ == 'wahrfalsch') {
      neue = {optionsIndex};
    } else {
      neue = Set.of(aktuell.antwort.ausgewaehlteIndizes);
      neue.contains(optionsIndex)
          ? neue.remove(optionsIndex)
          : neue.add(optionsIndex);
    }
    _aktualisiereAntwort(aktuell.antwort.copyWith(ausgewaehlteIndizes: neue));
  }

  void zuordnungAuswaehlen(int linkerIndex, int optionsIndex) {
    final aktuell = state.value;
    if (aktuell == null) return;
    final neue = Map<int, int>.of(aktuell.antwort.zuordnungsAuswahl);
    neue[linkerIndex] = optionsIndex;
    _aktualisiereAntwort(aktuell.antwort.copyWith(zuordnungsAuswahl: neue));
  }

  void freitextSetzen(String text) {
    final aktuell = state.value;
    if (aktuell == null) return;
    _aktualisiereAntwort(aktuell.antwort.copyWith(freitext: text));
  }

  // Schließt den Recall-/Auswahlversuch ab und schaltet zur Konfidenz-Abfrage.
  void weiterZuKonfidenz() {
    final aktuell = state.value;
    if (aktuell == null) return;
    _aktualisiereAntwort(aktuell.antwort.copyWith(phase: FragePhase.konfidenz));
  }

  void konfidenzSetzen(Konfidenz konfidenz) {
    final aktuell = state.value;
    if (aktuell == null) return;
    _aktualisiereAntwort(aktuell.antwort.copyWith(konfidenz: konfidenz));
  }

  void aufdecken() {
    final aktuell = state.value;
    final frage = aktuell?.aktuelleFrage;
    if (aktuell == null || frage == null) return;

    final korrekt = _pruefeKorrektheit(frage, aktuell.antwort);
    _aktualisiereAntwort(
      aktuell.antwort.copyWith(phase: FragePhase.aufgedeckt, korrekt: korrekt),
    );
  }

  void selbsterklaerungSetzen(String text) {
    final aktuell = state.value;
    if (aktuell == null) return;
    _aktualisiereAntwort(aktuell.antwort.copyWith(selbsterklaerung: text));
  }

  // FSRS-Bewertung (Nochmal/Schwer/Gut/Leicht), persistiert den neuen
  // Kartenstand und springt zur nächsten Frage.
  Future<void> bewerten(Rating rating) async {
    final aktuell = state.value;
    final frage = aktuell?.aktuelleFrage;
    if (aktuell == null || frage == null) return;

    final scheduler = ref.read(fsrsSchedulerProvider);
    final store = ref.read(fsrsCardStoreProvider);
    final jetzt = DateTime.now();

    final bisherigerStand = store.kartenStandFuer(frage.id);
    final karte = bisherigerStand?.card ?? FsrsCard.newCard(now: jetzt);

    var neueKarte = scheduler.review(karte, rating, jetzt);

    // Hypercorrection-Effekt: hochkonfident-falsche Antworten kommen früher
    // wieder, indem das berechnete Intervall halbiert wird (min. 1 Tag).
    final hochkonfidentFalsch =
        aktuell.antwort.konfidenz == Konfidenz.sicher &&
        aktuell.antwort.korrekt == false;
    if (hochkonfidentFalsch) {
      final intervallTage = neueKarte.due.difference(jetzt).inDays;
      final verkuerzteTage = math.max(1, (intervallTage / 2).round());
      neueKarte = neueKarte.copyWith(
        due: jetzt.add(Duration(days: verkuerzteTage)),
      );
    }

    await store.speichern(
      frage.id,
      GespeicherteKarte(
        card: neueKarte,
        hochkonfidentFalsch: hochkonfidentFalsch,
      ),
    );

    final naechsterIndex = aktuell.index + 1;
    state = AsyncData(
      naechsterIndex >= aktuell.fragen.length
          ? aktuell.copyWith(fertig: true)
          : aktuell.copyWith(
              index: naechsterIndex,
              antwort: const AntwortZustand(),
            ),
    );
  }

  void _aktualisiereAntwort(AntwortZustand neueAntwort) {
    final aktuell = state.value;
    if (aktuell == null) return;
    state = AsyncData(aktuell.copyWith(antwort: neueAntwort));
  }

  bool _pruefeKorrektheit(Frage frage, AntwortZustand antwort) {
    switch (frageTypVon(frage.typ)) {
      case FrageTyp.single:
      case FrageTyp.wahrfalsch:
        return antwort.ausgewaehlteIndizes.length == 1 &&
            frage.richtigeIndizes.contains(antwort.ausgewaehlteIndizes.first);
      case FrageTyp.multi:
        return setEquals(
          antwort.ausgewaehlteIndizes,
          frage.richtigeIndizes.toSet(),
        );
      case FrageTyp.zuordnung:
        for (var i = 0; i < frage.richtigeIndizes.length; i++) {
          if (antwort.zuordnungsAuswahl[i] != frage.richtigeIndizes[i]) {
            return false;
          }
        }
        return true;
      case FrageTyp.rechnung:
        final wert = double.tryParse(
          antwort.freitext.trim().replaceAll(',', '.'),
        );
        if (wert == null || frage.loesungswert == null) return false;
        final toleranz = frage.toleranz ?? 0;
        return (wert - frage.loesungswert!).abs() <= toleranz;
      case FrageTyp.kurzantwort:
        final eingabe = _normalisieren(antwort.freitext);
        return frage.akzeptierteKurzantworten.any(
          (a) => _normalisieren(a) == eingabe,
        );
    }
  }

  String _normalisieren(String text) => text.trim().toLowerCase();
}
