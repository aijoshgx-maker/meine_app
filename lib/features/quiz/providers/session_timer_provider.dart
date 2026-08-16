import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quiz_providers.dart';

class TimerZustand {
  final Duration verbleibend;
  final bool pausiert;

  const TimerZustand({required this.verbleibend, this.pausiert = false});

  TimerZustand copyWith({Duration? verbleibend, bool? pausiert}) => TimerZustand(
        verbleibend: verbleibend ?? this.verbleibend,
        pausiert: pausiert ?? this.pausiert,
      );
}

// Echtzeit-Countdown für die Prüfungssimulation mit Pause/Fortsetzen.
// Für alle anderen Modi liefert der Provider sofort Duration.zero zurück.
final sessionTimerProvider = NotifierProvider.autoDispose
    .family<SessionTimerController, TimerZustand, QuizModus>(
      (modus) => SessionTimerController(modus),
    );

class SessionTimerController extends Notifier<TimerZustand> {
  final QuizModus modus;
  SessionTimerController(this.modus);

  Timer? _timer;

  @override
  TimerZustand build() {
    final limitMin = modus.zeitlimitMinuten;
    if (limitMin == null || limitMin <= 0) {
      return const TimerZustand(verbleibend: Duration.zero);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.pausiert) return; // Tick überspringen solange pausiert

      final remaining = state.verbleibend - const Duration(seconds: 1);
      if (remaining <= Duration.zero) {
        _timer?.cancel();
        state = state.copyWith(verbleibend: Duration.zero);
        try {
          ref.read(quizSessionProvider(modus).notifier).beenden();
        } catch (_) {}
      } else {
        state = state.copyWith(verbleibend: remaining);
      }
    });

    ref.onDispose(() => _timer?.cancel());
    return TimerZustand(verbleibend: Duration(minutes: limitMin));
  }

  void pausieren() {
    if (!state.pausiert) state = state.copyWith(pausiert: true);
  }

  void fortsetzen() {
    if (state.pausiert) state = state.copyWith(pausiert: false);
  }
}

String formatiereDauer(Duration d) {
  if (d <= Duration.zero) return '00:00';
  final stunden = d.inHours;
  final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final sek = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (stunden > 0) return '${stunden.toString().padLeft(2, '0')}:$min:$sek';
  return '$min:$sek';
}
