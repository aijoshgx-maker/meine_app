import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/matching/antwort_matcher.dart';
import '../../../core/quiz/options_shuffle.dart';
import '../../../core/spaced_repetition/fsrs_scheduler.dart';
import '../../../data/attempt_history_store.dart';
import '../../../data/fsrs_card_store.dart';
import '../../../data/store_providers.dart';
import '../../../models/frage.dart';
import '../../../models/konfidenz.dart';
import '../../kurse/providers/kurs_providers.dart';
import 'quiz_fragen_auswahl.dart';
import 'quiz_modus.dart';

export '../../../data/store_providers.dart';
export '../../../models/konfidenz.dart';
export 'quiz_modus.dart';

final quizFragenAuswahlProvider = Provider((ref) => QuizFragenAuswahl());

// Fragen des aktiven Kurses. Wechselt der Kurs, lädt hier alles neu -
// inklusive aller abgeleiteten Provider (Session, Dashboard, Themen).
final fragenProvider = FutureProvider<List<Frage>>(
  (ref) async => (await ref.watch(aktivesPaketProvider.future)).fragen,
);

// Anzahl der heute fälligen Karten im aktiven Kurs. Wird vom Dashboard als
// Badge genutzt. Zeigt max. _tageslimit fällige Karten an — verhindert den
// visuellen Overflow-Effekt, wenn mehrere Tage ausgelassen wurden.
final faelligeAnzahlProvider = FutureProvider<int>((ref) async {
  ref.watch(lernfortschrittVersionProvider);
  final paket = await ref.watch(aktivesPaketProvider.future);
  final kartenstaende = ref
      .read(fsrsCardStoreProvider)
      .alleKartenstaende(paket.kurs.id);
  final jetzt = DateTime.now();
  final anzahl = paket.fragen.where((f) {
    final stand = kartenstaende[f.id];
    if (stand == null) return true;
    return !stand.card.due.isAfter(jetzt);
  }).length;
  return anzahl.clamp(0, 30);
});

// Ablaufphase der aktuell angezeigten Frage, steuert was der QuizScreen zeigt.
enum FragePhase { antworten, konfidenz, aufgedeckt }

class AntwortZustand {
  final FragePhase phase;
  final Set<int>
  ausgewaehlteIndizes; // single/multi/wahrfalsch (0=Falsch,1=Wahr)
  final Map<int, int>
  zuordnungsAuswahl; // zuordnung: linkerIdx → Original-Index von paare[].rechts
  final String freitext; // rechnung/kurzantwort
  final Map<int, String> lueckenAntworten; // lueckentext: Lückenindex → Eingabe
  final List<int>
  reihenfolgeAuswahl; // reihenfolge: aktuelle Sortierung als Optionsindizes
  // Anzeigereihenfolge (Original-Indizes), pro Frage-Anzeige neu gemischt.
  // An Position i steht der Original-Index des dort angezeigten Elements.
  final List<int> optionenReihenfolge; // single/multi: für frage.optionen
  final List<int> zuordnungRechteReihenfolge; // zuordnung: für paare[].rechts
  final Konfidenz? konfidenz;
  final bool? korrekt;
  final String selbsterklaerung;

  const AntwortZustand({
    this.phase = FragePhase.antworten,
    this.ausgewaehlteIndizes = const {},
    this.zuordnungsAuswahl = const {},
    this.freitext = '',
    this.lueckenAntworten = const {},
    this.reihenfolgeAuswahl = const [],
    this.optionenReihenfolge = const [],
    this.zuordnungRechteReihenfolge = const [],
    this.konfidenz,
    this.korrekt,
    this.selbsterklaerung = '',
  });

