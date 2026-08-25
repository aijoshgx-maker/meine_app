// Auswertung einfacher Rechenausdrücke aus den Fragendaten.
//
// Gebraucht für variierende Aufgaben: Statt eines festen Lösungswerts trägt
// die Frage die Formel, aus der er entsteht ("eta * P1"). Nur so bleibt bei
// gewürfelten Werten eine einzige Wahrheitsquelle - eine zweite, mitgepflegte
// Ergebnisliste würde früher oder später auseinanderlaufen.
//
// Bewusst ein handgeschriebener Parser: Das Projekt kommt ohne
// Codegenerierung und ohne zusätzliche Pakete aus, und der gebrauchte
// Sprachumfang ist klein genug, um ihn vollständig zu prüfen.
library;

import 'dart:math' as math;

/// Fehler in einer Formel aus den Fragendaten.
///
/// Absichtlich eine Ausnahme und kein stilles NaN: Ein Tippfehler in einer
/// Formel soll im Validator auffallen, nicht als leeres Ergebnis in der
/// Aufgabe landen.
class FormelException implements Exception {
  final String nachricht;
  final String formel;

  const FormelException(this.nachricht, this.formel);

  @override
  String toString() => 'FormelException: $nachricht (in "$formel")';
}

/// Wertet [formel] mit den Werten aus [variablen] aus.
///
/// Unterstützt `+ - * / ^`, Klammern, unäres Minus, die Konstante `pi` und
/// die Funktionen `sqrt abs round floor ceil min max sin cos tan ln log`.
///
/// Winkelfunktionen rechnen in **Grad** - technische Aufgaben geben Winkel
/// so an, und `sin(30)` soll 0,5 ergeben und nicht -0,988.
double werteAus(String formel, Map<String, double> variablen) {
  final ergebnis = _Parser(formel, variablen).auswerten();
  if (ergebnis.isNaN || ergebnis.isInfinite) {
    throw FormelException('Ergebnis ist $ergebnis', formel);
  }
  return ergebnis;
}

/// Namen aller Variablen, die [formel] benutzt.
///
/// Der Validator prüft damit, ob eine Formel auf etwas zugreift, das die
/// Frage gar nicht deklariert.
Set<String> variablenIn(String formel) {
  final namen = <String>{};
  for (final treffer in _bezeichner.allMatches(formel)) {
    final name = treffer.group(0)!;
    if (_konstanten.containsKey(name)) continue;
    if (_funktionen.containsKey(name)) continue;
    namen.add(name);
  }
  return namen;
}

final _bezeichner = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');

/// Nur `pi`. Die eulersche Zahl fehlt bewusst: "e" ist in technischen
/// Aufgaben weit häufiger ein Variablenname (Exzentrizität, Dehnung) als
/// eine Konstante, und ein stiller Namenskonflikt wäre hier nicht zu
/// bemerken.
const _konstanten = <String, double>{'pi': math.pi};

double _grad(double x) => x * math.pi / 180;

final _funktionen = <String, double Function(List<double>)>{
  'sqrt': (a) => math.sqrt(a.single),
  'abs': (a) => a.single.abs(),
  'round': (a) => a.single.roundToDouble(),
  'floor': (a) => a.single.floorToDouble(),
  'ceil': (a) => a.single.ceilToDouble(),
  'ln': (a) => math.log(a.single),
  'log': (a) => math.log(a.single) / math.ln10,
  'sin': (a) => math.sin(_grad(a.single)),
  'cos': (a) => math.cos(_grad(a.single)),
  'tan': (a) => math.tan(_grad(a.single)),
  'min': (a) => a.reduce(math.min),
  'max': (a) => a.reduce(math.max),
};

/// Wie viele Argumente eine Funktion nimmt (null = beliebig viele, >= 1).
const _stelligkeit = <String, int?>{
  'sqrt': 1,
  'abs': 1,
  'round': 1,
  'floor': 1,
  'ceil': 1,
  'ln': 1,
  'log': 1,
  'sin': 1,
  'cos': 1,
  'tan': 1,
  'min': null,
  'max': null,
};

/// Rekursiver Abstieg über die übliche Rangfolge:
/// Summe → Produkt → Potenz → Vorzeichen → Grundwert.
class _Parser {
  final String quelle;
  final Map<String, double> variablen;
  int _pos = 0;

