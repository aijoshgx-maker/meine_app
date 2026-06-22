import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'data/attempt_history_store.dart';
import 'data/fsrs_card_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(FsrsCardStore.boxName);
  await Hive.openBox(AttemptHistoryStore.boxName);
  runApp(const ProviderScope(child: Ap2App()));
}