  // Neuer Zustand für den ersten Aufruf einer Frage: mischt die
  // Anzeigereihenfolgen frisch (neuer Seed pro Anzeige, nicht pro Session)
  // und initialisiert bei "reihenfolge"-Fragen die Startanordnung ebenfalls
  // gemischt statt in Original-Reihenfolge.
  factory AntwortZustand.fuerFrage(Frage frage, math.Random zufall) {
    final optionenReihenfolge = berechneAnzeigeReihenfolge(
      frage.optionen.length,
      zufall,
      istAnker: (i) => istAnkerOptionstext(frage.optionen[i]),
    );
    final zuordnungRechteReihenfolge = berechneAnzeigeReihenfolge(
      frage.paare.length,
      zufall,
      istAnker: (i) => istAnkerOptionstext(frage.paare[i].rechts),
    );
    final reihenfolgeStart = frageTypVon(frage.typ) == FrageTyp.reihenfolge
        ? berechneAnzeigeReihenfolge(frage.optionen.length, zufall)
        : const <int>[];
    return AntwortZustand(
      optionenReihenfolge: optionenReihenfolge,
      zuordnungRechteReihenfolge: zuordnungRechteReihenfolge,
      reihenfolgeAuswahl: reihenfolgeStart,
    );
  }

  AntwortZustand copyWith({
    FragePhase? phase,
    Set<int>? ausgewaehlteIndizes,
    Map<int, int>? zuordnungsAuswahl,
    String? freitext,
    Map<int, String>? lueckenAntworten,
    List<int>? reihenfolgeAuswahl,
    Konfidenz? konfidenz,
    bool? korrekt,
    String? selbsterklaerung,
  }) {
    return AntwortZustand(
      phase: phase ?? this.phase,
      ausgewaehlteIndizes: ausgewaehlteIndizes ?? this.ausgewaehlteIndizes,
      zuordnungsAuswahl: zuordnungsAuswahl ?? this.zuordnungsAuswahl,
      freitext: freitext ?? this.freitext,
      lueckenAntworten: lueckenAntworten ?? this.lueckenAntworten,
      reihenfolgeAuswahl: reihenfolgeAuswahl ?? this.reihenfolgeAuswahl,
      optionenReihenfolge: optionenReihenfolge,
      zuordnungRechteReihenfolge: zuordnungRechteReihenfolge,
      konfidenz: konfidenz ?? this.konfidenz,
      korrekt: korrekt ?? this.korrekt,
      selbsterklaerung: selbsterklaerung ?? this.selbsterklaerung,
    );
  }
}

class QuizSessionState {
  final QuizModus modus;
  final List<Frage> fragen;
  final int index;
  final AntwortZustand antwort;
  final int richtigBeantwortet;
  final int gesamtFragen; // Ursprüngliche Fragenzahl (für Endanzeige)
  final Set<String>
  uebersprungeneIds; // IDs bereits einmal übersprungener Fragen
  final bool fertig;

  QuizSessionState({
    required this.modus,
    required this.fragen,
    this.index = 0,
    this.antwort = const AntwortZustand(),
    this.richtigBeantwortet = 0,
    int? gesamtFragen,
    Set<String>? uebersprungeneIds,
    this.fertig = false,
  }) : gesamtFragen = gesamtFragen ?? fragen.length,
       uebersprungeneIds = uebersprungeneIds ?? const {};

  Frage? get aktuelleFrage =>
      (fertig || index >= fragen.length) ? null : fragen[index];

  QuizSessionState copyWith({
    List<Frage>? fragen,
    int? index,
    AntwortZustand? antwort,
    int? richtigBeantwortet,
    int? gesamtFragen,
    Set<String>? uebersprungeneIds,
    bool? fertig,
  }) {
    return QuizSessionState(
      modus: modus,
      fragen: fragen ?? this.fragen,
      index: index ?? this.index,
      antwort: antwort ?? this.antwort,
      richtigBeantwortet: richtigBeantwortet ?? this.richtigBeantwortet,
      gesamtFragen: gesamtFragen ?? this.gesamtFragen,
      uebersprungeneIds: uebersprungeneIds ?? this.uebersprungeneIds,
      fertig: fertig ?? this.fertig,
    );
  }
}

