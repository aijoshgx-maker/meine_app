import 'dart:math';
import 'package:flutter/material.dart';

// Schnittdaten-Diagramm: Schnittgeschwindigkeit vc, Vorschub f, Schnitttiefe ap
class SchnittdatenPainter extends CustomPainter {
  final ColorScheme cs;
  const SchnittdatenPainter({required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.38;
    final cy = h * 0.52;
    final r = h * 0.34;

    final paint = Paint()..strokeCap = StrokeCap.round;

    // Werkstück (rotierender Zylinder — Kreis mit Ellipse)
    paint
      ..color = cs.surfaceContainerHighest
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    paint
      ..color = cs.outline
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Schraffur (Drehhilfslinien)
    paint
      ..color = cs.outline.withAlpha(40)
      ..strokeWidth = 0.8;
    for (int i = -5; i <= 5; i++) {
      final y = cy + i * (r * 0.35);
      final dx = sqrt(max(0.0, r * r - (y - cy) * (y - cy)));
      canvas.drawLine(Offset(cx - dx, y), Offset(cx + dx, y), paint);
    }

    // Werkzeugschneide (Rechteck von rechts ansetzend)
    final toolLeft = cx + r - 2;
    final toolTop = cy - h * 0.08;
    final toolRight = cx + r + w * 0.14;
    final toolBot = cy + h * 0.08;

    paint
      ..color = cs.primaryContainer
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(toolLeft, toolTop, toolRight, toolBot), paint);
    paint
      ..color = cs.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTRB(toolLeft, toolTop, toolRight, toolBot), paint);

    // Spannut (entfernte Schicht)
    paint
      ..color = cs.secondaryContainer
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.80, paint);
    paint
      ..color = cs.secondary.withAlpha(140)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), r * 0.80, paint);

    // Achsenpfeil (Schnittgeschwindigkeit vc — tangential)
    final vcX = cx + r * cos(-0.4);
    final vcY = cy + r * sin(-0.4);
    _pfeil(canvas, Offset(cx + r, cy - 2), Offset(cx + r * 0.55, cy - r * 0.72), cs.tertiary, paint);
    _label(canvas, 'vc (Schnittgeschwindigkeit)', Offset(vcX - 60, vcY - 24),
        TextStyle(color: cs.tertiary, fontSize: 9, fontWeight: FontWeight.w600));

    // Vorschub f (horizontaler Pfeil nach links)
    _pfeil(canvas, Offset(toolRight, cy - h * 0.20), Offset(toolRight - w * 0.10, cy - h * 0.20),
        cs.secondary, paint);
    _label(canvas, 'f  (Vorschub)', Offset(toolRight - w * 0.10 - 4, cy - h * 0.32),
        TextStyle(color: cs.secondary, fontSize: 9, fontWeight: FontWeight.w600));

    // Schnitttiefe ap (vertikaler Pfeil)
    final apX = toolLeft + 6.0;
    _pfeil(canvas, Offset(apX, cy - h * 0.08), Offset(apX, cy - h * 0.34), cs.error, paint);
    _pfeil(canvas, Offset(apX, cy + h * 0.08), Offset(apX, cy + h * 0.20), cs.error, paint);
    _label(canvas, 'ap', Offset(apX + 4, cy - h * 0.24),
        TextStyle(color: cs.error, fontSize: 9, fontWeight: FontWeight.w700));

    // Drehrichtung (Bogenpfeil)
    final arc = Paint()
      ..color = cs.outline
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.12),
      -pi * 0.7, pi * 0.9, false, arc,
    );
    _pfeil(canvas, Offset(cx + r * 1.12 * cos(-pi * 0.7 + pi * 0.9 - 0.05),
              cy + r * 1.12 * sin(-pi * 0.7 + pi * 0.9 - 0.05)),
           Offset(cx + r * 1.12 * cos(-pi * 0.7 + pi * 0.9),
              cy + r * 1.12 * sin(-pi * 0.7 + pi * 0.9)),
           cs.outline, arc);

    _label(canvas, 'Werkstück (rotierend)', Offset(cx - 38, h * 0.88),
        TextStyle(color: cs.outline, fontSize: 9));
  }

  void _pfeil(Canvas canvas, Offset from, Offset to, Color color, Paint p) {
    p
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, p);
    final dir = to - from;
    final len = dir.distance;
    if (len < 1) return;
    final norm = Offset(dir.dx / len, dir.dy / len);
    final perp = Offset(-norm.dy * 4, norm.dx * 4);
    canvas.drawLine(to, to - Offset(norm.dx * 7, norm.dy * 7) + perp, p);
    canvas.drawLine(to, to - Offset(norm.dx * 7, norm.dy * 7) - perp, p);
  }

  void _label(Canvas canvas, String text, Offset pos, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
