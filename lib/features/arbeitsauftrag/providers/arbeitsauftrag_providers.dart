import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/arbeitsauftrag_inhalte.dart';
import '../../../data/arbeitsauftrag_store.dart';

final arbeitsauftragStoreProvider = Provider((ref) => ArbeitsauftragStore());

final checklistProvider =
    NotifierProvider<ChecklistController, Map<String, bool>>(
      ChecklistController.new,
    );

class ChecklistController extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() =>
      ref.read(arbeitsauftragStoreProvider).checklistStatus();

  Future<void> umschalten(String itemId) async {
    final aktuell = !(state[itemId] ?? false);
    await ref
        .read(arbeitsauftragStoreProvider)
        .checklistSetzen(itemId, aktuell);
    state = {...state, itemId: aktuell};
  }
}

// Anteil erledigter Checklisten-Items (0..1) – fließt in die Dashboard-
// Prüfungsreife-Anzeige (Phase 6) als eigener, nicht vermischter Wert ein.
final checklistFortschrittProvider = Provider<double>((ref) {
  final status = ref.watch(checklistProvider);
  final erledigt = checklistenEintraege
      .where((eintrag) => status[eintrag.id] ?? false)
      .length;
  return erledigt / checklistenEintraege.length;
});

final dokumentationProvider =
    NotifierProvider<DokumentationController, Map<String, String>>(
      DokumentationController.new,
    );

class DokumentationController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() =>
      ref.read(arbeitsauftragStoreProvider).dokumentationLaden();

  Future<void> feldSetzen(String feldId, String text) async {
    final neu = {...state, feldId: text};
    state = neu;
    await ref.read(arbeitsauftragStoreProvider).dokumentationSpeichern(neu);
  }
}

final fachgespraechProvider =
    NotifierProvider<FachgespraechController, Map<String, String>>(
      FachgespraechController.new,
    );

class FachgespraechController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() =>
      ref.read(arbeitsauftragStoreProvider).fachgespraechAntworten();

  Future<void> antwortSetzen(String fragId, String text) async {
    await ref
        .read(arbeitsauftragStoreProvider)
        .fachgespraechAntwortSetzen(fragId, text);
    state = {...state, fragId: text};
  }
}
