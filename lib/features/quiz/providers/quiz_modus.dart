// Wie eine Quiz-Session zusammengestellt wird. Wird als Family-Argument an
// quizSessionProvider übergeben, daher MUSS diese Klasse ==/hashCode
// überschreiben (Riverpod cacht Family-Provider-Instanzen anhand davon).
enum QuizArt { freiUebung, heuteFaellig, pruefungssimulation }

class QuizModus {
  final QuizArt art;
  final String? bereich; // nur bei pruefungssimulation
  final Duration? zeitlimit; // nur bei pruefungssimulation

  const QuizModus.freiUebung()
    : art = QuizArt.freiUebung,
      bereich = null,
      zeitlimit = null;

  const QuizModus.heuteFaellig()
    : art = QuizArt.heuteFaellig,
      bereich = null,
      zeitlimit = null;

  const QuizModus.pruefungssimulation({
    required this.bereich,
    required this.zeitlimit,
  }) : art = QuizArt.pruefungssimulation;

  @override
  bool operator ==(Object other) =>
      other is QuizModus &&
      art == other.art &&
      bereich == other.bereich &&
      zeitlimit == other.zeitlimit;

  @override
  int get hashCode => Object.hash(art, bereich, zeitlimit);
}
