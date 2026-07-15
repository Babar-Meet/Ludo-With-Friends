import 'package:flutter/material.dart';
import 'dart:math' as math;

class HoppingTokenWidget extends StatefulWidget {
  final double left;
  final double top;
  final Widget child;
  final Duration duration;

  const HoppingTokenWidget({
    super.key,
    required this.left,
    required this.top,
    required this.child,
    this.duration = const Duration(milliseconds: 250), // slightly faster for snappy feel
  });

  @override
  State<HoppingTokenWidget> createState() => _HoppingTokenWidgetState();
}

class _HoppingTokenWidgetState extends State<HoppingTokenWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _currentLeft;
  late double _currentTop;
  
  double _startLeft = 0;
  double _startTop = 0;

  @override
  void initState() {
    super.initState();
    _currentLeft = widget.left;
    _currentTop = widget.top;
    
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addListener(() {
      setState(() {
        _currentLeft = _startLeft + (widget.left - _startLeft) * _controller.value;
        _currentTop = _startTop + (widget.top - _startTop) * _controller.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant HoppingTokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.left != widget.left || oldWidget.top != widget.top) {
      _startLeft = _currentLeft;
      _startTop = _currentTop;
      
      double dx = widget.left - _startLeft;
      double dy = widget.top - _startTop;
      double distance = math.sqrt(dx * dx + dy * dy);
      
      if (distance > 100) {
        _controller.duration = const Duration(milliseconds: 800); // smooth flight
      } else {
        _controller.duration = widget.duration;
      }
      
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double t = _controller.value;
    
    double dx = widget.left - _startLeft;
    double dy = widget.top - _startTop;
    double distance = math.sqrt(dx * dx + dy * dy);
    bool isFlying = distance > 100;
    
    // Parabolic arc height
    double hopOffset = isFlying ? math.sin(t * math.pi) * 120.0 : math.sin(t * math.pi) * 35.0; 
    
    // Squash and stretch
    double scaleX = 1.0;
    double scaleY = 1.0;
    
    if (_controller.isAnimating && !isFlying) {
      // Stretch tall at the peak of the hop
      scaleY = 1.0 + (math.sin(t * math.pi) * 0.25);
      scaleX = 1.0 - (math.sin(t * math.pi) * 0.15);
    } else if (_controller.isAnimating && isFlying) {
      // Flying state: slightly elongated in direction of travel, but mostly steady
      scaleY = 1.1;
      scaleX = 0.9;
    }

    // Rotational wobble
    double angle = 0.0;
    
    if (_controller.isAnimating) {
      if (isFlying) {
        // Continuous spin or tilt
        angle = t * math.pi * 4; // spin while flying
      } else {
        // Tilt in direction of movement
        if (dx > 5) angle = math.pi / 8; // Right
        else if (dx < -5) angle = -math.pi / 8; // Left
        else if (dy < -5) angle = math.pi / 12; // Up (slight tilt)
        else if (dy > 5) angle = -math.pi / 12; // Down
        
        // Interpolate tilt so it returns to 0 at the end
        angle = angle * math.sin(t * math.pi);
      }
    }
    
    return Positioned(
      left: _currentLeft,
      top: _currentTop - hopOffset,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..rotateZ(angle)
          ..scale(scaleX, scaleY),
        child: widget.child,
      ),
    );
  }
}