final quizSessionProvider =
    AsyncNotifierProvider.family<
      QuizSessionController,
      QuizSessionState,
      QuizModus
    >((modus) => QuizSessionController(modus));

class QuizSessionController extends AsyncNotifier<QuizSessionState> {
  final QuizModus modus;

  // Kurs, zu dem diese Session gehört. In build() gesetzt und beim Speichern
  // gebraucht, damit der Lernfortschritt beim richtigen Kurs landet.
  late String _kursId;

  QuizSessionController(this.modus);

  @override
  Future<QuizSessionState> build() async {
    final paket = await ref.watch(aktivesPaketProvider.future);
    _kursId = paket.kurs.id;
    final kartenstaende = ref
        .read(fsrsCardStoreProvider)
        .alleKartenstaende(_kursId);
    final fragen = ref
        .read(quizFragenAuswahlProvider)
        .waehleFragen(
          modus,
          paket.fragen,
          kartenstaende: kartenstaende,
          zufall: math.Random(),
        );
    final antwort = fragen.isEmpty
        ? const AntwortZustand()
        : AntwortZustand.fuerFrage(fragen.first, math.Random());
    return QuizSessionState(modus: modus, fragen: fragen, antwort: antwort);
  }

  // Beendet die Session sofort (z.B. wenn das Zeitlimit einer
  // Prüfungssimulation abläuft).
  void beenden() {
    final aktuell = state.value;
    if (aktuell == null) return;
    state = AsyncData(aktuell.copyWith(fertig: true));
  }

