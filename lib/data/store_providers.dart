import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/spaced_repetition/fsrs_scheduler.dart';
import 'attempt_history_store.dart';
import 'fsrs_card_store.dart';

// Zugriffspunkte auf die Datenschicht. Bewusst hier und nicht in einem
// Feature-Ordner: sowohl die Quiz- als auch die Kursverwaltung brauchen sie,
// und ein gemeinsamer Ort vermeidet einen Import-Zyklus zwischen beiden.

final fsrsSchedulerProvider = Provider((ref) => FsrsScheduler());
final fsrsCardStoreProvider = Provider((ref) => FsrsCardStore());
final attemptHistoryStoreProvider = Provider((ref) => AttemptHistoryStore());
