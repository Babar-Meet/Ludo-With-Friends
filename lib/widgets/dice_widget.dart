import 'package:flutter/material.dart';
import 'dart:math';

class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final VoidCallback? onRoll;

  const DiceWidget({
    super.key,
    required this.value,
    this.isRolling = false,
    this.onRoll,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _FaceDef {
  final int value;
  final double x;
  final double y;
  final double z;
  final Matrix4 transform;
  double transformedZ = 0.0;

  _FaceDef(this.value, this.x, this.y, this.z, this.transform);
}

class _DiceWidgetState extends State<DiceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  double _startX = 0;
  double _startY = 0;
  int _targetValue = 1;

  @override
  void initState() {
    super.initState();
    _targetValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      // Since it wasn't rolling before, it was resting exactly at the target rotation.
      _startX = _getTargetX(_targetValue);
      _startY = _getTargetY(_targetValue);
      _targetValue = widget.value;
      _controller.forward(from: 0.0);
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _targetValue = widget.value;
      if (!_controller.isAnimating) {
        _controller.value = 1.0;
      }
    } else if (!widget.isRolling) {
      _targetValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getCurrentX() {
    return _startX + (_getTargetX(_targetValue) + pi * 4 - _startX) * _animation.value;
  }

  double _getCurrentY() {
    return _startY + (_getTargetY(_targetValue) + pi * 4 - _startY) * _animation.value;
  }

  double _getTargetX(int value) {
    switch (value) {
      case 4: return pi / 2;    // Bottom face to front
      case 3: return -pi / 2;   // Top face to front
      default: return 0;
    }
  }

  double _getTargetY(int value) {
    switch (value) {
      case 2: return pi / 2;    // Left face to front
      case 5: return -pi / 2;   // Right face to front
      case 6: return pi;        // Back face to front
      default: return 0;        
    }
  }

  @override
  Widget build(BuildContext context) {
    double size = 52.0;
    double containerSize = 68.0;

    if (!widget.isRolling) {
      return GestureDetector(
        onTap: widget.onRoll,
        child: Container(
          width: containerSize,
          height: containerSize,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(1, 1)),
                ],
              ),
              child: CustomPaint(
                painter: _DicePainter(_targetValue),
              ),
            ),
          ),
        ),
      );
    }

    double hop = sin(_animation.value * pi) * 24.0;

    double rx = _getCurrentX();
    double ry = _getCurrentY();

    List<_FaceDef> faces = [
      _FaceDef(6, 0.0, 0.0, -size / 2, Matrix4.identity()..translate(0.0, 0.0, -size / 2)..rotateY(pi)),
      _FaceDef(5, size / 2, 0.0, 0.0, Matrix4.identity()..translate(size / 2, 0.0, 0.0)..rotateY(pi / 2)),
      _FaceDef(2, -size / 2, 0.0, 0.0, Matrix4.identity()..translate(-size / 2, 0.0, 0.0)..rotateY(-pi / 2)),
      _FaceDef(4, 0.0, size / 2, 0.0, Matrix4.identity()..translate(0.0, size / 2, 0.0)..rotateX(pi / 2)),
      _FaceDef(3, 0.0, -size / 2, 0.0, Matrix4.identity()..translate(0.0, -size / 2, 0.0)..rotateX(-pi / 2)),
      _FaceDef(1, 0.0, 0.0, size / 2, Matrix4.identity()..translate(0.0, 0.0, size / 2)),
    ];

    for (var f in faces) {
      double zp = f.y * sin(rx) + f.z * cos(rx);
      f.transformedZ = -f.x * sin(ry) + zp * cos(ry);
    }

    faces.sort((a, b) => a.transformedZ.compareTo(b.transformedZ));

    List<Widget> faceWidgets = faces.map((f) => _buildFace(f.value, size, f.transform)).toList();

    return GestureDetector(
      onTap: null,
      child: Container(
        width: containerSize,
        height: containerSize,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: const Offset(0, 22),
              child: Transform.scale(
                scale: 1.0 - (sin(_animation.value * pi) * 0.5),
                child: Container(
                  width: size * 0.7,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                    ]
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: Offset(0, -hop),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(rx)
                  ..rotateY(ry),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    children: faceWidgets,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFace(int value, double size, Matrix4 transform) {
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: CustomPaint(
          painter: _DicePainter(value),
        ),
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  final int value;
  _DicePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.black;
    double r = size.width * 0.09; 
    double cx = size.width / 2;
    double cy = size.height / 2;
    double offset = size.width * 0.25;

    void drawDot(double x, double y) {
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    switch (value) {
      case 1: drawDot(cx, cy); break;
      case 2: drawDot(cx - offset, cy - offset); drawDot(cx + offset, cy + offset); break;
      case 3: drawDot(cx - offset, cy - offset); drawDot(cx, cy); drawDot(cx + offset, cy + offset); break;
      case 4: drawDot(cx - offset, cy - offset); drawDot(cx + offset, cy - offset); drawDot(cx - offset, cy + offset); drawDot(cx + offset, cy + offset); break;
      case 5: drawDot(cx - offset, cy - offset); drawDot(cx + offset, cy - offset); drawDot(cx, cy); drawDot(cx - offset, cy + offset); drawDot(cx + offset, cy + offset); break;
      case 6: drawDot(cx - offset, cy - offset); drawDot(cx - offset, cy); drawDot(cx - offset, cy + offset); drawDot(cx + offset, cy - offset); drawDot(cx + offset, cy); drawDot(cx + offset, cy + offset); break;
    }
  }

  @override
  bool shouldRepaint(_DicePainter oldDelegate) => oldDelegate.value != value;
}