  _Parser(this.quelle, this.variablen);

  double auswerten() {
    final wert = _summe();
    _leerzeichenUeberspringen();
    if (_pos < quelle.length) {
      throw FormelException('Unerwartetes Zeichen "${quelle[_pos]}"', quelle);
    }
    return wert;
  }

  void _leerzeichenUeberspringen() {
    while (_pos < quelle.length && quelle[_pos] == ' ') {
      _pos++;
    }
  }

  bool _naechstesIst(String zeichen) {
    _leerzeichenUeberspringen();
    if (_pos < quelle.length && quelle[_pos] == zeichen) {
      _pos++;
      return true;
    }
    return false;
  }

  double _summe() {
    var wert = _produkt();
    while (true) {
      if (_naechstesIst('+')) {
        wert += _produkt();
      } else if (_naechstesIst('-')) {
        wert -= _produkt();
      } else {
        return wert;
      }
    }
  }

  double _produkt() {
    var wert = _vorzeichen();
    while (true) {
      if (_naechstesIst('*')) {
        wert *= _vorzeichen();
      } else if (_naechstesIst('/')) {
        final teiler = _vorzeichen();
        if (teiler == 0) throw FormelException('Division durch null', quelle);
        wert /= teiler;
      } else {
        return wert;
      }
    }
  }

  /// Das Vorzeichen bindet schwächer als die Potenz: -2^2 ist -4, nicht 4.
  double _vorzeichen() {
    if (_naechstesIst('-')) return -_vorzeichen();
    if (_naechstesIst('+')) return _vorzeichen();
    return _potenz();
  }

  /// Rechtsassoziativ: 2^3^2 ist 2^(3^2) = 512, nicht (2^3)^2 = 64.
  /// Der Exponent geht über [_vorzeichen], damit 2^-1 möglich bleibt.
  double _potenz() {
    final basis = _grundwert();
    if (_naechstesIst('^')) {
      return math.pow(basis, _vorzeichen()).toDouble();
    }
    return basis;
  }

  double _grundwert() {
    _leerzeichenUeberspringen();
    if (_pos >= quelle.length) {
      throw FormelException('Ausdruck endet unvollständig', quelle);
    }

    if (_naechstesIst('(')) {
      final wert = _summe();
      if (!_naechstesIst(')')) {
        throw FormelException('Schließende Klammer fehlt', quelle);
      }
      return wert;
    }

    final zeichen = quelle[_pos];
    if (_istZiffer(zeichen) || zeichen == '.') return _zahl();
    if (_bezeichner.matchAsPrefix(quelle, _pos) != null) return _name();

    throw FormelException('Unerwartetes Zeichen "$zeichen"', quelle);
  }

  bool _istZiffer(String z) {
    final code = z.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  double _zahl() {
    final start = _pos;
    while (_pos < quelle.length &&
        (_istZiffer(quelle[_pos]) || quelle[_pos] == '.')) {
      _pos++;
    }
    final text = quelle.substring(start, _pos);
    final wert = double.tryParse(text);
    if (wert == null) throw FormelException('Ungültige Zahl "$text"', quelle);
    return wert;
  }

  double _name() {
    final treffer = _bezeichner.matchAsPrefix(quelle, _pos)!;
    final name = treffer.group(0)!;
    _pos = treffer.end;

    if (_naechstesIst('(')) return _funktionsaufruf(name);

    final konstante = _konstanten[name];
    if (konstante != null) return konstante;

    final wert = variablen[name];
    if (wert == null) {
      throw FormelException('Unbekannte Variable "$name"', quelle);
    }
    return wert;
  }

  double _funktionsaufruf(String name) {
    final funktion = _funktionen[name];
    if (funktion == null) {
      throw FormelException('Unbekannte Funktion "$name"', quelle);
    }

    final argumente = <double>[_summe()];
    while (_naechstesIst(',')) {
      argumente.add(_summe());
    }
    if (!_naechstesIst(')')) {
      throw FormelException('Schließende Klammer nach "$name" fehlt', quelle);
    }

    final erwartet = _stelligkeit[name];
    if (erwartet != null && argumente.length != erwartet) {
      throw FormelException(
        '$name erwartet $erwartet Argument(e), bekam ${argumente.length}',
        quelle,
      );
    }
    return funktion(argumente);
  }
}
