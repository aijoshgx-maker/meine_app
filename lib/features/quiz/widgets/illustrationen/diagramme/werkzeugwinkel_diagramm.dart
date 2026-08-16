import 'dart:math';
import 'package:flutter/material.dart';

// Querschnitt eines Drehmeißels: Spanwinkel γ, Keilwinkel β, Freiwinkel α
class WerkzeugwinkelPainter extends CustomPainter {
  final ColorScheme cs;
  const WerkzeugwinkelPainter({required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    final cx = size.width * 0.38;
    final cy = size.height * 0.72;

    // Werkstück-Oberfläche (horizontale Linie)
    paint
      ..color = cs.outline
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(20, cy), Offset(size.width - 20, cy), paint);

    // Werkzeug-Körper (Dreieck)
    const gammaRad = 10 * pi / 180; // Spanwinkel γ = 10°
    const alphaRad = 8 * pi / 180; // Freiwinkel α = 8°
    final tipX = cx;
    final tipY = cy;
    final spanFaceLen = size.height * 0.55;
    final freiFaceLen = size.height * 0.30;

    final spanX = tipX + spanFaceLen * sin(gammaRad);
    final spanY = tipY - spanFaceLen * cos(gammaRad);
    final freiX = tipX + freiFaceLen * cos(alphaRad);
    final freiY = tipY + freiFaceLen * sin(alphaRad);

    final toolPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(spanX, spanY)
      ..lineTo(spanX + size.width * 0.12, freiY)
      ..lineTo(freiX, freiY)
      ..close();

    paint
      ..color = cs.primaryContainer
      ..style = PaintingStyle.fill;
    canvas.drawPath(toolPath, paint);
    paint
      ..color = cs.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(toolPath, paint);

    // Lotrechte (vertikale Hilfslinie durch Spitze)
    paint
      ..color = cs.outline.withAlpha(120)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(tipX, tipY - size.height * 0.65),
      Offset(tipX, tipY + 10),
      paint,
    );

    final textStyle = TextStyle(
      color: cs.onSurface,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    // Beschriftungen
    _text(
      canvas,
      'α (Freiwinkel)',
      Offset(cx + 18, cy - 14),
      textStyle,
      cs.secondary,
    );
    _text(
      canvas,
      'β (Keilwinkel)',
      Offset(cx - 12, cy - 52),
      textStyle,
      cs.primary,
    );
    _text(
      canvas,
      'γ (Spanwinkel)',
      Offset(cx - 90, cy - 70),
      textStyle,
      cs.tertiary,
    );

    // Winkelbögen
    _bogen(
      canvas,
      Offset(tipX, tipY),
      24,
      -pi / 2,
      -pi / 2 + gammaRad,
      cs.tertiary,
    ); // γ
    _bogen(canvas, Offset(tipX, tipY), 38, 0, alphaRad, cs.secondary); // α
    _bogen(
      canvas,
      Offset(tipX, tipY),
      28,
      alphaRad,
      pi / 2 - gammaRad,
      cs.primary,
    ); // β

    // Beschriftung Werkstück
    _text(
      canvas,
      'Werkstückoberfläche',
      Offset(size.width - 105, cy + 8),
      TextStyle(color: cs.outline, fontSize: 9),
      cs.outline,
    );
  }

  void _bogen(
    Canvas canvas,
    Offset center,
    double r,
    double start,
    double end,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(rect, start, end - start, false, paint);
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
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