  void auswahlUmschalten(int optionsIndex) {
    final aktuell = state.value;
    final frage = aktuell?.aktuelleFrage;
    if (aktuell == null || frage == null) return;

    HapticFeedback.selectionClick();

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

  void lueckeSetzen(int index, String text) {
    final aktuell = state.value;
    if (aktuell == null) return;
    final neue = Map<int, String>.of(aktuell.antwort.lueckenAntworten);
    neue[index] = text;
    _aktualisiereAntwort(aktuell.antwort.copyWith(lueckenAntworten: neue));
  }

  void reihenfolgeAktualisieren(List<int> neueReihenfolge) {
    final aktuell = state.value;
    if (aktuell == null) return;
    _aktualisiereAntwort(
      aktuell.antwort.copyWith(reihenfolgeAuswahl: neueReihenfolge),
    );
  }

  // Schließt den Recall-/Auswahlversuch ab und schaltet zur Konfidenz-Abfrage.
  // Im Prüfungssimulations-Modus wird die Konfidenz-Phase übersprungen.
  void weiterZuKonfidenz() {
    final aktuell = state.value;
    if (aktuell == null) return;
    if (modus.art == QuizArt.pruefungssimulation) {
      final frage = aktuell.aktuelleFrage;
      if (frage == null) return;
      final korrekt = _pruefeKorrektheit(frage, aktuell.antwort);
      korrekt ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
      _aktualisiereAntwort(
        aktuell.antwort.copyWith(
          phase: FragePhase.aufgedeckt,
          korrekt: korrekt,
          konfidenz: Konfidenz.geraten,
        ),
      );
      return;
    }
    _aktualisiereAntwort(aktuell.antwort.copyWith(phase: FragePhase.konfidenz));
  }

  void konfidenzSetzen(Konfidenz konfidenz) {
    final aktuell = state.value;
    if (aktuell == null) return;
    _aktualisiereAntwort(aktuell.antwort.copyWith(konfidenz: konfidenz));
  }

  // Setzt Konfidenz und deckt sofort auf (Single-Tap aus KonfidenzAuswahl).
  void konfidenzUndAufdecken(Konfidenz konfidenz) {
    final aktuell = state.value;
    final frage = aktuell?.aktuelleFrage;
    if (aktuell == null || frage == null) return;
    final korrekt = _pruefeKorrektheit(frage, aktuell.antwort);
    korrekt ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
    _aktualisiereAntwort(
      aktuell.antwort.copyWith(
        konfidenz: konfidenz,
        phase: FragePhase.aufgedeckt,
        korrekt: korrekt,
      ),
    );
  }

  void aufdecken() {
    final aktuell = state.value;
    final frage = aktuell?.aktuelleFrage;
    if (aktuell == null || frage == null) return;

    final korrekt = _pruefeKorrektheit(frage, aktuell.antwort);
    korrekt ? HapticFeedback.lightImpact() : HapticFeedback.mediumImpact();
    _aktualisiereAntwort(
      aktuell.antwort.copyWith(phase: FragePhase.aufgedeckt, korrekt: korrekt),
    );
  }

  // Verschiebt die aktuelle Frage ans Ende der Queue (erster Übersprung) oder
  // entfernt sie endgültig (zweiter Übersprung). Kein FSRS, kein Bewertungslog.
  void ueberspringen() {
    final aktuell = state.value;
    final frage = aktuell?.aktuelleFrage;
    if (aktuell == null || frage == null) return;

    final bereitsMalUebersprungen = aktuell.uebersprungeneIds.contains(
      frage.id,
    );
    final neueFragen = List<Frage>.of(aktuell.fragen);
    neueFragen.removeAt(aktuell.index);

    if (!bereitsMalUebersprungen) {
      // Erster Übersprung: Frage ans Ende der Warteschlange anhängen.
      neueFragen.add(frage);
    }
    // Zweiter Übersprung: endgültig entfernen.

    final neueUebersprungene = Set<String>.of(aktuell.uebersprungeneIds)
      ..add(frage.id);

    if (neueFragen.isEmpty) {
      state = AsyncData(aktuell.copyWith(fertig: true));
      return;
    }

    final neuerIndex = aktuell.index.clamp(0, neueFragen.length - 1);
    state = AsyncData(
      aktuell.copyWith(
        fragen: neueFragen,
        index: neuerIndex,
        antwort: AntwortZustand.fuerFrage(
          neueFragen[neuerIndex],
          math.Random(),
        ),
        uebersprungeneIds: neueUebersprungene,
      ),
    );
  }

  void selbsterklaerungSetzen(String text) {
    final aktuell = state.value;
    if (aktuell == null) return;
    _aktualisiereAntwort(aktuell.antwort.copyWith(selbsterklaerung: text));
  }

  // FSRS-Bewertung (Nochmal/Schwer/Gut/Leicht), persistiert den neuen
  // Kartenstand und springt zur nächsten Frage.
  // Im Prüfungssimulations-Modus: kein FSRS, kein Attempt-Log – nur zählen.
  Future<void> bewerten(Rating rating) async {
    final aktuell = state.value;
    final frage = aktuell?.aktuelleFrage;
    if (aktuell == null || frage == null) return;

    if (modus.art == QuizArt.pruefungssimulation) {
      final neuerZaehler =
          aktuell.richtigBeantwortet +
          (aktuell.antwort.korrekt == true ? 1 : 0);
      final naechsterIndex = aktuell.index + 1;
      state = AsyncData(
        naechsterIndex >= aktuell.fragen.length
            ? aktuell.copyWith(fertig: true, richtigBeantwortet: neuerZaehler)
            : aktuell.copyWith(
                index: naechsterIndex,
                antwort: AntwortZustand.fuerFrage(
                  aktuell.fragen[naechsterIndex],
                  math.Random(),
                ),
                richtigBeantwortet: neuerZaehler,
              ),
      );
      return;
    }

    final scheduler = ref.read(fsrsSchedulerProvider);
    final store = ref.read(fsrsCardStoreProvider);
    final jetzt = DateTime.now();

    final bisherigerStand = store.kartenStandFuer(_kursId, frage.id);
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
      _kursId,
      frage.id,
      GespeicherteKarte(
        card: neueKarte,
        hochkonfidentFalsch: hochkonfidentFalsch,
      ),
    );

    await ref
        .read(attemptHistoryStoreProvider)
        .anhaengen(
          Attempt(
            kursId: _kursId,
            frageId: frage.id,
            zeitpunkt: jetzt,
            konfidenz: aktuell.antwort.konfidenz ?? Konfidenz.geraten,
            korrekt: aktuell.antwort.korrekt ?? false,
            bereich: frage.bereich,
            kategorie: frage.kategorie,
            selbsterklaerung: aktuell.antwort.selbsterklaerung.trim().isEmpty
                ? null
                : aktuell.antwort.selbsterklaerung.trim(),
          ),
        );

    // Dashboard-Auswertungen lesen direkt aus Hive und würden sonst erst
    // nach einem Neustart aktualisieren.
    ref.read(lernfortschrittVersionProvider.notifier).melden();

    final neuerZaehler =
        aktuell.richtigBeantwortet + (aktuell.antwort.korrekt == true ? 1 : 0);
    final naechsterIndex = aktuell.index + 1;
    state = AsyncData(
      naechsterIndex >= aktuell.fragen.length
          ? aktuell.copyWith(fertig: true, richtigBeantwortet: neuerZaehler)
          : aktuell.copyWith(
              index: naechsterIndex,
              antwort: AntwortZustand.fuerFrage(
                aktuell.fragen[naechsterIndex],
                math.Random(),
              ),
              richtigBeantwortet: neuerZaehler,
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
        return antwort.ausgewaehlteIndizes.length == 1 &&
            frage.richtigeIndizes.contains(antwort.ausgewaehlteIndizes.first);
      case FrageTyp.wahrfalsch:
        if (frage.wahr != null) {
          // Neues Format: 1=Wahr-Button gedrückt, 0=Falsch-Button gedrückt
          final wahrGewaehlt = antwort.ausgewaehlteIndizes.contains(1);
          return wahrGewaehlt == frage.wahr;
        }
        // Altes Fallback: richtigeIndizes mit optionen ["Wahr","Falsch"]
        return antwort.ausgewaehlteIndizes.length == 1 &&
            frage.richtigeIndizes.contains(antwort.ausgewaehlteIndizes.first);
      case FrageTyp.multi:
        return setEquals(
          antwort.ausgewaehlteIndizes,
          frage.richtigeIndizes.toSet(),
        );
      case FrageTyp.zuordnung:
        if (frage.paare.isNotEmpty) {
          // Neues Format: zuordnungsAuswahl[i] ist der Original-Index von
          // paare[].rechts, den der Nutzer für den linken Eintrag i gewählt
          // hat (unabhängig von der - ggf. gemischten - Anzeigereihenfolge).
          for (var i = 0; i < frage.paare.length; i++) {
            final ausgewaehlt = antwort.zuordnungsAuswahl[i];
            if (ausgewaehlt == null) return false;
            if (frage.paare[ausgewaehlt].rechts != frage.paare[i].rechts) {
              return false;
            }
          }
          return true;
        }
        // Altes Fallback: richtigeIndizes
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
        return AntwortMatcher.passtGegenListe(
          antwort.freitext,
          frage.akzeptierteKurzantworten,
        );
      case FrageTyp.lueckentext:
        for (var i = 0; i < frage.luecken.length; i++) {
          final eingabe = antwort.lueckenAntworten[i] ?? '';
          if (!AntwortMatcher.passtGegenListe(eingabe, frage.luecken[i])) {
            return false;
          }
        }
        return true;
      case FrageTyp.reihenfolge:
        final auswahl = antwort.reihenfolgeAuswahl;
        if (auswahl.length != frage.reihenfolge.length) return false;
        for (var i = 0; i < frage.reihenfolge.length; i++) {
          if (auswahl[i] != frage.reihenfolge[i]) return false;
        }
        return true;
    }
  }
}
