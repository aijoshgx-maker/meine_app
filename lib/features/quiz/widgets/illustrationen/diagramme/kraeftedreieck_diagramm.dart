import 'dart:math';
import 'package:flutter/material.dart';

// Kräftedreieck beim Zerspanen: Schnittkraft Fc, Vorschubkraft Ff, Resultierende F
class KraefteDreieckPainter extends CustomPainter {
  final ColorScheme cs;
  const KraefteDreieckPainter({required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..strokeCap = StrokeCap.round;

    // Ursprung (Angriffspunkt Schneide)
    final ox = w * 0.22;
    final oy = h * 0.72;

    // Fc (Schnittkraft) — senkrecht nach oben
    final fcEnd = Offset(ox, oy - h * 0.55);
    // Ff (Vorschubkraft) — waagerecht nach rechts
    final ffEnd = Offset(ox + w * 0.55, oy);
    // Resultierende F = Fc + Ff (Diagonale des Kräfteparallelogramms)
    final fEnd = Offset(ox + w * 0.55, oy - h * 0.55);

    // Kräfteparallelogramm (gestrichelt)
    paint
      ..color = cs.outline.withAlpha(80)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _strichlinie(canvas, fcEnd, fEnd, paint);
    _strichlinie(canvas, ffEnd, fEnd, paint);

    // Fc (Schnittkraft — primär)
    _pfeil(canvas, Offset(ox, oy), fcEnd, cs.primary, 2.0, paint);
    _label(
      canvas,
      'Fc\n(Schnittkraft)',
      Offset(ox - 62, oy - h * 0.38),
      TextStyle(color: cs.primary, fontSize: 9, fontWeight: FontWeight.w700),
    );

    // Ff (Vorschubkraft)
    _pfeil(canvas, Offset(ox, oy), ffEnd, cs.secondary, 2.0, paint);
    _label(
      canvas,
      'Ff (Vorschubkraft)',
      Offset(ox + w * 0.18, oy + 8),
      TextStyle(color: cs.secondary, fontSize: 9, fontWeight: FontWeight.w700),
    );

    // Resultierende F
    _pfeil(canvas, Offset(ox, oy), fEnd, cs.tertiary, 2.5, paint);
    _label(
      canvas,
      'F (Resultierende)',
      Offset(ox + w * 0.20, oy - h * 0.34),
      TextStyle(color: cs.tertiary, fontSize: 9, fontWeight: FontWeight.w700),
    );

    // Winkel φ zwischen Fc und F
    final angle = atan2(w * 0.55, h * 0.55);
    final arc = Paint()
      ..color = cs.outline
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(ox, oy), radius: 28),
      -pi / 2,
      angle,
      false,
      arc,
    );
    _label(
      canvas,
      'φ',
      Offset(ox + 10, oy - 30),
      TextStyle(color: cs.outline, fontSize: 9),
    );

    // Maßstab-Hinweis
    _label(
      canvas,
      'Kräfteparallelogramm',
      Offset(w * 0.28, h * 0.89),
      TextStyle(color: cs.outline, fontSize: 8),
    );

    // Koordinatenachsen (klein, Ursprung)
    paint
      ..color = cs.outline.withAlpha(100)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(ox, oy), Offset(ox + 20, oy), paint);
    canvas.drawLine(Offset(ox, oy), Offset(ox, oy - 20), paint);
    _label(
      canvas,
      'x',
      Offset(ox + 22, oy - 6),
      TextStyle(color: cs.outline, fontSize: 8),
    );
    _label(
      canvas,
      'y',
      Offset(ox + 3, oy - 24),
      TextStyle(color: cs.outline, fontSize: 8),
    );
  }

  void _strichlinie(Canvas canvas, Offset from, Offset to, Paint p) {
    final dir = to - from;
    final len = dir.distance;
    final norm = Offset(dir.dx / len, dir.dy / len);
    double d = 0;
    bool draw = true;
    while (d < len) {
      final seg = min(6.0, len - d);
      final a = from + norm * d;
      final b = from + norm * (d + seg);
      if (draw) canvas.drawLine(a, b, p);
      d += 6;
      draw = !draw;
    }
  }

  void _pfeil(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
    double width,
    Paint p,
  ) {
    p
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, p);
    final dir = to - from;
    final len = dir.distance;
    if (len < 1) return;
    final norm = Offset(dir.dx / len, dir.dy / len);
    final perp = Offset(-norm.dy * 5, norm.dx * 5);
    canvas.drawLine(to, to - Offset(norm.dx * 9, norm.dy * 9) + perp, p);
    canvas.drawLine(to, to - Offset(norm.dx * 9, norm.dy * 9) - perp, p);
  }

  void _label(Canvas canvas, String text, Offset pos, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
