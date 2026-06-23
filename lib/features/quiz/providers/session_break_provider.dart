import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Einmaliger, sanfter Pausen-Hinweis nach ~27 Minuten ununterbrochener
// Quiz-Aktivität (Konsolidierung/Pausen-Prinzip). Lebt so lange wie der
// QuizScreen, der diesen Provider beobachtet (autoDispose).
final sessionBreakProvider =
    NotifierProvider.autoDispose<SessionBreakController, bool>(
      SessionBreakController.new,
    );

class SessionBreakController extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer(const Duration(minutes: 27), () => state = true);
    return false;
  }
}
