import 'dart:math' as math;

/// FSRS (Free Spaced Repetition Scheduler), Variante 4.5.
///
/// Eigenständige, storage-agnostische Implementierung. Kennt weder Hive noch
/// das Frage-Datenmodell – sie rechnet ausschließlich mit [FsrsCard].
/// Die App-Schicht speichert/lädt [FsrsCard] (z.B. via Hive) und ruft pro
/// Bewertung [review] auf.
///
/// Modell (Kurzfassung):
///  - stability (S): Tage, Maß für die Gedächtnisstabilität.
///  - difficulty (D): 1..10, intrinsische Schwierigkeit der Karte.
///  - retrievability (R): Abrufwahrscheinlichkeit zum Zeitpunkt t.
/// Das nächste Fälligkeitsintervall wird so gewählt, dass R zum Fälligkeitstag
/// dem Zielwert [requestRetention] entspricht (Standard 0.9 = 90 %).
///
/// Quelle der Formeln: offener FSRS-4.5-Algorithmus. Die Default-Gewichte
/// stammen aus dem Standard-Parametersatz und können später durch optimierte,
/// nutzerindividuelle Gewichte ersetzt werden.

enum Rating {
  again, // = 1 (vergessen / Lapse)
  hard, //  = 2
  good, //  = 3
  easy; //  = 4

  /// Prüfungswert G (1..4), wie in den FSRS-Formeln verwendet.
  int get grade => index + 1;
}

class FsrsCard {
  /// Gedächtnisstabilität in Tagen. 0 bzw. null-Zustand => neue Karte.
  final double stability;

  /// Schwierigkeit, geklammert auf [1, 10].
  final double difficulty;

  /// Zeitpunkt der letzten Bewertung. null => Karte wurde noch nie gelernt.
  final DateTime? lastReview;

  /// Nächster Fälligkeitszeitpunkt (UTC empfohlen).
  final DateTime due;

  /// Anzahl Bewertungen insgesamt.
  final int reps;

  /// Anzahl "Again"-Bewertungen (Lapses).
  final int lapses;

  const FsrsCard({
    required this.stability,
    required this.difficulty,
    required this.lastReview,
    required this.due,
    required this.reps,
    required this.lapses,
  });

  /// Erzeugt eine fabrikfrische, sofort fällige Karte.
  factory FsrsCard.newCard({DateTime? now}) {
    final t = now ?? DateTime.now();
    return FsrsCard(
      stability: 0,
      difficulty: 0,
      lastReview: null,
      due: t,
      reps: 0,
      lapses: 0,
    );
  }

  bool get isNew => lastReview == null;

  FsrsCard copyWith({
    double? stability,
    double? difficulty,
    DateTime? lastReview,
    DateTime? due,
    int? reps,
    int? lapses,
  }) {
    return FsrsCard(
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      lastReview: lastReview ?? this.lastReview,
      due: due ?? this.due,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
    );
  }

  /// Storage-agnostische Serialisierung (z.B. für Hive/JSON).
  Map<String, dynamic> toMap() => {
    'stability': stability,
    'difficulty': difficulty,
    'lastReview': lastReview?.toIso8601String(),
    'due': due.toIso8601String(),
    'reps': reps,
    'lapses': lapses,
  };

  factory FsrsCard.fromMap(Map<String, dynamic> map) => FsrsCard(
    stability: (map['stability'] as num).toDouble(),
    difficulty: (map['difficulty'] as num).toDouble(),
    lastReview: map['lastReview'] == null
        ? null
        : DateTime.parse(map['lastReview'] as String),
    due: DateTime.parse(map['due'] as String),
    reps: map['reps'] as int,
    lapses: map['lapses'] as int,
  );
}

class FsrsScheduler {
  /// 19 Default-Gewichte des FSRS-4.5-Standardparametersatzes.
  final List<double> w;

  /// Zielretention zum Fälligkeitstag (0..1). 0.9 = 90 %.
  final double requestRetention;

  /// Obergrenze für Intervalle in Tagen (~100 Jahre).
  final int maximumInterval;

  /// Untergrenze für Stabilität, verhindert Division/Logs gegen 0.
  static const double _stabilityMin = 0.01;

  static const double _decay = -0.5;

  /// FACTOR = 0.9^(1/decay) - 1 = 19/81 ≈ 0.2345679.
  static final double _factor = math.pow(0.9, 1 / _decay).toDouble() - 1;

  FsrsScheduler({
    List<double>? weights,
    this.requestRetention = 0.9,
    this.maximumInterval = 36500,
  }) : w = weights ?? _defaultWeights {
    assert(w.length == 19, 'FSRS-4.5 erwartet genau 19 Gewichte.');
    assert(
      requestRetention > 0 && requestRetention < 1,
      'requestRetention muss in (0,1) liegen.',
    );
  }

  static const List<double> _defaultWeights = [
    0.4072,
    1.1829,
    3.1262,
    15.4722,
    7.2102,
    0.5316,
    1.0651,
    0.0234,
    1.616,
    0.1544,
    1.0824,
    1.9813,
    0.0953,
    0.2975,
    2.2042,
    0.2407,
    2.9466,
    0.5034,
    0.6567,
  ];

