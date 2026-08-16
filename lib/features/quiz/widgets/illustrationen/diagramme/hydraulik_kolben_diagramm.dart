import 'dart:math' as math;
import 'package:flutter/material.dart';

// Hydraulikzylinder-Querschnitt: Kolben Ø80mm, p→F.
class HydraulikKolbenPainter extends CustomPainter {
  final ColorScheme cs;
  const HydraulikKolbenPainter({required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layout
    const cylLf = 0.06;
    const cylRf = 0.72;
    const cylTf = 0.24;
    const cylBf = 0.76;
    final cylL = w * cylLf;
    final cylR = w * cylRf;
    final cylT = h * cylTf;
    final cylB = h * cylBf;
    final cylH = cylB - cylT;

    final pistonX = cylL + (cylR - cylL) * 0.42;
    final pistonWid = (cylR - cylL) * 0.07;
    final rodT = cylT + cylH * 0.32;
    final rodB = cylB - cylH * 0.32;
    final rodEnd = w * 0.92;

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = cs.onSurface
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Pressure side fill (blue)
    fill.color = Colors.blue.withAlpha(38);
    canvas.drawRect(Rect.fromLTRB(cylL + 2, cylT + 2, pistonX, cylB - 2), fill);

    // Piston fill
    fill.color = cs.primaryContainer;
    canvas.drawRect(
      Rect.fromLTRB(pistonX, cylT, pistonX + pistonWid, cylB),
      fill,
    );

    // Rod fill
    fill.color = cs.secondaryContainer;
    canvas.drawRect(
      Rect.fromLTRB(pistonX + pistonWid, rodT, rodEnd, rodB),
      fill,
    );

    // Cylinder outline (walls + left end)
    canvas.drawLine(Offset(cylL, cylT), Offset(cylR, cylT), stroke);
    canvas.drawLine(Offset(cylL, cylB), Offset(cylR, cylB), stroke);
    canvas.drawLine(Offset(cylL, cylT), Offset(cylL, cylB), stroke);
    // Right end wall (with rod hole)
    canvas.drawLine(Offset(cylR, cylT), Offset(cylR, rodT), stroke);
    canvas.drawLine(Offset(cylR, rodB), Offset(cylR, cylB), stroke);

    // Piston outline
    canvas.drawRect(
      Rect.fromLTRB(pistonX, cylT, pistonX + pistonWid, cylB),
      stroke,
    );

    // Rod outline
    canvas.drawLine(
      Offset(pistonX + pistonWid, rodT),
      Offset(rodEnd, rodT),
      stroke,
    );
    canvas.drawLine(
      Offset(pistonX + pistonWid, rodB),
      Offset(rodEnd, rodB),
      stroke,
    );
    canvas.drawLine(Offset(rodEnd, rodT), Offset(rodEnd, rodB), stroke);

    // Hatching on left end wall
    final hatch = Paint()
      ..color = cs.onSurface.withAlpha(90)
      ..strokeWidth = 0.8;
    for (double y = cylT - 4; y <= cylB + 4; y += 7) {
      canvas.drawLine(Offset(cylL - 7, y), Offset(cylL + 1, y + 8), hatch);
    }

    // Pressure arrow (→ toward piston)
    final midY = (cylT + cylB) / 2;
    _arrow(
      canvas,
      Offset(cylL + 20, midY),
      Offset(pistonX - 6, midY),
      Colors.blue.shade700,
      1.8,
    );

    // Force arrow (→ out of rod)
    _arrow(
      canvas,
      Offset(rodEnd + 4, midY),
      Offset(rodEnd + 26, midY),
      Colors.green.shade700,
      1.8,
    );

    // Diameter dimension arrows (top & bottom of piston center)
    final px = pistonX + pistonWid / 2;
    final dimPaint = Paint()
      ..color = cs.onSurface.withAlpha(110)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(px, cylT - 14), Offset(px, cylT - 4), dimPaint);
    canvas.drawLine(Offset(px, cylB + 4), Offset(px, cylB + 14), dimPaint);
    canvas.drawLine(
      Offset(px - 8, cylT - 10),
      Offset(px + 8, cylT - 10),
      dimPaint,
    );
    canvas.drawLine(
      Offset(px - 8, cylB + 10),
      Offset(px + 8, cylB + 10),
      dimPaint,
    );

    // Labels
    final on = cs.onSurface;
    _label(canvas, 'Ø 80 mm', Offset(px, cylT - 22), on, 9);
    _label(
      canvas,
      'p',
      Offset((cylL + pistonX) / 2 - 14, midY - 10),
      Colors.blue.shade700,
      10,
    );
    _label(
      canvas,
      '= 6 bar',
      Offset((cylL + pistonX) / 2 + 6, midY - 10),
      Colors.blue.shade700,
      9,
    );
    _label(
      canvas,
      'Kolben\n(CuSn8)',
      Offset(pistonX + pistonWid / 2, midY),
      on,
      8,
    );
    _label(
      canvas,
      'Schaltstange',
      Offset((pistonX + pistonWid + cylR) / 2, midY + 4),
      on,
      8,
    );
    _label(
      canvas,
      'F ≈ 3 kN',
      Offset(rodEnd + 16, midY - 14),
      Colors.green.shade700,
      9,
    );
    _label(
      canvas,
      'F = p · A',
      Offset(rodEnd + 16, midY + 8),
      Colors.green.shade700,
      8,
    );
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Color color, double w) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = w
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final ux = dx / len;
    final uy = dy / len;
    const al = 7.0;
    const aw = 4.0;
    final p1 = Offset(to.dx - ux * al + uy * aw, to.dy - uy * al - ux * aw);
    final p2 = Offset(to.dx - ux * al - uy * aw, to.dy - uy * al + ux * aw);
    canvas.drawPath(
      Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _label(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double fontSize,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, height: 1.25),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
