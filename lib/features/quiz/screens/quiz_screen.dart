import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/frage.dart';
import '../providers/quiz_providers.dart';
import '../providers/session_break_provider.dart';
import '../providers/session_timer_provider.dart';
import '../widgets/antwort_eingabe.dart';
import '../widgets/bewertungs_buttons.dart';
import '../widgets/konfidenz_auswahl.dart';

class QuizScreen extends ConsumerWidget {
  final QuizModus modus;

  const QuizScreen({super.key, required this.modus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(quizSessionProvider(modus));

    ref.listen(sessionBreakProvider, (zuvor, jetzt) {
      if (jetzt) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: const Text('Du lernst schon eine Weile – kurze Pause?'),
            actions: [
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: const Text('Okay'),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          if (modus.zeitlimit != null) _TimerAnzeige(modus: modus),
          if (sessionAsync.value != null && !sessionAsync.value!.fertig)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '${sessionAsync.value!.richtigBeantwortet}/${sessionAsync.value!.index}',
                ),
              ),
            ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (fehler, _) => Center(child: Text('Fehler beim Laden: $fehler')),
        data: (session) {
          if (session.fertig) {
            return Center(
              child: Text(
                session.fragen.isEmpty
                    ? 'Keine Fragen in diesem Modus.'
                    : '${session.richtigBeantwortet} von ${session.fragen.length} richtig',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }
          if (session.fragen.isEmpty) {
            return const Center(child: Text('Keine Fragen in diesem Modus.'));
          }
          final frage = session.aktuelleFrage!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Frage ${session.index + 1} von ${session.fragen.length} · ${frage.kategorie}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    frage.frage,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (frage.bildAsset != null) ...[
                    const SizedBox(height: 12),
                    Image.asset(frage.bildAsset!),
                  ],
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey('${frage.id}-${session.antwort.phase}'),
                      child: switch (session.antwort.phase) {
                        FragePhase.antworten => AntwortEingabe(
                          frage: frage,
                          antwort: session.antwort,
                          modus: modus,
                        ),
                        FragePhase.konfidenz => KonfidenzAuswahl(
                          ausgewaehlt: session.antwort.konfidenz,
                          modus: modus,
                        ),
                        FragePhase.aufgedeckt => _AufdeckungsAnsicht(
                          frage: frage,
                          session: session,
                          modus: modus,
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimerAnzeige extends ConsumerWidget {
  final QuizModus modus;

  const _TimerAnzeige({required this.modus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rest = ref.watch(sessionTimerProvider(modus));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Text(
          formatiereDauer(rest),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _AufdeckungsAnsicht extends ConsumerWidget {
  final Frage frage;
  final QuizSessionState session;
  final QuizModus modus;

  const _AufdeckungsAnsicht({
    required this.frage,
    required this.session,
    required this.modus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quizSessionProvider(modus).notifier);
    final korrekt = session.antwort.korrekt ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              korrekt ? Icons.check_circle : Icons.cancel,
              color: korrekt ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              korrekt ? 'Richtig' : 'Falsch',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(frage.erklaerung),
        if (frage.workedExample != null) ...[
          const SizedBox(height: 12),
          ExpansionTile(
            title: const Text('Lösungsweg'),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(frage.workedExample!),
              ),
            ],
          ),
        ],
        if (frage.schwierigkeit == 3) ...[
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Erkläre kurz, WARUM (optional, wird nicht bewertet)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: controller.selbsterklaerungSetzen,
          ),
        ],
        const SizedBox(height: 24),
        const Text('Wie gut wusstest du es?'),
        const SizedBox(height: 8),
        BewertungsButtons(onBewertet: controller.bewerten),
      ],
    );
  }
}
