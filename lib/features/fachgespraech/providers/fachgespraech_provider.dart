import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/fachgespraech_szenario.dart';

final fachgespraechSzenarienProvider =
    FutureProvider<List<FachgespraechSzenario>>((ref) async {
  return FachgespraechSzenario.ladeAlle();
});
