// Eine Multiple-Choice-Frage für den Checkpoint-Test am Ende eines Moduls.
class CheckpointFrage {
  final String id;
  final String frageText;
  final List<String> antwortOptionen;
  final int richtigeAntwortIndex;
  final String? erklaerung;

  const CheckpointFrage({
    required this.id,
    required this.frageText,
    required this.antwortOptionen,
    required this.richtigeAntwortIndex,
    this.erklaerung,
  });

  factory CheckpointFrage.fromJson(Map<String, dynamic> json) {
    return CheckpointFrage(
      id: json['id'] as String,
      frageText: json['frageText'] as String,
      antwortOptionen: (json['antwortOptionen'] as List)
          .map((option) => option as String)
          .toList(),
      richtigeAntwortIndex: json['richtigeAntwortIndex'] as int,
      erklaerung: json['erklaerung'] as String?,
    );
  }
}
