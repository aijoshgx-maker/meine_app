import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/frage.dart';
import '../providers/quiz_providers.dart';

// Die Eingabe-UI für den Recall-/Auswahlversuch, abhängig vom Fragetyp.
// kurzantwort/rechnung verlangen zuerst freien Abruf (Recall-first), bevor
// es weitergeht; bei den Auswahltypen ist die Auswahl selbst der Abrufversuch.
class AntwortEingabe extends ConsumerWidget {
  final Frage frage;
  final AntwortZustand antwort;
  final QuizModus modus;

  const AntwortEingabe({
    super.key,
    required this.frage,
    required this.antwort,
    required this.modus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quizSessionProvider(modus).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (frageTypVon(frage.typ)) {
          FrageTyp.single || FrageTyp.wahrfalsch => _auswahlListe(
            mehrfach: false,
            controller: controller,
          ),
          FrageTyp.multi => _auswahlListe(
            mehrfach: true,
            controller: controller,
          ),
          FrageTyp.zuordnung => _zuordnungListe(controller),
          FrageTyp.rechnung => _texteingabe(
            controller: controller,
            hinweis: 'Zahlenwert eingeben',
            tastatur: TextInputType.number,
          ),
          FrageTyp.kurzantwort => _texteingabe(
            controller: controller,
            hinweis: 'Antwort eingeben',
            tastatur: TextInputType.text,
          ),
        },
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _kannWeiter() ? controller.weiterZuKonfidenz : null,
          child: const Text('Weiter'),
        ),
      ],
    );
  }

  bool _kannWeiter() {
    switch (frageTypVon(frage.typ)) {
      case FrageTyp.single:
      case FrageTyp.wahrfalsch:
      case FrageTyp.multi:
        return antwort.ausgewaehlteIndizes.isNotEmpty;
      case FrageTyp.zuordnung:
        return antwort.zuordnungsAuswahl.length == frage.richtigeIndizes.length;
      case FrageTyp.rechnung:
      case FrageTyp.kurzantwort:
        return antwort.freitext.trim().isNotEmpty;
    }
  }

  Widget _auswahlListe({
    required bool mehrfach,
    required QuizSessionController controller,
  }) {
    return Column(
      children: [
        for (var i = 0; i < frage.optionen.length; i++)
          mehrfach
              ? CheckboxListTile(
                  title: Text(frage.optionen[i]),
                  value: antwort.ausgewaehlteIndizes.contains(i),
                  onChanged: (_) => controller.auswahlUmschalten(i),
                )
              : ListTile(
                  leading: Icon(
                    antwort.ausgewaehlteIndizes.contains(i)
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(frage.optionen[i]),
                  onTap: () => controller.auswahlUmschalten(i),
                ),
      ],
    );
  }

  Widget _zuordnungListe(QuizSessionController controller) {
    return Column(
      children: [
        for (
          var linkerIndex = 0;
          linkerIndex < frage.richtigeIndizes.length;
          linkerIndex++
        )
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 32, child: Text('${linkerIndex + 1}.')),
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: antwort.zuordnungsAuswahl[linkerIndex],
                    hint: const Text('Zuordnen...'),
                    items: [
                      for (var i = 0; i < frage.optionen.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(frage.optionen[i]),
                        ),
                    ],
                    onChanged: (wert) {
                      if (wert != null) {
                        controller.zuordnungAuswaehlen(linkerIndex, wert);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _texteingabe({
    required QuizSessionController controller,
    required String hinweis,
    required TextInputType tastatur,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: hinweis,
        border: const OutlineInputBorder(),
      ),
      keyboardType: tastatur,
      onChanged: controller.freitextSetzen,
    );
  }
}
