import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/kurs.dart';
import '../../kurse/providers/kurs_providers.dart';
import '../../quiz/providers/quiz_modus.dart';

// Auswahlscreen: alle Kategorien des aktiven Kurses, gruppiert nach Bereich.
// Antippen startet eine Quiz-Session nur mit Fragen dieses Themas.
//
// Die Kategorien werden aus den geladenen Fragen abgeleitet, nicht gepflegt.
// Vorher stand hier eine feste Liste, die stillschweigend von den Daten
// abwich - Kategorien mit abweichender Schreibweise waren dadurch gar nicht
// erreichbar.
class ThemenAuswahlScreen extends ConsumerWidget {
  const ThemenAuswahlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paket = ref.watch(aktivesPaketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thema vertiefen'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: paket.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Hinweis(text: 'Themen nicht ladbar: $e'),
        data: (paket) {
          final gruppen = paket.kategorienProBereich;
          if (gruppen.isEmpty) {
            return const _Hinweis(
              text: 'Dieser Kurs enthält noch keine Themen.',
            );
          }

          // Anzahl Fragen je Kategorie, damit sichtbar ist, was einen erwartet.
          final anzahl = <String, int>{};
          for (final frage in paket.fragen) {
            anzahl[frage.kategorie] = (anzahl[frage.kategorie] ?? 0) + 1;
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final eintrag in gruppen.entries) ...[
                _BereichHeader(
                  bereich: paket.kurs.bereichFuer(eintrag.key),
                  ersatzTitel: eintrag.key,
                ),
                const SizedBox(height: 4),
                for (final kategorie in eintrag.value)
                  _KategorieKarte(
                    kategorie: kategorie,
                    anzahl: anzahl[kategorie] ?? 0,
                  ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Hinweis extends StatelessWidget {
  final String text;
  const _Hinweis({required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

class _BereichHeader extends StatelessWidget {
  final Bereich? bereich;
  final String ersatzTitel;

  const _BereichHeader({required this.bereich, required this.ersatzTitel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final farbe = bereich?.farbeAlsColor ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            bereich?.iconData ?? Icons.folder_outlined,
            size: 18,
            color: farbe,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bereich?.titel ?? ersatzTitel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: farbe,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KategorieKarte extends StatelessWidget {
  final String kategorie;
  final int anzahl;

  const _KategorieKarte({required this.kategorie, required this.anzahl});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        title: Text(kategorie),
        subtitle: Text('$anzahl ${anzahl == 1 ? 'Frage' : 'Fragen'}'),
        trailing: const Icon(Icons.play_arrow_rounded, size: 20),
        onTap: () => context.go(
          '/quiz',
          extra: QuizModus.themenVertiefung(kategorie: kategorie),
        ),
      ),
    );
  }
}
