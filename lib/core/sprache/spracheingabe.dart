// Diktierte Antworten: Sprache zu Text.
//
// Duenne Huelle um speech_to_text. Der Sinn ist nicht, das Paket zu
// verstecken, sondern die Oberflaeche testbar zu halten: Ein Widget-Test
// kann keine echte Spracherkennung starten, wohl aber eine Fake-Umsetzung
// dieser Klasse einsetzen.
//
// Das Fachgespraech wird gesprochen gefuehrt - eine Antwort zu tippen ist
// eine andere Uebung als eine zu formulieren. Die Tastatur bleibt trotzdem:
// Nicht jedes Geraet kann Spracherkennung, und nicht jede Umgebung erlaubt
// lautes Sprechen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Zustand einer laufenden Aufnahme, wie ihn die Oberflaeche braucht.
enum Sprachzustand { aus, hoert, verarbeitet }

class Spracheingabe {
  final SpeechToText _dienst;

  Spracheingabe({SpeechToText? dienst}) : _dienst = dienst ?? SpeechToText();

  bool _bereit = false;
  bool _versucht = false;

  /// Ob das Geraet Spracherkennung anbietet und die Erlaubnis vorliegt.
  ///
  /// Erst nach [vorbereiten] aussagekraeftig. Ist sie false, blendet die
  /// Oberflaeche den Knopf ganz aus - ein Knopf, der nichts tut, ist
  /// schlimmer als keiner.
  bool get verfuegbar => _bereit;

  bool get laeuft => _dienst.isListening;

  /// Fragt einmalig Verfuegbarkeit und Mikrofonerlaubnis ab.
  ///
  /// Der Berechtigungsdialog erscheint hier - deshalb wird die Methode erst
  /// beim ersten Tippen auf den Knopf gerufen und nicht beim App-Start. Ein
  /// ungefragter Mikrofon-Dialog beim Oeffnen der App waere uebergriffig.
  Future<bool> vorbereiten() async {
    if (_versucht) return _bereit;
    _versucht = true;
    try {
      _bereit = await _dienst.initialize();
    } catch (_) {
      // Auf Plattformen ohne Erkennung wirft das Paket statt false zu
      // liefern. Fuer die Oberflaeche ist beides dasselbe: kein Mikrofon.
      _bereit = false;
    }
    return _bereit;
  }

  /// Startet die Aufnahme.
  ///
  /// [onText] wird waehrend des Sprechens mehrfach gerufen; [endgueltig]
  /// sagt, ob der Text noch korrigiert werden kann. Die Oberflaeche zeigt
  /// auch Zwischenstaende an, sonst wirkt die Aufnahme wie eingefroren.
  Future<void> starten({
    required void Function(String text, bool endgueltig) onText,
    void Function()? onEnde,
  }) async {
    if (!_bereit) return;
    await _dienst.listen(
      onResult: (ergebnis) =>
          onText(ergebnis.recognizedWords, ergebnis.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: 'de_DE',
        partialResults: true,
        // Antworten im Fachgespraech sind mehrere Saetze. Die Voreinstellung
        // beendet die Aufnahme nach der ersten Sprechpause - das wuerde
        // mitten im Gedanken abschneiden.
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(minutes: 2),
      ),
    );
    if (onEnde != null) {
      _dienst.statusListener = (status) {
        if (status == 'done' || status == 'notListening') onEnde();
      };
    }
  }

  Future<void> stoppen() async {
    if (!_dienst.isListening) return;
    await _dienst.stop();
  }
}

/// Ueberschreibbar, damit Widget-Tests ohne echtes Mikrofon auskommen.
final spracheingabeProvider = Provider<Spracheingabe>((ref) => Spracheingabe());
