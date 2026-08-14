import 'package:flutter/material.dart';

// 5/2-Wegeventil (ISO 1219): Normstellung links, geschaltet rechts
class Pneumatik52VentilPainter extends CustomPainter {
  final ColorScheme cs;
  const Pneumatik52VentilPainter({required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..strokeCap = StrokeCap.round;

    // ──────────────────────────────────────────────────────
    // Symbol-Layout: zwei Schaltfelder nebeneinander
    // ──────────────────────────────────────────────────────
    final boxH = h * 0.44;
    final boxW = w * 0.28;
    final yTop = h * 0.18;
    final x1 = w * 0.10; // Schaltstellung 1 (aktiv)
    final x2 = x1 + boxW; // Schaltstellung 2 (Ruhe)

    // Hintergrund der aktiven Stellung
    paint
      ..color = cs.primaryContainer
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x1, yTop, boxW, boxH), paint);

    // Rahmen beider Felder
    paint
      ..color = cs.outline
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(x1, yTop, boxW, boxH), paint);
    canvas.drawRect(Rect.fromLTWH(x2, yTop, boxW, boxH), paint);

    // ──── Schaltstellung 1: Kreuzkonfiguration ────
    final mid1X = x1 + boxW / 2;
    // Linie von unten-links nach oben-rechts + von oben-links nach unten-rechts
    _linie(canvas, Offset(x1 + 4, yTop + boxH - 4), Offset(x1 + boxW - 4, yTop + 4), cs.primary, 1.5, paint);
    _linie(canvas, Offset(x1 + 4, yTop + 4), Offset(x1 + boxW - 4, yTop + boxH - 4), cs.primary, 1.5, paint);

    // ──── Schaltstellung 2: Parallelleitungen ────
    _linie(canvas, Offset(x2 + boxW * 0.25, yTop + 4), Offset(x2 + boxW * 0.25, yTop + boxH - 4),
        cs.outline, 1.5, paint);
    _linie(canvas, Offset(x2 + boxW * 0.75, yTop + 4), Offset(x2 + boxW * 0.75, yTop + boxH - 4),
        cs.outline, 1.5, paint);

    // ──────────────────────────────────────────────────────
    // Anschlüsse nach ISO 1219 (P,A,B,R,S)
    // ──────────────────────────────────────────────────────
    final yUnten = yTop + boxH;
    final yOben = yTop;
    final portY1 = yUnten + h * 0.12;
    final portY2 = yOben - h * 0.12;

    // P (Druckluft) — unten Mitte Feld 1
    _anschluss(canvas, Offset(mid1X, yUnten), Offset(mid1X, portY1), 'P', false, paint, cs);
    // R (Entlüftung) — unten links
    _anschluss(canvas, Offset(x1 + boxW * 0.25, yUnten), Offset(x1 + boxW * 0.25, portY1), 'R', false, paint, cs);
    // S (Entlüftung 2) — unten rechts Feld 2
    _anschluss(canvas, Offset(x2 + boxW * 0.75, yUnten), Offset(x2 + boxW * 0.75, portY1), 'S', false, paint, cs);

    // A — oben links Feld 1
    _anschluss(canvas, Offset(x1 + boxW * 0.25, yOben), Offset(x1 + boxW * 0.25, portY2), 'A', true, paint, cs);
    // B — oben rechts Feld 2
    _anschluss(canvas, Offset(x2 + boxW * 0.75, yOben), Offset(x2 + boxW * 0.75, portY2), 'B', true, paint, cs);

    // ──────────────────────────────────────────────────────
    // Betätigung: Elektromagnet links, Feder rechts
    // ──────────────────────────────────────────────────────
    final magLeft = x1 - w * 0.10;
    final magTop = yTop + boxH * 0.15;
    final magBot = yTop + boxH * 0.85;
    // Elektromagnet (Rechteck + Spulen-Symbol)
    paint
      ..color = cs.secondaryContainer
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(magLeft, magTop, w * 0.09, magBot - magTop), paint);
    paint
      ..color = cs.secondary
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(magLeft, magTop, w * 0.09, magBot - magTop), paint);
    // Spulen-Linie
    _linie(canvas, Offset(magLeft + w * 0.025, magTop + 4), Offset(magLeft + w * 0.025, magBot - 4),
        cs.secondary, 1, paint);
    _label(canvas, 'Y1', Offset(magLeft + 2, magTop - 14),
        TextStyle(color: cs.secondary, fontSize: 9, fontWeight: FontWeight.w700));
    // Verbindung Magnet → Feld1
    _linie(canvas, Offset(magLeft + w * 0.09, (magTop + magBot) / 2),
        Offset(x1, (magTop + magBot) / 2), cs.outline, 1, paint);

    // Feder (Zickzack rechts)
    final sprX = x2 + boxW + w * 0.01;
    final sprMid = (magTop + magBot) / 2;
    _feder(canvas, Offset(sprX, sprMid), Offset(sprX + w * 0.08, sprMid), cs.outline, paint);
    _label(canvas, '(Feder)', Offset(sprX + w * 0.02, sprMid + 6),
        TextStyle(color: cs.outline, fontSize: 8));

    // Titel
    _label(canvas, '5/2-Wegeventil (ISO 1219)', Offset(w * 0.08, h * 0.04),
        TextStyle(color: cs.onSurface, fontSize: 10, fontWeight: FontWeight.w600));
    _label(canvas, '■ aktive Stellung', Offset(x1 + 2, yTop + boxH + h * 0.26),
        TextStyle(color: cs.primary, fontSize: 8));
  }

  void _anschluss(Canvas canvas, Offset from, Offset to, String label, bool oben,
      Paint p, ColorScheme cs) {
    p
      ..color = cs.outline
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, p);
    final tp = TextPainter(
      text: TextSpan(
          text: label,
          style: TextStyle(color: cs.onSurface, fontSize: 10, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(to.dx - tp.width / 2, oben ? to.dy - tp.height - 2 : to.dy + 2));
  }

  void _linie(Canvas canvas, Offset from, Offset to, Color color, double width, Paint p) {
    p
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, p);
  }

  void _feder(Canvas canvas, Offset from, Offset to, Color color, Paint p) {
    p
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final steps = 8;
    final dx = (to.dx - from.dx) / steps;
    final amp = 5.0;
    final path = Path()..moveTo(from.dx, from.dy);
    for (int i = 0; i < steps; i++) {
      final x = from.dx + i * dx + dx / 2;
      final y = from.dy + (i.isEven ? -amp : amp);
      path.lineTo(x, y);
    }
    path.lineTo(to.dx, to.dy);
    canvas.drawPath(path, p);
  }

  void _label(Canvas canvas, String text, Offset pos, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 200);
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
