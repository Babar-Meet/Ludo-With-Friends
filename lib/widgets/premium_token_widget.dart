import 'package:flutter/material.dart';
import 'dart:math' as math;

class PremiumTokenWidget extends StatelessWidget {
  final Color color;
  final double size;
  final int shapeType; // 0 = Classic Pawn, 1 = Sphere, 2 = Cylinder

  const PremiumTokenWidget({
    super.key,
    required this.color,
    required this.size,
    this.shapeType = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.25),
      painter: _PremiumTokenPainter(
        color: color, 
        shapeType: shapeType,
        width: size,
        height: size * 1.25,
      ),
    );
  }
}

class _PremiumTokenPainter extends CustomPainter {
  final Color color;
  final int shapeType;
  final double width;
  final double height;

  _PremiumTokenPainter({
    required this.color, 
    required this.shapeType,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shapeType == 0) {
      _drawGlossyPawn(canvas, size);
    } else if (shapeType == 1) {
      _drawGlossyRook(canvas, size);
    } else if (shapeType == 2) {
      _drawGlossyCrown(canvas, size);
    } else if (shapeType == 3) {
      _drawGlossyPin(canvas, size);
    } else if (shapeType == 4) {
      _drawGlossyStar(canvas, size);
    } else {
      _drawGlossyGem(canvas, size);
    }
  }

