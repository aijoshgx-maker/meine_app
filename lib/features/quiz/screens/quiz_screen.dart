import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/frage.dart';
import '../providers/quiz_providers.dart';
import '../widgets/antwort_eingabe.dart';
import '../widgets/bewertungs_buttons.dart';
import '../widgets/konfidenz_auswahl.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(quizSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (fehler, _) => Center(child: Text('Fehler beim Laden: $fehler')),
        data: (session) {
          if (session.fertig) {
            return const Center(
              child: Text('Fertig! Alle Fragen beantwortet.'),
            );
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
                  switch (session.antwort.phase) {
                    FragePhase.antworten => AntwortEingabe(
                      frage: frage,
                      antwort: session.antwort,
                    ),
                    FragePhase.konfidenz => KonfidenzAuswahl(
                      ausgewaehlt: session.antwort.konfidenz,
                    ),
                    FragePhase.aufgedeckt => _AufdeckungsAnsicht(
                      frage: frage,
                      session: session,
                    ),
                  },
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AufdeckungsAnsicht extends ConsumerWidget {
  final Frage frage;
  final QuizSessionState session;

  const _AufdeckungsAnsicht({required this.frage, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quizSessionProvider.notifier);
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
