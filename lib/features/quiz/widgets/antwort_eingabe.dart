import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/frage.dart';
import '../providers/quiz_providers.dart';

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
          FrageTyp.single => _auswahlListe(
            mehrfach: false,
            controller: controller,
          ),
          FrageTyp.multi => _auswahlListe(
            mehrfach: true,
            controller: controller,
          ),
          FrageTyp.wahrfalsch => _wahrFalschButtons(context, controller),
          FrageTyp.zuordnung => _zuordnungListe(controller),
          FrageTyp.rechnung => _texteingabe(
            controller: controller,
            hinweis: frage.einheit != null
                ? 'Zahlenwert in ${frage.einheit}'
                : 'Zahlenwert eingeben',
            tastatur: TextInputType.number,
          ),
          FrageTyp.kurzantwort => _texteingabe(
            controller: controller,
            hinweis: 'Antwort eingeben',
            tastatur: TextInputType.text,
          ),
          FrageTyp.lueckentext => _lueckentextFelder(controller),
          FrageTyp.reihenfolge => _reihenfolgeWidget(controller),
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
        final anzahl = frage.paare.isNotEmpty
            ? frage.paare.length
            : frage.richtigeIndizes.length;
        return antwort.zuordnungsAuswahl.length == anzahl;
      case FrageTyp.rechnung:
      case FrageTyp.kurzantwort:
        return antwort.freitext.trim().isNotEmpty;
      case FrageTyp.lueckentext:
        if (antwort.lueckenAntworten.length < frage.luecken.length) {
          return false;
        }
        return antwort.lueckenAntworten.values.every(
          (v) => v.trim().isNotEmpty,
        );
      case FrageTyp.reihenfolge:
        return true;
    }
  }

  // Anzeigereihenfolge (Original-Indizes von frage.optionen), pro
  // Frage-Anzeige neu gemischt (siehe AntwortZustand.fuerFrage). An
  // Position i steht der Original-Index des dort gezeigten Elements.
  // Fallback auf Original-Reihenfolge, falls (noch) nicht gesetzt.
  List<int> get _optionenAnzeige =>
      antwort.optionenReihenfolge.length == frage.optionen.length
      ? antwort.optionenReihenfolge
      : List.generate(frage.optionen.length, (i) => i);

  Widget _auswahlListe({
    required bool mehrfach,
    required QuizSessionController controller,
  }) {
    final anzeige = _optionenAnzeige;
    return Column(
      children: [
        for (final originalIndex in anzeige)
          mehrfach
              ? CheckboxListTile(
                  title: Text(frage.optionen[originalIndex]),
                  value: antwort.ausgewaehlteIndizes.contains(originalIndex),
                  onChanged: (_) => controller.auswahlUmschalten(originalIndex),
                )
              : ListTile(
                  leading: Icon(
                    antwort.ausgewaehlteIndizes.contains(originalIndex)
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(frage.optionen[originalIndex]),
                  onTap: () => controller.auswahlUmschalten(originalIndex),
                ),
      ],
    );
  }

  Widget _wahrFalschButtons(
    BuildContext context,
    QuizSessionController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final (label, idx) in [('Falsch', 0), ('Wahr', 1)])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                style: antwort.ausgewaehlteIndizes.contains(idx)
                    ? OutlinedButton.styleFrom(
                        backgroundColor: scheme.primaryContainer,
                        side: BorderSide(color: scheme.primary, width: 2),
                      )
                    : null,
                onPressed: () => controller.auswahlUmschalten(idx),
                child: Text(label),
              ),
            ),
          ),
      ],
    );
  }

  Widget _zuordnungListe(QuizSessionController controller) {
    if (frage.paare.isNotEmpty) {
      // Rechte Spalte in der (pro Anzeige neu gemischten) Anzeigereihenfolge
      // zeigen. Der Dropdown-Wert ist immer der Original-Index von
      // paare[].rechts, unabhängig von der Anzeigeposition - so bleibt die
      // Bewertungslogik unabhängig vom Shuffle.
      final rechteAnzeige =
          antwort.zuordnungRechteReihenfolge.length == frage.paare.length
          ? antwort.zuordnungRechteReihenfolge
          : List.generate(frage.paare.length, (i) => i);
      return Column(
        children: [
          for (var i = 0; i < frage.paare.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      frage.paare[i].links,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: antwort.zuordnungsAuswahl[i],
                      hint: const Text('Zuordnen…'),
                      items: [
                        for (final originalIndex in rechteAnzeige)
                          DropdownMenuItem(
                            value: originalIndex,
                            child: Text(
                              frage.paare[originalIndex].rechts,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (wert) {
                        if (wert != null) {
                          controller.zuordnungAuswaehlen(i, wert);
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

    // Altes Format (Fallback): optionen + richtigeIndizes
    return Column(
      children: [
        for (var i = 0; i < frage.richtigeIndizes.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 32, child: Text('${i + 1}.')),
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: antwort.zuordnungsAuswahl[i],
                    hint: const Text('Zuordnen…'),
                    items: [
                      for (var j = 0; j < frage.optionen.length; j++)
                        DropdownMenuItem(
                          value: j,
                          child: Text(frage.optionen[j]),
                        ),
                    ],
                    onChanged: (wert) {
                      if (wert != null) controller.zuordnungAuswaehlen(i, wert);
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _lueckentextFelder(QuizSessionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < frage.luecken.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Lücke ${i + 1}',
                border: const OutlineInputBorder(),
              ),
              onChanged: (text) => controller.lueckeSetzen(i, text),
            ),
          ),
      ],
    );
  }

  Widget _reihenfolgeWidget(QuizSessionController controller) {
    final reihenfolge = antwort.reihenfolgeAuswahl.isNotEmpty
        ? antwort.reihenfolgeAuswahl
        : List.generate(frage.optionen.length, (i) => i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ziehe die Elemente in die richtige Reihenfolge:',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorderItem: (oldIndex, newIndex) {
            final neu = List<int>.of(reihenfolge);
            final item = neu.removeAt(oldIndex);
            neu.insert(newIndex, item);
            controller.reihenfolgeAktualisieren(neu);
          },
          children: [
            for (final optIdx in reihenfolge)
              ListTile(
                key: ValueKey(optIdx),
                title: Text(frage.optionen[optIdx]),
                trailing: const Icon(Icons.drag_handle),
                dense: true,
              ),
          ],
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
