import 'dart:math' as math;
import 'package:flutter/material.dart';

// Zahnrad-Referenzkreise: Kopfkreis Da, Teilkreis d (gestrichelt), Fußkreis Df.
// Annotiert mit m und z aus dem S18-Sekundärrad (m=3, z=82).
class ZahnradGeometriePainter extends CustomPainter {
  final ColorScheme cs;
  const ZahnradGeometriePainter({required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.42;
    final cy = size.height / 2;
    final rA = size.height * 0.40; // Kopfkreis
    final rT = rA * (246 / 252); // Teilkreis  (d=m·z=3·82=246, Da=252)
    final rF = rA * (238.5 / 252); // Fußkreis  (Df=(z-2.5)·m=238.5)

    final solid = Paint()
      ..color = cs.onSurface
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final thin = Paint()
      ..color = cs.onSurface.withAlpha(160)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillGear = Paint()
      ..color = cs.primaryContainer.withAlpha(120)
      ..style = PaintingStyle.fill;

    // Fill between Kopf- und Fußkreis
    canvas.drawCircle(Offset(cx, cy), rA, fillGear);
    canvas.drawCircle(
      Offset(cx, cy),
      rF,
      Paint()
        ..color = cs.surface
        ..style = PaintingStyle.fill,
    );

    // Simplified teeth (7 visible teeth as arcs from rF to rA)
    final z = 82;
    final toothAngle = 2 * math.pi / z;
    final halfTooth = toothAngle * 0.45;
    final toothPath = Path();
    for (int i = 0; i < 7; i++) {
      final ang = i * toothAngle * (82 / 7);
      toothPath.moveTo(
        cx + rF * math.cos(ang - halfTooth),
        cy + rF * math.sin(ang - halfTooth),
      );
      toothPath.lineTo(
        cx + rA * math.cos(ang - halfTooth * 0.5),
        cy + rA * math.sin(ang - halfTooth * 0.5),
      );
      toothPath.arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: rA),
        ang - halfTooth * 0.5,
        halfTooth,
        false,
      );
      toothPath.lineTo(
        cx + rF * math.cos(ang + halfTooth),
        cy + rF * math.sin(ang + halfTooth),
      );
    }
    canvas.drawPath(toothPath, thin);

    // Kopfkreis Da
    canvas.drawCircle(Offset(cx, cy), rA, solid);

    // Teilkreis d (dashed blue)
    _dashedCircle(
      canvas,
      Offset(cx, cy),
      rT,
      Paint()
        ..color = Colors.blue.shade600
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Fußkreis Df (thin)
    canvas.drawCircle(Offset(cx, cy), rF, thin);

    // Center cross
    canvas.drawLine(Offset(cx - 6, cy), Offset(cx + 6, cy), thin);
    canvas.drawLine(Offset(cx, cy - 6), Offset(cx, cy + 6), thin);

    // Leader lines + labels (right side)
    final labelX = cx + rA + 8;
    final on = cs.onSurface;

    // Da label (at top-right of Kopfkreis)
    final daAng = -math.pi / 6;
    _leaderLine(canvas, cx, cy, rA, daAng, labelX, cy - rA * 0.55, thin);
    _label(
      canvas,
      'Da = (z+2)·m',
      Offset(labelX + 4, cy - rA * 0.55),
      on,
      8.5,
      left: true,
    );
    _label(
      canvas,
      '= 252 mm',
      Offset(labelX + 4, cy - rA * 0.55 + 11),
      on,
      8.5,
      left: true,
    );

    // d (Teilkreis) label (mid-right)
    _leaderLine(
      canvas,
      cx,
      cy,
      rT,
      0,
      labelX,
      cy,
      thin..color = Colors.blue.shade600,
    );
    _label(
      canvas,
      'd = z · m',
      Offset(labelX + 4, cy - 5),
      Colors.blue.shade600,
      8.5,
      left: true,
    );
    _label(
      canvas,
      '= 246 mm',
      Offset(labelX + 4, cy + 6),
      Colors.blue.shade600,
      8.5,
      left: true,
    );

    // Df label (bottom-right)
    final dfAng = math.pi / 5;
    _leaderLine(
      canvas,
      cx,
      cy,
      rF,
      dfAng,
      labelX,
      cy + rA * 0.55,
      thin..color = on.withAlpha(140),
    );
    _label(
      canvas,
      'Df = (z−2,5)·m',
      Offset(labelX + 4, cy + rA * 0.55),
      on.withAlpha(160),
      8.5,
      left: true,
    );

    // m and z annotation bottom-left
    _label(canvas, 'm = 3', Offset(cx - rA - 4, cy + rA * 0.3), on, 9);
    _label(canvas, 'z = 82', Offset(cx - rA - 4, cy + rA * 0.55), on, 9);
    _label(canvas, 'Sekundärrad', Offset(cx - rA - 4, cy + rA * 0.0), on, 8);
  }

  void _dashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dash = 0.12;
    const gap = 0.08;
    var a = 0.0;
    while (a < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        a,
        dash,
        false,
        paint,
      );
      a += dash + gap;
    }
  }

  void _leaderLine(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double ang,
    double toX,
    double toY,
    Paint paint,
  ) {
    final fromX = cx + r * math.cos(ang);
    final fromY = cy + r * math.sin(ang);
    canvas.drawLine(Offset(fromX, fromY), Offset(toX, toY), paint);
  }

  void _label(
    Canvas canvas,
    String text,
    Offset pos,
    Color color,
    double fontSize, {
    bool left = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = left ? 0.0 : tp.width / 2;
    tp.paint(canvas, pos - Offset(dx, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
