import 'themenbereich.dart';

// Der gesamte Lernplan: alle Themenbereiche zusammen. Dient als ein
// Wurzel-Objekt, damit das Dashboard nur ein Objekt zum Anzeigen braucht.
class Lernplan {
  final List<Themenbereich> themenbereiche;

  const Lernplan({required this.themenbereiche});
}
