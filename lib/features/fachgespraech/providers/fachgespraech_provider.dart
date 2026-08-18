import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/fachgespraech_szenario.dart';
import '../../kurse/providers/kurs_providers.dart';

// Dialog-Szenarien des aktiven Kurses. Früher wurde hier fest
// assets/fragen/fachgespraech_szenarien.json geladen; jetzt bringt jedes
// Lernpaket seine eigenen Szenarien mit (oder eben keine).
final fachgespraechSzenarienProvider =
    FutureProvider<List<FachgespraechSzenario>>((ref) async {
      final paket = await ref.watch(aktivesPaketProvider.future);
      return paket.szenarien;
    });
