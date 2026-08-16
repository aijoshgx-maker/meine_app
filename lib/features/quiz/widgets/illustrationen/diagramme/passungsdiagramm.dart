import 'package:flutter/material.dart';

// Passungsdiagramm: Spielpassung / Übergangspassung / Übermaßpassung
class PassungsPainter extends CustomPainter {
  final ColorScheme cs;
  const PassungsPainter({required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..strokeCap = StrokeCap.square;

    const passungen = [
      ('Spielpassung', 'H7/g6', true),
      ('Übergangs-\npassung', 'H7/k6', false),
      ('Übermaß-\npassung', 'H7/s6', false),
    ];

    final colW = w / 3.2;
    final startX = w * 0.04;
    final midY = h * 0.50;
    final boreTop = midY - h * 0.30;
    final boreBot = midY + h * 0.30;

    for (int i = 0; i < passungen.length; i++) {
      final (titel, code, spiel) = passungen[i];
      final x = startX + i * (colW + 4);

      // Bohrung (grün)
      paint
        ..color = cs.primary.withAlpha(50)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(x, boreTop, x + colW, boreBot), paint);
      paint
        ..color = cs.primary
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(Rect.fromLTRB(x, boreTop, x + colW, boreBot), paint);

      // Welle (Position je Passungsart)
      final shaftTop = spiel
          ? midY +
                h *
                    0.04 // Spielpassung: Welle kleiner als Bohrung
          : i == 1
          ? midY -
                h *
                    0.22 // Übergang: fast gleich
          : midY - h * 0.36; // Übermaß: Welle größer als Bohrung
      final shaftBot = shaftTop + h * 0.24;

      paint
        ..color = cs.secondary.withAlpha(120)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTRB(x + 4, shaftTop, x + colW - 4, shaftBot),
        paint,
      );
      paint
        ..color = cs.secondary
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(
        Rect.fromLTRB(x + 4, shaftTop, x + colW - 4, shaftBot),
        paint,
      );

      // Beschriftung
      _text(
        canvas,
        titel,
        Offset(x + 2, h * 0.03),
        TextStyle(
          color: cs.onSurface,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
        cs.onSurface,
      );
      _text(
        canvas,
        code,
        Offset(x + 2, h * 0.88),
        TextStyle(color: cs.outline, fontSize: 9),
        cs.outline,
      );
    }

    // Legende
    _textBox(canvas, '  Bohrung (H)', Offset(w * 0.05, h * 0.92), cs.primary);
    _textBox(
      canvas,
      '  Welle (Passungsart)',
      Offset(w * 0.35, h * 0.92),
      cs.secondary,
    );
  }

  void _textBox(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _text(
    Canvas canvas,
    String text,
    Offset pos,
    TextStyle style,
    Color color,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
