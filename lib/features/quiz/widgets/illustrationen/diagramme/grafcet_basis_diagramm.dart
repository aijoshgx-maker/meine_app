import 'package:flutter/material.dart';

// GRAFCET-Grundstruktur: Initialschritt (S0, Doppelrahmen),
// Transition, Schritt S1 mit Aktion, Transition mit Bedingung, Schritt S2.
class GrafcetBasisPainter extends CustomPainter {
  final ColorScheme cs;
  const GrafcetBasisPainter({required this.cs});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final cx = w * 0.30; // center x for the step column
    const stepW = 90.0;
    const stepH = 28.0;
    const transW = 28.0;
    const transH = 3.0;

    // Vertical layout
    final s0Y = h * 0.12;
    final t01Y = h * 0.38;
    final s1Y = h * 0.55;
    final t12Y = h * 0.78;
    final s2Y = h * 0.91;

    final on = cs.onSurface;
    final stroke = Paint()
      ..color = on
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = cs.primaryContainer
      ..style = PaintingStyle.fill;
    final thinFill = Paint()
      ..color = cs.secondaryContainer
      ..style = PaintingStyle.fill;

    // --- S0: Initialschritt (double border) ---
    final s0Rect = Rect.fromCenter(
        center: Offset(cx, s0Y + stepH / 2),
        width: stepW,
        height: stepH);
    canvas.drawRect(s0Rect, fill);
    canvas.drawRect(s0Rect, stroke);
    // Inner border (double frame)
    canvas.drawRect(s0Rect.deflate(3), stroke);
    _stepLabel(canvas, 'S0', '(Grundstellung)', s0Rect, on);

    // Vertical line S0 → T01
    final s0Bottom = s0Y + stepH;
    canvas.drawLine(Offset(cx, s0Bottom), Offset(cx, t01Y), stroke);

    // --- T01: Transition ---
    _transition(canvas, cx, t01Y, transW, transH, 'Startbedingung', on, stroke);

    // Vertical line T01 → S1
    canvas.drawLine(
        Offset(cx, t01Y + transH + 2), Offset(cx, s1Y), stroke);

    // --- S1: Aktion ---
    final s1Rect = Rect.fromCenter(
        center: Offset(cx, s1Y + stepH / 2),
        width: stepW,
        height: stepH);
    canvas.drawRect(s1Rect, fill);
    canvas.drawRect(s1Rect, stroke);
    _stepLabel(canvas, 'S1', 'EH1 EIN', s1Rect, on);

    // Action box (attached to right of S1)
    final actRect = Rect.fromLTWH(
        cx + stepW / 2, s1Y + 4, 55, stepH - 8);
    canvas.drawRect(actRect, thinFill);
    canvas.drawRect(actRect, stroke..strokeWidth = 1.0);
    _smallLabel(canvas, 'Aktion:', Offset(actRect.left + 4, actRect.top + 2), on, 7.5);
    _smallLabel(canvas, 'EH1 = 1', Offset(actRect.left + 4, actRect.top + 11), on, 8.5);
    stroke.strokeWidth = 1.6;

    // Vertical line S1 → T12
    canvas.drawLine(
        Offset(cx, s1Y + stepH), Offset(cx, t12Y), stroke);

    // --- T12: Transition with condition ---
    _transition(canvas, cx, t12Y, transW, transH, 'BT1 ≥ T_soll', on, stroke);

    // Vertical line T12 → S2
    canvas.drawLine(
        Offset(cx, t12Y + transH + 2), Offset(cx, s2Y), stroke);

    // --- S2: nächster Schritt ---
    final s2Rect = Rect.fromCenter(
        center: Offset(cx, s2Y + stepH / 2),
        width: stepW,
        height: stepH);
    canvas.drawRect(s2Rect, fill);
    canvas.drawRect(s2Rect, stroke);
    _stepLabel(canvas, 'S2', 'EH1 AUS', s2Rect, on);

    // Legend on right
    final legendX = w * 0.62;
    final legendPaint = Paint()
      ..color = on.withAlpha(180)
      ..strokeWidth = 1.2;
    _legendItem(canvas, legendX, h * 0.20, stepW * 0.6, stepH * 0.7,
        'Schritt\n(stabile Phase)', on, legendPaint, fill);
    _legendItem(canvas, legendX, h * 0.50, stepW * 0.6, transH + 2,
        'Transition\n(Bedingung)', on, legendPaint, Paint()..color = on..style = PaintingStyle.fill);
  }

  void _stepLabel(Canvas canvas, String nr, String aktion, Rect rect, Color on) {
    final nrTp = TextPainter(
      text: TextSpan(
          text: nr,
          style: TextStyle(
              color: on,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    nrTp.paint(
        canvas, Offset(rect.left + 4, rect.top + (rect.height - nrTp.height) / 2));

    final akTp = TextPainter(
      text: TextSpan(
          text: aktion, style: TextStyle(color: on, fontSize: 8.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    akTp.paint(canvas,
        Offset(rect.left + 20, rect.top + (rect.height - akTp.height) / 2));
  }

  void _smallLabel(Canvas canvas, String text, Offset pos, Color color,
      double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _transition(Canvas canvas, double cx, double y, double tw, double th,
      String cond, Color on, Paint stroke) {
    // Horizontal bar
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, y + th / 2), width: tw, height: th),
      Paint()..color = on..style = PaintingStyle.fill,
    );
    // Short vertical stubs
    canvas.drawLine(Offset(cx, y - 5), Offset(cx, y), stroke);
    canvas.drawLine(Offset(cx, y + th), Offset(cx, y + th + 5), stroke);
    // Condition label to the right
    final tp = TextPainter(
      text: TextSpan(
          text: cond,
          style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 8.5,
              fontStyle: FontStyle.italic)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx + tw / 2 + 4, y - tp.height / 2));
  }

  void _legendItem(Canvas canvas, double x, double y, double bW, double bH,
      String label, Color on, Paint paint, Paint boxFill) {
    final rect = Rect.fromLTWH(x, y, bW, bH);
    canvas.drawRect(rect, boxFill);
    canvas.drawRect(rect, paint);
    final tp = TextPainter(
      text: TextSpan(
          text: label,
          style: TextStyle(color: on.withAlpha(170), fontSize: 8, height: 1.3)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + bW + 5, y + bH / 2 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