  /// Hauptmethode: bewertet [card] mit [rating] zum Zeitpunkt [now] und gibt die
  /// aktualisierte Karte zurück (inkl. neuem Fälligkeitsdatum).
  FsrsCard review(FsrsCard card, Rating rating, DateTime now) {
    late double newStability;
    late double newDifficulty;
    var lapses = card.lapses;

    if (card.isNew) {
      // Erste Bewertung: Initialwerte aus den Gewichten.
      newStability = _initStability(rating);
      newDifficulty = _initDifficulty(rating);
      if (rating == Rating.again) lapses++;
    } else {
      final elapsedDays = now.difference(card.lastReview!).inDays;
      final r = _retrievability(
        elapsedDays < 0 ? 0 : elapsedDays,
        card.stability,
      );
      newDifficulty = _nextDifficulty(card.difficulty, rating);
      if (rating == Rating.again) {
        newStability = _stabilityAfterForget(
          card.difficulty,
          card.stability,
          r,
        );
        lapses++;
      } else {
        newStability = _stabilityAfterRecall(
          card.difficulty,
          card.stability,
          r,
          rating,
        );
      }
    }

    newStability = math.max(newStability, _stabilityMin);
    final intervalDays = _intervalDays(newStability);

    return card.copyWith(
      stability: newStability,
      difficulty: newDifficulty,
      lastReview: now,
      due: now.add(Duration(days: intervalDays)),
      reps: card.reps + 1,
      lapses: lapses,
    );
  }

  /// Vorschau der nächsten Intervalle (in Tagen) je Bewertung – z.B. um sie auf
  /// den Buttons "Again / Hard / Good / Easy" anzuzeigen, ohne zu speichern.
  Map<Rating, int> previewIntervals(FsrsCard card, DateTime now) {
    return {
      for (final r in Rating.values)
        r: review(card, r, now).due.difference(now).inDays,
    };
  }

  /// Aktuelle Abrufwahrscheinlichkeit der Karte zum Zeitpunkt [now] (0..1).
  /// Nützlich fürs Dashboard ("aktuelle Behaltenswahrscheinlichkeit").
  double currentRetrievability(FsrsCard card, DateTime now) {
    if (card.isNew) return 0;
    final elapsed = now.difference(card.lastReview!).inDays;
    return _retrievability(elapsed < 0 ? 0 : elapsed, card.stability);
  }

  /// Behaltenswahrscheinlichkeit [tage] Tage nach der letzten Wiederholung.
  ///
  /// Anders als [currentRetrievability] haengt das Ergebnis nicht am
  /// Kalender: Es faellt nicht, weil ein Tag vergangen ist, sondern steigt
  /// nur, wenn tatsaechlich wiederholt wurde.
  ///
  /// Fuer Kennzahlen gedacht, die einen Stand ueber einen laengeren Zeitraum
  /// abbilden sollen. Die aktuelle Abrufwahrscheinlichkeit schwankt von Tag
  /// zu Tag - eine Zahl, die jeden Morgen anders aussieht, zeigt keinen
  /// Trend, sondern Rauschen.
  double retrievabilityNach(FsrsCard card, int tage) {
    if (card.isNew) return 0;
    return _retrievability(tage < 0 ? 0 : tage, card.stability);
  }

  // ---------------------------------------------------------------------------
  // Interne FSRS-4.5-Formeln
  // ---------------------------------------------------------------------------

  double _retrievability(int elapsedDays, double stability) {
    if (stability <= 0) return 0;
    return math.pow(1 + _factor * elapsedDays / stability, _decay).toDouble();
  }

  /// Tatsächliches Intervall, gerundet und auf [1, maximumInterval] geklammert.
  int _intervalDays(double stability) {
    final raw =
        (stability / _factor) * (math.pow(requestRetention, 1 / _decay) - 1);
    final clamped = raw.clamp(1.0, maximumInterval.toDouble());
    return clamped.round();
  }

  double _initStability(Rating rating) =>
      math.max(w[rating.index], _stabilityMin);

  double _initDifficulty(Rating rating) {
    // D0(G) = w4 - exp(w5 * (G-1)) + 1
    final d = w[4] - math.exp(w[5] * (rating.grade - 1)) + 1;
    return _clampDifficulty(d);
  }

  double _nextDifficulty(double d, Rating rating) {
    // D' = D - w6 * (G-3), danach Mean-Reversion zur Easy-Baseline.
    final next = d - w[6] * (rating.grade - 3);
    final target = _initDifficulty(Rating.easy);
    final reverted = w[7] * target + (1 - w[7]) * next;
    return _clampDifficulty(reverted);
  }

  double _stabilityAfterRecall(double d, double s, double r, Rating rating) {
    final hardPenalty = rating == Rating.hard ? w[15] : 1.0;
    final easyBonus = rating == Rating.easy ? w[16] : 1.0;
    return s *
        (1 +
            math.exp(w[8]) *
                (11 - d) *
                math.pow(s, -w[9]) *
                (math.exp(w[10] * (1 - r)) - 1) *
                hardPenalty *
                easyBonus);
  }

  double _stabilityAfterForget(double d, double s, double r) {
    return w[11] *
        math.pow(d, -w[12]) *
        (math.pow(s + 1, w[13]) - 1) *
        math.exp(w[14] * (1 - r));
  }

  double _clampDifficulty(double d) => d.clamp(1.0, 10.0);
}
