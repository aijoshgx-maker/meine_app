import 'package:flutter/material.dart';

// Toleranzfeld: Nennmaß, oberes Abmaß, unteres Abmaß, Toleranz IT
class ToleranzfeldPainter extends CustomPainter {
  final ColorScheme cs;
  const ToleranzfeldPainter({required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..strokeCap = StrokeCap.square;
    final mid = h * 0.50;
    final left = w * 0.22;
    final right = w * 0.62;
    final boxTop = mid - h * 0.18;
    final boxBot = mid + h * 0.12;

    // Nulllinie (Nennmaß)
    paint
      ..color = cs.outline
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(left - 20, mid), Offset(right + 20, mid), paint);

    // Toleranzfeld (blaues Rechteck)
    final rect = Rect.fromLTRB(left, boxTop, right, boxBot);
    paint
      ..color = cs.primaryContainer
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
    paint
      ..color = cs.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, paint);

    // Maßpfeile + Beschriftungen
    final ts = TextStyle(color: cs.onSurface, fontSize: 10);

    _pfeil(canvas, Offset(right + 14, mid), Offset(right + 14, boxTop), cs.secondary, paint);
    _pfeil(canvas, Offset(right + 14, mid), Offset(right + 14, boxBot), cs.error, paint);

    _text(canvas, 'ES (ob. Abmaß)', Offset(right + 20, boxTop - 2), ts, cs.secondary);
    _text(canvas, 'EI (unt. Abmaß)', Offset(right + 20, boxBot - 2), ts, cs.error);
    _text(canvas, 'Nennmaß N', Offset(right + 20, mid - 6), ts, cs.outline);
    _text(canvas, 'IT = ES − EI', Offset(left + 4, (boxTop + boxBot) / 2 - 6), ts, cs.primary);

    // Werkstück-Silhouette (vereinfacht)
    paint
      ..color = cs.outlineVariant
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTRB(left * 0.18, h * 0.18, left * 0.95, h * 0.82), paint);
    _text(canvas, 'Bohrung / Welle', Offset(2, h * 0.84), TextStyle(color: cs.outline, fontSize: 9), cs.outline);
  }

  void _pfeil(Canvas canvas, Offset from, Offset to, Color color, Paint p) {
    p
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, p);
    // Pfeilspitze
    final dir = (to - from);
    final len = dir.distance;
    final norm = Offset(dir.dx / len, dir.dy / len);
    final perp = Offset(-norm.dy * 4, norm.dx * 4);
    canvas.drawLine(to, to - Offset(norm.dx * 6, norm.dy * 6) + perp, p);
    canvas.drawLine(to, to - Offset(norm.dx * 6, norm.dy * 6) - perp, p);
  }

  void _text(Canvas canvas, String text, Offset pos, TextStyle style, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
