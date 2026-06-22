import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quiz_providers.dart';

// Countdown für die Prüfungssimulation (120/120/60 Min je Bereich). Läuft nur,
// wenn modus.zeitlimit gesetzt ist; zählt sekundenweise runter und beendet
// die zugehörige Quiz-Session automatisch bei Ablauf.
final sessionTimerProvider = NotifierProvider.autoDispose
    .family<SessionTimerController, Duration, QuizModus>(
      (modus) => SessionTimerController(modus),
    );

class SessionTimerController extends Notifier<Duration> {
  final QuizModus modus;
  Timer? _timer;

  SessionTimerController(this.modus);

  @override
  Duration build() {
    ref.onDispose(() => _timer?.cancel());

    final gesamt = modus.zeitlimit;
    if (gesamt == null) return Duration.zero;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    return gesamt;
  }

  void _tick() {
    final rest = state - const Duration(seconds: 1);
    if (rest <= Duration.zero) {
      _timer?.cancel();
      state = Duration.zero;
      ref.read(quizSessionProvider(modus).notifier).beenden();
    } else {
      state = rest;
    }
  }
}

String formatiereDauer(Duration d) {
  final minuten = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final sekunden = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minuten:$sekunden';
}
