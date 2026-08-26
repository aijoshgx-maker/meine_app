import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/spaced_repetition/fsrs_scheduler.dart';

void main() {
  late FsrsScheduler scheduler;
  final now = DateTime.utc(2026, 1, 1);

  setUp(() => scheduler = FsrsScheduler());

  group('Neue Karte – erste Bewertung', () {
    test('Initialstabilität entspricht den Gewichten w[0..3]', () {
      // Erwartete Roh-Intervalle ≈ Stabilität (bei Retention 0.9):
      // Again w0=0.4072 -> min 1 Tag | Hard w1=1.1829 -> 1
      // Good w2=3.1262 -> 3          | Easy w3=15.4722 -> 15
      final good = scheduler.review(
        FsrsCard.newCard(now: now),
        Rating.good,
        now,
      );
      expect(good.due.difference(now).inDays, 3);

      final easy = scheduler.review(
        FsrsCard.newCard(now: now),
        Rating.easy,
        now,
      );
      expect(easy.due.difference(now).inDays, 15);
    });

    test('Intervalle sind monoton: again <= hard <= good <= easy', () {
      final p = scheduler.previewIntervals(FsrsCard.newCard(now: now), now);
      expect(p[Rating.again]! <= p[Rating.hard]!, isTrue);
      expect(p[Rating.hard]! <= p[Rating.good]!, isTrue);
      expect(p[Rating.good]! <= p[Rating.easy]!, isTrue);
    });

    test('Difficulty liegt immer in [1, 10]', () {
      for (final r in Rating.values) {
        final c = scheduler.review(FsrsCard.newCard(now: now), r, now);
        expect(c.difficulty, inInclusiveRange(1.0, 10.0));
      }
    });

    test('Schlechtere Bewertung => höhere Difficulty', () {
      final again = scheduler.review(
        FsrsCard.newCard(now: now),
        Rating.again,
        now,
      );
      final easy = scheduler.review(
        FsrsCard.newCard(now: now),
        Rating.easy,
        now,
      );
      expect(again.difficulty, greaterThan(easy.difficulty));
    });

    test('Mindestens 1 Tag, auch bei Again', () {
      final again = scheduler.review(
        FsrsCard.newCard(now: now),
        Rating.again,
        now,
      );
      expect(again.due.difference(now).inDays, greaterThanOrEqualTo(1));
      expect(again.lapses, 1);
      expect(again.reps, 1);
    });
  });

  group('Folgebewertungen', () {
    test('Erfolgreicher Abruf erhöht die Stabilität', () {
      var card = scheduler.review(FsrsCard.newCard(now: now), Rating.good, now);
      final sBefore = card.stability;
      final later = card.due; // genau am Fälligkeitstag (R ≈ 0.9)
      card = scheduler.review(card, Rating.good, later);
      expect(card.stability, greaterThan(sBefore));
    });

    test('Vergessen (Again) reduziert die Stabilität', () {
      var card = scheduler.review(FsrsCard.newCard(now: now), Rating.good, now);
      // einmal stabilisieren …
      card = scheduler.review(card, Rating.good, card.due);
      final sBefore = card.stability;
      // … dann vergessen
      card = scheduler.review(card, Rating.again, card.due);
      expect(card.stability, lessThan(sBefore));
      expect(card.lapses, 1);
    });
  });

  group('Retrievability', () {
    test('faellt mit der Zeit monoton', () {
      final card = scheduler.review(
        FsrsCard.newCard(now: now),
        Rating.good,
        now,
      );
      final r1 = scheduler.currentRetrievability(
        card,
        now.add(const Duration(days: 1)),
      );
      final r5 = scheduler.currentRetrievability(
        card,
        now.add(const Duration(days: 5)),
      );
      final r20 = scheduler.currentRetrievability(
        card,
        now.add(const Duration(days: 20)),
      );
      expect(r1, greaterThan(r5));
      expect(r5, greaterThan(r20));
      expect(r1, inInclusiveRange(0.0, 1.0));
    });

    test('am Faelligkeitstag liegt R nahe der Zielretention 0.9', () {
      final card = scheduler.review(
        FsrsCard.newCard(now: now),
        Rating.good,
        now,
      );
      final r = scheduler.currentRetrievability(card, card.due);
      expect(r, closeTo(0.9, 0.05));
    });
  });

  // Die Kennzahl fuers Dashboard: Sie soll etwas ueber das Gelernte sagen und
  // nicht darueber, wie viele Tage seit der letzten Session vergangen sind.
  group('retrievabilityNach', () {
    test('haengt nicht am Kalender', () {
      final card = scheduler.review(
        FsrsCard.newCard(now: now),
        Rating.good,
        now,
      );

      // Derselbe Kartenstand, betrachtet an drei verschiedenen Tagen: Die
      // aktuelle Abrufwahrscheinlichkeit faellt, der Horizontwert nicht.
      final wert = scheduler.retrievabilityNach(card, 30);
      expect(scheduler.retrievabilityNach(card, 30), wert);

      expect(
        scheduler.currentRetrievability(card, now.add(const Duration(days: 1))),
        greaterThan(
          scheduler.currentRetrievability(
            card,
            now.add(const Duration(days: 20)),
          ),
        ),
      );
    });

    test('steigt, wenn wiederholt wird', () {
      var card = scheduler.review(FsrsCard.newCard(now: now), Rating.good, now);
      final vorher = scheduler.retrievabilityNach(card, 30);

      card = scheduler.review(card, Rating.good, card.due);
      expect(scheduler.retrievabilityNach(card, 30), greaterThan(vorher));
    });

    test('faellt mit laengerem Horizont', () {
      final card = scheduler.review(
        FsrsCard.newCard(now: now),
        Rating.good,
        now,
      );

      expect(
        scheduler.retrievabilityNach(card, 7),
        greaterThan(scheduler.retrievabilityNach(card, 30)),
      );
      expect(
        scheduler.retrievabilityNach(card, 30),
        greaterThan(scheduler.retrievabilityNach(card, 365)),
      );
    });

    test('eine nie gelernte Karte steht auf 0', () {
      expect(scheduler.retrievabilityNach(FsrsCard.newCard(now: now), 30), 0);
    });
  });

  group('Serialisierung', () {
    test('toMap/fromMap ist verlustfrei', () {
      final card = scheduler.review(
        FsrsCard.newCard(now: now),
        Rating.good,
        now,
      );
      final restored = FsrsCard.fromMap(card.toMap());
      expect(restored.stability, card.stability);
      expect(restored.difficulty, card.difficulty);
      expect(restored.due, card.due);
      expect(restored.lastReview, card.lastReview);
      expect(restored.reps, card.reps);
      expect(restored.lapses, card.lapses);
    });
  });
}