  void _drawGlossyPawn(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cast soft shadow beneath
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.9), width: w * 0.75, height: h * 0.25),
      shadowPaint,
    );

    // Deep Base Ring (Darker border)
    final baseBorderRect = Rect.fromCenter(center: Offset(w / 2, h * 0.88), width: w * 0.7, height: h * 0.22);
    canvas.drawOval(baseBorderRect, Paint()..color = color.withValues(alpha: 0.6));
    
    // Main Base
    final baseRect = Rect.fromCenter(center: Offset(w / 2, h * 0.85), width: w * 0.65, height: h * 0.2);
    final baseGradient = RadialGradient(
      colors: [color, color.withValues(alpha: 0.6)],
      center: const Alignment(-0.3, -0.5),
      radius: 0.8,
    );
    canvas.drawOval(baseRect, Paint()..shader = baseGradient.createShader(baseRect));
    
    // Glossy Top Ring for Base
    final baseHighlight = Rect.fromCenter(center: Offset(w / 2, h * 0.82), width: w * 0.55, height: h * 0.15);
    canvas.drawOval(baseHighlight, Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Body (Stem)
    final bodyPath = Path()
      ..moveTo(w * 0.3, h * 0.85)
      ..quadraticBezierTo(w * 0.45, h * 0.5, w * 0.4, h * 0.4)
      ..lineTo(w * 0.6, h * 0.4)
      ..quadraticBezierTo(w * 0.55, h * 0.5, w * 0.7, h * 0.85)
      ..close();

    final bodyGradient = LinearGradient(
      colors: [color.withValues(alpha: 0.5), color, Colors.white.withValues(alpha: 0.4), color],
      stops: const [0.0, 0.3, 0.7, 1.0],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    canvas.drawPath(bodyPath, Paint()..shader = bodyGradient.createShader(Rect.fromLTWH(0, 0, w, h)));

    // Collar
    final collarRect = Rect.fromCenter(center: Offset(w / 2, h * 0.4), width: w * 0.5, height: h * 0.12);
    final collarGradient = RadialGradient(
      colors: [Colors.white.withValues(alpha: 0.8), color, color.withValues(alpha: 0.5)],
      center: const Alignment(-0.2, -0.2),
      radius: 0.8,
    );
    canvas.drawOval(collarRect, Paint()..shader = collarGradient.createShader(collarRect));

    // Head (Sphere)
    final headRect = Rect.fromCircle(center: Offset(w / 2, h * 0.22), radius: w * 0.22);
    final headGradient = RadialGradient(
      colors: [Colors.white, color, Colors.black.withValues(alpha: 0.4)],
      stops: const [0.0, 0.5, 1.0],
      center: const Alignment(-0.3, -0.3),
      radius: 0.9,
    );
    canvas.drawCircle(Offset(w / 2, h * 0.22), w * 0.22, Paint()..shader = headGradient.createShader(headRect));
    
    // Intense specular highlight on head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.4, h * 0.13), width: w * 0.15, height: w * 0.08),
      Paint()..color = Colors.white.withValues(alpha: 0.7)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  void _drawGlossyRook(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.9), width: w * 0.75, height: h * 0.25),
      shadowPaint,
    );

    // Deep Base
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.88), width: w * 0.7, height: h * 0.22),
      Paint()..color = color.withValues(alpha: 0.6)
    );
    final baseRect = Rect.fromCenter(center: Offset(w / 2, h * 0.85), width: w * 0.65, height: h * 0.2);
    canvas.drawOval(baseRect, Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0.6)], center: const Alignment(-0.3, -0.5), radius: 0.8).createShader(baseRect));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.82), width: w * 0.55, height: h * 0.15),
      Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2
    );

    // Rook Body (Thick cylinder)
    final bodyPath = Path()
      ..moveTo(w * 0.3, h * 0.85)
      ..lineTo(w * 0.35, h * 0.4)
      ..lineTo(w * 0.65, h * 0.4)
      ..lineTo(w * 0.7, h * 0.85)
      ..close();
    final bodyGradient = LinearGradient(
      colors: [color.withValues(alpha: 0.5), color, Colors.white.withValues(alpha: 0.4), color],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    canvas.drawPath(bodyPath, Paint()..shader = bodyGradient.createShader(Rect.fromLTWH(0, 0, w, h)));

    // Rook Battlements (Top)
    final topRect = Rect.fromCenter(center: Offset(w / 2, h * 0.35), width: w * 0.6, height: h * 0.15);
    canvas.drawOval(topRect, Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.8), color, color.withValues(alpha: 0.5)], center: const Alignment(-0.2, -0.2), radius: 0.8).createShader(topRect));
    
    // Top highlight rim
    canvas.drawOval(topRect, Paint()..color = Colors.white.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Inner hole for rook
    final innerRect = Rect.fromCenter(center: Offset(w / 2, h * 0.33), width: w * 0.35, height: h * 0.08);
    canvas.drawOval(innerRect, Paint()..color = Colors.black.withValues(alpha: 0.4));
  }

  void _drawGlossyCrown(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 0.9), width: w * 0.75, height: h * 0.25), shadowPaint);

    // Deep Base
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 0.88), width: w * 0.7, height: h * 0.22), Paint()..color = color.withValues(alpha: 0.6));
    final baseRect = Rect.fromCenter(center: Offset(w / 2, h * 0.85), width: w * 0.65, height: h * 0.2);
    canvas.drawOval(baseRect, Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0.6)], center: const Alignment(-0.3, -0.5), radius: 0.8).createShader(baseRect));
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 0.82), width: w * 0.55, height: h * 0.15), Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Crown Body
    final bodyPath = Path()
      ..moveTo(w * 0.3, h * 0.85)
      ..lineTo(w * 0.45, h * 0.5) // taper in
      ..lineTo(w * 0.2, h * 0.2) // left point
      ..lineTo(w * 0.4, h * 0.35) // left dip
      ..lineTo(w * 0.5, h * 0.15) // center point
      ..lineTo(w * 0.6, h * 0.35) // right dip
      ..lineTo(w * 0.8, h * 0.2) // right point
      ..lineTo(w * 0.55, h * 0.5) // taper in
      ..lineTo(w * 0.7, h * 0.85) // base
      ..close();

    final bodyGradient = LinearGradient(
      colors: [color.withValues(alpha: 0.5), color, Colors.white.withValues(alpha: 0.4), color],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    canvas.drawPath(bodyPath, Paint()..shader = bodyGradient.createShader(Rect.fromLTWH(0, 0, w, h)));

    // Crown Jewels (Specular highlights)
    final jewelPaint = Paint()..color = Colors.white.withValues(alpha: 0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.2, h * 0.2), width: w * 0.08, height: h * 0.08), jewelPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.15), width: w * 0.1, height: h * 0.1), jewelPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.8, h * 0.2), width: w * 0.08, height: h * 0.08), jewelPaint);
  }

  void _drawGlossyPin(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground Target (Shadow / Base marker)
    // Outer colored ring
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.9), width: w * 0.7, height: h * 0.25),
      Paint()..color = color.withValues(alpha: 0.5),
    );
    // Darker inner ring
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.9), width: w * 0.45, height: h * 0.15),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Center dot
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.9), width: w * 0.2, height: h * 0.08),
      Paint()..color = color.withValues(alpha: 0.8),
    );

    // Teardrop Pin Body
    final pinPath = Path()
      ..moveTo(w / 2, h * 0.9) // Bottom tip
      ..quadraticBezierTo(w * 0.1, h * 0.6, w * 0.15, h * 0.35) // Left curve up
      ..arcToPoint(
        Offset(w * 0.85, h * 0.35),
        radius: Radius.circular(w * 0.35),
        clockwise: true,
      ) // Top round
      ..quadraticBezierTo(w * 0.9, h * 0.6, w / 2, h * 0.9) // Right curve down
      ..close();

    final pinGradient = RadialGradient(
      colors: [Colors.white, Colors.grey.shade300, Colors.grey.shade600],
      stops: const [0.0, 0.6, 1.0],
      center: const Alignment(-0.2, -0.4),
      radius: 0.8,
    );
    
    // Draw the pin body with shadow
    canvas.drawShadow(pinPath, Colors.black, 4, false);
    canvas.drawPath(pinPath, Paint()..shader = pinGradient.createShader(Rect.fromLTWH(0, 0, w, h)));

    // Pin Body Highlight (Specular)
    final highlightPath = Path()
      ..moveTo(w / 2, h * 0.8)
      ..quadraticBezierTo(w * 0.2, h * 0.6, w * 0.25, h * 0.35)
      ..arcToPoint(
        Offset(w * 0.4, h * 0.1),
        radius: Radius.circular(w * 0.35),
        clockwise: true,
      )
      ..quadraticBezierTo(w * 0.3, h * 0.4, w / 2, h * 0.8)
      ..close();
    canvas.drawPath(highlightPath, Paint()..color = Colors.white.withValues(alpha: 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // Inner Colored Sphere
    final innerSphereCenter = Offset(w / 2, h * 0.35);
    final innerSphereRadius = w * 0.22;
    
    // Dark recess behind sphere
    canvas.drawCircle(
      innerSphereCenter, 
      innerSphereRadius + 1, 
      Paint()..color = Colors.black.withValues(alpha: 0.5)
    );

    // Colored Orb
    final orbGradient = RadialGradient(
      colors: [Colors.white, color, Colors.black.withValues(alpha: 0.7)],
      stops: const [0.0, 0.4, 1.0],
      center: const Alignment(-0.3, -0.3),
      radius: 0.9,
    );
    canvas.drawCircle(
      innerSphereCenter, 
      innerSphereRadius, 
      Paint()..shader = orbGradient.createShader(Rect.fromCircle(center: innerSphereCenter, radius: innerSphereRadius))
    );

    // Orb Specular Highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(innerSphereCenter.dx - innerSphereRadius * 0.3, innerSphereCenter.dy - innerSphereRadius * 0.3), width: innerSphereRadius * 0.6, height: innerSphereRadius * 0.4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  void _drawGlossyStar(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 0.9), width: w * 0.75, height: h * 0.25), shadowPaint);

    // Base
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 0.88), width: w * 0.7, height: h * 0.22), Paint()..color = color.withValues(alpha: 0.6));
    final baseRect = Rect.fromCenter(center: Offset(w / 2, h * 0.85), width: w * 0.65, height: h * 0.2);
    canvas.drawOval(baseRect, Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0.6)], center: const Alignment(-0.3, -0.5), radius: 0.8).createShader(baseRect));
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 0.82), width: w * 0.55, height: h * 0.15), Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Star Body (5-pointed floating above base)
    final double cx = w / 2;
    final double cy = h * 0.45;
    final double outerRadius = w * 0.4;
    final double innerRadius = w * 0.15;
    
    final starPath = Path();
    for (int i = 0; i < 10; i++) {
      double angle = -math.pi / 2 + (i * math.pi / 5);
      double r = (i % 2 == 0) ? outerRadius : innerRadius;
      double px = cx + r * math.cos(angle);
      double py = cy + r * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(px, py);
      } else {
        starPath.lineTo(px, py);
      }
    }
    starPath.close();

    final starGradient = RadialGradient(
      colors: [Colors.white, color, Colors.black.withValues(alpha: 0.6)],
      stops: const [0.0, 0.4, 1.0],
      center: const Alignment(-0.3, -0.3),
      radius: 0.9,
    );
    canvas.drawPath(starPath, Paint()..shader = starGradient.createShader(Rect.fromCircle(center: Offset(cx, cy), radius: outerRadius)));

    // Star Specular Highlight
    final highlightPath = Path()
      ..moveTo(cx, cy - outerRadius * 0.8)
      ..lineTo(cx + outerRadius * 0.2, cy - innerRadius)
      ..lineTo(cx - outerRadius * 0.2, cy - innerRadius)
      ..close();
    canvas.drawPath(highlightPath, Paint()..color = Colors.white.withValues(alpha: 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
  }

  void _drawGlossyGem(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 0.9), width: w * 0.75, height: h * 0.25), shadowPaint);

    // Base
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 0.88), width: w * 0.7, height: h * 0.22), Paint()..color = color.withValues(alpha: 0.6));
    final baseRect = Rect.fromCenter(center: Offset(w / 2, h * 0.85), width: w * 0.65, height: h * 0.2);
    canvas.drawOval(baseRect, Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0.6)], center: const Alignment(-0.3, -0.5), radius: 0.8).createShader(baseRect));
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 0.82), width: w * 0.55, height: h * 0.15), Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Gem Body (Hexagonal prism)
    final topY = h * 0.15;
    final midY = h * 0.35;
    final botY = h * 0.75;
    
    // Left facet
    final leftFacet = Path()
      ..moveTo(w / 2, topY)
      ..lineTo(w * 0.2, midY)
      ..lineTo(w * 0.3, botY)
      ..lineTo(w / 2, botY)
      ..close();
    canvas.drawPath(leftFacet, Paint()..color = color.withValues(alpha: 0.8));
    
    // Right facet
    final rightFacet = Path()
      ..moveTo(w / 2, topY)
      ..lineTo(w * 0.8, midY)
      ..lineTo(w * 0.7, botY)
      ..lineTo(w / 2, botY)
      ..close();
    canvas.drawPath(rightFacet, Paint()..color = color.withValues(alpha: 0.5));
    
    // Center facet
    final centerFacet = Path()
      ..moveTo(w * 0.4, topY + h * 0.05)
      ..lineTo(w * 0.6, topY + h * 0.05)
      ..lineTo(w * 0.7, midY)
      ..lineTo(w * 0.6, botY)
      ..lineTo(w * 0.4, botY)
      ..lineTo(w * 0.3, midY)
      ..close();
    final centerGradient = LinearGradient(
      colors: [Colors.white.withValues(alpha: 0.8), color, color],
      stops: const [0.0, 0.4, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    canvas.drawPath(centerFacet, Paint()..shader = centerGradient.createShader(Rect.fromLTWH(w*0.3, topY, w*0.4, botY-topY)));

    // Highlight
    final highlightPath = Path()
      ..moveTo(w * 0.4, topY + h * 0.05)
      ..lineTo(w * 0.6, topY + h * 0.05)
      ..lineTo(w * 0.5, midY)
      ..close();
    canvas.drawPath(highlightPath, Paint()..color = Colors.white.withValues(alpha: 0.9)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));
  }

  @override
  bool? hitTest(Offset position) {
    final w = width;
    final h = height;
    final x = position.dx;
    final y = position.dy;

    // Check base oval (center: w/2, h*0.85, width: w*0.7, height: h*0.22 -> rx=w*0.35, ry=h*0.11)
    double dx = (x - w / 2) / (w * 0.35);
    double dy = (y - h * 0.85) / (h * 0.15); // slightly larger ry to be forgiving
    if (dx * dx + dy * dy <= 1.0) return true;

    // Check head circle/top area
    double hx = (x - w / 2) / (w * 0.35);
    double hy = (y - h * 0.35) / (w * 0.35);
    if (hx * hx + hy * hy <= 1.0) return true;

    // Check central body rectangle
    if (x >= w * 0.25 && x <= w * 0.75 && y >= h * 0.3 && y <= h * 0.85) return true;

    // Additional check for wider middle parts (like the Star or Crown)
    if (x >= w * 0.15 && x <= w * 0.85 && y >= h * 0.35 && y <= h * 0.65) return true;

    return false;
  }

  @override
  bool shouldRepaint(covariant _PremiumTokenPainter oldDelegate) {
    return color != oldDelegate.color || 
           shapeType != oldDelegate.shapeType ||
           width != oldDelegate.width ||
           height != oldDelegate.height;
  }
}
