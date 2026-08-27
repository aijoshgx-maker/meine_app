import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/quiz/frage_haerte.dart';
import '../../../models/frage.dart';
import '../providers/quiz_providers.dart';

class AntwortEingabe extends ConsumerWidget {
  final Frage frage;
  final AntwortZustand antwort;
  final QuizModus modus;

  /// Steuert die Hinweise an den Eingabefeldern. Was sich am Inhalt der
  /// Frage aendert, ist zu diesem Zeitpunkt bereits geschehen - siehe
  /// core/quiz/frage_haerte.dart.
  final Haertegrad haertegrad;

  const AntwortEingabe({
    super.key,
    required this.frage,
    required this.antwort,
    required this.modus,
    this.haertegrad = Haertegrad.normal,
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
          FrageTyp.zuordnung => _zuordnungListe(context, controller),
          FrageTyp.rechnung => _texteingabe(
            controller: controller,
            // Ab Stufe 2 nennt der Hinweis die Einheit nicht mehr - sie
            // gehoert dann zum Gewussten, nicht zur Aufgabenstellung.
            // Dimensionslose Ergebnisse (Sicherheit, cpk, Uebersetzung)
            // tragen eine leere Einheit - daraus wuerde sonst der Hinweis
            // "Zahlenwert in " mit nichts dahinter.
            hinweis:
                (frage.einheit?.isNotEmpty ?? false) &&
                    haertegrad != Haertegrad.freierAbruf
                ? 'Zahlenwert in ${frage.einheit}'
                : 'Zahlenwert eingeben',
            // TextInputType.number ist auf dem Telefon der reine
            // Ziffernblock - ohne Komma. Die Bewertung nimmt Kommas seit
            // jeher an, es fehlte nur die Taste. Vorzeichen, weil einzelne
            // Aufgaben negative Ergebnisse haben.
            tastatur: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
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

  // Zuordnung: pro Begriff eine Auswahl über die volle Breite.
  //
  // Früher standen hier zwei DropdownButtons nebeneinander in einer Row. Auf
  // dem Handy blieb damit nur die halbe Bildschirmbreite für das Auswahlmenü,
  // dessen Popup an der Bildschirmkante abgeschnitten wurde - lange Begriffe
  // wie "Zugdruckumformen" waren nicht lesbar. Jetzt liegt der Begriff über
  // seiner Auswahl, und die Optionen erscheinen in einem Blatt über die
  // gesamte Breite, in dem langer Text umbricht statt zu verschwinden.
  Widget _zuordnungListe(
    BuildContext context,
    QuizSessionController controller,
  ) {
    if (frage.paare.isNotEmpty) {
      // Rechte Spalte in der (pro Anzeige neu gemischten) Anzeigereihenfolge
      // zeigen. Der gespeicherte Wert ist immer der Original-Index von
      // paare[].rechts, unabhängig von der Anzeigeposition - so bleibt die
      // Bewertungslogik unabhängig vom Shuffle.
      final rechteAnzeige =
          antwort.zuordnungRechteReihenfolge.length == frage.paare.length
          ? antwort.zuordnungRechteReihenfolge
          : List.generate(frage.paare.length, (i) => i);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < frage.paare.length; i++)
            _ZuordnungsZeile(
              begriff: frage.paare[i].links,
              auswahl: antwort.zuordnungsAuswahl[i],
              optionen: {
                for (final originalIndex in rechteAnzeige)
                  originalIndex: frage.paare[originalIndex].rechts,
              },
              onGewaehlt: (wert) => controller.zuordnungAuswaehlen(i, wert),
            ),
        ],
      );
    }

    // Altes Format (Fallback): optionen + richtigeIndizes
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < frage.richtigeIndizes.length; i++)
          _ZuordnungsZeile(
            begriff: '${i + 1}.',
            auswahl: antwort.zuordnungsAuswahl[i],
            optionen: {
              for (var j = 0; j < frage.optionen.length; j++)
                j: frage.optionen[j],
            },
            onGewaehlt: (wert) => controller.zuordnungAuswaehlen(i, wert),
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

/// Ein Begriff mit seiner Zuordnung, über die volle Breite.
///
/// Statt eines Dropdowns, dessen Popup am Bildschirmrand abgeschnitten wird,
/// öffnet ein Tippen ein Auswahlblatt von unten. Dort steht jede Option über
/// die gesamte Breite und bricht bei Bedarf um - damit bleibt sie auf jedem
/// Bildschirm vollständig lesbar.
class _ZuordnungsZeile extends StatelessWidget {
  final String begriff;
  final int? auswahl;

  /// Original-Index -> anzuzeigender Text, in Anzeigereihenfolge.
  final Map<int, String> optionen;
  final ValueChanged<int> onGewaehlt;

  const _ZuordnungsZeile({
    required this.begriff,
    required this.auswahl,
    required this.optionen,
    required this.onGewaehlt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gewaehlt = auswahl != null ? optionen[auswahl] : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(begriff, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _auswahlOeffnen(context),
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                gewaehlt ?? 'Zuordnen…',
                // Kein Ellipsis: Lieber zwei Zeilen als ein halber Begriff.
                style: TextStyle(
                  color: gewaehlt == null ? cs.onSurfaceVariant : cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _auswahlOeffnen(BuildContext context) async {
    final gewaehlt = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (blattContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                begriff,
                style: Theme.of(blattContext).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            // Flexible statt fester Höhe: Bei wenigen Optionen bleibt das
            // Blatt niedrig, bei vielen wird es scrollbar statt überzulaufen.
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final eintrag in optionen.entries)
                    ListTile(
                      title: Text(eintrag.value),
                      trailing: eintrag.key == auswahl
                          ? const Icon(Icons.check)
                          : null,
                      selected: eintrag.key == auswahl,
                      onTap: () => Navigator.of(blattContext).pop(eintrag.key),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (gewaehlt != null) onGewaehlt(gewaehlt);
  }
}
