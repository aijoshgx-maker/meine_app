// Wie eine Quiz-Session zusammengestellt wird. Wird als Family-Argument an
// quizSessionProvider übergeben, daher MUSS diese Klasse ==/hashCode
// überschreiben (Riverpod cacht Family-Provider-Instanzen anhand davon).
enum QuizArt { freiUebung, heuteFaellig, themenVertiefung, pruefungssimulation }

class QuizModus {
  final QuizArt art;
  final String? kategorie; // nur bei themenVertiefung
  final String?
  pruefungsId; // nur bei pruefungssimulation ("W22","S17","S19","S18")
  final int? zeitlimitMinuten; // nur bei pruefungssimulation

  const QuizModus.freiUebung()
    : art = QuizArt.freiUebung,
      kategorie = null,
      pruefungsId = null,
      zeitlimitMinuten = null;

  const QuizModus.heuteFaellig()
    : art = QuizArt.heuteFaellig,
      kategorie = null,
      pruefungsId = null,
      zeitlimitMinuten = null;

  const QuizModus.themenVertiefung({required this.kategorie})
    : art = QuizArt.themenVertiefung,
      pruefungsId = null,
      zeitlimitMinuten = null;

  const QuizModus.pruefungssimulation({
    required this.pruefungsId,
    required this.zeitlimitMinuten,
  }) : art = QuizArt.pruefungssimulation,
       kategorie = null;

  @override
  bool operator ==(Object other) =>
      other is QuizModus &&
      art == other.art &&
      kategorie == other.kategorie &&
      pruefungsId == other.pruefungsId &&
      zeitlimitMinuten == other.zeitlimitMinuten;

  @override
  int get hashCode =>
      Object.hash(art, kategorie, pruefungsId, zeitlimitMinuten);
}
