import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/kurs.dart';
import '../../kurse/providers/kurs_providers.dart';
import '../../quiz/providers/quiz_providers.dart';
import '../../quiz/providers/session_timer_provider.dart';

// Testläufe auf Zeit. Welche es gibt, steht im aktiven Kurs - früher war das
// eine feste Liste der vier IHK-Prüfungen im Dart-Code.
//
// Ein Testlauf zieht seine Aufgaben über frage.pruefung == code.
//
// Ist im Kurs eine Sollzahl (`aufgabenAnzahl`) hinterlegt und wird sie nicht
// erreicht, sagt die Karte das - statt still eine unvollständige Prüfung zu
// simulieren. Ohne Sollzahl gibt es nichts zu vergleichen, und die Karte
// nennt einfach die vorhandene Anzahl.
//
// Früher stand hier ein Vergleich gegen den GRÖSSTEN der vorhandenen
// Testläufe. Das markierte zwangsläufig alle bis auf einen als
// "unvollständigen Datensatz" - denn nur einer kann der größte sein. Die
// Meldung behauptete damit ein Datenproblem, das es nicht gab.
class PruefungsAuswahlScreen extends ConsumerWidget {
  const PruefungsAuswahlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paketAsync = ref.watch(aktivesPaketProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(paketAsync.value?.kurs.begriffe.testlauf ?? 'Testlauf'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: paketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Nicht ladbar: $e', textAlign: TextAlign.center),
          ),
        ),
        data: (paket) {
          final anzahl = paket.fragenProPruefung;
          // Nur Testläufe zeigen, für die es auch Aufgaben gibt.
          final verfuegbar = paket.kurs.pruefungen
              .where((p) => (anzahl[p.code] ?? 0) > 0)
              .toList();

          if (verfuegbar.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Dieser Kurs enthält keine Testläufe.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${paket.kurs.begriffe.testlauf} starten',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Der Timer läuft mit dem hinterlegten Zeitlimit. '
                'Bewertung und Wiederholungsplanung bleiben dabei außen vor.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              for (final pruefung in verfuegbar)
                _PruefungsKarte(
                  info: pruefung,
                  anzahlVerfuegbar: anzahl[pruefung.code],
                  anzahlSoll: pruefung.aufgabenAnzahl,
                  onStart: () => _starteSimulation(context, ref, pruefung),
                ),
            ],
          );
        },
      ),
    );
  }

  void _starteSimulation(
    BuildContext context,
    WidgetRef ref,
    PruefungsDefinition info,
  ) {
    final modus = QuizModus.pruefungssimulation(
      pruefungsId: info.code,
      zeitlimitMinuten: info.zeitlimitMinuten,
    );
    // Alten Stand verwerfen → nächster Start beginnt immer von vorne.
    ref.invalidate(quizSessionProvider(modus));
    ref.invalidate(sessionTimerProvider(modus));
    context.go('/quiz', extra: modus);
  }
}

class _PruefungsKarte extends StatelessWidget {
  final PruefungsDefinition info;
  final int? anzahlVerfuegbar;

  /// Sollzahl aus dem Kurs, oder null, wenn er keine kennt.
  final int? anzahlSoll;
  final VoidCallback onStart;

  const _PruefungsKarte({
    required this.info,
    required this.anzahlVerfuegbar,
    required this.anzahlSoll,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unvollstaendig =
        anzahlVerfuegbar != null &&
        anzahlSoll != null &&
        anzahlVerfuegbar! < anzahlSoll!;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    info.titel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _ZeitChip(minuten: info.zeitlimitMinuten),
              ],
            ),
            if (anzahlVerfuegbar != null) ...[
              const SizedBox(height: 4),
              Text(
                unvollstaendig
                    ? '$anzahlVerfuegbar von $anzahlSoll Aufgaben verfügbar '
                          '(unvollständiger Datensatz)'
                    : '$anzahlVerfuegbar Aufgaben verfügbar',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: unvollstaendig ? cs.error : cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              info.beschreibung,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Die Diagramm-Chips MUESSEN in Expanded stehen. Ohne das nimmt
            // sich das Wrap seine natuerliche Breite, der Spacer faellt auf
            // null zusammen und der Starten-Knopf wird aus dem Bild
            // geschoben - er war dann nicht mehr antippbar.
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final key in info.diagrammKeys.take(3))
                        Chip(
                          label: Text(key.replaceAll('_', ' ')),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: Theme.of(context).textTheme.labelSmall,
                        ),
                      if (info.diagrammKeys.length > 3)
                        Chip(
                          label: Text('+${info.diagrammKeys.length - 3}'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Starten'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZeitChip extends StatelessWidget {
  final int minuten;
  const _ZeitChip({required this.minuten});

  @override
  Widget build(BuildContext context) {
    final stunden = minuten ~/ 60;
    final rest = minuten % 60;
    final text = stunden > 0
        ? '${stunden}h${rest > 0 ? ' ${rest}min' : ''}'
        : '${minuten}min';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
